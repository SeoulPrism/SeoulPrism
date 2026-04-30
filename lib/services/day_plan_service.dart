import 'dart:math';
import '../models/sns_content_models.dart';
import 'path_finding_service.dart';

class DayPlanService {
  static DayPlanService? _instance;
  DayPlanService._();

  static DayPlanService get instance {
    _instance ??= DayPlanService._();
    return _instance!;
  }

  final _pathService = PathFindingService();

  /// 3가지 스타일의 플랜 동시 생성
  Future<List<DayPlan>> generatePlans(
    List<ExtractedPlace> places, {
    String startTime = '10:00',
  }) async {
    if (places.isEmpty) return [];

    final validPlaces = places.where((p) => p.nearestStation != null).toList();
    if (validPlaces.isEmpty) return [];

    return [
      await _generateEfficient(validPlaces, startTime),
      await _generateLeisurely(validPlaces, startTime),
      await _generateFoodFocused(validPlaces, startTime),
    ];
  }

  /// 효율적 동선: nearest-neighbor 그리디 + 최소시간 경로
  Future<DayPlan> _generateEfficient(List<ExtractedPlace> places, String startTime) async {
    final ordered = _nearestNeighborOrder(places);
    return _buildPlan(PlanStyle.efficient, ordered, startTime, PathSearchType.duration, 15);
  }

  /// 여유로운 산책: 환승 최소 + 여유 버퍼
  Future<DayPlan> _generateLeisurely(List<ExtractedPlace> places, String startTime) async {
    // 분위기 우선: 자연/카페를 앞으로
    final ordered = List<ExtractedPlace>.from(places);
    ordered.sort((a, b) {
      const leisureCategories = {'자연', '카페', '문화'};
      final aScore = leisureCategories.contains(a.category) ? 0 : 1;
      final bScore = leisureCategories.contains(b.category) ? 0 : 1;
      return aScore.compareTo(bScore);
    });
    return _buildPlan(PlanStyle.leisurely, ordered, startTime, PathSearchType.transfer, 30);
  }

  /// 맛집 중심: 식사 시간대에 맛집/카페 배치
  Future<DayPlan> _generateFoodFocused(List<ExtractedPlace> places, String startTime) async {
    final food = places.where((p) => p.category == '맛집' || p.category == '카페').toList();
    final other = places.where((p) => p.category != '맛집' && p.category != '카페').toList();

    // 맛집을 식사 시간대(점심/간식/저녁)에 배치, 나머지를 사이에
    final ordered = <ExtractedPlace>[];
    int foodIdx = 0;
    int otherIdx = 0;

    // 오전 활동
    if (otherIdx < other.length) ordered.add(other[otherIdx++]);
    // 점심 맛집
    if (foodIdx < food.length) ordered.add(food[foodIdx++]);
    // 오후 활동
    if (otherIdx < other.length) ordered.add(other[otherIdx++]);
    // 간식 카페
    if (foodIdx < food.length) ordered.add(food[foodIdx++]);
    // 오후 활동2
    if (otherIdx < other.length) ordered.add(other[otherIdx++]);
    // 저녁 맛집
    if (foodIdx < food.length) ordered.add(food[foodIdx++]);

    // 남은 장소들 추가
    while (foodIdx < food.length) ordered.add(food[foodIdx++]);
    while (otherIdx < other.length) ordered.add(other[otherIdx++]);

    return _buildPlan(PlanStyle.foodFocused, ordered, startTime, PathSearchType.duration, 15);
  }

  /// 플랜 빌드 공통 로직
  Future<DayPlan> _buildPlan(
    PlanStyle style,
    List<ExtractedPlace> orderedPlaces,
    String startTime,
    PathSearchType searchType,
    int bufferMinutes,
  ) async {
    final stops = <PlanStop>[];
    var currentMinutes = _parseTime(startTime);
    int totalTransit = 0;
    int totalActivity = 0;
    int transfers = 0;

    for (int i = 0; i < orderedPlaces.length; i++) {
      final place = orderedPlaces[i];
      PathResult? route;
      int transit = 0;

      // 이전 장소에서 이동 경로
      if (i > 0 && orderedPlaces[i - 1].nearestStation != null && place.nearestStation != null) {
        try {
          route = await _pathService.findPath(
            departure: orderedPlaces[i - 1].nearestStation!,
            arrival: place.nearestStation!,
            searchType: searchType,
          );
          if (route != null) {
            transit = (route.totalTimeSec / 60).ceil();
            transfers += route.transferCount;
          }
        } catch (_) {}
      }

      currentMinutes += transit + bufferMinutes;
      final arrival = _formatTime(currentMinutes);
      final departure = _formatTime(currentMinutes + place.estimatedMinutes);

      stops.add(PlanStop(
        place: place,
        arrivalTime: arrival,
        departureTime: departure,
        routeFromPrevious: route,
        transitMinutes: transit,
      ));

      totalTransit += transit;
      totalActivity += place.estimatedMinutes;
      currentMinutes += place.estimatedMinutes;
    }

    return DayPlan(
      style: style,
      stops: stops,
      totalTransitMinutes: totalTransit,
      totalActivityMinutes: totalActivity,
      transferCount: transfers,
    );
  }

  /// Nearest-neighbor 순서 정렬 (greedy)
  List<ExtractedPlace> _nearestNeighborOrder(List<ExtractedPlace> places) {
    if (places.length <= 1) return List.from(places);

    final remaining = List<ExtractedPlace>.from(places);
    final result = <ExtractedPlace>[remaining.removeAt(0)];

    while (remaining.isNotEmpty) {
      final last = result.last;
      if (last.lat == null || last.lng == null) {
        result.add(remaining.removeAt(0));
        continue;
      }

      int bestIdx = 0;
      double bestDist = double.infinity;
      for (int i = 0; i < remaining.length; i++) {
        final p = remaining[i];
        if (p.lat == null || p.lng == null) continue;
        final d = _distance(last.lat!, last.lng!, p.lat!, p.lng!);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      result.add(remaining.removeAt(bestIdx));
    }
    return result;
  }

  double _distance(double lat1, double lng1, double lat2, double lng2) {
    final dLat = lat1 - lat2;
    final dLng = lng1 - lng2;
    return sqrt(dLat * dLat + dLng * dLng);
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatTime(int minutes) {
    final h = (minutes ~/ 60).clamp(0, 23);
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
