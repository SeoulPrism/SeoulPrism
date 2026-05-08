import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/map_interface.dart';
import '../../../data/seoul_bus_data.dart';
import '../../../widgets/bus_overlay.dart';

/// 튜토리얼용 버스 시뮬레이터.
/// 실 버스 API 호출 없이 여러 노선의 가상 버스가 실제 정류소 시퀀스를 따라
/// 부드럽게 움직임. 지하철 TrainSimulator 와 동일한 퀄리티 목표.
///
/// - 노선별로 N 대 분산 배치 (양방향)
/// - 정류소 좌표를 waypoints 로 → 누적 거리 보간 (선분 단위 등속)
/// - 노선 유형별 평균 속도 차등 (간선 30 / 지선 22 / 광역 35 km/h)
/// - bearing 은 경로 탱전트
/// - 60fps tick + setStyleSourceProperty 한 번에 일괄 갱신
class DemoBusSimulator {
  final List<_RouteSim> _routes = [];
  DateTime? _lastTick;

  /// 정적 노선 데이터로 노선 추가.
  /// [busCount] 대 만큼 양방향 분산 배치.
  void addRoute(String routeName, {int busCount = 6}) {
    final route = SeoulBusData.getRouteByName(routeName);
    if (route == null || route.stops.length < 2) return;

    // 정류소 좌표 시퀀스. 같은 좌표 연속 제거.
    final waypoints = <List<double>>[];
    for (final s in route.stops) {
      if (waypoints.isEmpty ||
          waypoints.last[0] != s.lat ||
          waypoints.last[1] != s.lng) {
        waypoints.add([s.lat, s.lng]);
      }
    }
    if (waypoints.length < 2) return;

    // 누적 거리 (미터)
    final cum = <double>[0.0];
    for (int i = 1; i < waypoints.length; i++) {
      cum.add(cum.last +
          _distM(waypoints[i - 1][0], waypoints[i - 1][1],
              waypoints[i][0], waypoints[i][1]));
    }
    final total = cum.last;
    if (total <= 0) return;

    final speedMps = _speedKmhFor(route.routeType) / 3.6;
    final color = BusColors.fromRouteType(route.routeType);

    final buses = <_BusSim>[];
    for (int i = 0; i < busCount; i++) {
      buses.add(_BusSim(
        id: '${route.routeId}-D${i.toString().padLeft(2, '0')}',
        t: i / busCount,
        forward: i.isEven, // 짝수 정방향 / 홀수 역방향
      ));
    }

    _routes.add(_RouteSim(
      routeId: route.routeId,
      routeName: route.routeName,
      waypoints: waypoints,
      cumDist: cum,
      total: total,
      speedMps: speedMps,
      color: color,
      buses: buses,
    ));
  }

  /// 한 tick 진행. 호출 간격 자동 측정 (dt 기반).
  void step() {
    final now = DateTime.now();
    final dt = _lastTick == null
        ? 0.05
        : now.difference(_lastTick!).inMilliseconds / 1000.0;
    _lastTick = now;
    if (dt > 0.5) return; // tab off 후 큰 점프 방지

    for (final r in _routes) {
      final dT = (r.speedMps * dt) / r.total;
      for (final b in r.buses) {
        b.t += b.forward ? dT : -dT;
        // wrap [0, 1)
        if (b.t >= 1.0) b.t -= 1.0;
        if (b.t < 0) b.t += 1.0;
      }
    }
  }

  /// 현재 모든 가상 버스의 렌더 데이터.
  List<BusRenderData> renderData() {
    final result = <BusRenderData>[];
    for (final r in _routes) {
      final colorStr = BusColors.toRgba(r.color);
      for (final b in r.buses) {
        final pos = _interp(r, b.t);
        final bearing = b.forward ? pos.bearing : (pos.bearing + 180) % 360;
        result.add(BusRenderData(
          vehId: b.id,
          lat: pos.lat,
          lng: pos.lng,
          bearing: bearing,
          color: colorStr,
          congestion: 3,
        ));
      }
    }
    return result;
  }

