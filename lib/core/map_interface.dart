import 'package:flutter/material.dart';
import '../models/subway_models.dart';
import '../models/building_hit.dart';

enum MapType { mapbox }

abstract class IMapController {
  /// flyTo 기반 (포물선) — 멀리/가까이 갈 때 자연스러운 호 모션.
  void moveTo(double lat, double lng, {double? zoom, double? pitch, double? bearing, int durationMs = 1500});
  /// 직선 이동 (flyTo 의 포물선 없이) — 카메라가 위로 솟지 않고 평면으로 부드럽게.
  void easeTo(
    double lat,
    double lng, {
    double? zoom,
    double? pitch,
    double? bearing,
    int durationMs = 1200,
  }) {}
  /// 카메라 즉시 스냅 (애니메이션 X). flyTo 의 호 모션은 먼 거리(수십 km)에서
  /// 중간 줌이 12 미만으로 떨어져 Mapbox Standard 의 3D extrusion 이 꺼지고
  /// 광역 타일을 한꺼번에 fetch 하는데, Android 는 tile decode 가 느려서
  /// 화면이 일순간 비고 frame skip 발생. 그런 케이스에 대비한 직접 setCamera.
  void snapTo(double lat, double lng,
      {double? zoom, double? pitch, double? bearing}) {}
  /// 시네마틱 도착 (easeTo + follow lock). snap 직후 자연스러운 "위로 올라오는"
  /// 효과를 만들기 위해 사용. easeTo 가 진행되는 동안 followTrain 의 setCamera
  /// 호출이 카메라를 끌어당기지 않도록 내부 _flyToEndTime + _isFollowing flag 도
  /// 함께 세팅. 호출 직후 primeFollowMode() 별도로 부르지 말 것.
  void arriveAt(double lat, double lng,
      {double? zoom, double? pitch, double? bearing, int durationMs = 800}) {}
  void toggleLayer(String layerId, bool visible);
  void setPitch(double pitch);
  void setBearing(double bearing);
  void setZoom(double zoom);

  // 가시성 및 스타일 제어
  void setStyle(String styleUri);
  void setFilter(String layerId, dynamic filter);

  // 마커 및 어노테이션
  Future<void> addMarker(String id, double lat, double lng, {String? title, String? iconPath});
  void removeMarker(String id);
  void clearMarkers();

  // 3D 및 라이트 설정 (Mapbox 특화)
  void setLightPreset(String preset); // day, night, dusk, dawn
  void setTerrain(bool enabled);

  // ── 지하철 시각화용 확장 메서드 ──

  /// 폴리라인 추가 (노선 경로 표시)
  Future<void> addPolyline(String id, List<List<double>> coordinates, {
    Color color = Colors.blue,
    double width = 3.0,
    double opacity = 1.0,
  }) async {}

  /// 폴리라인 제거
  void removePolyline(String id) {}

  /// 모든 폴리라인 제거
  void clearPolylines() {}

  /// 화살표 마커 추가 (경로 방향 표시)
  Future<void> addArrowMarker(String id, double lat, double lng, {
    required double bearing,
    Color color = Colors.white,
  }) async {}

  /// 경로 화살표 일괄 업데이트 (SymbolLayer)
  Future<void> updateRouteArrows(List<Map<String, dynamic>> arrows) async {}

  /// 경로 화살표 제거
  Future<void> clearRouteArrows() async {}

  /// 원형 마커 추가 (열차 위치 표시)
  Future<void> addCircleMarker(String id, double lat, double lng, {
    Color color = Colors.red,
    double radius = 6.0,
    Color strokeColor = Colors.white,
    double strokeWidth = 2.0,
  }) async {}

  /// 원형 마커 제거
  void removeCircleMarker(String id) {}

  /// 모든 원형 마커 제거
  void clearCircleMarkers() {}

  /// 역 마커 추가 (작은 점 + 이름)
  Future<void> addStationMarker(String id, double lat, double lng, {
    String? name,
    Color color = Colors.white,
    double radius = 3.0,
  }) async {}

  // ── 3D 지하철 시각화 (Style Layer 기반) ──

  /// 3D 열차 위치 일괄 업데이트 (GeoJSON Source)
  /// [trainDelays] 열차별 지연 시간 (trainNo → 분), 없으면 빈 맵
  Future<void> updateTrainPositions3D(List<InterpolatedTrainPosition> trains, {Map<String, int> trainDelays = const {}}) async {}

