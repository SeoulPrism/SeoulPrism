import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';

/// 마이크 입력 및 오디오 재생 관리
/// flutter_sound로 PCM 스트리밍 재생 (파일 I/O 불필요, 마이크와 동시 가능)
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  StreamSubscription? _recordSubscription;
  bool _isRecording = false;
  bool _playerOpen = false;

  final _audioInController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioInStream => _audioInController.stream;

  final _levelController = StreamController<double>.broadcast();
  Stream<double> get levelStream => _levelController.stream;

  bool get isRecording => _isRecording;

  // base64 청크 저장
  final _base64Chunks = <String>[];

  AudioService() {
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // 오디오 세션: 재생 + 녹음 동시
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

    await _player.openPlayer();
    _playerOpen = true;
    debugPrint('[AudioService] Player opened + audio session configured');
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
      debugPrint('[AudioService] Recording started');
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

  /// base64 오디오 청크 저장 (메인 스레드 부하 없음)
  void bufferBase64(String base64Data) {
    _base64Chunks.add(base64Data);
  }

  /// 전체 버퍼를 PCM 스트리밍 재생 (파일 I/O 없음, 마이크 끄지 않음)
  Future<void> flushAndPlay() async {
    if (_base64Chunks.isEmpty || !_playerOpen) return;

    final chunks = List<String>.from(_base64Chunks);
    _base64Chunks.clear();

    // base64 → PCM 디코딩
    final pcmBuffer = BytesBuilder();
    for (final chunk in chunks) {
      pcmBuffer.add(base64Decode(chunk));
    }
    final pcmData = pcmBuffer.toBytes();
    if (pcmData.length < 100) return;

    debugPrint('[AudioService] Playing ${(pcmData.length / 48000.0).toStringAsFixed(1)}s via stream');

    try {
      // flutter_sound 스트리밍 재생: 파일 불필요, 마이크 영향 없음
      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        interleaved: true,
        sampleRate: 24000,
        numChannels: 1,
        bufferSize: 8192,
      );

      // PCM 데이터를 uint8ListSink에 전송
      _player.uint8ListSink?.add(pcmData);

      // 재생 시간만큼 대기 (24kHz 16-bit mono = 48000 bytes/sec)
      final durationMs = (pcmData.length / 48000.0 * 1000).round();
      await Future.delayed(Duration(milliseconds: durationMs + 200));

      await _player.stopPlayer();
    } catch (e) {
      debugPrint('[AudioService] Playback error: $e');
      try { await _player.stopPlayer(); } catch (_) {}
    }
  }

  void stopPlayback() {
    try { _player.stopPlayer(); } catch (_) {}
    _base64Chunks.clear();
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
    if (_playerOpen) {
      _player.closePlayer();
      _playerOpen = false;
    }
    _audioInController.close();
    _levelController.close();
  }
}
