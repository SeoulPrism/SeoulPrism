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
  StreamSubscription? _playerStateSub;
  bool _isRecording = false;

  final _audioInController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioInStream => _audioInController.stream;

  final _levelController = StreamController<double>.broadcast();
  Stream<double> get levelStream => _levelController.stream;

  /// 재생 완료 알림
  final _playbackDoneController = StreamController<void>.broadcast();
  Stream<void> get playbackDoneStream => _playbackDoneController.stream;

  bool get isRecording => _isRecording;

  // ── 스트리밍 재생 ──
  final _pcmBuffer = BytesBuilder();
  ConcatenatingAudioSource? _playlist;
  bool _isPlaybackActive = false;
  Timer? _flushTimer;
  int _segCounter = 0;
  final _tempFiles = <String>[];
  Completer<void>? _playbackCompleter;

  // 24kHz 16-bit mono: 48000 bytes/sec → 48000 = 1초 분량
  static const _flushThreshold = 48000;

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

  /// 첫 오디오 청크 시 마이크를 멈추고 재생 준비
  /// 이후 청크는 gapless playlist에 추가
  void bufferAudio(Uint8List pcmData) {
    _pcmBuffer.add(pcmData);

    if (_pcmBuffer.length >= _flushThreshold) {
      _flushToPlaylist();
    } else if (!_isPlaybackActive) {
      // 첫 청크: 0.3초 후 바로 재생 시작 (약간의 버퍼)
      _flushTimer?.cancel();
      _flushTimer = Timer(const Duration(milliseconds: 300), _flushToPlaylist);
    } else {
      // 이미 재생 중: 0.5초 타이머로 누적 후 추가
      _flushTimer?.cancel();
      _flushTimer = Timer(const Duration(milliseconds: 500), _flushToPlaylist);
    }
  }

  /// 턴 완료: 잔여 버퍼 flush + 재생 완료 대기
  Future<void> flushAndWaitDone() async {
    _flushTimer?.cancel();
    _flushToPlaylist();

    // 재생 완료까지 대기
    if (_isPlaybackActive && _playbackCompleter != null) {
      await _playbackCompleter!.future;
    }
  }

  void _flushToPlaylist() {
    if (_pcmBuffer.isEmpty) return;

    final pcmData = _pcmBuffer.toBytes();
    _pcmBuffer.clear();

    if (pcmData.length < 100) return;

    final wavData = _pcmToWav(pcmData, sampleRate: 24000);
    final filePath = '${Directory.systemTemp.path}/sp_s${_segCounter++}.wav';
    File(filePath).writeAsBytesSync(wavData);
    _tempFiles.add(filePath);

    if (!_isPlaybackActive) {
      // 첫 세그먼트: playlist 생성 + 재생 시작
      _playlist = ConcatenatingAudioSource(children: [
        AudioSource.file(filePath),
      ]);
      _isPlaybackActive = true;
      _playbackCompleter = Completer<void>();

      _startPlayback();
    } else {
      // 추가 세그먼트: gapless 추가
      _playlist?.add(AudioSource.file(filePath));
    }
  }

  Future<void> _startPlayback() async {
    try {
      await _player.setAudioSource(_playlist!);
      _player.play();

      // 재생 완료 감지
      _playerStateSub?.cancel();
      _playerStateSub = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _onPlaybackComplete();
        }
      });

      debugPrint('[AudioService] Streaming playback started');
    } catch (e) {
      debugPrint('[AudioService] Playback start error: $e');
      _onPlaybackComplete();
    }
  }

  void _onPlaybackComplete() {
    _playerStateSub?.cancel();
    _isPlaybackActive = false;

    // 임시 파일 정리
    for (final path in _tempFiles) {
      try { File(path).deleteSync(); } catch (_) {}
    }
    _tempFiles.clear();
    _segCounter = 0;
    _playlist = null;

    if (_playbackCompleter != null && !_playbackCompleter!.isCompleted) {
      _playbackCompleter!.complete();
    }
    _playbackDoneController.add(null);

    debugPrint('[AudioService] Playback complete');
  }

  void stopPlayback() {
    _flushTimer?.cancel();
    _player.stop();
    _pcmBuffer.clear();
    if (_isPlaybackActive) {
      _onPlaybackComplete();
    }
  }

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
    _playerStateSub?.cancel();
    stopRecording();
    stopPlayback();
    _recorder.dispose();
    _player.dispose();
    _audioInController.close();
    _levelController.close();
    _playbackDoneController.close();
  }
}
