import '../core/debug_log.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_keys.dart';

enum TravelMode { transit, driving, walking }

/// 대중교통 경로 구간
class TransitLeg {
  final String mode;       // WALK, BUS, SUBWAY
  final String routeName;  // 버스번호, 지하철노선명
  final String startName;
  final String endName;
  final int durationSec;
  final double distanceM;
  final List<List<double>> coordinates; // [lat, lng]
  final int? color;

  const TransitLeg({
    required this.mode,
    required this.routeName,
    required this.startName,
    required this.endName,
    required this.durationSec,
    required this.distanceM,
    required this.coordinates,
    this.color,
  });
}

/// 도보 안내 턴바이턴
class WalkStep {
  final String description;
  final String? name; // 랜드마크 or 출구명
  final double lat;
  final double lng;

  const WalkStep({required this.description, this.name, required this.lat, required this.lng});
}

/// 경로 결과
class DirectionsResult {
  final TravelMode mode;
  final double distanceKm;
  final int durationSec;
  final int? fare;
  final int? walkTimeSec;
  final int? transferCount;
  final List<List<double>> coordinates; // [lat, lng]
  final List<TransitLeg> legs;
  final List<WalkStep> walkSteps; // 도보 턴바이턴 안내

  const DirectionsResult({
    required this.mode,
    required this.distanceKm,
    required this.durationSec,
    this.fare,
    this.walkTimeSec,
    this.transferCount,
    required this.coordinates,
    required this.legs,
    this.walkSteps = const [],
  });
}

/// TMAP 통합 길찾기 (대중교통 + 자동차 + 도보)
class DirectionsService {
  static DirectionsService? _instance;
  DirectionsService._();
  static DirectionsService get instance {
    _instance ??= DirectionsService._();
    return _instance!;
  }

  static const _baseUrl = 'https://apis.openapi.sk.com';

  Map<String, String> get _headers => {
    'appKey': ApiKeys.tmapAppKey,
    'Content-Type': 'application/json',
  };

