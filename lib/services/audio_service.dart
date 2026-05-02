import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

/// 마이크 입력 및 오디오 재생 관리
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _recordSubscription;
  bool _isRecording = false;

  /// 마이크 오디오 스트림 (PCM 16kHz 16-bit mono)
  final _audioInController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioInStream => _audioInController.stream;

  /// 현재 오디오 레벨 (0.0 ~ 1.0, Glow 반응용)
  final _levelController = StreamController<double>.broadcast();
  Stream<double> get levelStream => _levelController.stream;

  bool get isRecording => _isRecording;

  // PCM 오디오 버퍼 (턴 단위로 누적)
  final _pcmBuffer = BytesBuilder();
  bool _isPlaying = false;

  /// 마이크 권한 요청
  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// 마이크 녹음 시작 (PCM 스트리밍)
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

        // RMS 기반 볼륨 레벨 계산
        final level = _calculateRmsLevel(Uint8List.fromList(data));
        _levelController.add(level);
      });

      _isRecording = true;
      debugPrint('[AudioService] Recording started (PCM 16kHz mono)');
      return true;
    } catch (e) {
      debugPrint('[AudioService] Failed to start recording: $e');
      return false;
    }
  }

  /// 마이크 녹음 중지
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _recordSubscription?.cancel();
    _recordSubscription = null;
    await _recorder.stop();
    _isRecording = false;
    debugPrint('[AudioService] Recording stopped');
  }

  /// PCM 오디오 청크를 버퍼에 추가
  void bufferAudio(Uint8List pcmData) {
    _pcmBuffer.add(pcmData);
  }

  /// 버퍼에 쌓인 오디오를 WAV로 변환 후 재생
  Future<void> flushAndPlay() async {
    if (_pcmBuffer.isEmpty) return;

    final pcmData = _pcmBuffer.toBytes();
    _pcmBuffer.clear();

    if (pcmData.length < 100) return; // 너무 짧은 오디오 무시

    try {
      // PCM → WAV 변환
      // Gemini Live API 출력: PCM 16kHz 16-bit mono
      final wavData = _pcmToWav(pcmData, sampleRate: 16000, channels: 1, bitsPerSample: 16);

      // 임시 파일 저장
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/gemini_response_${DateTime.now().millisecondsSinceEpoch}.wav');
      await file.writeAsBytes(wavData);

      // 재생
      _isPlaying = true;
      await _player.setFilePath(file.path);
      await _player.play();

      // 재생 완료 대기
      await _player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
      _isPlaying = false;

      // 임시 파일 삭제
      try { await file.delete(); } catch (_) {}

      debugPrint('[AudioService] Played ${pcmData.length} bytes of audio');
    } catch (e) {
      _isPlaying = false;
      debugPrint('[AudioService] Playback error: $e');
    }
  }

  /// PCM raw data → WAV file bytes
  Uint8List _pcmToWav(Uint8List pcmData, {int sampleRate = 24000, int channels = 1, int bitsPerSample = 16}) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // chunk size
    header.setUint16(20, 1, Endian.little);  // PCM format
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final wav = BytesBuilder();
    wav.add(header.buffer.asUint8List());
    wav.add(pcmData);
    return wav.toBytes();
  }

  /// RMS 레벨 계산 (0.0 ~ 1.0)
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
    _recorder.dispose();
    _player.dispose();
    _pcmBuffer.clear();
    _audioInController.close();
    _levelController.close();
  }
}
