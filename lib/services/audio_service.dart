import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

/// 마이크 입력 및 오디오 재생 관리
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  AudioPlayer? _player;
  StreamSubscription? _recordSubscription;
  bool _isRecording = false;

  final _audioInController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioInStream => _audioInController.stream;

  final _levelController = StreamController<double>.broadcast();
  Stream<double> get levelStream => _levelController.stream;

  bool get isRecording => _isRecording;

  // base64 문자열만 저장 (메인 스레드에서 디코딩 안 함)
  final _base64Chunks = <String>[];

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

  /// base64 오디오 청크 저장 (메인 스레드 부하 제로)
  void bufferBase64(String base64Data) {
    _base64Chunks.add(base64Data);
  }

  /// 모든 청크를 background isolate에서 디코딩 + WAV 생성 → 재생
  Future<void> flushAndPlay() async {
    if (_base64Chunks.isEmpty) return;

    final chunks = List<String>.from(_base64Chunks);
    _base64Chunks.clear();

    // 무거운 작업은 모두 isolate에서 (메인 스레드 블로킹 제로)
    final filePath = await compute(_decodeAndCreateWav, chunks);

    if (filePath == null) return;

    try {
      // 새 플레이어 생성 (이전 플레이어의 상태 문제 방지)
      _player?.dispose();
      _player = AudioPlayer();

      await _player!.setFilePath(filePath);
      await _player!.play();

      debugPrint('[AudioService] Playing ${chunks.length} chunks');

      // 재생 완료 대기
      await _player!.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      ).timeout(const Duration(seconds: 30), onTimeout: () => _player!.playerState);

      try { await File(filePath).delete(); } catch (_) {}
    } catch (e) {
      debugPrint('[AudioService] Playback error: $e');
    }
  }

  /// [Isolate] base64 디코딩 + WAV 파일 생성 (메인 스레드 밖에서 실행)
  static String? _decodeAndCreateWav(List<String> base64Chunks) {
    try {
      final pcmBuffer = BytesBuilder();
      for (final chunk in base64Chunks) {
        pcmBuffer.add(base64Decode(chunk));
      }
      final pcmData = pcmBuffer.toBytes();
      if (pcmData.length < 100) return null;

      final wavData = _buildWav(pcmData, 24000);
      final filePath = '${Directory.systemTemp.path}/sp_${DateTime.now().millisecondsSinceEpoch}.wav';
      File(filePath).writeAsBytesSync(wavData);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// WAV 헤더 + PCM 데이터 결합
  static Uint8List _buildWav(Uint8List pcmData, int sampleRate) {
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;
    final byteRate = sampleRate * 2; // 16-bit mono

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

  void stopPlayback() {
    _player?.stop();
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
    _player?.dispose();
    _audioInController.close();
    _levelController.close();
  }
}
