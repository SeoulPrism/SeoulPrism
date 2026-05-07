import 'package:flutter/foundation.dart';

/// 런타임 디버그 로그 게이트.
/// 설정에서 토글되며, 활성화될 때만 debugPrint 가 실제로 출력됨.
/// SettingsService 가 init 시점에 [enabled] 를 갱신함.
class DebugLog {
  static bool enabled = false;

  static void log(String message) {
    if (!enabled) return;
    debugPrint(message);
  }
}
