import 'dart:math';
import 'package:flutter/material.dart';
import '../core/map_interface.dart';
import '../data/seoul_subway_data.dart';
import '../data/seoul_bus_data.dart';
import '../data/subway_geojson_loader.dart';
import '../models/subway_models.dart';
import '../theme/app_colors.dart';
import '../widgets/bus_overlay.dart';
import 'directions_service.dart';
import 'path_finding_service.dart';

/// 단일 [PathResult] 를 지도 위에 폴리라인으로 그려주는 헬퍼.
/// `_drawRouteOnMap` 의 시각 스타일 (white outline + colored line) 만 추출.
/// 애니메이션 / 출발-도착 마커 / 카메라 이동 등 단일 경로 네비게이션 특화 로직은
/// 호출자가 따로 처리한다.
class RouteRenderer {
  /// [route] 의 모든 (transfer 가 아닌) segment 를 outline + colored line 로 그린다.
  /// [prefix] 로 polyline id 충돌 방지 — 동일 지도에 여러 route 를 동시에 그릴 때 사용.
  /// [drawTransitMarkers] 가 true 면 (non-walk) segment 시작/끝점에 환승 마커.
  /// [arrowsOut] 이 주어지면 그곳에 화살표를 누적해 추가 (호출자가 마지막에
  /// 한꺼번에 `mc.updateRouteArrows` 호출 — 여러 route 를 한번에 표시할 때 사용).
  /// 반환값은 실제로 그려진 segment 수.
  static Future<int> render(
    IMapController mc,
    PathResult route, {
    required String prefix,
    bool drawTransitMarkers = false,
    List<Map<String, dynamic>>? arrowsOut,
  }) async {
    final segments = await _computeSegments(route);
    for (int s = 0; s < segments.length; s++) {
      final seg = segments[s];
      final lineWidth = seg.isWalk ? 4.0 : 5.0;
      final outlineWidth = seg.isWalk ? 6.0 : 8.0;
      await mc.addPolyline(
        '${prefix}_outline_$s',
        seg.coords,
        color: Colors.white.withValues(alpha: seg.isWalk ? 0.85 : 0.55),
        width: outlineWidth,
        opacity: 1.0,
      );
      await mc.addPolyline(
        '${prefix}_seg_$s',
        seg.coords,
        color: seg.color,
        width: lineWidth,
        opacity: seg.isWalk ? 0.9 : 1.0,
      );

      if (drawTransitMarkers && !seg.isWalk) {
        await mc.addCircleMarker(
          '${prefix}_mk_${s}_s',
          seg.coords.first[0],
          seg.coords.first[1],
          color: seg.color,
          radius: 7,
          strokeColor: Colors.white,
          strokeWidth: 2.5,
        );
        await mc.addCircleMarker(
          '${prefix}_mk_${s}_e',
          seg.coords.last[0],
          seg.coords.last[1],
          color: seg.color,
          radius: 7,
          strokeColor: Colors.white,
          strokeWidth: 2.5,
        );
      }

      if (arrowsOut != null && !seg.isWalk) {
        _collectArrows(arrowsOut, seg.coords, seg.color);
      }
    }
    return segments.length;
  }

  /// 폴리라인 위에 일정 간격으로 방향 화살표 좌표/베어링을 누적.
  /// `_drawRouteOnMap` 의 동명 헬퍼와 동일 로직.
  static void _collectArrows(
    List<Map<String, dynamic>> arrows,
    List<List<double>> coords,
    Color color,
  ) {
    if (coords.length < 2) return;
    final colorStr =
        'rgba(${(color.r * 255).round()},${(color.g * 255).round()},${(color.b * 255).round()},1)';
    const intervalDeg = 0.0012;
    double accumulated = 0;
    for (int i = 1; i < coords.length; i++) {
      final dLat = coords[i][0] - coords[i - 1][0];
      final dLng = coords[i][1] - coords[i - 1][1];
      final dist = sqrt(dLat * dLat + dLng * dLng);
      accumulated += dist;
      if (accumulated >= intervalDeg) {
        accumulated = 0;
        final bearing = (atan2(dLng, dLat) * 180 / pi + 360) % 360;
        arrows.add({
          'lat': coords[i][0],
          'lng': coords[i][1],
          'bearing': bearing - 90,
          'color': colorStr,
        });
      }
    }
  }

