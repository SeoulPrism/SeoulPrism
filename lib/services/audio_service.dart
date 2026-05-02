import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart' show Level;

/// 마이크 입력 및 오디오 재생 관리
/// flutter_sound로 녹음 + 재생 모두 처리 (패키지 충돌 없음)
///
/// 참고: https://github.com/alfredobs97/gemini_talk
/// - Player: startPlayerFromStream 1번 → feedUint8FromStream으로 실시간 재생
/// - Recorder: FlutterSoundRecorder로 PCM 스트리밍 녹음
class AudioService {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _playerOpen = false;
  bool _playerStreaming = false;
  bool _isRecording = false;

  // 녹음 데이터 스트림
  final _recordingDataController = StreamController<Uint8List>.broadcast();
  final _audioInController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioInStream => _audioInController.stream;

  final _levelController = StreamController<double>.broadcast();
  Stream<double> get levelStream => _levelController.stream;

  bool get isRecording => _isRecording;

  // base64 청크 저장
  final _base64Chunks = <String>[];

  AudioService() {
    _init();
  }

  Future<void> _init() async {
    // 플레이어 열기
    await _player.openPlayer();
    _player.setLogLevel(Level.warning);
    _playerOpen = true;

    // 플레이어를 스트리밍 모드로 시작 (1번만, 이후 feed로 데이터 전달)
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      interleaved: true,
      sampleRate: 24000,
      numChannels: 1,
      bufferSize: 8192,
    );
    _playerStreaming = true;
    debugPrint('[AudioService] Player streaming mode ready');
  }

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// 녹음 시작 (FlutterSoundRecorder — flutter_sound 통합)
  Future<bool> startRecording() async {
    if (_isRecording) return true;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return false;

    try {
      if (_recorder.isStopped) {
        await _recorder.openRecorder();
        _recorder.setLogLevel(Level.warning);
      }

      // PCM 16kHz mono 스트리밍 녹음
      await _recorder.startRecorder(
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
        toStream: _recordingDataController.sink,
      );

      // 녹음 데이터를 외부 스트림으로 전달
      _recordingDataController.stream.listen((data) {
        _audioInController.add(data);
        final level = _calculateRmsLevel(data);
        _levelController.add(level);
      });

      _isRecording = true;
      debugPrint('[AudioService] Recording started (FlutterSoundRecorder)');
      return true;
    } catch (e) {
      debugPrint('[AudioService] Failed to start recording: $e');
      return false;
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    await _recorder.stopRecorder();
    _isRecording = false;
    debugPrint('[AudioService] Recording stopped');
  }

  /// base64 오디오 청크 저장
  void bufferBase64(String base64Data) {
    _base64Chunks.add(base64Data);
  }

  /// 전체 버퍼를 디코딩 → feedUint8FromStream으로 즉시 재생
  /// (stopPlayer/startPlayer 없이, 스트리밍 모드 유지)
  Future<void> flushAndPlay() async {
    if (_base64Chunks.isEmpty || !_playerStreaming) return;

    final chunks = List<String>.from(_base64Chunks);
    _base64Chunks.clear();

    // base64 → PCM 디코딩
    final pcmBuffer = BytesBuilder();
    for (final chunk in chunks) {
      pcmBuffer.add(base64Decode(chunk));
    }
    final pcmData = pcmBuffer.toBytes();
    if (pcmData.length < 100) return;

    final durationSec = pcmData.length / 48000.0;
    debugPrint('[AudioService] Feeding ${durationSec.toStringAsFixed(1)}s to player stream');

    // feedUint8FromStream: 이미 열린 스트림에 데이터만 넣으면 바로 재생
    await _player.feedUint8FromStream(pcmData);

    // 재생 시간만큼 대기
    await Future.delayed(Duration(milliseconds: (durationSec * 1000 + 300).round()));
  }

  void stopPlayback() {
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
    if (_playerStreaming) {
      _player.stopPlayer();
      _playerStreaming = false;
    }
    if (_playerOpen) {
      _player.closePlayer();
      _playerOpen = false;
    }
    if (!_recorder.isStopped) {
      _recorder.stopRecorder();
    }
    try { _recorder.closeRecorder(); } catch (_) {}
    _recordingDataController.close();
    _audioInController.close();
    _levelController.close();
  }
}
