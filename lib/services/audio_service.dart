import 'dart:async';
import 'dart:collection';
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

  // ── 오디오 재생 (스트리밍 방식) ──
  final _pcmBuffer = BytesBuilder();
  final _playQueue = Queue<Uint8List>();
  bool _isPlaying = false;
  Timer? _flushTimer;

  // 24kHz 16-bit mono: 48000 bytes/sec → ~12000 bytes = 0.25초
  static const _flushThreshold = 12000;

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

  /// PCM 오디오 청크를 버퍼에 추가 + 자동 flush
  void bufferAudio(Uint8List pcmData) {
    _pcmBuffer.add(pcmData);

    // 일정량 쌓이면 즉시 flush
    if (_pcmBuffer.length >= _flushThreshold) {
      _flushBuffer();
    } else {
      // 작은 청크도 200ms 후 자동 flush (마지막 조각 처리)
      _flushTimer?.cancel();
      _flushTimer = Timer(const Duration(milliseconds: 200), _flushBuffer);
    }
  }

  /// 턴 완료 시 남은 버퍼 강제 flush
  void flushAndPlay() {
    _flushTimer?.cancel();
    _flushBuffer();
  }

  void _flushBuffer() {
    if (_pcmBuffer.isEmpty) return;

    final pcmData = _pcmBuffer.toBytes();
    _pcmBuffer.clear();

    if (pcmData.length < 100) return;

    _playQueue.add(pcmData);
    _playNext();
  }

  Future<void> _playNext() async {
    if (_isPlaying || _playQueue.isEmpty) return;
    _isPlaying = true;

    while (_playQueue.isNotEmpty) {
      final pcmData = _playQueue.removeFirst();

      try {
        // PCM 24kHz → WAV
        final wavData = _pcmToWav(pcmData, sampleRate: 24000);
        final file = File('${Directory.systemTemp.path}/sp_audio_${DateTime.now().millisecondsSinceEpoch}.wav');
        await file.writeAsBytes(wavData);

        await _player.setFilePath(file.path);
        await _player.play();

        // 재생 완료 대기
        await _player.playerStateStream.firstWhere(
          (state) => state.processingState == ProcessingState.completed,
        );

        try { await file.delete(); } catch (_) {}
      } catch (e) {
        debugPrint('[AudioService] Playback error: $e');
      }
    }

    _isPlaying = false;
  }

  /// PCM raw data → WAV file bytes
  Uint8List _pcmToWav(Uint8List pcmData, {int sampleRate = 24000, int channels = 1, int bitsPerSample = 16}) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

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
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    header.setUint8(36, 0x64); header.setUint8(37, 0x61);
    header.setUint8(38, 0x74); header.setUint8(39, 0x61);
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
    _flushTimer?.cancel();
    stopRecording();
    _recorder.dispose();
    _player.dispose();
    _pcmBuffer.clear();
    _playQueue.clear();
    _audioInController.close();
    _levelController.close();
  }
}
