import 'dart:math';

/// 한강 리버버스 노선 및 시간표 데이터
/// 출처: hgbus.co.kr (2025~2026 운항 정보)
/// 현재 마곡↔여의도만 정상 운항, 나머지 정비 중
class RiverBusData {
  /// 선착장 좌표 (OSM 한강 waterway 중심선 기반)
  static const List<RiverBusStop> stops = [
    RiverBusStop(id: 'magok', name: '마곡', lat: 37.5891, lng: 126.8249,
        address: '서울 강서구 마곡동'),
    RiverBusStop(id: 'yeouido', name: '여의도', lat: 37.5347, lng: 126.9351,
        address: '서울 영등포구 여의도동'),
    RiverBusStop(id: 'oksu', name: '옥수', lat: 37.5207, lng: 127.0047,
        address: '서울 성동구 옥수동'),
    RiverBusStop(id: 'apgujeong', name: '압구정', lat: 37.5268, lng: 127.0120,
        address: '서울 강남구 압구정동'),
    RiverBusStop(id: 'ttukseom', name: '뚝섬', lat: 37.5249, lng: 127.0660,
        address: '서울 광진구 자양동'),
    RiverBusStop(id: 'jamsil', name: '잠실', lat: 37.5231, lng: 127.0797,
        address: '서울 송파구 잠실동'),
  ];

  static RiverBusStop? findStop(String id) {
    try { return stops.firstWhere((s) => s.id == id); } catch (_) { return null; }
  }

  /// 노선 정의 (현재 운항 + 정비 중)
  static const List<RiverBusRoute> routes = [
    RiverBusRoute(
      id: 'river_1',
      name: '1호선',
      displayName: '마곡 ↔ 여의도',
      stopIds: ['magok', 'yeouido'],
      intervalMin: 30,
      firstDeparture: 7 * 60,       // 07:00
      lastDeparture: 21 * 60,       // 21:00
      travelTimeMin: 25,
      dwellTimeSec: 180,            // 선착장 3분 정차
      isActive: true,
      color: 0xFF00ACC1,            // 시안
    ),
    RiverBusRoute(
      id: 'river_2',
      name: '2호선',
      displayName: '여의도 ↔ 잠실',
      stopIds: ['yeouido', 'oksu', 'apgujeong', 'ttukseom', 'jamsil'],
      intervalMin: 40,
      firstDeparture: 7 * 60 + 30,  // 07:30
      lastDeparture: 20 * 60 + 30,  // 20:30
      travelTimeMin: 50,
      dwellTimeSec: 120,            // 중간 정차 2분
      isActive: false,              // 정비 중
      color: 0xFF26A69A,            // 틸
    ),
  ];

  /// 실제 한강 물길을 따르는 경로 좌표 (더 많은 중간점)
  /// 경로 좌표 — OSM 한강 중심선 + 선착장 좌표 시작/끝 고정
  static Map<String, List<List<double>>> get routePaths => {
    'magok_yeouido': [
      [stops[0].lat, stops[0].lng],  // 마곡
      [37.5734, 126.8531],
      [37.5588, 126.8785],
      [37.5551, 126.8853],
      [37.5513, 126.8918],
      [37.5406, 126.9091],
      [37.5378, 126.9228],
      [stops[1].lat, stops[1].lng],  // 여의도
    ],
    'yeouido_oksu': [
      [stops[1].lat, stops[1].lng],  // 여의도
      [37.5223, 126.9482],
      [37.5184, 126.9535],
      [37.5156, 126.9606],
      [37.5132, 126.9673],
      [37.5119, 126.9728],
      [37.5113, 126.9819],
      [37.5119, 126.9872],
      [37.5171, 126.9990],
      [stops[2].lat, stops[2].lng],  // 옥수
    ],
    'oksu_apgujeong': [
      [stops[2].lat, stops[2].lng],  // 옥수
      [stops[3].lat, stops[3].lng],  // 압구정
    ],
    'apgujeong_ttukseom': [
      [stops[3].lat, stops[3].lng],  // 압구정
      [37.5357, 127.0203],
      [37.5382, 127.0277],
      [37.5312, 127.0540],
      [stops[4].lat, stops[4].lng],  // 뚝섬
    ],
    'ttukseom_jamsil': [
      [stops[4].lat, stops[4].lng],  // 뚝섬
      [stops[5].lat, stops[5].lng],  // 잠실
    ],
  };

