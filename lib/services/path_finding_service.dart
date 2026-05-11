import 'dart:developer' as developer;
import 'dart:collection';
import 'dart:math';
import '../data/seoul_subway_data.dart';
import '../data/seoul_bus_data.dart';
import '../models/subway_models.dart';

/// 최단경로 탐색 유형
enum PathSearchType {
  duration, // 최소 시간
  distance, // 최단 거리
  transfer, // 최소 환승
}

/// 교통수단 유형
enum TransportMode { subway, bus, walk }

/// 경로 구간 정보
class PathSegment {
  final String lineName;
  final String lineId;
  final List<String> stations;
  final int travelTimeSec;
  final double distanceKm;
  final bool isTransfer;
  final TransportMode mode;

  /// 도보 구간 시작/끝 좌표 (TMAP 호출용)
  final double? startLat, startLng, endLat, endLng;

  /// 도보 턴바이턴 안내 (출구 정보 등)
  final String? walkDescription;

  const PathSegment({
    required this.lineName,
    required this.lineId,
    required this.stations,
    required this.travelTimeSec,
    required this.distanceKm,
    this.isTransfer = false,
    this.mode = TransportMode.subway,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.walkDescription,
  });
}

/// 전체 경로 결과
class PathResult {
  final String departure;
  final String arrival;
  final PathSearchType searchType;
  final int totalTimeSec;
  final double totalDistanceKm;
  final int transferCount;
  final List<PathSegment> segments;
  final bool isLocal; // 로컬 계산 결과 여부

  const PathResult({
    required this.departure,
    required this.arrival,
    required this.searchType,
    required this.totalTimeSec,
    required this.totalDistanceKm,
    required this.transferCount,
    required this.segments,
    this.isLocal = false,
  });

  String get totalTimeFormatted {
    final min = totalTimeSec ~/ 60;
    if (min >= 60) return '${min ~/ 60}시간 ${min % 60}분';
    return '$min분';
  }
}

/// 서울 지하철 최단경로 탐색 서비스
/// 1차: data.go.kr API 호출
/// 2차: 로컬 BFS 경로 계산 (폴백)
class PathFindingService {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 그래프 캐시 (최초 1회 빌드)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static bool _graphBuilt = false;
  // 역명 → 속한 노선ID 목록
  static final Map<String, Set<String>> _stationLines = {};
  // (역명, 노선ID) → 해당 노선에서의 인접역 목록 [(역명, 소요시간초)]
  static final Map<String, List<_Edge>> _adj = {};

  /// 버스 노선 유형별 평균 속도 (km/h).
  /// 서울 시내 버스 실측치 기반: 광역 ≈ 30, 간선 ≈ 22, 지선 ≈ 18, 마을 ≈ 15.
  static double _busSpeedKmh(int routeType) {
    switch (routeType) {
      case 6: // 광역
        return 30.0;
      case 1: // 공항
        return 28.0;
      case 3: // 간선
        return 22.0;
      case 5: // 순환
        return 20.0;
      case 4: // 지선
        return 18.0;
      case 13: // 동행
      case 14: // 한강
      case 15: // 심야 (도로 비어 약간 빠름)
        return 22.0;
      case 2: // 마을
        return 15.0;
      default:
        return 20.0;
    }
  }

  /// 두 역 좌표 사이 거리(km) 기반 소요시간 추정 (평균 35km/h)
  static int _estimateTimeSec(StationInfo a, StationInfo b) {
    final dLat = (a.lat - b.lat) * 111.0; // 위도 1도 ≈ 111km
    final dLng = (a.lng - b.lng) * 88.0; // 경도 1도 ≈ 88km (서울 위도 기준)
    final distKm = sqrt(dLat * dLat + dLng * dLng) * 1.3; // 직선 × 1.3 보정
    return (distKm / 35.0 * 3600).round().clamp(60, 600); // 최소 1분, 최대 10분
  }

