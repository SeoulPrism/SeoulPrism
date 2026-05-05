import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/map_interface.dart';
import '../models/bus_models.dart';
import '../services/settings_service.dart';
import '../services/seoul_bus_service.dart';
import '../data/river_bus_data.dart';

/// 버스 노선 유형별 색상
class BusColors {
  static const Color trunk = Color(0xFF3366CC);      // 간선 (파랑)
  static const Color branch = Color(0xFF55AA55);     // 지선 (초록)
  static const Color circular = Color(0xFFEEAA00);   // 순환 (노랑)
  static const Color express = Color(0xFFCC3333);    // 광역 (빨강)
  static const Color night = Color(0xFF333333);      // 심야 (검정)

  static Color fromRouteType(int type) => switch (type) {
    3 => trunk,
    4 => branch,
    5 => circular,
    6 => express,
    _ => trunk,
  };

  static String toRgba(Color c) {
    final r = (c.r * 255).round().clamp(0, 255);
    final g = (c.g * 255).round().clamp(0, 255);
    final b = (c.b * 255).round().clamp(0, 255);
    return 'rgba($r,$g,$b,1)';
  }
}

/// 인기 버스 노선 프리셋 (노선검색 API 없이 바로 사용)
class BusPresets {
  static const List<Map<String, dynamic>> popular = [
    {'id': '100100118', 'name': '143', 'type': 3},
    {'id': '100100016', 'name': '301', 'type': 3},
    {'id': '100100225', 'name': '402', 'type': 3},
    {'id': '100100061', 'name': '144', 'type': 3},
    {'id': '100100253', 'name': '472', 'type': 4},
    {'id': '100100609', 'name': '740', 'type': 3},
    {'id': '100100395', 'name': '503', 'type': 3},
    {'id': '100100073', 'name': '151', 'type': 3},
    {'id': '100100598', 'name': '721', 'type': 3},
    {'id': '100100036', 'name': '100', 'type': 3},
    {'id': '100100596', 'name': '710', 'type': 3},
    {'id': '100100124', 'name': '173', 'type': 3},
    {'id': '100100604', 'name': '733', 'type': 3},
    {'id': '100100247', 'name': '463', 'type': 4},
    {'id': '104000001', 'name': '9701', 'type': 6},
  ];
}

/// 버스 시각화 오버레이 컨트롤러
/// 지하철 SubwayOverlayController와 동일한 패턴:
/// - 3D Style Layer 기반 렌더링
/// - 타이머로 주기적 위치 갱신
/// - bearing 계산으로 버스 방향 표시
class BusOverlayController {
  final SeoulBusService _api = SeoulBusService.instance;
  IMapController? _mapController;

  Timer? _refreshTimer;
  Timer? _riverBusTimer;
  bool _isActive = false;
  bool _showBuses = true;
  bool _showRiverBus = true;

  // 추적 중인 노선 목록
  final List<TrackedBusRoute> _trackedRoutes = [];
  // 현재 버스 위치
  final Map<String, List<BusPosition>> _currentPositions = {};
  // 이전 위치 (bearing 계산용)
  final Map<String, _BusState> _prevStates = {};

  // 선택된 버스
  BusPosition? _selectedBus;
  TrackedBusRoute? _selectedBusRoute;

  // 한강버스 상태
  List<RiverBusVessel> _currentVessels = [];
  RiverBusVessel? _selectedVessel;

  // 콜백
  VoidCallback? onStateChanged;
  void Function(BusPosition bus, TrackedBusRoute route)? onBusSelected;
  void Function(RiverBusVessel vessel)? onVesselSelected;

  // ── Getters ──
  bool get isActive => _isActive;
  bool get showBuses => _showBuses;
  bool get showRiverBus => _showRiverBus;
  List<TrackedBusRoute> get trackedRoutes => List.unmodifiable(_trackedRoutes);
  int get totalBusCount => _currentPositions.values.fold(0, (s, l) => s + l.length);
  BusPosition? get selectedBus => _selectedBus;
  TrackedBusRoute? get selectedBusRoute => _selectedBusRoute;
  RiverBusVessel? get selectedVessel => _selectedVessel;
  List<RiverBusVessel> get currentVessels => _currentVessels;

  void attachMap(IMapController controller) {
    _mapController = controller;
    controller.setOnBusTapped((vehId) {
      _handleBusTap(vehId);
    });
  }

  void _handleBusTap(String vehId) {
    // 모든 노선에서 해당 차량 찾기
    for (final entry in _currentPositions.entries) {
      final routeId = entry.key;
      for (final pos in entry.value) {
        if (pos.vehId == vehId) {
          _selectedBus = pos;
          _selectedBusRoute = _trackedRoutes.firstWhere(
            (r) => r.routeId == routeId,
            orElse: () => TrackedBusRoute(routeId: routeId, routeName: '', routeType: 3, color: BusColors.trunk),
          );
          _mapController?.moveTo(pos.lat, pos.lng, zoom: 16.0, pitch: 50.0);
          onBusSelected?.call(_selectedBus!, _selectedBusRoute!);
          onStateChanged?.call();
          return;
        }
      }
    }

    // 한강버스 vessel에서 찾기
    for (final v in _currentVessels) {
      if (v.id == vehId) {
        selectVessel(vehId);
        return;
      }
    }
  }

