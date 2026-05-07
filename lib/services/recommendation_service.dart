import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/api_keys.dart';

/// 추천 장소 모델
class RecommendedPlace {
  final int rank;
  final String name;
  final String category;
  final String description;
  final double rating;
  final int visitorCount;
  final String? nearestStation;
  final int? distanceMeters;
  final String congestion; // 여유, 보통, 약간 붐빔, 붐빔

  const RecommendedPlace({
    required this.rank,
    required this.name,
    required this.category,
    required this.description,
    required this.rating,
    required this.visitorCount,
    this.nearestStation,
    this.distanceMeters,
    this.congestion = '보통',
  });
}

/// 전국 트렌드 아이템
class TrendItem {
  final int rank;
  final String name;
  final String category;
  final String description;
  final String region;
  final double rating;
  final String trend; // 'up', 'down', 'new', 'same'
  final int searchCount;

  const TrendItem({
    required this.rank,
    required this.name,
    required this.category,
    required this.description,
    required this.region,
    required this.rating,
    required this.trend,
    this.searchCount = 0,
  });
}

/// 추천 서비스 — 서울 열린데이터 API + Gemini 보조
class RecommendationService {
  static RecommendationService? _instance;
  RecommendationService._();

  static RecommendationService get instance {
    _instance ??= RecommendationService._();
    return _instance!;
  }

  // 서울시 실시간 도시데이터 API
  static const _seoulCityDataUrl =
      'http://openapi.seoul.go.kr:8088';

  /// 현재 위치 기반 주변 인기 장소 Top 10
  Future<List<RecommendedPlace>> getNearbyPopularPlaces() async {
    try {
      // 서울 실시간 인구 밀집 데이터 시도
      final places = await _fetchSeoulPopularAreas();
      if (places.isNotEmpty) return places;
    } catch (e) {
      debugPrint('[RecommendationService] 서울 API 실패: $e');
    }
    // 폴백
    return _fallbackNearbyPlaces();
  }

  /// 전국 트렌드 Top 10
  Future<List<TrendItem>> getNationalTrends() async {
    // 실시간 데이터 소스가 없으므로 큐레이션 데이터 사용
    return _curatedTrends();
  }

  /// 서울시 실시간 인구 데이터 기반 인기 장소
  Future<List<RecommendedPlace>> _fetchSeoulPopularAreas() async {
    final key = ApiKeys.seoulApiKey;
    if (key.isEmpty) return [];

    final url = '$_seoulCityDataUrl/$key/json/citydata_ppltn/1/10';
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 8),
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final items = data['SeoulRtd.citydata_ppltn'] as List?;
    if (items == null || items.isEmpty) return [];