  static void _buildGraph() {
    if (_graphBuilt) return;

    for (final entry in SubwayColors.lineColors.entries) {
      final lineId = entry.key;
      final stations = SeoulSubwayData.getLineStations(lineId);

      for (int i = 0; i < stations.length; i++) {
        final s = stations[i];
        final key = '${s.name}|$lineId';
        _stationLines.putIfAbsent(s.name, () => {}).add(lineId);
        _adj.putIfAbsent(key, () => []);

        // 다음 역 연결
        if (i + 1 < stations.length) {
          final next = stations[i + 1];
          final nextKey = '${next.name}|$lineId';
          _adj.putIfAbsent(nextKey, () => []);
          // travelNextSec이 0이면 좌표 기반 추정
          final timeSec = s.travelNextSec > 0
              ? s.travelNextSec
              : _estimateTimeSec(s, next);
          _adj[key]!.add(_Edge(next.name, lineId, timeSec));
          _adj[nextKey]!.add(_Edge(s.name, lineId, timeSec));
        }
      }
    }

    // 지하철 환승 간선 (같은 이름 다른 노선 → 180초)
    for (final entry in _stationLines.entries) {
      final name = entry.key;
      final lines = entry.value.toList();
      for (int i = 0; i < lines.length; i++) {
        for (int j = i + 1; j < lines.length; j++) {
          final keyA = '$name|${lines[i]}';
          final keyB = '$name|${lines[j]}';
          _adj[keyA]!.add(_Edge(name, lines[j], 180, isTransfer: true));
          _adj[keyB]!.add(_Edge(name, lines[i], 180, isTransfer: true));
        }
      }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 버스 노드 + 간선 추가
    // 노드 키: "정류소명|bus_노선번호"
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    for (final route in SeoulBusData.allRoutes) {
      final routeKey = 'bus_${route.routeName}';
      // 노선 유형별 평균 속도 (km/h). 광역은 고속도로 구간 다수라 빠르고, 마을버스는 느림.
      // routeType: 1=공항, 2=마을, 3=간선, 4=지선, 5=순환, 6=광역, 13=동행, 14=한강, 15=심야.
      final speedKmh = _busSpeedKmh(route.routeType);
      // 정류소 정차 시간 (탑승객 승하차 평균).
      const dwellSec = 15;

      for (int i = 0; i < route.stops.length; i++) {
        final stop = route.stops[i];
        final key = '${stop.name}|$routeKey';
        _stationLines.putIfAbsent(stop.name, () => {}).add(routeKey);
        _adj.putIfAbsent(key, () => []);

        if (i + 1 < route.stops.length) {
          final next = route.stops[i + 1];
          final nextKey = '${next.name}|$routeKey';
          _adj.putIfAbsent(nextKey, () => []);
          final distKm = _haversineKm(stop.lat, stop.lng, next.lat, next.lng);
          // 주행시간 + 정류소 정차시간. 클램프 범위는 노선 특성을 반영해 광역에 더 큰 상한.
          final travelSec = (distKm / speedKmh * 3600).round();
          final timeSec = (travelSec + dwellSec).clamp(30, 900);
          _adj[key]!.add(_Edge(next.name, routeKey, timeSec));
        }
      }
    }

    // 환승 간선: 같은 정류소명 → 가상 환승 허브 패턴
    // 버스↔버스: 대기 300초, 버스↔지하철: 도보 120초
    // O(n²) 대신 허브 노드 사용: "정류소명|_hub" ↔ 각 노선 (150초씩)
    for (final entry in _stationLines.entries) {
      final name = entry.key;
      final lines = entry.value.toList();
      if (lines.length < 2) continue;

      final busLines = lines.where((l) => l.startsWith('bus_')).toList();
      final subwayLines = lines.where((l) => !l.startsWith('bus_')).toList();

      // 버스 2개 이상이면 허브 노드 사용
      if (busLines.length >= 2) {
        final hubKey = '$name|_hub';
        _adj.putIfAbsent(hubKey, () => []);

        for (final bus in busLines) {
          final busKey = '$name|$bus';
          if (!_adj.containsKey(busKey)) continue;
          // 버스 → 허브: 0초, 허브 → 버스: 300초 (대기)
          _adj[busKey]!.add(_Edge(name, '_hub', 0, isTransfer: true));
          _adj[hubKey]!.add(_Edge(name, bus, 300, isTransfer: true));
        }

        // 지하철 ↔ 허브: 120초
        for (final sub in subwayLines) {
          final subKey = '$name|$sub';
          if (!_adj.containsKey(subKey)) continue;
          _adj[subKey]!.add(_Edge(name, '_hub', 0, isTransfer: true));
          _adj[hubKey]!.add(_Edge(name, sub, 120, isTransfer: true));
        }
      } else {
        // 버스 1개 이하: 직접 연결
        for (final bus in busLines) {
          for (final sub in subwayLines) {
            final keyBus = '$name|$bus';
            final keySub = '$name|$sub';
            if (_adj.containsKey(keyBus) && _adj.containsKey(keySub)) {
              _adj[keyBus]!.add(_Edge(name, sub, 120, isTransfer: true));
              _adj[keySub]!.add(_Edge(name, bus, 120, isTransfer: true));
            }
          }
        }
      }
    }

    // 근접 도보 환승: 지하철역 ↔ 버스정류소 (300m 이내, 이름이 다른 경우)
    _buildWalkingTransfers();

    _graphBuilt = true;
    final busRouteCount = SeoulBusData.allRoutes.length;
    developer.log(
      '[PathFinding] 그래프 빌드 완료: ${_stationLines.length}개 노드 (지하철+버스 $busRouteCount노선)',
    );
  }

  /// 지하철역 근처 버스정류소 도보 환승 (300m 이내)
  static void _buildWalkingTransfers() {
    const maxWalkDistKm = 0.3; // 300m
    const walkSpeedKmh = 4.0; // 도보 4km/h
    // 위도 0.003° ≈ 330m → 빠른 필터링용
    const latThreshold = 0.003;
    const lngThreshold = 0.004;

    // 유니크 지하철역 좌표 (역명 → 좌표, 노선 목록)
    final subwayCoords = <String, _LatLng>{}; // 역명 → 좌표
    for (final entry in SubwayColors.lineColors.entries) {
      final lineId = entry.key;
      for (final s in SeoulSubwayData.getLineStations(lineId)) {
        subwayCoords.putIfAbsent(s.name, () => _LatLng(s.lat, s.lng));
      }
    }

    // 유니크 버스 정류소 (정류소명 → 좌표, 노선 목록)
    final busCoords = <String, _LatLng>{}; // 정류소명 → 좌표
    for (final route in SeoulBusData.allRoutes) {
      for (final stop in route.stops) {
        busCoords.putIfAbsent(stop.name, () => _LatLng(stop.lat, stop.lng));
      }
    }

    int walkEdges = 0;

    for (final subEntry in subwayCoords.entries) {
      final subName = subEntry.key;
      final subCoord = subEntry.value;
      final subLines = _stationLines[subName];
      if (subLines == null) continue;

      for (final busEntry in busCoords.entries) {
        final busName = busEntry.key;
        if (busName == subName) continue;

        final busCoord = busEntry.value;
        // 빠른 bounding box 체크
        if ((subCoord.lat - busCoord.lat).abs() > latThreshold) continue;
        if ((subCoord.lng - busCoord.lng).abs() > lngThreshold) continue;

        final dist = _haversineKm(
          subCoord.lat,
          subCoord.lng,
          busCoord.lat,
          busCoord.lng,
        );
        if (dist > maxWalkDistKm) continue;

        final walkTimeSec = (dist / walkSpeedKmh * 3600).round().clamp(30, 600);
        final busLines = _stationLines[busName];
        if (busLines == null) continue;

        // 지하철 노선 → 버스 노선 연결
        final subLineList = subLines.where((l) => !l.startsWith('bus_'));
        final busLineList = busLines.where((l) => l.startsWith('bus_'));

        for (final subLine in subLineList) {
          final subKey = '$subName|$subLine';
          for (final busLine in busLineList) {
            final busKey = '$busName|$busLine';
            _adj[subKey]?.add(
              _Edge(busName, busLine, walkTimeSec, isTransfer: true),
            );
            _adj[busKey]?.add(
              _Edge(subName, subLine, walkTimeSec, isTransfer: true),
            );
            walkEdges++;
          }
        }
      }
    }
    developer.log('[PathFinding] 도보 환승 간선: $walkEdges개');
  }

  /// 역/정류소 좌표 조회
  static _LatLng? _getStationCoord(String name) {
    // 지하철
    for (final entry in SubwayColors.lineColors.entries) {
      for (final s in SeoulSubwayData.getLineStations(entry.key)) {
        if (s.name == name) return _LatLng(s.lat, s.lng);
      }
    }
    // 버스 정류소
    for (final route in SeoulBusData.allRoutes) {
      for (final stop in route.stops) {
        if (stop.name == name) return _LatLng(stop.lat, stop.lng);
      }
    }
    return null;
  }

  /// Haversine 거리 계산 (km)
  static double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// 좌표로 가장 가까운 역/정류소 찾기
  String? findNearestStation(double lat, double lng) {
    _buildGraph();
    String? best;
    double bestDist = double.infinity;

    // 지하철역
    for (final entry in SubwayColors.lineColors.entries) {
      for (final s in SeoulSubwayData.getLineStations(entry.key)) {
        final d = _haversineKm(lat, lng, s.lat, s.lng);
        if (d < bestDist) {
          bestDist = d;
          best = s.name;
        }
      }
    }

    // 버스 정류소
    for (final route in SeoulBusData.allRoutes) {
      for (final stop in route.stops) {
        final d = _haversineKm(lat, lng, stop.lat, stop.lng);
        if (d < bestDist) {
          bestDist = d;
          best = stop.name;
        }
      }
    }

    return best;
  }

  /// 최단경로 검색 (좌표 기반 출발/도착 지원)
  Future<PathResult> findPath({
    required String departure,
    required String arrival,
    PathSearchType searchType = PathSearchType.duration,
    double? departureLat,
    double? departureLng,
    double? arrivalLat,
    double? arrivalLng,
    List<String>? excludeTransferStations,
    List<String>? throughStations,
  }) async {
    _buildGraph();

    // 그래프에 없는 이름이면 좌표로 가장 가까운 역 찾기 + 도보시간 계산
    String dep = departure;
    String arr = arrival;
    int walkToDepSec = 0;
    int walkFromArrSec = 0;

    if (!_stationLines.containsKey(dep) &&
        departureLat != null &&
        departureLng != null) {
      dep = findNearestStation(departureLat, departureLng) ?? dep;
      // 도보 시간: 출발지 → 가장 가까운 역 (4km/h, 직선×1.3)
      final nearestCoord = _getStationCoord(dep);
      if (nearestCoord != null) {
        final distKm =
            _haversineKm(
              departureLat,
              departureLng,
              nearestCoord.lat,
              nearestCoord.lng,
            ) *
            1.3;
        walkToDepSec = (distKm / 4.0 * 3600).round();
      }
    }
    if (!_stationLines.containsKey(arr) &&
        arrivalLat != null &&
        arrivalLng != null) {
      arr = findNearestStation(arrivalLat, arrivalLng) ?? arr;
      final nearestCoord = _getStationCoord(arr);
      if (nearestCoord != null) {
        final distKm =
            _haversineKm(
              arrivalLat,
              arrivalLng,
              nearestCoord.lat,
              nearestCoord.lng,
            ) *
            1.3;
        walkFromArrSec = (distKm / 4.0 * 3600).round();
      }
    }

    // 로컬 경로 탐색
    final result = _findPathLocal(dep, arr, searchType);

    // 현실적 소요시간 보정:
    // - 첫 탑승 대기+역내이동: 240초 (4분)
    // - 하차 후 출구: 120초 (2분)
    const int boardingOverheadSec = 240; // 대기 + 승강장 이동
    const int alightingOverheadSec = 120; // 하차 + 출구 이동
    final hasRide = result.segments.any(
      (s) => !s.isTransfer && s.mode != TransportMode.walk,
    );
    final overheadSec = hasRide
        ? boardingOverheadSec + alightingOverheadSec
        : 0;

    // 도보 구간 + 오버헤드 추가
    final needsWrap = walkToDepSec > 0 || walkFromArrSec > 0 || overheadSec > 0;
    if (needsWrap) {
      final segments = <PathSegment>[];
      if (walkToDepSec > 0) {
        final depCoord = _getStationCoord(dep);
        segments.add(
          PathSegment(
            lineName: '도보',
            lineId: '',
            stations: [departure, dep],
            travelTimeSec: walkToDepSec,
            distanceKm: walkToDepSec / 3600 * 4.0,
            mode: TransportMode.walk,
            startLat: departureLat,
            startLng: departureLng,
            endLat: depCoord?.lat,
            endLng: depCoord?.lng,
          ),
        );
      }
      segments.addAll(result.segments);
      if (walkFromArrSec > 0) {
        final arrCoord = _getStationCoord(arr);
        segments.add(
          PathSegment(
            lineName: '도보',
            lineId: '',
            stations: [arr, arrival],
            travelTimeSec: walkFromArrSec,
            distanceKm: walkFromArrSec / 3600 * 4.0,
            mode: TransportMode.walk,
            startLat: arrCoord?.lat,
            startLng: arrCoord?.lng,
            endLat: arrivalLat,
            endLng: arrivalLng,
          ),
        );
      }
      return PathResult(
        departure: departure,
        arrival: arrival,
        searchType: searchType,
        totalTimeSec:
            result.totalTimeSec + walkToDepSec + walkFromArrSec + overheadSec,
        totalDistanceKm:
            result.totalDistanceKm +
            (walkToDepSec + walkFromArrSec) / 3600 * 4.0,
        transferCount: result.transferCount,
        segments: segments,
        isLocal: true,
      );
    }

    // 도보 없어도 탑승 오버헤드는 적용
    if (overheadSec > 0) {
      return PathResult(
        departure: departure,
        arrival: arrival,
        searchType: searchType,
        totalTimeSec: result.totalTimeSec + overheadSec,
        totalDistanceKm: result.totalDistanceKm,
        transferCount: result.transferCount,
        segments: result.segments,
        isLocal: true,
      );
    }

    return result;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 로컬 경로 탐색 (Dijkstra)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  PathResult _findPathLocal(
    String departure,
    String arrival,
    PathSearchType searchType,
  ) {
    _buildGraph();

    final depLines = _stationLines[departure];
    final arrLines = _stationLines[arrival];
    if (depLines == null || arrLines == null) {
      return PathResult(
        departure: departure,
        arrival: arrival,
        searchType: searchType,
        totalTimeSec: 0,
        totalDistanceKm: 0,
        transferCount: 0,
        segments: [],
        isLocal: true,
      );
    }

    // Dijkstra (최소 시간 or 최소 환승)
    final useTransferWeight = searchType == PathSearchType.transfer;
    final dist = <String, int>{};
    final prev = <String, String>{};
    final prevEdge = <String, _Edge>{};
    final pq = SplayTreeSet<_PQEntry>((a, b) {
      final cmp = a.cost.compareTo(b.cost);
      return cmp != 0 ? cmp : a.key.compareTo(b.key);
    });

    // 시작점: 출발역의 모든 노선
    for (final lineId in depLines) {
      final key = '$departure|$lineId';
      dist[key] = 0;
      pq.add(_PQEntry(key, 0));
    }

    while (pq.isNotEmpty) {
      final cur = pq.first;
      pq.remove(cur);

      if (cur.cost > (dist[cur.key] ?? 999999)) continue;

      final curName = cur.key.split('|')[0];
      if (curName == arrival) break;

      for (final edge in _adj[cur.key] ?? <_Edge>[]) {
        final nextKey = '${edge.toStation}|${edge.lineId}';
        // 최소환승 모드: 시간은 그대로 누적하고 환승마다 큰 페널티만 추가.
        // 같은 환승 횟수면 시간이 짧은 경로가 선택되도록 함 (이전엔 환승 횟수만 보고 최악의 시간을 고를 수 있었음).
        // 1회 환승 ≈ 30분 페널티 → 환승 1회 줄이기 위해 30분 이상 더 걸리는 경로는 채택하지 않음.
        const transferPenalty = 1800;
        final weight = useTransferWeight
            ? edge.timeSec + (edge.isTransfer ? transferPenalty : 0)
            : edge.timeSec;
        final newCost = cur.cost + weight;

        if (newCost < (dist[nextKey] ?? 999999)) {
          dist[nextKey] = newCost;
          prev[nextKey] = cur.key;
          prevEdge[nextKey] = edge;
          pq.add(_PQEntry(nextKey, newCost));
        }
      }
    }

    // 도착점에서 최소 비용 노선 찾기
    String? endKey;
    int minCost = 999999;
    for (final lineId in arrLines) {
      final key = '$arrival|$lineId';
      if ((dist[key] ?? 999999) < minCost) {
        minCost = dist[key]!;
        endKey = key;
      }
    }

    if (endKey == null) {
      return PathResult(
        departure: departure,
        arrival: arrival,
        searchType: searchType,
        totalTimeSec: 0,
        totalDistanceKm: 0,
        transferCount: 0,
        segments: [],
        isLocal: true,
      );
    }

    // 경로 역추적
    final path = <String>[endKey];
    while (prev.containsKey(path.last)) {
      path.add(prev[path.last]!);
    }
    final reversedPath = path.reversed.toList();

    // 경로를 구간(같은 노선)별로 그룹핑.
    // 핵심 규칙:
    //  - 연속된 isTransfer 엣지는 하나의 환승으로 합친다 (버스↔허브↔버스 패턴 보호).
    //  - lineId == '_hub' 인 노드는 표시상 건너뛴다 (허브는 그래프 내부 가상 노드).
    final segments = <PathSegment>[];
    int totalTime = 0;
    int transfers = 0;
    String? currentLineId;
    List<String> currentStations = [];
    int currentTime = 0;

    bool inTransfer = false;
    String pendingTransferAt = '';
    int pendingTransferTime = 0;

    void flushRideSegment() {
      final lid = currentLineId;
      if (lid != null && lid != '_hub' && currentStations.isNotEmpty) {
        segments.add(
          PathSegment(
            lineName: _getLineName(lid),
            lineId: lid,
            stations: List.from(currentStations),
            travelTimeSec: currentTime,
            distanceKm: _segDistanceKm(lid, currentTime),
            mode: _getMode(lid),
          ),
        );
      }
      currentStations = [];
      currentTime = 0;
    }

    for (int i = 0; i < reversedPath.length; i++) {
      final parts = reversedPath[i].split('|');
      final stationName = parts[0];
      final lineId = parts[1];

      if (i == 0) {
        currentLineId = lineId;
        currentStations = [stationName];
        continue;
      }

      final edge = prevEdge[reversedPath[i]];
      if (edge == null) continue;
      totalTime += edge.timeSec;

      if (edge.isTransfer) {
        // 환승 시작: 이전 탑승 구간을 닫고, 환승 누적을 시작.
        if (!inTransfer) {
          flushRideSegment();
          inTransfer = true;
          pendingTransferAt = stationName;
          pendingTransferTime = 0;
        }
        pendingTransferTime += edge.timeSec;

        // 허브 노드는 표시 안 함 — 그래프 통과만 하고 다음 실제 노선까지 환승 누적 지속.
        if (lineId == '_hub') {
          currentLineId = '_hub';
          continue;
        }

        // 실제 노선에 도달 → 환승 1회 완료
        segments.add(
          PathSegment(
            lineName: '환승',
            lineId: '',
            stations: [pendingTransferAt],
            travelTimeSec: pendingTransferTime,
            distanceKm: 0,
            isTransfer: true,
            mode: TransportMode.walk,
          ),
        );
        transfers++;
        inTransfer = false;
        pendingTransferTime = 0;
        currentLineId = lineId;
        currentStations = [stationName];
        continue;
      }

      // 일반 이동 엣지
      inTransfer = false;
      if (lineId != currentLineId) {
        // 노선이 바뀌었는데 환승 엣지를 못 받은 경우의 안전망
        flushRideSegment();
        currentLineId = lineId;
        currentStations = [stationName];
        currentTime = edge.timeSec;
      } else {
        currentTime += edge.timeSec;
        if (currentStations.isEmpty || currentStations.last != stationName) {
          currentStations.add(stationName);
        }
      }
    }

    flushRideSegment();

    return PathResult(
      departure: departure,
      arrival: arrival,
      searchType: searchType,
      totalTimeSec: totalTime,
      totalDistanceKm: segments.fold(0.0, (sum, s) => sum + s.distanceKm),
      transferCount: transfers,
      segments: segments,
      isLocal: true,
    );
  }

  // 노선별 평균속도로 거리 추정. 지하철 35, 버스 20 km/h.
  double _segDistanceKm(String lineId, int timeSec) {
    final hours = timeSec / 3600.0;
    if (lineId.startsWith('bus_')) return hours * 20.0;
    return hours * 35.0;
  }

  /// 노선 키로 표시 이름 반환 (지하철 or 버스)
  String _getLineName(String lineKey) {
    if (lineKey.startsWith('bus_')) {
      return '${lineKey.substring(4)}번 버스';
    }
    return SubwayColors.lineNames[lineKey] ?? lineKey;
  }

  /// 노선 키로 교통수단 판별
  TransportMode _getMode(String lineKey) {
    if (lineKey.startsWith('bus_')) return TransportMode.bus;
    return TransportMode.subway;
  }
}

class _Edge {
  final String toStation;
  final String lineId;
  final int timeSec;
  final bool isTransfer;

  const _Edge(
    this.toStation,
    this.lineId,
    this.timeSec, {
    this.isTransfer = false,
  });
}

class _PQEntry {
  final String key;
  final int cost;

  const _PQEntry(this.key, this.cost);
}

class _LatLng {
  final double lat;
  final double lng;
  const _LatLng(this.lat, this.lng);
}
