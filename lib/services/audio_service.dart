import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// 마이크 입력 및 오디오 재생 관리
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  late final AudioPlayer _player;
  StreamSubscription? _recordSubscription;
  bool _isRecording = false;
  bool _playerReady = false;

  final _audioInController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioInStream => _audioInController.stream;

  final _levelController = StreamController<double>.broadcast();
  Stream<double> get levelStream => _levelController.stream;

  bool get isRecording => _isRecording;

  // base64 문자열만 저장 (메인 스레드 부하 제로)
  final _base64Chunks = <String>[];

  AudioService() {
    _player = AudioPlayer();
    _playerReady = true;
    _configureAudioSession();
  }

  /// 오디오 세션 설정: 재생과 녹음 동시 허용
  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.voiceChat,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
    ));
    debugPrint('[AudioService] Audio session configured: playAndRecord + voiceCommunication');
  }

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> startRecording() async {
    if (_isRecording) return true;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      final granted = await requestMicPermission();
      if (!granted) return false;
    }

    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );

      _recordSubscription = stream.listen((data) {
        _audioInController.add(Uint8List.fromList(data));
        final level = _calculateRmsLevel(Uint8List.fromList(data));
        _levelController.add(level);
      });

      _isRecording = true;
      return true;
    } catch (e) {
      debugPrint('[AudioService] Failed to start recording: $e');
      return false;
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _recordSubscription?.cancel();
    _recordSubscription = null;
    await _recorder.stop();
    _isRecording = false;
  }

  /// base64 문자열 저장 (O(1), 메인 스레드 부하 없음)
  void bufferBase64(String base64Data) {
    _base64Chunks.add(base64Data);
  }

  /// generationComplete 시 호출 — 디코딩 + WAV 생성 + 재생
  Future<void> flushAndPlay() async {
    if (_base64Chunks.isEmpty || !_playerReady) return;

    final chunks = List<String>.from(_base64Chunks);
    _base64Chunks.clear();

    // WAV 파일 생성 (isolate 없이 — 리스트 저장만 했으므로 빠름)
    final pcmBuffer = BytesBuilder();
    for (final chunk in chunks) {
      pcmBuffer.add(base64Decode(chunk));
    }
    final pcmData = pcmBuffer.toBytes();
    if (pcmData.length < 100) return;

    final wavData = _buildWav(pcmData, 24000);
    final filePath = '${Directory.systemTemp.path}/sp_${DateTime.now().millisecondsSinceEpoch}.wav';
    await File(filePath).writeAsBytes(wavData);

    try {
      await _player.setFilePath(filePath);
      await _player.play();

      // 재생 완료 대기
      await _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      ).timeout(const Duration(seconds: 30), onTimeout: () => _player.playerState);

      try { await File(filePath).delete(); } catch (_) {}
    } catch (e) {
      debugPrint('[AudioService] Playback error: $e');
    }
  }

  void stopPlayback() {
    _player.stop();
    _base64Chunks.clear();
  }

  static Uint8List _buildWav(Uint8List pcmData, int sampleRate) {
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;
    final byteRate = sampleRate * 2;

    final header = ByteData(44);
    header.setUint8(0, 0x52); header.setUint8(1, 0x49);
    header.setUint8(2, 0x46); header.setUint8(3, 0x46);
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57); header.setUint8(9, 0x41);
    header.setUint8(10, 0x56); header.setUint8(11, 0x45);
    header.setUint8(12, 0x66); header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74); header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint8(36, 0x64); header.setUint8(37, 0x61);
    header.setUint8(38, 0x74); header.setUint8(39, 0x61);
    header.setUint32(40, dataSize, Endian.little);

    final wav = BytesBuilder();
    wav.add(header.buffer.asUint8List());
    wav.add(pcmData);
    return wav.toBytes();
  }

  double _calculateRmsLevel(Uint8List pcmData) {
    if (pcmData.length < 2) return 0.0;
    final byteData = ByteData.sublistView(pcmData);
    double sumSquares = 0;
    final sampleCount = pcmData.length ~/ 2;
    for (int i = 0; i < sampleCount; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      final normalized = sample / 32768.0;
      sumSquares += normalized * normalized;
    }
    final rms = sampleCount > 0 ? (sumSquares / sampleCount) : 0.0;
    return (rms * 10).clamp(0.0, 1.0);
  }

  void dispose() {
    stopRecording();
    stopPlayback();
    _recorder.dispose();
    _player.dispose();
    _playerReady = false;
    _audioInController.close();
    _levelController.close();
  }
}