  /// 3D 노선 경로 초기화 (지상/지하 구분)
  Future<void> initRoutes3D(Map<String, List<List<double>>> routeCoordinates,
      Map<String, Color> lineColors, Map<String, List<bool>> segmentUnderground) async {}

  /// 3D 역 마커 업데이트 (MiniTokyo3D 스타일 필/캡슐 마커)
  /// [pills] 역별 캡슐 배경 (LineString), [dots] 노선별 컬러 도트 (Point)
  Future<void> updateStations3D(List<Map<String, dynamic>> pills, List<Map<String, dynamic>> dots) async {}

  /// 지하 구간 표시 토글
  void setUndergroundVisible(bool visible) {}

  /// 3D Style Layer 초기화 (맵 엔진 준비 완료 후 호출)
  Future<void> init3DLayers() async {}

  /// 3D Style Layer 정리
  void cleanup3DLayers() {}

  /// 열차 탭 콜백 설정 (Mapbox only)
  void setOnTrainTapped(void Function(String trainNo)? callback) {}

  /// 역 탭 콜백 설정 (Mapbox only)
  void setOnStationTapped(void Function(String stationName)? callback) {}

  /// 선택된 열차 따라가기 — 카메라 이동 (Mapbox only)
  void followTrain(double lat, double lng, double bearing) {}

  /// follow 모드 진입 표시. 이후 followTrain 호출은 zoom/pitch 변경 없이
  /// setCamera(center) 만 함 — 외부에서 미리 카메라를 원하는 zoom/pitch 로 맞춰놨을 때 사용.
  void primeFollowMode() {}

  /// 열차 선택 해제 시 호출 — 맵 빈 곳 탭 (Mapbox only)
  void setOnMapTappedEmpty(VoidCallback? callback) {}

  /// 맵 어디든 탭 시 호출 (키보드 dismiss 등 용도)
  void setOnAnyMapTap(VoidCallback? callback) {}

  /// 현재 위치 표시 활성화 (location puck)
  Future<void> enableLocationPuck() async {}

  /// 현재 위치로 카메라 이동
  Future<void> moveToCurrentLocation() async {}

  /// 외부에서 받은 GPS fix 로 사용자 아바타 위치를 즉시 갱신.
  /// distanceFilter 로 사라진 듯 보이거나 카메라/아바타가 어긋날 때 호출.
  Future<void> setUserLocation(double lat, double lng) async {}

  /// 위성지도 레이어 토글
  void setSatelliteVisible(bool visible) {}

  /// 실시간 교통정보 토글
  void setTrafficVisible(bool visible) {}

  /// 장소 핀 마커 표시 (빨간 드롭 핀)
  Future<void> showPlacePin(double lat, double lng, {String? label}) async {}

  /// 장소 핀 마커 제거
  void removePlacePin() {}

  /// POI 탭 콜백 설정 (지도 위 장소 아이콘 클릭 시)
  void setOnPoiTapped(void Function(String name, double lat, double lng)? callback) {}

  /// 좌표 기반 탭 콜백 (빈 곳 탭 시 좌표 전달)
  void setOnMapCoordTapped(void Function(double lat, double lng)? callback) {}

  /// 주변 POI 마커 표시 (카카오 데이터)
  Future<void> showNearbyPoi(List<Map<String, dynamic>> pois) async {}

  /// 주변 POI 마커 제거
  void clearNearbyPoi() {}

  /// 카메라 이동 완료 콜백
  void setOnCameraIdle(void Function(double lat, double lng, double zoom)? callback) {}

  /// 선택된 열차 번호 설정 (하이라이트 표시용)
  void setSelectedTrain(String? trainNo) {}

  /// 선택된 역 이름 설정 (하이라이트 표시용)
  void setSelectedStation(String? stationName) {}

  /// 한강버스 선착장/배 바닥 glow 표시
  void showRiverBusHighlight(double lat, double lng) {}
  void hideRiverBusHighlight() {}

  /// 날씨 시각 효과 적용 (안개, 비, 눈 등)
  void applyWeatherEffect({
    required String lightPreset,
    double fogOpacity = 0.0,
    double atmosphereRange = 1.0,
    double rainIntensity = 0.0,
    double snowIntensity = 0.0,
  }) {}

