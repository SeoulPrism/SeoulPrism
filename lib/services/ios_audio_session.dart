import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS AVAudioSession 제어.
///
/// Gemini Live 처럼 마이크 (record + VoiceProcessingIO echoCancel) 와
/// 스피커 (SoLoud) 를 동시에 쓸 때 native 단에서 category 를
/// playAndRecord + voiceChat 으로 통일하지 않으면 `auou/vpio/appl render err: -1`
/// 가 반복 발생한다. AI 진입 시 activate, 이탈 시 deactivate 한다.
class IosAudioSession {
  static const _channel = MethodChannel('seoul_prism/audio_session');

  /// AI 진입 시 호출. iOS 외 플랫폼에서는 no-op.
  static Future<void> activateVoiceChat() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('activateVoiceChat');
    } catch (e) {
      debugPrint('[IosAudioSession] activate failed: $e');
    }
  }

  /// AI 이탈 시 호출. 다른 앱 (음악 등) 에 audio session 양보.
  static Future<void> deactivate() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('deactivate');
    } catch (e) {
      debugPrint('[IosAudioSession] deactivate failed: $e');
    }
  }
}
