import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'recent_route_service.dart';

/// 홈위젯/Control 위젯과 데이터 공유.
/// iOS App Group `group.com.seoul.prism.widget` 의 UserDefaults 에 최근 길찾기 페어 저장.
/// Android 는 미지원 (no-op).
class WidgetDataService {
  static final WidgetDataService instance = WidgetDataService._();
  WidgetDataService._();

  static const _channel = MethodChannel('seoul_prism/widget_data');

  bool get _supported => Platform.isIOS;

  /// 최근 길찾기 페어 1개 push (가장 최근 1개만).
  Future<void> pushRecentRoute(RecentRoute? r) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('setRecentRoute', {
        'departure': r?.departure ?? '',
        'arrival': r?.arrival ?? '',
        'depLat': r?.depLat,
        'depLng': r?.depLng,
        'arrLat': r?.arrLat,
        'arrLng': r?.arrLng,
      });
    } catch (e) {
      debugPrint('[WidgetData] pushRecentRoute 실패: $e');
    }
  }

  /// RecentRoute 리스트가 갱신될 때 호출 — 첫 번째 항목을 위젯용으로 push.
  Future<void> syncFromService() async {
    final routes = RecentRouteService.instance.routes;
    await pushRecentRoute(routes.isNotEmpty ? routes.first : null);
  }
}
