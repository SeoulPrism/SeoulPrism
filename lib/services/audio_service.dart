import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ios_audio_session.dart';

/// 공식 firebase_ai 예제 패턴:
/// - 녹음: record 패키지 (AudioRecorder)
/// - 재생: flutter_soloud (SoLoud 엔진 — AudioFocus 안 씀, 마이크 방해 안 함)
///
/// singleton — AiView 인스턴스마다 새로 만들지 않는다. SoLoud / recorder 는 앱 lifecycle 동안 유지.
class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  AudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  // SoLoud 재생
  AudioSource? _stream;
  SoundHandle? _handle;
  bool _soloudReady = false;
  bool _isPlaying = false;
  bool _playReady = false; // play() 완료 여부
  final List<Uint8List> _pendingChunks = []; // play() 완료 전 도착한 청크

  // 녹음 데이터 → Gemini. broadcast 로 만들어서 level 계산 listener 와
  // sendMediaStream 의 await-for listener 가 같이 쓸 수 있게 한다.
  Stream<Uint8List>? audioInputStream;
  StreamSubscription<Uint8List>? _levelSub;

  // 오디오 레벨 (Glow 반응)
  final _levelController = StreamController<double>.broadcast();
  Stream<double> get levelStream => _levelController.stream;

  bool get isRecording => _isRecording;

  /// SoLoud 초기화 (24kHz mono) — 네이티브 라이브러리 로딩 지연 대비 재시도
  Future<void> init() async {
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (SoLoud.instance.isInitialized) {
          _soloudReady = true;
          debugPrint('[AudioService] SoLoud already initialized');
          return;
        }
        await SoLoud.instance.init(sampleRate: 24000, channels: Channels.mono);
        _soloudReady = true;
        debugPrint('[AudioService] SoLoud ready (24kHz mono)');
        return;
      } catch (e) {
        debugPrint('[AudioService] SoLoud init attempt $attempt/$maxRetries failed: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
    debugPrint('[AudioService] SoLoud init failed after $maxRetries attempts');
  }

  Future<void> _stopStream() async {
    if (_stream != null && _handle != null &&
        SoLoud.instance.getIsValidVoiceHandle(_handle!)) {
      SoLoud.instance.setDataIsEnded(_stream!);
      await SoLoud.instance.stop(_handle!);
    }
    _stream = null;
    _handle = null;
  }

  /// 재생 스트림 시작 (새 발화마다 한 번만 호출됨)
  Future<void> startPlayStream() async {
    if (!_soloudReady || _isPlaying) return;
    _isPlaying = true;
    _playReady = false;
    _pendingChunks.clear();
    _stream = SoLoud.instance.setBufferStream(
      maxBufferSizeBytes: 1024 * 1024 * 10,
      bufferingType: BufferingType.released,
      bufferingTimeNeeds: 0,
      onBuffering: (isBuffering, handle, time) {},
    );
    _handle = await SoLoud.instance.play(_stream!);
    // play() 완료 → 대기 중이던 청크 flush
    _playReady = true;
    for (final chunk in _pendingChunks) {
      SoLoud.instance.addAudioDataStream(_stream!, chunk);
    }
    _pendingChunks.clear();
  }

  /// AI 오디오 청크 즉시 재생 (마이크에 영향 없음)
  void feedAudioChunk(Uint8List audioBytes) {
    if (!_soloudReady) return;
    if (!_isPlaying) {
      // 첫 청크 도착 시 자동으로 스트림 시작
      startPlayStream();
    }
    if (!_playReady) {
      _pendingChunks.add(audioBytes);
      return;
    }
    if (_stream == null) return;
    SoLoud.instance.addAudioDataStream(_stream!, audioBytes);
  }

  /// 현재 발화 종료 표시 (버퍼 오디오는 계속 재생, 다음 startPlayStream에서 정리)
  void markPlayStreamEnded() {
    _isPlaying = false;
    _playReady = false;
    _pendingChunks.clear();
  }

  /// 사용자 interrupt 시 — 큐된 audio 즉시 중단해서 잘린 음성 잔여 재생을 막는다.
  Future<void> flushPlayback() async {
    _pendingChunks.clear();
    await _stopStream();
    _isPlaying = false;
    _playReady = false;
  }

  /// 마이크 권한 확인
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// 녹음 시작 → Stream<Uint8List> 반환 (broadcast — 여러 listener 가능).
  Future<Stream<Uint8List>?> startRecording() async {
    if (_isRecording) return audioInputStream;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      final granted = await checkPermission();
      if (!granted) return null;
    }

    // iOS — VPIO 마이크 + 스피커 동시 사용 위해 audio session 통일.
    // 녹음 시작 *전* 에 활성화해야 VPIO 가 render err -1 안 던짐.
    await IosAudioSession.activateVoiceChat();

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

    final raw = await _recorder.startStream(recordConfig);
    // single-subscription → broadcast 로 변환. sendMediaStream 과 level 계산이
    // 같은 stream 을 동시에 listen 해야 하기 때문.
    audioInputStream = raw.asBroadcastStream();
    _isRecording = true;
    debugPrint('[AudioService] Recording started (16kHz mono)');

    // 레벨 계산용 리스너
    _levelSub = audioInputStream!.listen((data) {
      _levelController.add(_calculateRmsLevel(data));
    });

    return audioInputStream;
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    await _levelSub?.cancel();
    _levelSub = null;
    try {
      await _recorder.stop();
    } catch (e) {
      debugPrint('[AudioService] stopRecording error (suppressed): $e');
    }
    audioInputStream = null;
    // 다른 앱 (음악 등) 에 audio session 돌려준다.
    await IosAudioSession.deactivate();
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

  /// 앱 lifecycle 동안 singleton 유지가 의도이므로 일반적으로 호출되지 않는다.
  /// 명시적으로 정리하고 싶을 때만 호출.
  Future<void> dispose() async {
    await stopRecording();
    await _stopStream();
    await _recorder.dispose();
    await _levelController.close();
  }
}
