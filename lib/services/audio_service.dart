import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:permission_handler/permission_handler.dart';

/// 공식 firebase_ai 예제 패턴:
/// - 녹음: record 패키지 (AudioRecorder)
/// - 재생: flutter_soloud (SoLoud 엔진 — AudioFocus 안 씀, 마이크 방해 안 함)
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  // SoLoud 재생
  AudioSource? _stream;
  SoundHandle? _handle;
  bool _soloudReady = false;

  // 녹음 데이터 → Gemini
  Stream<Uint8List>? audioInputStream;

  // 오디오 레벨 (Glow 반응)
  final _levelController = StreamController<double>.broadcast();
  Stream<double> get levelStream => _levelController.stream;

  bool get isRecording => _isRecording;

  /// SoLoud 초기화 (24kHz mono)
  Future<void> init() async {
    try {
      await SoLoud.instance.init(sampleRate: 24000, channels: Channels.mono);
      await _setupNewStream();
      _soloudReady = true;
      debugPrint('[AudioService] SoLoud ready (24kHz mono)');
    } catch (e) {
      debugPrint('[AudioService] SoLoud init failed: $e');
    }
  }

  Future<void> _setupNewStream() async {
    if (!SoLoud.instance.isInitialized) return;
    await _stopStream();
    _stream = SoLoud.instance.setBufferStream(
      maxBufferSizeBytes: 1024 * 1024 * 10,
      bufferingType: BufferingType.released,
      bufferingTimeNeeds: 0,
      onBuffering: (isBuffering, handle, time) {},
    );
    _handle = null;
  }

  Future<void> _stopStream() async {
    if (_stream != null && _handle != null &&
        SoLoud.instance.getIsValidVoiceHandle(_handle!)) {
      SoLoud.instance.setDataIsEnded(_stream!);
      await SoLoud.instance.stop(_handle!);
    }
  }

  /// 재생 스트림 시작 (오디오 청크 feed 전에 호출)
  Future<void> startPlayStream() async {
    if (!_soloudReady || _stream == null) return;
    _handle = await SoLoud.instance.play(_stream!);
  }

  /// AI 오디오 청크 즉시 재생 (마이크에 영향 없음)
  void feedAudioChunk(Uint8List audioBytes) {
    if (!_soloudReady || _stream == null) return;
    SoLoud.instance.addAudioDataStream(_stream!, audioBytes);
  }

  /// 재생 종료 + 새 스트림 준비
  Future<void> stopPlayStream() async {
    await _setupNewStream();
  }

  /// 마이크 권한 확인
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// 녹음 시작 → Stream<Uint8List> 반환 (공식 예제 패턴)
  Future<Stream<Uint8List>?> startRecording() async {
    if (_isRecording) return audioInputStream;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      final granted = await checkPermission();
      if (!granted) return null;
    }

    final recordConfig = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
      androidConfig: const AndroidRecordConfig(
        audioSource: AndroidAudioSource.voiceCommunication,
      ),
    );

    audioInputStream = await _recorder.startStream(recordConfig);
    _isRecording = true;
    debugPrint('[AudioService] Recording started (16kHz mono)');

    // 레벨 계산용 리스너
    audioInputStream!.listen((data) {
      _levelController.add(_calculateRmsLevel(data));
    });

    return audioInputStream;
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    await _recorder.stop();
    _isRecording = false;
    debugPrint('[AudioService] Recording stopped');
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
    _stopStream();
    if (_soloudReady) {
      SoLoud.instance.deinit();
    }
    _recorder.dispose();
    _levelController.close();
  }
}