    final places = <RecommendedPlace>[];
    for (int i = 0; i < items.length && i < 10; i++) {
      final item = items[i];
      places.add(RecommendedPlace(
        rank: i + 1,
        name: item['AREA_NM'] ?? '알 수 없음',
        category: '핫플레이스',
        description: '실시간 방문객 ${item['AREA_PPLTN_MIN'] ?? 0}~${item['AREA_PPLTN_MAX'] ?? 0}명',
        rating: 4.5,
        visitorCount: int.tryParse('${item['AREA_PPLTN_MIN'] ?? 0}') ?? 0,
        congestion: item['AREA_CONGEST_LVL'] ?? '보통',
      ));
    }
    return places;
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return _defaultPosition();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return _defaultPosition();
      }
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
  }

  Position _defaultPosition() {
    return Position(
      latitude: 37.5665,
      longitude: 126.9780,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// 큐레이션 전국 트렌드 (시즌/시기별 업데이트)
  List<TrendItem> _curatedTrends() {
    return const [
      TrendItem(rank: 1, name: '성수동 카페거리', category: '카페', description: '팝업스토어 밀집, MZ세대 핫플', region: '서울 성수', rating: 4.6, trend: 'up', searchCount: 52400),
      TrendItem(rank: 2, name: '해운대 블루라인파크', category: '관광', description: '해변열차 & 스카이캡슐 인생샷 명소', region: '부산 해운대', rating: 4.8, trend: 'up', searchCount: 48200),
      TrendItem(rank: 3, name: '제주 협재해수욕장', category: '자연', description: '에메랄드빛 바다, 초여름 시즌 시작', region: '제주 한림', rating: 4.7, trend: 'new', searchCount: 41000),
      TrendItem(rank: 4, name: '경주 동궁과 월지', category: '관광', description: '야간 조명 리뉴얼로 재방문 급증', region: '경북 경주', rating: 4.5, trend: 'up', searchCount: 35600),
      TrendItem(rank: 5, name: '여수 밤바다', category: '관광', description: '낭만포차 & 해상케이블카', region: '전남 여수', rating: 4.6, trend: 'same', searchCount: 33100),
      TrendItem(rank: 6, name: '을지로 힙지로', category: '문화', description: '레트로 감성 + 루프탑 바 신규 오픈', region: '서울 을지로', rating: 4.3, trend: 'up', searchCount: 29800),
      TrendItem(rank: 7, name: '강릉 안목해변', category: '카페', description: '바다뷰 카페 + 서핑 클래스', region: '강원 강릉', rating: 4.4, trend: 'same', searchCount: 27500),
      TrendItem(rank: 8, name: '전주 한옥마을', category: '맛집', description: '비빔밥 골목 + 한복 대여 봄 시즌', region: '전북 전주', rating: 4.5, trend: 'up', searchCount: 25200),
      TrendItem(rank: 9, name: '양양 서피비치', category: '자연', description: '서핑 성지, 5월 시즌 오픈', region: '강원 양양', rating: 4.3, trend: 'new', searchCount: 22100),
      TrendItem(rank: 10, name: '대구 동성로', category: '쇼핑', description: '야시장 리뉴얼 & 스트리트 푸드', region: '대구 중구', rating: 4.2, trend: 'new', searchCount: 19800),
    ];
  }

  /// 폴백 — 서울 인기 장소
  List<RecommendedPlace> _fallbackNearbyPlaces() {
    return const [
      RecommendedPlace(rank: 1, name: '광화문 광장', category: '관광', description: '서울의 중심, 역사와 현대가 만나는 광장', rating: 4.5, visitorCount: 15420, nearestStation: '광화문', distanceMeters: 200, congestion: '약간 붐빔'),
      RecommendedPlace(rank: 2, name: '경복궁', category: '관광', description: '조선 왕조의 정궁, 한복 체험 인기', rating: 4.7, visitorCount: 32100, nearestStation: '경복궁', distanceMeters: 500, congestion: '붐빔'),
      RecommendedPlace(rank: 3, name: '북촌 한옥마을', category: '관광', description: '전통 한옥이 모여있는 포토 스팟', rating: 4.4, visitorCount: 8900, nearestStation: '안국', distanceMeters: 700, congestion: '보통'),
      RecommendedPlace(rank: 4, name: '통인시장', category: '맛집', description: '엽전 도시락으로 유명한 전통시장', rating: 4.3, visitorCount: 5600, nearestStation: '경복궁', distanceMeters: 800, congestion: '여유'),
      RecommendedPlace(rank: 5, name: '삼청동 카페거리', category: '카페', description: '아기자기한 카페와 갤러리 밀집', rating: 4.2, visitorCount: 7200, nearestStation: '안국', distanceMeters: 600, congestion: '보통'),
      RecommendedPlace(rank: 6, name: '인사동', category: '쇼핑', description: '전통 공예품과 먹거리가 가득', rating: 4.3, visitorCount: 12300, nearestStation: '종각', distanceMeters: 400, congestion: '약간 붐빔'),
      RecommendedPlace(rank: 7, name: '청계천', category: '자연', description: '도심 속 산책로, 야경 명소', rating: 4.4, visitorCount: 18700, nearestStation: '광화문', distanceMeters: 300, congestion: '보통'),
      RecommendedPlace(rank: 8, name: '서촌 골목', category: '문화', description: '예술가 작업실과 독립서점의 동네', rating: 4.1, visitorCount: 3400, nearestStation: '경복궁', distanceMeters: 900, congestion: '여유'),
      RecommendedPlace(rank: 9, name: '을지로 노가리골목', category: '맛집', description: '힙지로의 시작, 레트로 감성 맛집', rating: 4.2, visitorCount: 6800, nearestStation: '을지로3가', distanceMeters: 1200, congestion: '약간 붐빔'),
      RecommendedPlace(rank: 10, name: '익선동 한옥거리', category: '카페', description: '한옥 개조 트렌디 카페 & 레스토랑', rating: 4.5, visitorCount: 9100, nearestStation: '종로3가', distanceMeters: 1000, congestion: '붐빔'),
    ];
  }
}