  void deselectBus() {
    _selectedBus = null;
    _selectedBusRoute = null;
    onStateChanged?.call();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 노선 추가/제거
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> addRoute(BusRouteInfo route) async {
    if (_trackedRoutes.any((r) => r.routeId == route.busRouteId)) return;

    final tracked = TrackedBusRoute(
      routeId: route.busRouteId,
      routeName: route.busRouteNm,
      routeType: route.routeType,
      color: BusColors.fromRouteType(route.routeType),
    );
    _trackedRoutes.add(tracked);

    // 즉시 위치 가져오기 + 렌더링
    await _fetchPositionsForRoute(tracked.routeId);
    await _render3D();

    if (!_isActive) start();
    onStateChanged?.call();
  }

  void removeRoute(String routeId) {
    _trackedRoutes.removeWhere((r) => r.routeId == routeId);
    _currentPositions.remove(routeId);
    // 이전 상태 정리
    _prevStates.removeWhere((k, _) => k.startsWith('${routeId}_'));
    if (_trackedRoutes.isEmpty) stop();
    _render3D();
    onStateChanged?.call();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 시작/중지
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> start() async {
    if (_isActive) return;
    _isActive = true;

    // 3D 레이어 초기화
    await _mapController?.initBusLayers();
    await _mapController?.initRiverBusLayers();

    // 즉시 한번 fetch + render
    await _fetchAllPositions();

    // 30초마다 위치 갱신
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchAllPositions();
    });

    // 한강버스 시뮬레이션 (1초마다 — 초 단위 보간)
    // 한강버스 위치 갱신 (quality preset에 따라 프레임 조절)
    final riverMs = switch (SettingsService.instance.qualityPreset) {
      'low' => 100,
      'medium' => 33,
      _ => 16,
    };
    _riverBusTimer = Timer.periodic(Duration(milliseconds: riverMs), (_) {
      _render3D();
    });

    // 선착장 마커 + 노선 경로
    if (_showRiverBus) _drawRiverBusMarkers();

    onStateChanged?.call();
  }

  void stop() {
    _isActive = false;
    _refreshTimer?.cancel();
    _riverBusTimer?.cancel();
    _refreshTimer = null;
    _riverBusTimer = null;
    _mapController?.cleanupBusLayers();
    _mapController?.cleanupRiverBusLayers();
    _clearRiverBusMarkers();
    _currentPositions.clear();
    _prevStates.clear();
    _currentVessels.clear();
    _selectedVessel = null;
    onStateChanged?.call();
  }