  /// 지연/장애 노선에 방어막(쉴드) 효과 표시 (MiniTokyo3D 스타일)
  /// [delayInfo] 지연 노선 ID → 지연 분 수 (e.g., {'1002': 5, '1004': 12})
  Future<void> updateDelayShield3D(Map<String, int> delayInfo) async {}

  /// 혼잡도 히트맵 업데이트 (역 좌표 + 가중치)
  Future<void> updateCongestionHeatmap(List<Map<String, dynamic>> points) async {}

  /// 혼잡도 히트맵 표시/숨김
  void setCongestionVisible(bool visible) {}

  // ── 버스 3D 시각화 ──

  /// 버스 탭 콜백 설정
  void setOnBusTapped(void Function(String vehId)? callback) {}

  // ── 리버버스 3D 시각화 ──
  Future<void> initRiverBusLayers() async {}
  void cleanupRiverBusLayers() {}
  Future<void> updateRiverBusPositions3D(List<BusRenderData> vessels) async {}

  /// 비행기 탭 콜백 설정
  void setOnFlightTapped(void Function(String icao24)? callback) {}

  // ── 항공기 3D 시각화 ──

  /// 항공기 3D 레이어 초기화
  Future<void> initFlightLayers() async {}

  /// 항공기 3D 레이어 정리
  void cleanupFlightLayers() {}

  /// 항공기 위치 일괄 업데이트 (3D — 고도 비례 높이)
  Future<void> updateFlightPositions3D(List<FlightRenderData> flights) async {}

  /// 버스 3D 레이어 초기화
  Future<void> initBusLayers() async {}

  /// 버스 3D 레이어 정리
  void cleanupBusLayers() {}

  /// 버스 위치 일괄 업데이트 (3D 블록)
  Future<void> updateBusPositions3D(List<BusRenderData> buses) async {}

  // ── 멀티플레이어 peer 핀 (지하철 마커와 충돌 회피용 별도 매니저) ──
  /// peer 핀 추가/갱신 — 같은 id 호출 시 위치/색/라벨만 이동.
  /// [label] 이 주어지면 핀 위에 닉네임 텍스트 표시.
  Future<void> upsertPeerPin(
    String id,
    double lat,
    double lng, {
    required Color color,
    String? label,
  }) async {}

  /// peer 핀 제거.
  void removePeerPin(String id) {}

  /// 모든 peer 핀 제거 (방 나갈 때).
  void clearPeerPins() {}

  /// peer 핀 탭 콜백. userId 받음.
  void setOnPeerPinTapped(void Function(String userId)? callback) {}

  /// 내 위치 3D 아바타 탭 콜백 (Mapbox only). 친구방 멤버 시트 진입 등에 사용.
  void setOnUserAvatarTapped(VoidCallback? callback) {}

  /// 내 위치 마커 색을 동기화 (보통 myProfile.pinColor).
  Future<void> setUserPinColor(Color color) async {}

  /// 좌표가 건물 footprint 안에 있는지 hit-test. 안에 있으면 BuildingHit, 아니면 null.
  /// 좌표가 화면 밖이면 보통 null (Mapbox 는 visible tile 만 query).
  Future<BuildingHit?> queryBuildingAt(double lat, double lng) async => null;

  /// 내 위치 마커의 표시 여부. 자기 자신이 건물 안에 있을 때 false 로 숨김.
  void setUserPinVisible(bool visible) {}
}

/// 항공기 렌더링 데이터
class FlightRenderData {
  final String icao24;
  final String callsign;
  final double lat;
  final double lng;
  final double altitude; // 미터
  final double bearing;
  final String color;
  final bool onGround;

  FlightRenderData({
    required this.icao24,
    required this.callsign,
    required this.lat,
    required this.lng,
    required this.altitude,
    required this.bearing,
    required this.color,
    required this.onGround,
  });
}

/// 버스 렌더링 데이터
class BusRenderData {
  final String vehId;
  final double lat;
  final double lng;
  final double bearing;
  final String color; // rgba 문자열
  final int congestion; // 0~6

  BusRenderData({
    required this.vehId,
    required this.lat,
    required this.lng,
    required this.bearing,
    required this.color,
    required this.congestion,
  });
}

class CameraInfo {
  final double lat;
  final double lng;
  final double zoom;
  final double pitch;
  final double bearing;

  CameraInfo({
    required this.lat,
    required this.lng,
    required this.zoom,
    required this.pitch,
    required this.bearing,
  });
}