  /// 현재 시각 기준 운항 중인 선박 (초 단위 정밀 보간)
  /// 운항 시간 외에도 데모 선박 1대 표시
  static List<RiverBusVessel> getActiveVessels() {
    final now = DateTime.now();
    final currentSec = now.hour * 3600 + now.minute * 60 + now.second;
    final vessels = <RiverBusVessel>[];

    for (final route in routes) {
      if (!route.isActive) continue;

      // 운항 시간 외: 데모 선박 (8분 주기로 왕복)
      final isOperating = now.hour >= route.firstDeparture ~/ 60 &&
          now.hour <= route.lastDeparture ~/ 60;
      if (!isOperating) {
        const demoCycleSec = 8 * 60; // 8분 주기
        final demoT = (currentSec % demoCycleSec) / demoCycleSec;
        final reverse = (currentSec ~/ demoCycleSec) % 2 == 1;
        final pos = _interpolateRoute(route, demoT, reverse);
        if (pos != null) {
          vessels.add(RiverBusVessel(
            id: '${route.id}_demo',
            routeId: route.id,
            routeName: route.displayName,
            lat: pos[0], lng: pos[1], bearing: pos[2],
            progress: demoT,
            direction: reverse ? 1 : 0,
            phase: '데모',
            nextStopName: reverse ? route.stopIds.first : route.stopIds.last,
          ));
        }
        continue;
      }

      final travelSec = route.travelTimeMin * 60;
      final dwellSec = route.dwellTimeSec;
      // 왕복 주기: 정방향 + 정차 + 역방향 + 정차
      final roundTripSec = travelSec + dwellSec + travelSec + dwellSec;

      for (int dep = route.firstDeparture; dep <= route.lastDeparture; dep += route.intervalMin) {
        final depSec = dep * 60;
        final elapsed = currentSec - depSec;
        if (elapsed < 0 || elapsed > roundTripSec) continue;

        String phase;
        double progress;
        bool reverse;
        String? currentStop; // 정차 중인 선착장

        if (elapsed < travelSec) {
          // 정방향 운항 중
          phase = '운항';
          progress = elapsed / travelSec;
          reverse = false;
        } else if (elapsed < travelSec + dwellSec) {
          // 도착지 정차 중
          phase = '정차';
          progress = 1.0;
          reverse = false;
          currentStop = route.stopIds.last;
        } else if (elapsed < travelSec + dwellSec + travelSec) {
          // 역방향 운항 중
          phase = '운항';
          progress = (elapsed - travelSec - dwellSec) / travelSec;
          reverse = true;
        } else {
          // 출발지 정차 중
          phase = '정차';
          progress = 1.0;
          reverse = true;
          currentStop = route.stopIds.first;
        }

        final pos = _interpolateRoute(route, progress, reverse);
        if (pos == null) continue;

        // 다음 선착장 계산
        String nextStop;
        if (phase == '정차') {
          nextStop = currentStop ?? '';
        } else {
          final ids = reverse ? route.stopIds.reversed.toList() : route.stopIds;
          final segIdx = (progress * (ids.length - 1)).floor().clamp(0, ids.length - 2);
          nextStop = ids[segIdx + 1];
        }

        vessels.add(RiverBusVessel(
          id: '${route.id}_$dep',
          routeId: route.id,
          routeName: route.displayName,
          lat: pos[0],
          lng: pos[1],
          bearing: pos[2],
          progress: progress,
          direction: reverse ? 1 : 0,
          phase: phase,
          nextStopName: findStop(nextStop)?.name ?? nextStop,
          currentStopName: currentStop != null ? findStop(currentStop)?.name : null,
        ));
      }
    }

    return vessels;
  }

