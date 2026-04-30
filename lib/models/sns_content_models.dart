import '../services/path_finding_service.dart';

/// 사용자 SNS 입력
class SnsContent {
  final List<String> imagePaths;
  final String text;
  final String url;

  const SnsContent({
    this.imagePaths = const [],
    this.text = '',
    this.url = '',
  });

  bool get isEmpty => imagePaths.isEmpty && text.isEmpty && url.isEmpty;
}

/// AI가 추출한 장소
class ExtractedPlace {
  final String name;
  final String nameEn;
  final String category;       // 맛집, 카페, 관광, 쇼핑, 문화, 자연
  final String activity;       // 구체적 활동
  final String mood;           // 분위기 키워드
  final String description;
  final double? lat;
  final double? lng;
  final String? nearestStation;
  final int estimatedMinutes;

  const ExtractedPlace({
    required this.name,
    this.nameEn = '',
    required this.category,
    required this.activity,
    this.mood = '',
    this.description = '',
    this.lat,
    this.lng,
    this.nearestStation,
    this.estimatedMinutes = 60,
  });

  ExtractedPlace copyWith({
    String? name,
    String? nameEn,
    String? category,
    String? activity,
    String? mood,
    String? description,
    double? lat,
    double? lng,
    String? nearestStation,
    int? estimatedMinutes,
  }) {
    return ExtractedPlace(
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      category: category ?? this.category,
      activity: activity ?? this.activity,
      mood: mood ?? this.mood,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      nearestStation: nearestStation ?? this.nearestStation,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  bool get hasCoordinates => lat != null && lng != null;

  factory ExtractedPlace.fromJson(Map<String, dynamic> json) {
    return ExtractedPlace(
      name: json['name'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      category: json['category'] as String? ?? '관광',
      activity: json['activity'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
      description: json['description'] as String? ?? '',
      nearestStation: json['nearestStation'] as String?,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 60,
    );
  }
}

/// Gemini 분석 결과
class SnsAnalysisResult {
  final List<ExtractedPlace> places;
  final String overallMood;
  final List<String> keywords;

  const SnsAnalysisResult({
    required this.places,
    this.overallMood = '',
    this.keywords = const [],
  });
}

/// 플랜 스타일
enum PlanStyle {
  efficient,     // 효율적 동선
  leisurely,     // 여유로운 산책
  foodFocused,   // 맛집 중심
}

extension PlanStyleExt on PlanStyle {
  String get label => switch (this) {
    PlanStyle.efficient => '효율적 동선',
    PlanStyle.leisurely => '여유로운 산책',
    PlanStyle.foodFocused => '맛집 중심',
  };

  String get description => switch (this) {
    PlanStyle.efficient => '최소 이동시간으로 알차게',
    PlanStyle.leisurely => '환승 적고 여유있게',
    PlanStyle.foodFocused => '식사 시간에 맞춘 맛집 코스',
  };

  String get icon => switch (this) {
    PlanStyle.efficient => '⚡',
    PlanStyle.leisurely => '🚶',
    PlanStyle.foodFocused => '🍽️',
  };
}

/// 플랜 내 한 정거장
class PlanStop {
  final ExtractedPlace place;
  final String arrivalTime;
  final String departureTime;
  final PathResult? routeFromPrevious;
  final int transitMinutes;

  const PlanStop({
    required this.place,
    required this.arrivalTime,
    required this.departureTime,
    this.routeFromPrevious,
    this.transitMinutes = 0,
  });
}

/// 완성된 하루 플랜
class DayPlan {
  final PlanStyle style;
  final List<PlanStop> stops;
  final int totalTransitMinutes;
  final int totalActivityMinutes;
  final int transferCount;

  const DayPlan({
    required this.style,
    required this.stops,
    this.totalTransitMinutes = 0,
    this.totalActivityMinutes = 0,
    this.transferCount = 0,
  });

  String get startTime => stops.isNotEmpty ? stops.first.arrivalTime : '10:00';
  String get endTime => stops.isNotEmpty ? stops.last.departureTime : '18:00';
}