  void dispose() {
    stop();
    _trackedRoutes.clear();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 토글
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void toggleBuses(bool show) {
    _showBuses = show;
    _render3D();
    onStateChanged?.call();
  }

  void toggleRiverBus(bool show) {
    _showRiverBus = show;
    if (show) {
      if (!_isActive) start();
      _drawRiverBusMarkers();
    } else {
      _clearRiverBusMarkers();
      _selectedVessel = null;
    }
    _render3D();
    onStateChanged?.call();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 데이터 Fetch
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _fetchAllPositions() async {
    for (final route in _trackedRoutes) {
      await _fetchPositionsForRoute(route.routeId);
    }
    await _render3D();
  }

  Future<void> _fetchPositionsForRoute(String routeId) async {
    final positions = await _api.fetchBusPositions(routeId);
    _currentPositions[routeId] = positions;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3D 렌더링
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _render3D() async {
    final mc = _mapController;
    if (mc == null) return;

    if (!_showBuses && !_showRiverBus) {
      await mc.updateBusPositions3D([]);
      return;
    }

    final renderData = <BusRenderData>[];

    if (_showBuses) for (final entry in _currentPositions.entries) {
      final routeId = entry.key;
      final positions = entry.value;
      final route = _trackedRoutes.firstWhere(
        (r) => r.routeId == routeId,
        orElse: () => TrackedBusRoute(routeId: routeId, routeName: '', routeType: 3, color: BusColors.trunk),
      );
      final colorStr = BusColors.toRgba(route.color);

      for (final pos in positions) {
        if (pos.lat == 0 || pos.lng == 0) continue;

        // bearing 계산 (이전 위치와 비교)
        final stateKey = '${routeId}_${pos.vehId}';
        final prev = _prevStates[stateKey];
        double bearing = prev?.bearing ?? 0;

        if (prev != null && (prev.lat != pos.lat || prev.lng != pos.lng)) {
          final dLng = pos.lng - prev.lat; // 실제론 prev.lng
          final dLat = pos.lat - prev.lat;
          if (dLat.abs() > 0.00001 || dLng.abs() > 0.00001) {
            bearing = (atan2(pos.lng - prev.lng, pos.lat - prev.lat) * 180 / pi + 360) % 360;
          }
        }

        _prevStates[stateKey] = _BusState(lat: pos.lat, lng: pos.lng, bearing: bearing);

        renderData.add(BusRenderData(
          vehId: pos.vehId,
          lat: pos.lat,
          lng: pos.lng,
          bearing: bearing,
          color: colorStr,
          congestion: pos.congestion,
        ));
      }
    }

    await mc.updateBusPositions3D(renderData);

    // 한강버스 (전용 레이어 — 배 모양)
    if (_showRiverBus) {
      _currentVessels = RiverBusData.getActiveVessels();
      if (_currentVessels.isNotEmpty && !_riverBusLocated) {
        _riverBusLocated = true;
        final v = _currentVessels.first;
        debugPrint('[BusOverlay] 🚢 한강버스 ${v.routeName}: ${v.lat.toStringAsFixed(4)}, ${v.lng.toStringAsFixed(4)}');
      }
      final vesselData = <BusRenderData>[];
      for (final v in _currentVessels) {
        final route = RiverBusData.routes.firstWhere((r) => r.id == v.routeId);
        final c = Color(route.color);
        final colorStr = 'rgba(${(c.r * 255).round()},${(c.g * 255).round()},${(c.b * 255).round()},1)';
        vesselData.add(BusRenderData(
          vehId: v.id, lat: v.lat, lng: v.lng,
          bearing: v.bearing, color: colorStr, congestion: 0,
        ));
      }
      await mc.updateRiverBusPositions3D(vesselData);
    } else {
      await mc.updateRiverBusPositions3D([]);
    }

    // 선택된 한강버스 카메라 + glow 추적 (60fps)
    if (_selectedVessel != null) {
      final tracked = _currentVessels.firstWhere(
        (v) => v.id == _selectedVessel!.id,
        orElse: () => _selectedVessel!,
      );
      _selectedVessel = tracked;
      mc.followTrain(tracked.lat, tracked.lng, tracked.bearing);
      mc.showRiverBusHighlight(tracked.lat, tracked.lng);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 한강버스 선착장 + 노선 경로 표시
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  bool _riverMarkersDrawn = false;
  bool _riverBusLocated = false; // TODO: 디버그 후 true로 변경하여 자동이동 비활성화

  void _drawRiverBusMarkers() {
    if (_riverMarkersDrawn || _mapController == null) return;
    _riverMarkersDrawn = true;
    final mc = _mapController!;

    // 노선 경로는 Mapbox 기본 ferry 레이어 사용 (road class=ferry)
    // 별도 polyline 불필요

    // 선착장 마커 — 활성/비활성 구분
    final activeStopIds = <String>{};
    for (final route in RiverBusData.routes) {
      if (route.isActive) activeStopIds.addAll(route.stopIds);
    }
    for (final stop in RiverBusData.stops) {
      final active = activeStopIds.contains(stop.id);
      mc.addCircleMarker(
        'riverbus_stop_${stop.id}',
        stop.lat, stop.lng,
        color: active ? const Color(0xFF00ACC1) : const Color(0xFF9E9E9E),
        radius: 7.0,
        strokeColor: const Color(0xFFFFFFFF),
        strokeWidth: 2.5,
      );
    }
  }

  void _clearRiverBusMarkers() {
    if (!_riverMarkersDrawn || _mapController == null) return;
    final mc = _mapController!;
    for (final stop in RiverBusData.stops) {
      mc.removeCircleMarker('riverbus_stop_${stop.id}');
    }
    _riverMarkersDrawn = false;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 한강버스 선택/탭
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void selectVessel(String vesselId) {
    final v = _currentVessels.firstWhere(
      (v) => v.id == vesselId,
      orElse: () => _currentVessels.isNotEmpty ? _currentVessels.first : _selectedVessel!,
    );
    _selectedVessel = v;
    _mapController?.moveTo(v.lat, v.lng, zoom: 15.0, pitch: 50.0);
    onVesselSelected?.call(v);
    onStateChanged?.call();
  }

  void deselectVessel() {
    _selectedVessel = null;
    _mapController?.hideRiverBusHighlight();
    onStateChanged?.call();
  }
}

/// 버스 이전 상태 (bearing 계산용)
class _BusState {
  final double lat;
  final double lng;
  final double bearing;
  _BusState({required this.lat, required this.lng, required this.bearing});
}

/// 추적 중인 버스 노선
class TrackedBusRoute {
  final String routeId;
  final String routeName;
  final int routeType;
  final Color color;

  TrackedBusRoute({
    required this.routeId,
    required this.routeName,
    required this.routeType,
    required this.color,
  });
}
