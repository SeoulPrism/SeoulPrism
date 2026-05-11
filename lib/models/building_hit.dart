/// Mapbox 건물 footprint hit-test 결과.
class BuildingHit {
  /// Mapbox feature id 또는 centroid 기반 deterministic id.
  final String id;
  /// 외곽 링 [lng, lat] 좌표 리스트.
  final List<List<double>> ringLngLat;
  final double centroidLat;
  final double centroidLng;
  /// 알려진 이름 (Mapbox properties.name 등) — 보통 비어있음.
  final String? name;

  const BuildingHit({
    required this.id,
    required this.ringLngLat,
    required this.centroidLat,
    required this.centroidLng,
    this.name,
  });

  /// 사용자에게 표시할 라벨 — 이름이 있으면 그대로, 없으면 "건물".
  String get displayName => (name == null || name!.isEmpty) ? '건물' : name!;
}
