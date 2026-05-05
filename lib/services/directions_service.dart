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

  const DirectionsResult({
    required this.mode,
    required this.distanceKm,
    required this.durationSec,
    this.fare,
    this.walkTimeSec,
    this.transferCount,
    required this.coordinates,
    required this.legs,
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

  /// 대중교통 경로 (지하철 + 버스 + 도보 통합)
  Future<List<DirectionsResult>> getTransitRoutes(
    double fromLat, double fromLng,
    double toLat, double toLng,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transit/routes'),
        headers: _headers,
        body: jsonEncode({
          'startX': '$fromLng', 'startY': '$fromLat',
          'endX': '$toLng', 'endY': '$toLat',
          'format': 'json', 'count': 5,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[Directions] TMAP 대중교통 HTTP ${response.statusCode}: ${response.body.substring(0, 200.clamp(0, response.body.length))}');
        return [];
      }
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        debugPrint('[Directions] TMAP 에러: ${data['error']}');
        return [];
      }
      final itineraries = data['metaData']?['plan']?['itineraries'] as List? ?? [];

      return itineraries.map<DirectionsResult>((it) {
        final legs = <TransitLeg>[];
        final allCoords = <List<double>>[];
        int transfers = 0;

        for (final leg in (it['legs'] as List)) {
          final mode = leg['mode'] as String;
          final coords = <List<double>>[];

          // 좌표 추출
          if (leg['passShape'] != null) {
            final linestring = leg['passShape']['linestring'] as String;
            for (final pt in linestring.split(' ')) {
              final parts = pt.split(',');
              if (parts.length >= 2) {
                coords.add([double.parse(parts[1]), double.parse(parts[0])]); // lat, lng
              }
            }
          } else {
            final startLat = (leg['start']?['lat'] as num?)?.toDouble();
            final startLng = (leg['start']?['lon'] as num?)?.toDouble();
            final endLat = (leg['end']?['lat'] as num?)?.toDouble();
            final endLng = (leg['end']?['lon'] as num?)?.toDouble();
            if (startLat != null && startLng != null) coords.add([startLat, startLng]);
            if (endLat != null && endLng != null) coords.add([endLat, endLng]);
          }
          allCoords.addAll(coords);

          if (mode == 'BUS' || mode == 'SUBWAY') transfers++;

          int? lineColor;
          if (mode == 'SUBWAY') {
            lineColor = _subwayColor(leg['route'] ?? '');
          } else if (mode == 'BUS') {
            lineColor = _busColor(leg['routeColor'] ?? '');
          }

          legs.add(TransitLeg(
            mode: mode,
            routeName: leg['route'] ?? '',
            startName: leg['start']?['name'] ?? '',
            endName: leg['end']?['name'] ?? '',
            durationSec: leg['sectionTime'] ?? 0,
            distanceM: (leg['distance'] as num?)?.toDouble() ?? 0,
            coordinates: coords,
            color: lineColor,
          ));
        }

        return DirectionsResult(
          mode: TravelMode.transit,
          distanceKm: (it['totalDistance'] as num? ?? 0) / 1000,
          durationSec: it['totalTime'] ?? 0,
          fare: it['fare']?['regular']?['totalFare'],
          walkTimeSec: it['totalWalkTime'],
          transferCount: transfers > 0 ? transfers - 1 : 0,
          coordinates: allCoords,
          legs: legs,
        );
      }).toList();
    } catch (e) {
      debugPrint('[Directions] TMAP 대중교통 실패: $e');
      return [];
    }
  }

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
      for (final f in features) {
        final geom = f['geometry'];
        if (geom['type'] == 'LineString') {
          for (final c in (geom['coordinates'] as List)) {
            coords.add([(c[1] as num).toDouble(), (c[0] as num).toDouble()]);
          }
        }
      }

      return DirectionsResult(
        mode: TravelMode.walking,
        distanceKm: (props['totalDistance'] as num? ?? 0) / 1000,
        durationSec: props['totalTime'] ?? 0,
        coordinates: coords,
        legs: [],
      );
    } catch (e) {
      debugPrint('[Directions] TMAP 도보 실패: $e');
      return null;
    }
  }

  int _subwayColor(String route) {
    if (route.contains('1호선')) return 0xFF0052A4;
    if (route.contains('2호선')) return 0xFF00A84D;
    if (route.contains('3호선')) return 0xFFEF7C1C;
    if (route.contains('4호선')) return 0xFF00A5DE;
    if (route.contains('5호선')) return 0xFF996CAC;
    if (route.contains('6호선')) return 0xFFCD7C2F;
    if (route.contains('7호선')) return 0xFF747F00;
    if (route.contains('8호선')) return 0xFFE6186C;
    if (route.contains('9호선')) return 0xFFBDB092;
    return 0xFF888888;
  }

  int _busColor(String colorStr) {
    if (colorStr.isEmpty) return 0xFF3366CC;
    try {
      return int.parse('0xFF${colorStr.replaceAll('#', '')}');
    } catch (_) {
      return 0xFF3366CC;
    }
  }
}