  /// vehId → 현재 (lat, lng, bearing). 카메라 follow 용.
  ({double lat, double lng, double bearing})? findById(String vehId) {
    for (final r in _routes) {
      for (final b in r.buses) {
        if (b.id == vehId) {
          final pos = _interp(r, b.t);
          final bearing = b.forward ? pos.bearing : (pos.bearing + 180) % 360;
          return (lat: pos.lat, lng: pos.lng, bearing: bearing);
        }
      }
    }
    return null;
  }

  /// 카메라 좌표에 가장 가까운 가상 버스의 (lat, lng, vehId).
  (double, double, String)? nearest(double camLat, double camLng) {
    String? bestId;
    double bestLat = 0, bestLng = 0;
    double bestSq = double.infinity;
    for (final r in _routes) {
      for (final b in r.buses) {
        final pos = _interp(r, b.t);
        final dLat = pos.lat - camLat;
        final dLng = pos.lng - camLng;
        final sq = dLat * dLat + dLng * dLng;
        if (sq < bestSq) {
          bestSq = sq;
          bestLat = pos.lat;
          bestLng = pos.lng;
          bestId = b.id;
        }
      }
    }
    return bestId == null ? null : (bestLat, bestLng, bestId);
  }

  /// 일괄 렌더 — mapController.updateBusPositions3D 호출.
  void flush(IMapController mapController) {
    mapController.updateBusPositions3D(renderData());
  }

  // ── internal helpers ─────────────────────────────────────

  _Interp _interp(_RouteSim r, double t) {
    final target = r.total * t;
    // 이진탐색 — 누적 거리 기준 segment 찾기.
    int lo = 0, hi = r.cumDist.length - 1;
    while (lo + 1 < hi) {
      final mid = (lo + hi) >> 1;
      if (r.cumDist[mid] <= target) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final segLen = r.cumDist[hi] - r.cumDist[lo];
    final segT = segLen <= 0 ? 0.0 : (target - r.cumDist[lo]) / segLen;
    final a = r.waypoints[lo];
    final b = r.waypoints[hi];
    final lat = a[0] + (b[0] - a[0]) * segT;
    final lng = a[1] + (b[1] - a[1]) * segT;
    // bearing — 현재 segment 방향
    final bearing = _bearing(a[0], a[1], b[0], b[1]);
    return _Interp(lat: lat, lng: lng, bearing: bearing);
  }

  static double _distM(double aLat, double aLng, double bLat, double bLng) {
    // 평면 근사 — 서울 위도 기준 (m).
    const double mPerDegLat = 111000.0;
    final mPerDegLng = 111000.0 * cos(aLat * pi / 180);
    final dLat = (bLat - aLat) * mPerDegLat;
    final dLng = (bLng - aLng) * mPerDegLng;
    return sqrt(dLat * dLat + dLng * dLng);
  }

  static double _bearing(double aLat, double aLng, double bLat, double bLng) {
    final lat1 = aLat * pi / 180;
    final lat2 = bLat * pi / 180;
    final dLng = (bLng - aLng) * pi / 180;
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  static double _speedKmhFor(int routeType) => switch (routeType) {
        3 => 28.0, // 간선
        4 => 22.0, // 지선
        5 => 18.0, // 순환
        6 => 36.0, // 광역
        _ => 25.0,
      };
}

class _RouteSim {
  final String routeId;
  final String routeName;
  final List<List<double>> waypoints; // [[lat, lng], ...]
  final List<double> cumDist; // 누적 거리 (m)
  final double total;
  final double speedMps;
  final Color color;
  final List<_BusSim> buses;
  _RouteSim({
    required this.routeId,
    required this.routeName,
    required this.waypoints,
    required this.cumDist,
    required this.total,
    required this.speedMps,
    required this.color,
    required this.buses,
  });
}

class _BusSim {
  final String id;
  double t; // 0..1 along path
  final bool forward;
  _BusSim({required this.id, required this.t, required this.forward});
}

class _Interp {
  final double lat;
  final double lng;
  final double bearing;
  _Interp({required this.lat, required this.lng, required this.bearing});
}