  /// 경로 보간 (dart:math 사용)
  static List<double>? _interpolateRoute(RiverBusRoute route, double progress, bool reverse) {
    final allCoords = <List<double>>[];
    final stopIds = reverse ? route.stopIds.reversed.toList() : route.stopIds;

    for (int i = 0; i < stopIds.length - 1; i++) {
      final key = '${stopIds[i]}_${stopIds[i + 1]}';
      final reverseKey = '${stopIds[i + 1]}_${stopIds[i]}';

      var path = routePaths[key];
      if (path == null) {
        path = routePaths[reverseKey];
        if (path != null) path = path.reversed.toList();
      }

      if (path != null) {
        if (allCoords.isNotEmpty) {
          allCoords.addAll(path.sublist(1));
        } else {
          allCoords.addAll(path);
        }
      }
    }

    if (allCoords.length < 2) return null;

    // 누적 거리 계산
    final distances = <double>[0];
    double totalDist = 0;
    for (int i = 1; i < allCoords.length; i++) {
      final dLat = allCoords[i][0] - allCoords[i - 1][0];
      final dLng = allCoords[i][1] - allCoords[i - 1][1];
      totalDist += sqrt(dLat * dLat + dLng * dLng);
      distances.add(totalDist);
    }

    final targetDist = progress * totalDist;

    for (int i = 1; i < distances.length; i++) {
      if (distances[i] >= targetDist) {
        final segStart = distances[i - 1];
        final segLen = distances[i] - segStart;
        final t = segLen > 0 ? (targetDist - segStart) / segLen : 0.0;

        final lat = allCoords[i - 1][0] + t * (allCoords[i][0] - allCoords[i - 1][0]);
        final lng = allCoords[i - 1][1] + t * (allCoords[i][1] - allCoords[i - 1][1]);

        final dLat = allCoords[i][0] - allCoords[i - 1][0];
        final dLng = allCoords[i][1] - allCoords[i - 1][1];
        final bearing = (atan2(dLng, dLat) * 180 / pi + 360) % 360;

        return [lat, lng, bearing];
      }
    }

    return [allCoords.last[0], allCoords.last[1], 0];
  }

  /// 노선 전체 경로 좌표 반환 (지도 폴리라인용)
  static List<List<double>> getRouteCoords(RiverBusRoute route) {
    final allCoords = <List<double>>[];
    for (int i = 0; i < route.stopIds.length - 1; i++) {
      final key = '${route.stopIds[i]}_${route.stopIds[i + 1]}';
      final path = routePaths[key];
      if (path != null) {
        if (allCoords.isNotEmpty) {
          allCoords.addAll(path.sublist(1));
        } else {
          allCoords.addAll(path);
        }
      }
    }
    return allCoords;
  }
}

class RiverBusStop {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String address;

  const RiverBusStop({
    required this.id, required this.name,
    required this.lat, required this.lng,
    this.address = '',
  });
}

class RiverBusRoute {
  final String id;
  final String name;
  final String displayName;
  final List<String> stopIds;
  final int intervalMin;
  final int firstDeparture;
  final int lastDeparture;
  final int travelTimeMin;
  final int dwellTimeSec;
  final bool isActive;
  final int color;

  const RiverBusRoute({
    required this.id, required this.name, required this.displayName,
    required this.stopIds, required this.intervalMin,
    required this.firstDeparture, required this.lastDeparture,
    required this.travelTimeMin, this.dwellTimeSec = 120,
    this.isActive = true, this.color = 0xFF00ACC1,
  });
}

class RiverBusVessel {
  final String id;
  final String routeId;
  final String routeName;
  final double lat;
  final double lng;
  final double bearing;
  final double progress;
  final int direction;
  final String phase;           // '운항', '정차'
  final String nextStopName;
  final String? currentStopName;

  RiverBusVessel({
    required this.id, required this.routeId, required this.routeName,
    required this.lat, required this.lng, required this.bearing,
    required this.progress, required this.direction,
    this.phase = '운항', this.nextStopName = '',
    this.currentStopName,
  });
}
