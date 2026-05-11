import 'dart:math';
import '../core/geo_distance.dart';
import '../models/sns_content_models.dart';
import '../services/environment_service.dart';

/// 여행 패널 "테마 추천" 카드용 시드 데이터.
/// 각 테마는 미리 정의된 4~5 개 정거장을 가지며, 탭 시 [DayPlan] 으로 변환되어
/// 지도 위 오버레이로 표시된다.
class TravelTheme {
  final String id;
  final String title;
  final String emoji;
  final String subtitle;
  final List<TravelThemeStop> stops;

  /// 추천 시간대(0~23 시). null = 시간 무관.
  final List<int>? bestHours;

  /// 어울리는 날씨. null = 무관.
  final List<WeatherCondition>? bestWeather;

  /// 카드 그라데이션 색상 (hex 정수 2개).
  final int colorStart;
  final int colorEnd;

  const TravelTheme({
    required this.id,
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.stops,
    this.bestHours,
    this.bestWeather,
    required this.colorStart,
    required this.colorEnd,
  });
}

class TravelThemeStop {
  final String name;
  final String category;
  final double lat;
  final double lng;
  final int estimatedMinutes;

  const TravelThemeStop({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    this.estimatedMinutes = 60,
  });
}

/// 8개 큐레이션 테마.
const List<TravelTheme> kTravelThemes = [
  TravelTheme(
    id: 'foodie_day',
    title: '당일치기 미식 투어',
    emoji: '🍜',
    subtitle: '광장시장 → 망원시장 → 을지로 노포',
    colorStart: 0xFFFF7043,
    colorEnd: 0xFFFFB74D,
    bestHours: [11, 12, 13, 17, 18, 19, 20],
    stops: [
      TravelThemeStop(
        name: '광장시장',
        category: '맛집',
        lat: 37.5704,
        lng: 126.9994,
        estimatedMinutes: 75,
      ),
      TravelThemeStop(
        name: '익선동 한옥거리',
        category: '카페',
        lat: 37.5733,
        lng: 126.9893,
        estimatedMinutes: 60,
      ),
      TravelThemeStop(
        name: '을지로 노가리골목',
        category: '맛집',
        lat: 37.5658,
        lng: 126.9920,
        estimatedMinutes: 90,
      ),
      TravelThemeStop(
        name: '망원시장',
        category: '맛집',
        lat: 37.5559,
        lng: 126.9050,
        estimatedMinutes: 60,
      ),
    ],
  ),
  TravelTheme(
    id: 'hangang_wind',
    title: '한강 바람 코스',
    emoji: '🌊',
    subtitle: '여의도 → 반포 → 뚝섬',
    colorStart: 0xFF4FC3F7,
    colorEnd: 0xFF81D4FA,
    bestHours: [10, 11, 16, 17, 18, 19],
    bestWeather: [WeatherCondition.clear, WeatherCondition.cloudy],
    stops: [
      TravelThemeStop(
        name: '여의도 한강공원',
        category: '자연',
        lat: 37.5283,
        lng: 126.9329,
        estimatedMinutes: 75,
      ),
      TravelThemeStop(
        name: '반포 한강공원',
        category: '자연',
        lat: 37.5117,
        lng: 126.9961,
        estimatedMinutes: 75,
      ),
      TravelThemeStop(
        name: '뚝섬 한강공원',
        category: '자연',
        lat: 37.5306,
        lng: 127.0701,
        estimatedMinutes: 75,
      ),
    ],
  ),
  TravelTheme(
    id: 'palace_walk',
    title: '궁궐 역사 산책',
    emoji: '🏯',
    subtitle: '경복궁 → 창덕궁 → 종묘',
    colorStart: 0xFFD7CCC8,
    colorEnd: 0xFF8D6E63,
    stops: [
      TravelThemeStop(
        name: '경복궁',
        category: '관광',
        lat: 37.5796,
        lng: 126.9770,
        estimatedMinutes: 90,
      ),
      TravelThemeStop(
        name: '창덕궁',
        category: '관광',
        lat: 37.5825,
        lng: 126.9910,
        estimatedMinutes: 75,
      ),
      TravelThemeStop(
        name: '종묘',
        category: '관광',
        lat: 37.5742,
        lng: 126.9938,
        estimatedMinutes: 60,
      ),
      TravelThemeStop(
        name: '광장시장',
        category: '맛집',
        lat: 37.5704,
        lng: 126.9994,
        estimatedMinutes: 60,
      ),
    ],
  ),
  TravelTheme(
    id: 'cafe_hop',
    title: '성수·연남 카페투어',
    emoji: '☕️',
    subtitle: '성수동 → 가로수길 → 연남동',
    colorStart: 0xFFA1887F,
    colorEnd: 0xFFD7CCC8,
    bestHours: [11, 12, 13, 14, 15, 16],
    stops: [
      TravelThemeStop(
        name: '성수동 카페거리',
        category: '카페',
        lat: 37.5446,
        lng: 127.0556,
        estimatedMinutes: 75,
      ),
      TravelThemeStop(
        name: '서울숲',
        category: '자연',
        lat: 37.5443,
        lng: 127.0374,
        estimatedMinutes: 60,
      ),
      TravelThemeStop(
        name: '가로수길',
        category: '쇼핑',
        lat: 37.5215,
        lng: 127.0226,
        estimatedMinutes: 75,
      ),
      TravelThemeStop(
        name: '연남동 경의선숲길',
        category: '카페',
        lat: 37.5586,
        lng: 126.9242,
        estimatedMinutes: 75,
      ),
    ],
  ),
  TravelTheme(
    id: 'kpop',
    title: 'K-팝 성지순례',
    emoji: '🎤',
    subtitle: 'HYBE → SM → 명동 → 홍대',
    colorStart: 0xFFAB47BC,
    colorEnd: 0xFFCE93D8,
    stops: [
      TravelThemeStop(
        name: 'HYBE 사옥',
        category: '관광',
        lat: 37.5246,
        lng: 126.9213,
        estimatedMinutes: 45,
      ),
      TravelThemeStop(
        name: 'SM Town COEX',
        category: '관광',
        lat: 37.5142,
        lng: 127.1024,
        estimatedMinutes: 60,
      ),
      TravelThemeStop(
        name: '명동 거리',
        category: '쇼핑',
        lat: 37.5635,
        lng: 126.9826,
        estimatedMinutes: 75,
      ),
      TravelThemeStop(
        name: '홍대 거리',
        category: '문화',
        lat: 37.5547,
        lng: 126.9249,
        estimatedMinutes: 90,
      ),
    ],
  ),
  TravelTheme(
    id: 'night_view',
    title: '야경 명소 3선',
    emoji: '🌃',
    subtitle: '남산 → 한강대교 → 청계천',
    colorStart: 0xFF5C6BC0,
    colorEnd: 0xFF7E57C2,
    bestHours: [18, 19, 20, 21, 22],
    stops: [
      TravelThemeStop(
        name: '남산서울타워',
        category: '관광',
        lat: 37.5512,
        lng: 126.9882,
        estimatedMinutes: 90,
      ),
      TravelThemeStop(
        name: '응봉산',
        category: '자연',
        lat: 37.5483,
        lng: 127.0260,
        estimatedMinutes: 60,
      ),
      TravelThemeStop(
        name: '한강대교 노들섬',
        category: '자연',
        lat: 37.5169,
        lng: 126.9610,
        estimatedMinutes: 60,
      ),
      TravelThemeStop(
        name: '청계천',
        category: '자연',
        lat: 37.5689,
        lng: 126.9779,
        estimatedMinutes: 45,
      ),
    ],
  ),
  TravelTheme(
    id: 'family_kids',
    title: '가족·아이 코스',
    emoji: '👨‍👩‍👧',
    subtitle: '서울숲 → 어린이대공원 → 롯데월드',
    colorStart: 0xFF66BB6A,
    colorEnd: 0xFFAED581,
    stops: [
      TravelThemeStop(
        name: '서울숲',
        category: '자연',
        lat: 37.5443,
        lng: 127.0374,
        estimatedMinutes: 90,
      ),
      TravelThemeStop(
        name: '어린이대공원',
        category: '자연',
        lat: 37.5485,
        lng: 127.0816,
        estimatedMinutes: 120,
      ),
      TravelThemeStop(
        name: '롯데월드 어드벤처',
        category: '관광',
        lat: 37.5111,
        lng: 127.0980,
        estimatedMinutes: 180,
      ),
    ],
  ),
  TravelTheme(
    id: 'rainy_indoor',
    title: '우중 실내 코스',
    emoji: '☔️',
    subtitle: '국립박물관 → 별마당 → 더현대',
    colorStart: 0xFF78909C,
    colorEnd: 0xFFB0BEC5,
    bestWeather: [
      WeatherCondition.rain,
      WeatherCondition.drizzle,
      WeatherCondition.thunderstorm,
      WeatherCondition.snow,
    ],
    stops: [
      TravelThemeStop(
        name: '국립중앙박물관',
        category: '문화',
        lat: 37.5240,
        lng: 126.9803,
        estimatedMinutes: 120,
      ),
      TravelThemeStop(
        name: '코엑스 별마당도서관',
        category: '문화',
        lat: 37.5119,
        lng: 127.0590,
        estimatedMinutes: 60,
      ),
      TravelThemeStop(
        name: '더현대 서울',
        category: '쇼핑',
        lat: 37.5258,
        lng: 126.9286,
        estimatedMinutes: 90,
      ),
      TravelThemeStop(
        name: 'DDP 동대문디자인플라자',
        category: '문화',
        lat: 37.5670,
        lng: 127.0095,
        estimatedMinutes: 75,
      ),
    ],
  ),
];

