import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// 마이크 입력 및 오디오 재생 관리
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription? _recordSubscription;
  bool _isRecording = false;

  /// 마이크 오디오 스트림 (PCM 16kHz 16-bit mono)
  final _audioInController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioInStream => _audioInController.stream;

  /// 현재 오디오 레벨 (0.0 ~ 1.0, Glow 반응용)
  final _levelController = StreamController<double>.broadcast();
  Stream<double> get levelStream => _levelController.stream;

  bool get isRecording => _isRecording;

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

  /// PCM 오디오 재생 (24kHz 16-bit mono → 시스템 출력)
  /// Flutter에서 raw PCM을 직접 재생하는 것은 제한적이므로
  /// 현재는 텍스트 기반 응답에 집중하고, 추후 네이티브 플러그인으로 확장
  Future<void> playPcmAudio(Uint8List pcmData) async {
    // TODO: 네이티브 PCM 재생 구현
    // 현재는 텍스트 응답 + TTS 방식으로 대체 가능
    debugPrint('[AudioService] PCM audio received: ${pcmData.length} bytes');
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
    // 스케일 조정 (일반 음성 기준)
    return (rms * 10).clamp(0.0, 1.0);
  }

  void dispose() {
    stopRecording();
    _recorder.dispose();
    _audioInController.close();
    _levelController.close();
  }
}
