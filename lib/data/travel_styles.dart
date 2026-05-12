import 'package:flutter/material.dart';

/// 사용자가 튜토리얼 AI 파트에서 선택한 여행 무드.
/// 한 곳에 모아둬서 AI 프롬프트 / 여행 탭 / 추천 탭이 같은 메타데이터를 공유.
class TravelStyle {
  final String key; // 'chill' | 'play' | 'history' | 'mixed'
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> palette; // AI 글로우 7색 (마지막 = wrap)
  /// Gemini 시스템 프롬프트에 주입될 무드 설명. 빈 문자열 = 추가 없음.
  final String aiPersona;
  /// 매칭되는 kTravelThemes id 들 — 가중치 정렬에 사용.
  final Set<String> matchingThemeIds;
  /// "당신의 무드" 추천 탭이 보여줄 카카오 카테고리 코드 (우선순위 순).
  final List<String> recommendKakaoCodes;

  const TravelStyle({
    required this.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.aiPersona,
    required this.matchingThemeIds,
    required this.recommendKakaoCodes,
  });
}

/// AI 글로우 기본 팔레트 (Apple Intelligence).
const List<Color> kDefaultStylePalette = [
  Color(0xFFBC82F3),
  Color(0xFFF5B9EA),
  Color(0xFF8D9FFF),
  Color(0xFFFF6778),
  Color(0xFFFFBA71),
  Color(0xFFC686FF),
  Color(0xFFBC82F3),
];

/// SharedPreferences 키.
const String kTravelStylePrefKey = 'travel_style_v1';

const List<TravelStyle> kTravelStyles = [
  TravelStyle(
    key: 'chill',
    emoji: '🌿',
    title: '쉬어가는 여행',
    subtitle: '한강·서울숲·고궁 산책',
    palette: [
      Color(0xFF4FD1C5),
      Color(0xFF81E6D9),
      Color(0xFF9AE6B4),
      Color(0xFFBEE3F8),
      Color(0xFFB794F4),
      Color(0xFF63B3ED),
      Color(0xFF4FD1C5),
    ],
    aiPersona:
        '사용자는 "쉬어가는 여행" 무드를 선호해. 한강, 서울숲, 고궁 산책, 카페에서 느긋한 시간 같은 차분한 코스를 우선 추천해. '
        '코스 짜줄 때 hangang_wind, rain_indoor, cafe_hop, palace_walk 테마 우선 고려. '
        '말투도 한 톤 낮춰 차분하게.',
    matchingThemeIds: {'hangang_wind', 'rain_indoor', 'night_view', 'cafe_hop'},
    recommendKakaoCodes: ['AT4', 'CE7'], // 관광·공원 + 카페
  ),
  TravelStyle(
    key: 'play',
    emoji: '🎉',
    title: '노는 여행',
    subtitle: '미식·카페·K-팝·쇼핑',
    palette: [
      Color(0xFFFF6B9D),
      Color(0xFFFFBA71),
      Color(0xFFFFE66D),
      Color(0xFFFF6778),
      Color(0xFFC084FC),
      Color(0xFFFFB4A2),
      Color(0xFFFF6B9D),
    ],
    aiPersona:
        '사용자는 "노는 여행" 무드를 선호해. 미식, 카페, K-팝 성지, 쇼핑, 야경처럼 활기찬 코스를 우선 추천해. '
        '코스 짜줄 때 foodie_day, cafe_hop, kpop, night_view 테마 우선 고려. '
        '톤은 들뜨고 신나게.',
    matchingThemeIds: {'foodie_day', 'cafe_hop', 'kpop', 'night_view'},
    recommendKakaoCodes: ['FD6', 'CT1'], // 맛집 + 문화시설
  ),
  TravelStyle(
    key: 'history',
    emoji: '🏯',
    title: '역사 여행',
    subtitle: '궁궐·종묘·고궁박물관',
    palette: [
      Color(0xFFDDA15E),
      Color(0xFFBC6C25),
      Color(0xFF9C7B5B),
      Color(0xFFD4A373),
      Color(0xFFA47148),
      Color(0xFFE9C46A),
      Color(0xFFDDA15E),
    ],
    aiPersona:
        '사용자는 "역사 여행" 무드를 선호해. 궁궐(경복궁/창덕궁/덕수궁), 종묘, 북촌 한옥마을, 국립중앙박물관, 고궁박물관 위주로 추천. '
        '코스 짜줄 때 palace_walk 테마를 가장 우선. 장소 설명할 때 간단한 역사 한 줄 곁들이면 좋아.',
    matchingThemeIds: {'palace_walk'},
    recommendKakaoCodes: ['AT4'], // 관광 명소
  ),
  TravelStyle(
    key: 'mixed',
    emoji: '✨',
    title: '섞어서',
    subtitle: 'AI 가 그날 컨디션에 맞춰 추천',
    palette: kDefaultStylePalette,
    aiPersona: '', // 별도 무드 없음 — 그날 시간/날씨 기반으로 추천
    matchingThemeIds: {},
    recommendKakaoCodes: ['FD6', 'CE7'], // 일반 인기 카테고리
  ),
];

/// key 로 TravelStyle 찾기. 알 수 없는 키 → null.
TravelStyle? travelStyleByKey(String? key) {
  if (key == null || key.isEmpty) return null;
  for (final s in kTravelStyles) {
    if (s.key == key) return s;
  }
  return null;
}
