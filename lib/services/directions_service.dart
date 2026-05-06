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
      debugPrint('[Directions] TMAP 자동차 실패: $e');
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
      debugPrint('[Directions] TMAP 도보 실패: $e');
      return null;
    }
  }

}