  /// 자동차 경로
  Future<DirectionsResult?> getDrivingRoute(
    double fromLat, double fromLng,
    double toLat, double toLng,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tmap/routes?version=1&startX=$fromLng&startY=$fromLat&endX=$toLng&endY=$toLat'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final features = data['features'] as List? ?? [];
      if (features.isEmpty) return null;

      final props = features[0]['properties'] ?? {};
      final coords = <List<double>>[];
      for (final f in features) {
        final geom = f['geometry'];
        if (geom['type'] == 'LineString') {
          for (final c in (geom['coordinates'] as List)) {
            coords.add([(c[1] as num).toDouble(), (c[0] as num).toDouble()]);
          }
        }
      }

      return DirectionsResult(
        mode: TravelMode.driving,
        distanceKm: (props['totalDistance'] as num? ?? 0) / 1000,
        durationSec: props['totalTime'] ?? 0,
        fare: props['taxiFare'],
        coordinates: coords,
        legs: [],
      );
    } catch (e) {
      DebugLog.log('[Directions] TMAP 자동차 실패: $e');
      return null;
    }
  }

  /// 도보 경로
  Future<DirectionsResult?> getWalkingRoute(
    double fromLat, double fromLng,
    double toLat, double toLng,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tmap/routes/pedestrian?version=1&startX=$fromLng&startY=$fromLat&endX=$toLng&endY=$toLat&startName=start&endName=end'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final features = data['features'] as List? ?? [];
      if (features.isEmpty) return null;

      final props = features[0]['properties'] ?? {};
      final coords = <List<double>>[];
      final steps = <WalkStep>[];

      for (final f in features) {
        final geom = f['geometry'];
        if (geom['type'] == 'LineString') {
          for (final c in (geom['coordinates'] as List)) {
            coords.add([(c[1] as num).toDouble(), (c[0] as num).toDouble()]);
          }
        } else if (geom['type'] == 'Point') {
          final p = f['properties'] ?? {};
          final desc = p['description']?.toString() ?? '';
          final name = p['name']?.toString();
          if (desc.isNotEmpty) {
            final c = geom['coordinates'] as List;
            steps.add(WalkStep(
              description: desc,
              name: (name != null && name.isNotEmpty) ? name : null,
              lat: (c[1] as num).toDouble(),
              lng: (c[0] as num).toDouble(),
            ));
          }
        }
      }

      return DirectionsResult(
        mode: TravelMode.walking,
        distanceKm: (props['totalDistance'] as num? ?? 0) / 1000,
        durationSec: props['totalTime'] ?? 0,
        coordinates: coords,
        legs: [],
        walkSteps: steps,
      );
    } catch (e) {
      DebugLog.log('[Directions] TMAP 도보 실패: $e');
      return null;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Mapbox Map Matching — 정류소 시퀀스를 도로에 스냅
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 같은 시퀀스 반복 매칭 비용 절약용 캐시. 키: 청크 해시.
  final Map<String, List<List<double>>> _matchCache = {};

  /// 정류소 좌표 시퀀스를 driving 프로필로 도로에 스냅한 polyline 반환.
  /// [coords] 형식: [[lat, lng], ...]. 결과도 동일 형식.
  /// 100 좌표 초과 시 자동 분할 호출 (인접 청크는 마지막 좌표 1개 겹침).
  /// 매칭 실패 시 null — 호출자가 직선 폴백.
  Future<List<List<double>>?> getMatchedRoute(List<List<double>> coords) async {
    if (coords.length < 2) return null;
    const maxChunk = 100;
    if (coords.length <= maxChunk) return _matchChunk(coords);

    final out = <List<double>>[];
    for (int start = 0; start < coords.length; start += maxChunk - 1) {
      final end = (start + maxChunk).clamp(0, coords.length);
      final chunk = coords.sublist(start, end);
      final matched = await _matchChunk(chunk);
      if (matched == null) return null;
      if (out.isEmpty) {
        out.addAll(matched);
      } else if (matched.isNotEmpty) {
        // 청크 경계 좌표 중복 제거.
        out.addAll(matched.skip(1));
      }
      if (end >= coords.length) break;
    }
    return out;
  }

  Future<List<List<double>>?> _matchChunk(List<List<double>> chunk) async {
    final cacheKey = _chunkKey(chunk);
    final cached = _matchCache[cacheKey];
    if (cached != null) return cached;

    // Mapbox 는 lng,lat 순서. 정류소 위치 부정확 가능성 고려해 반경 50m.
    final coordStr = chunk.map((c) => '${c[1]},${c[0]}').join(';');
    final radiusStr = List.filled(chunk.length, '50').join(';');
    final url =
        'https://api.mapbox.com/matching/v5/mapbox/driving/$coordStr'
        '?geometries=geojson&overview=full&radiuses=$radiusStr'
        '&access_token=${ApiKeys.mapboxAccessToken}';
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        DebugLog.log('[Directions] Mapbox matching ${response.statusCode}');
        return null;
      }
      final data = jsonDecode(response.body);
      final matchings = data['matchings'] as List?;
      if (matchings == null || matchings.isEmpty) return null;
      final geom = matchings.first['geometry'];
      if (geom is! Map || geom['type'] != 'LineString') return null;
      final raw = geom['coordinates'] as List;
      final out = raw
          .map<List<double>>(
            (c) => [(c[1] as num).toDouble(), (c[0] as num).toDouble()],
          )
          .toList();
      _matchCache[cacheKey] = out;
      return out;
    } catch (e) {
      DebugLog.log('[Directions] Mapbox matching 실패: $e');
      return null;
    }
  }

  String _chunkKey(List<List<double>> chunk) {
    // 첫/마지막 좌표 + 길이로 충분히 유일.
    final f = chunk.first;
    final l = chunk.last;
    return '${chunk.length}|${f[0].toStringAsFixed(5)},${f[1].toStringAsFixed(5)}|${l[0].toStringAsFixed(5)},${l[1].toStringAsFixed(5)}';
  }
}