  static Future<List<_SegmentDraw>> _computeSegments(PathResult route) async {
    final geojsonRoutes = await SubwayGeoJsonLoader.load();
    final result = <_SegmentDraw>[];

    for (final segment in route.segments) {
      if (segment.isTransfer || segment.stations.length < 2) continue;

      List<List<double>> segCoords;
      Color color;

      if (segment.mode == TransportMode.walk) {
        double? fromLat = segment.startLat;
        double? fromLng = segment.startLng;
        double? toLat = segment.endLat;
        double? toLng = segment.endLng;
        if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
          final stationCoords = _resolveStationCoords(segment.stations);
          if (stationCoords.length >= 2) {
            fromLat ??= stationCoords.first[0];
            fromLng ??= stationCoords.first[1];
            toLat ??= stationCoords.last[0];
            toLng ??= stationCoords.last[1];
          }
        }
        if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
          continue;
        }
        final walkRoute = await DirectionsService.instance.getWalkingRoute(
          fromLat, fromLng, toLat, toLng,
        );
        if (walkRoute != null && walkRoute.coordinates.length >= 2) {
          segCoords = walkRoute.coordinates;
        } else {
          segCoords = [
            [fromLat, fromLng],
            [toLat, toLng],
          ];
        }
        color = const Color(0xFF4FC3F7);
      } else if (segment.mode == TransportMode.bus) {
        final stopCoords = _resolveBusStopCoords(segment.lineId, segment.stations);
        if (stopCoords.length < 2) continue;
        final matched = await DirectionsService.instance.getMatchedRoute(stopCoords);
        segCoords = (matched != null && matched.length >= 2) ? matched : stopCoords;
        final ref = segment.lineId.startsWith('bus_')
            ? segment.lineId.substring(4)
            : '';
        final num = int.tryParse(ref);
        if (num != null && num >= 100 && num <= 999) {
          color = BusColors.trunk;
        } else if (num != null && num >= 1000) {
          color = BusColors.branch;
        } else if (ref.startsWith('M')) {
          color = BusColors.express;
        } else {
          color = BusColors.branch;
        }
      } else {
        final firstStn = SeoulSubwayData.findStation(segment.stations.first);
        final lastStn = SeoulSubwayData.findStation(segment.stations.last);
        if (firstStn == null || lastStn == null) continue;
        final lineCoords = geojsonRoutes[segment.lineId];
        if (lineCoords != null && lineCoords.length >= 2) {
          segCoords = _extractSegmentFromRoute(lineCoords, firstStn, lastStn);
        } else {
          segCoords = segment.stations
              .map((n) => SeoulSubwayData.findStation(n))
              .where((s) => s != null)
              .map((s) => [s!.lat, s.lng])
              .toList();
        }
        color = SubwayColors.lineColors[segment.lineId] ?? AppColors.accent;
      }

      if (segCoords.length < 2) continue;
      result.add(_SegmentDraw(
        coords: segCoords,
        color: color,
        isWalk: segment.mode == TransportMode.walk,
      ));
    }

    return result;
  }

  static List<List<double>> _resolveStationCoords(List<String> names) {
    final coords = <List<double>>[];
    for (final name in names) {
      final sub = SeoulSubwayData.findStation(name);
      if (sub != null) {
        coords.add([sub.lat, sub.lng]);
        continue;
      }
      for (final route in SeoulBusData.allRoutes) {
        final stop = route.stops.where((s) => s.name == name).firstOrNull;
        if (stop != null) {
          coords.add([stop.lat, stop.lng]);
          break;
        }
      }
    }
    return coords;
  }

  static List<List<double>> _resolveBusStopCoords(
    String lineId,
    List<String> names,
  ) {
    final routeRef = lineId.startsWith('bus_') ? lineId.substring(4) : lineId;
    final busRoute = SeoulBusData.getRouteByName(routeRef);
    if (busRoute == null) return _resolveStationCoords(names);
    final coords = <List<double>>[];
    for (final name in names) {
      final stop = busRoute.stops.where((s) => s.name == name).firstOrNull;
      if (stop != null) coords.add([stop.lat, stop.lng]);
    }
    return coords.length >= 2 ? coords : _resolveStationCoords(names);
  }

  static List<List<double>> _extractSegmentFromRoute(
    List<List<double>> routeCoords,
    StationInfo startStation,
    StationInfo endStation,
  ) {
    int startIdx = _findClosestIndex(routeCoords, startStation.lat, startStation.lng);
    int endIdx = _findClosestIndex(routeCoords, endStation.lat, endStation.lng);
    if (startIdx == endIdx) {
      return [
        [startStation.lat, startStation.lng],
        [endStation.lat, endStation.lng],
      ];
    }
    if (startIdx > endIdx) {
      final temp = startIdx;
      startIdx = endIdx;
      endIdx = temp;
    }
    return routeCoords.sublist(startIdx, endIdx + 1);
  }

  static int _findClosestIndex(List<List<double>> coords, double lat, double lng) {
    int bestIdx = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < coords.length; i++) {
      final dLat = coords[i][0] - lat;
      final dLng = coords[i][1] - lng;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }
}

class _SegmentDraw {
  final List<List<double>> coords;
  final Color color;
  final bool isWalk;
  const _SegmentDraw({
    required this.coords,
    required this.color,
    required this.isWalk,
  });
}
