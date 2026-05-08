import 'dart:math';
import '../core/geo_distance.dart';
import '../models/sns_content_models.dart';
import 'favorites_service.dart';
import 'visit_history_service.dart';

/// 사용자의 즐겨찾기 + 방문 기록을 기반으로 DayPlan 자동 생성.
/// 이동 경로(polyline) 그리지 않으므로 transit 시간은 거리 기반 근사치.
/// 사용자가 stop 별 "길찾기" 버튼 누르면 본 앱 PathFindingService 가 정확한 경로 검색.
class SavedPlacesPlanBuilder {
  static const int minPlaces = 3;
  static const int maxStops = 6;

  /// 가능하면 [DayPlan] 리스트 반환 (장소 부족하면 빈 리스트).
  static List<DayPlan> buildPlans() {
    final places = _collectPlaces();
    if (places.length < minPlaces) return [];

    final ordered = _orderByNearestNeighbor(places).take(maxStops).toList();
    final stops = _toStops(ordered);
    final transitTotal = stops.fold<int>(0, (sum, s) => sum + s.transitMinutes);
    final activityTotal =
        stops.fold<int>(0, (sum, s) => sum + s.place.estimatedMinutes);

    return [
      DayPlan(
        style: PlanStyle.efficient,
        stops: stops,
        totalTransitMinutes: transitTotal,
        totalActivityMinutes: activityTotal,
        transferCount: 0,
      ),
    ];
  }

  /// 즐겨찾기 + 자주 방문 + 최근 방문 = 통합 + 가중치 + 중복 제거.
  static List<_PlaceCandidate> _collectPlaces() {
    final fav = FavoritesService.instance.favorites;
    final freq = VisitHistoryService.instance.frequentVisits;
    final recent = VisitHistoryService.instance.recentVisits;
    final byName = <String, _PlaceCandidate>{};

    for (final f in fav) {
      if (f.lat == 0 && f.lng == 0) continue;
      byName.putIfAbsent(
        f.name,
        () => _PlaceCandidate(
          name: f.name,
          category: f.category.isEmpty ? '관광' : f.category,
          lat: f.lat,
          lng: f.lng,
          weight: 100,
        ),
      );
    }
    for (final v in freq) {
      if (v.lat == 0 && v.lng == 0) continue;
      final existing = byName[v.name];
      if (existing != null) {
        existing.weight += v.visitCount * 10;
      } else {
        byName[v.name] = _PlaceCandidate(
          name: v.name,
          category: v.category.isEmpty ? '관광' : v.category,
          lat: v.lat,
          lng: v.lng,
          weight: 50 + v.visitCount * 10,
        );
      }
    }
    for (final v in recent) {
      if (v.lat == 0 && v.lng == 0) continue;
      byName.putIfAbsent(
        v.name,
        () => _PlaceCandidate(
          name: v.name,
          category: v.category.isEmpty ? '관광' : v.category,
          lat: v.lat,
          lng: v.lng,
          weight: 20,
        ),
      );
    }

    return byName.values.toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
  }

  /// nearest-neighbor TSP — 가중치 큰 첫 장소부터 직선거리 가장 가까운 다음 선택.
  static List<_PlaceCandidate> _orderByNearestNeighbor(
      List<_PlaceCandidate> places) {
    if (places.length <= 2) return places;
    final remaining = List<_PlaceCandidate>.from(places);
    final ordered = <_PlaceCandidate>[remaining.removeAt(0)];
    while (remaining.isNotEmpty) {
      final last = ordered.last;
      var bestIdx = 0;
      var bestSq = double.infinity;
      for (int i = 0; i < remaining.length; i++) {
        final dLat = remaining[i].lat - last.lat;
        final dLng = remaining[i].lng - last.lng;
        final sq = dLat * dLat + dLng * dLng;
        if (sq < bestSq) {
          bestSq = sq;
          bestIdx = i;
        }
      }
      ordered.add(remaining.removeAt(bestIdx));
    }
    return ordered;
  }

  /// 거리 기반 근사 transit 시간 + 카테고리별 활동 시간.
  static List<PlanStop> _toStops(List<_PlaceCandidate> ordered) {
    final stops = <PlanStop>[];
    var currentMin = 10 * 60; // 10:00 기준 (분)

    for (int i = 0; i < ordered.length; i++) {
      final p = ordered[i];
      final activityMin = _estimatedMinutesFor(p.category);

      int transitMin = 0;
      if (i > 0) {
        final prev = ordered[i - 1];
        final distM = distanceMeters(prev.lat, prev.lng, p.lat, p.lng);
        // 1km 미만: 도보 (1km ≈ 13분), 1km 이상: 대중교통 평균 (1km ≈ 3.5분 + 환승/대기 5분).
        if (distM < 1000) {
          transitMin = (distM / 1000 * 13).round();
        } else {
          transitMin = (distM / 1000 * 3.5 + 5).round();
        }
        transitMin = max(5, min(60, transitMin));
        currentMin += transitMin;
      }

      final arrival = _formatTime(currentMin);
      final departure = _formatTime(currentMin + activityMin);
      currentMin += activityMin;

      stops.add(PlanStop(
        place: ExtractedPlace(
          name: p.name,
          category: p.category,
          activity: _activityFor(p.category),
          lat: p.lat,
          lng: p.lng,
          estimatedMinutes: activityMin,
        ),
        arrivalTime: arrival,
        departureTime: departure,
        transitMinutes: transitMin,
      ));
    }
    return stops;
  }

  static int _estimatedMinutesFor(String category) => switch (category) {
        '맛집' || '식당' || '레스토랑' => 90,
        '카페' => 60,
        '쇼핑' || '백화점' || '마트' => 75,
        '문화' || '전시' || '박물관' || '공연' => 90,
        '관광' || '명소' => 75,
        '자연' || '공원' || '한강' => 60,
        _ => 60,
      };

  static String _activityFor(String category) => switch (category) {
        '맛집' || '식당' || '레스토랑' => '식사',
        '카페' => '커피/디저트',
        '쇼핑' || '백화점' || '마트' => '쇼핑',
        '문화' || '전시' || '박물관' => '관람',
        '공연' => '관람',
        '관광' || '명소' => '구경',
        '자연' || '공원' || '한강' => '산책',
        _ => '방문',
      };

  static String _formatTime(int totalMin) {
    final h = (totalMin ~/ 60) % 24;
    final m = totalMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class _PlaceCandidate {
  final String name;
  final String category;
  final double lat;
  final double lng;
  int weight;
  _PlaceCandidate({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.weight,
  });
}
