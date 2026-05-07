import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 다이나믹 아일랜드 + 잠금화면 Live Activity 추상화.
/// iOS 16.1+ 의 ActivityKit 으로 구현. 다른 플랫폼은 무시 (no-op).
///
/// native 측 wire-up:
///   ios/Runner/AppDelegate.swift 에 MethodChannel handler 추가 +
///   Widget Extension target 으로 Live Activity Widget 정의 (별도 가이드 참고).
///
/// 호출 패턴:
///   - 길찾기 결과 표시되자마자 [start] (활성 구간 도착정보 + 다음 단계).
///   - 위치 변경 / 활성 구간 변경 시 [update].
///   - 길찾기 종료 또는 화면 떠날 때 [stop].
class LiveActivityService {
  static final LiveActivityService instance = LiveActivityService._();
  LiveActivityService._();

  static const _channel = MethodChannel('seoul_prism/live_activity');
  bool _started = false;
  String? _activityId;

  bool get _supported => Platform.isIOS;

  /// 새 Live Activity 시작. 이미 시작된 게 있으면 [update] 로 처리.
  Future<void> start({
    required String headline, // 예: "143번 버스 ─ 강남역"
    required String detail, // 예: "곧 도착 · 4정거장"
    required int etaMinutes, // 다음 단계까지 분 (다이나믹 아일랜드 minimal 영역에 큰 숫자로)
    required String? lineColorHex, // 노선 색 (#FF0000)
    int totalMinutes = 0, // 전체 길찾기 잔여 분
    String? destination, // 최종 도착지 이름
  }) async {
    if (!_supported) return;
    try {
      if (_started) {
        return update(
          headline: headline,
          detail: detail,
          etaMinutes: etaMinutes,
          lineColorHex: lineColorHex,
          totalMinutes: totalMinutes,
          destination: destination,
        );
      }
      final id = await _channel.invokeMethod<String>('start', {
        'headline': headline,
        'detail': detail,
        'etaMinutes': etaMinutes,
        'lineColorHex': lineColorHex,
        'totalMinutes': totalMinutes,
        'destination': destination,
      });
      _activityId = id;
      _started = true;
    } catch (e) {
      // native 미구현 또는 권한 거부 — silent.
      debugPrint('[LiveActivity] start 실패: $e');
    }
  }

  Future<void> update({
    required String headline,
    required String detail,
    required int etaMinutes,
    String? lineColorHex,
    int totalMinutes = 0,
    String? destination,
  }) async {
    if (!_supported || !_started) return;
    try {
      await _channel.invokeMethod('update', {
        'activityId': _activityId,
        'headline': headline,
        'detail': detail,
        'etaMinutes': etaMinutes,
        'lineColorHex': lineColorHex,
        'totalMinutes': totalMinutes,
        'destination': destination,
      });
    } catch (e) {
      debugPrint('[LiveActivity] update 실패: $e');
    }
  }

  Future<void> stop() async {
    if (!_supported || !_started) return;
    try {
      await _channel.invokeMethod('stop', {'activityId': _activityId});
    } catch (e) {
      debugPrint('[LiveActivity] stop 실패: $e');
    } finally {
      _started = false;
      _activityId = null;
    }
  }
}
