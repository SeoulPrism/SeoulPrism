import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/api_keys.dart';

/// 장소 검색 결과 모델
class PlaceSearchResult {
  final String name;
  final String address;
  final String category;
  final double lat;
  final double lng;
  final String? phone;
  final String? distance;
  final String? placeUrl;

  const PlaceSearchResult({
    required this.name,
    required this.address,
    required this.category,
    required this.lat,
    required this.lng,
    this.phone,
    this.distance,
    this.placeUrl,
  });
}

/// 카카오 로컬 API 기반 장소 검색
class PlaceSearchService {
  static PlaceSearchService? _instance;
  PlaceSearchService._();

  static PlaceSearchService get instance {
    _instance ??= PlaceSearchService._();
    return _instance!;
  }

  Position? _lastPosition;

  Future<Position> getCurrentPosition() async {
    if (_lastPosition != null) return _lastPosition!;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _defaultPosition();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _defaultPosition();
      }

      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      return _lastPosition!;
    } catch (_) {
      return _defaultPosition();
    }
  }

  Position _defaultPosition() {
    return Position(
      latitude: 37.5665, longitude: 126.9780,
      timestamp: DateTime.now(), accuracy: 0, altitude: 0,
      altitudeAccuracy: 0, heading: 0, headingAccuracy: 0,
      speed: 0, speedAccuracy: 0,
    );
  }

  /// 카카오 키워드 장소 검색
  Future<List<PlaceSearchResult>> search(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final position = await getCurrentPosition();
      final encoded = Uri.encodeComponent(query.trim());
      final url =
          'https://dapi.kakao.com/v2/local/search/keyword.json'
          '?query=$encoded'
          '&x=${position.longitude}'
          '&y=${position.latitude}'
          '&radius=20000'
          '&size=10'
          '&sort=accuracy';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'KakaoAK ${ApiKeys.kakaoRestApiKey}'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        debugPrint('[PlaceSearch] 카카오 API 실패: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body);
      final documents = data['documents'] as List? ?? [];

      return documents.map<PlaceSearchResult>((doc) {
        final categoryName = doc['category_group_name'] ?? '';
        return PlaceSearchResult(
          name: doc['place_name'] ?? '',
          address: doc['road_address_name'] ?? doc['address_name'] ?? '',
          category: categoryName.isNotEmpty
              ? categoryName
              : _extractCategory(doc['category_name'] ?? ''),
          lat: double.tryParse(doc['y'] ?? '') ?? 0,
          lng: double.tryParse(doc['x'] ?? '') ?? 0,
          phone: doc['phone'],
          distance: doc['distance'],
          placeUrl: doc['place_url'],
        );
      }).where((r) => r.name.isNotEmpty).toList();
    } catch (e) {
      debugPrint('[PlaceSearch] 검색 실패: $e');
      return [];
    }
  }

  /// 주변 POI 가져오기 (카테고리 기반, 지도에 표시용)
  /// [categories]: CE7(카페), FD6(음식점), MT1(마트), CS2(편의점), BK9(은행), HP8(병원), AT4(관광)
  Future<List<PlaceSearchResult>> fetchNearbyPoi(double lat, double lng, {int radius = 500}) async {
    try {
      final categories = ['CE7', 'FD6', 'CS2', 'AT4', 'CT1'];
      final allResults = <PlaceSearchResult>[];

      for (final code in categories) {
        final url =
            'https://dapi.kakao.com/v2/local/search/category.json'
            '?category_group_code=$code'
            '&x=$lng'
            '&y=$lat'
            '&radius=$radius'
            '&size=5'
            '&sort=distance';

        final response = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'KakaoAK ${ApiKeys.kakaoRestApiKey}'},
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body);
        final documents = data['documents'] as List? ?? [];

        allResults.addAll(documents.map<PlaceSearchResult>((doc) {
          return PlaceSearchResult(
            name: doc['place_name'] ?? '',
            address: doc['road_address_name'] ?? doc['address_name'] ?? '',
            category: doc['category_group_name'] ?? '',
            lat: double.tryParse(doc['y'] ?? '') ?? 0,
            lng: double.tryParse(doc['x'] ?? '') ?? 0,
            phone: doc['phone'],
            distance: doc['distance'],
            placeUrl: doc['place_url'],
          );
        }).where((r) => r.name.isNotEmpty));
      }

      return allResults;
    } catch (e) {
      debugPrint('[PlaceSearch] 주변 POI 실패: $e');
      return [];
    }
  }

  /// 카카오 카테고리에서 간단한 이름 추출
  String _extractCategory(String fullCategory) {
    final parts = fullCategory.split(' > ');
    return parts.first;
  }
}