/// 테마 → DayPlan 변환. 시작 시간 10:00 고정, transit 시간은 직선거리 기반 추정.
DayPlan buildPlanFromTheme(TravelTheme theme) {
  final stops = <PlanStop>[];
  var currentMin = 10 * 60;

  for (int i = 0; i < theme.stops.length; i++) {
    final s = theme.stops[i];
    int transitMin = 0;
    if (i > 0) {
      final prev = theme.stops[i - 1];
      final distM = distanceMeters(prev.lat, prev.lng, s.lat, s.lng);
      if (distM < 1000) {
        transitMin = (distM / 1000 * 13).round();
      } else {
        transitMin = (distM / 1000 * 3.5 + 5).round();
      }
      transitMin = max(5, min(60, transitMin));
      currentMin += transitMin;
    }

    final arrival = _formatTime(currentMin);
    final departure = _formatTime(currentMin + s.estimatedMinutes);
    currentMin += s.estimatedMinutes;

    stops.add(PlanStop(
      place: ExtractedPlace(
        name: s.name,
        category: s.category,
        activity: _activityFor(s.category),
        lat: s.lat,
        lng: s.lng,
        estimatedMinutes: s.estimatedMinutes,
      ),
      arrivalTime: arrival,
      departureTime: departure,
      transitMinutes: transitMin,
    ));
  }

  final transitTotal =
      stops.fold<int>(0, (sum, st) => sum + st.transitMinutes);
  final activityTotal =
      stops.fold<int>(0, (sum, st) => sum + st.place.estimatedMinutes);

  return DayPlan(
    style: PlanStyle.efficient,
    stops: stops,
    totalTransitMinutes: transitTotal,
    totalActivityMinutes: activityTotal,
    transferCount: 0,
  );
}

String _activityFor(String category) => switch (category) {
      '맛집' || '식당' || '레스토랑' => '식사',
      '카페' => '커피/디저트',
      '쇼핑' || '백화점' || '마트' => '쇼핑',
      '문화' || '전시' || '박물관' => '관람',
      '공연' => '관람',
      '관광' || '명소' => '구경',
      '자연' || '공원' || '한강' => '산책',
      _ => '방문',
    };

String _formatTime(int totalMin) {
  final h = (totalMin ~/ 60) % 24;
  final m = totalMin % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
