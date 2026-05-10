import '../core/debug_log.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Visibility;
import '../core/api_keys.dart';
import '../core/map_interface.dart';
import '../models/subway_models.dart';
import '../data/seoul_subway_data.dart';

class MapboxEngine extends StatefulWidget {
  final CameraInfo initialCamera;
  final Function(IMapController) onMapCreated;

  const MapboxEngine({
    super.key,
    required this.initialCamera,
    required this.onMapCreated,
  });

  @override
  State<MapboxEngine> createState() => _MapboxEngineState();
}

/// peer 핀 탭 listener (Mapbox Pigeon).
class _PeerPinClickListener extends OnCircleAnnotationClickListener {
  final _MapboxEngineState engine;
  _PeerPinClickListener(this.engine);
  @override
  void onCircleAnnotationClick(CircleAnnotation annotation) {
    debugPrint('[PeerPinClick] annotation ${annotation.id}');
    engine._firePeerPinTap(annotation);
  }
}

class _MapboxEngineState extends State<MapboxEngine> implements IMapController {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  CircleAnnotationManager? _circleAnnotationManager;
  CircleAnnotationManager? _peerCircleManager;
  PointAnnotationManager? _peerLabelManager; // 닉네임 텍스트 라벨 전용.
  final Map<String, CircleAnnotation> _peerAnnotations = {};
  final Map<String, PointAnnotation> _peerLabels = {};
  PolylineAnnotationManager? _polylineAnnotationManager;
  bool _disposed = false;
  // 채널 에러 발생한 소스: 스타일 재생성 전까지 호출 스킵 (로그 폭주 방지)
  final Set<String> _failedSources = {};

  // 관리 중인 소스/레이어 ID 추적
  final Set<String> _polylineIds = {};
  final Set<String> _circleMarkerIds = {};
  PointAnnotation? _placePinAnnotation;
  static const _poiSourceId = 'kakao-poi-source';
  static const _poiLayerId = 'kakao-poi-layer';
  static const _poiLabelLayerId = 'kakao-poi-label-layer';
  bool _poiLayerInitialized = false;
  void Function(double lat, double lng, double zoom)? _onCameraIdle;

  // ── 3D Style Layer 관련 ──
  static const _trainSourceId = 'subway-trains-source';
  static const _trainLayerId = 'subway-trains-layer';
  static const _selectedTrainSourceId = 'subway-selected-train-source';
  static const _selectedTrainLayerId = 'subway-selected-train-layer';
  static const _selectedStationSourceId = 'subway-selected-station-source';
  static const _selectedStationLayerId = 'subway-selected-station-layer';
  static const _routeSurfaceSourceId = 'subway-routes-surface-source';
  static const _routeSurfaceLayerId = 'subway-routes-surface-layer';
  static const _routeUndergroundSourceId = 'subway-routes-underground-source';
  static const _routeUndergroundLayerId = 'subway-routes-underground-layer';
  static const _routeArrowSourceId = 'route-arrow-source';
  static const _routeArrowLayerId = 'route-arrow-layer';
  static const _stationSourceId = 'subway-stations-source'; // 노선별 도트 (Point)
  static const _stationPillSourceId =
      'subway-stations-pill-source'; // 캡슐 배경 (LineString)
  static const _stationDotLayerId = 'subway-stations-dot-layer';
  static const _stationLabelLayerId = 'subway-stations-label-layer';
  static const _stationOutlineLayerId = 'subway-stations-outline-layer';
  static const _stationPillOutlineLayerId =
      'subway-stations-pill-outline-layer';
  static const _stationPillFillLayerId = 'subway-stations-pill-fill-layer';
  // 열차별 지연 표시 레이어
  static const _delaySourceId = 'subway-delay-source';
  static const _delayGlowLayerId = 'subway-delay-glow-layer';
  static const _delayLabelLayerId = 'subway-delay-label-layer';
  // 혼잡도 히트맵 레이어
  static const _congestionSourceId = 'subway-congestion-source';
  static const _congestionHeatmapLayerId = 'subway-congestion-heatmap-layer';
  static const _congestionCircleLayerId = 'subway-congestion-circle-layer';
  static const _congestionLabelLayerId = 'subway-congestion-label-layer';
  bool _layersInitialized3D = false;
  // ignore: unused_field
  bool _undergroundVisible = true;

  // ── 리버버스 3D 레이어 ──
  static const _riverBusSourceId = 'riverbus-source';
  static const _riverBusLayerId = 'riverbus-layer';
  static const _riverBusWakeSourceId = 'riverbus-wake-source';
  static const _riverBusWakeLayerId = 'riverbus-wake-layer';
  bool _riverBusLayersInitialized = false;

  // ── 버스 3D 레이어 ──
  static const _busSourceId = 'bus-positions-source';
  static const _busLayerId = 'bus-positions-layer';
  static const _busGlowSourceId = 'bus-glow-source';
  static const _busGlowLayerId = 'bus-glow-layer';
  bool _busLayersInitialized = false;

  // ── 항공기 3D 레이어 ──
  static const _flightSourceId = 'flight-positions-source';
  static const _flightLayerId = 'flight-positions-layer';
  static const _flightTrailSourceId = 'flight-trail-source';
  static const _flightTrailLayerId = 'flight-trail-layer';
  bool _flightLayersInitialized = false;

  // 열차 탭 / 버스 탭 / 비행기 탭 / 맵 빈 곳 탭 콜백
  void Function(String trainNo)? _onTrainTapped;
  void Function(String stationName)? _onStationTapped;
  void Function(String vehId)? _onBusTapped;
  void Function(String icao24)? _onFlightTapped;
  void Function(String name, double lat, double lng)? _onPoiTapped;
  void Function(double lat, double lng)? _onMapCoordTapped;
  bool _poiTappedThisFrame = false;
  bool _pendingPoiTriggered = false;
  String? _pendingPoiName;
  double? _pendingPoiLat;
  double? _pendingPoiLng;
  VoidCallback? _onMapTappedEmpty;
  VoidCallback? _onAnyMapTap;
  bool _isFollowing = false;
  String? _selectedTrainNo;
  String? _selectedStationName;
  double? _selectedStationLat;
  double? _selectedStationLng;

  // ── 현재 위치 (3D 사람 아바타) ──
  static const _locationSourceId = 'user-location-source';
  static const _locationBodyLayerId = 'user-location-body-layer';
  static const _locationPulseSourceId = 'user-location-pulse-source';
  static const _locationPulseLayerId = 'user-location-pulse-layer';
  static const _locationHeadLayerId = 'user-location-head-layer';
  bool _locationEnabled = false;
  bool _locationLayersReady = false; // _initLocationLayers 성공 여부.
  bool _locationFailed = false; // 플러그인 미등록 시 재시도 방지
  geo.Position? _currentPosition;
  StreamSubscription<geo.Position>? _positionSubscription;
  Timer? _locationPulseTimer;

  // 서울 위도에서의 미터→도 변환 계수
  static const double _mPerDegLat = 111320.0;
  static const double _mPerDegLng = 88000.0; // ~111320 * cos(37.5°)

  @override
  void moveTo(
    double lat,
    double lng, {
    double? zoom,
    double? pitch,
    double? bearing,
    int durationMs = 1500,
  }) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
        pitch: pitch,
        bearing: bearing,
      ),
      MapAnimationOptions(duration: durationMs),
    );
  }

  @override
  void primeFollowMode() {
    // 외부에서 카메라를 이미 의도한 zoom/pitch 로 맞췄음을 표시.
    // 이후 followTrain 첫 호출이 flyTo(zoom 15.5/pitch 55) 로 카메라 덮어쓰지 않도록.
    _isFollowing = true;
    _flyToEndTime = 0;
  }

  @override
  void easeTo(
    double lat,
    double lng, {
    double? zoom,
    double? pitch,
    double? bearing,
    int durationMs = 1200,
  }) {
    _mapboxMap?.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
        pitch: pitch,
        bearing: bearing,
      ),
      MapAnimationOptions(duration: durationMs),
    );
  }

  @override
  void snapTo(double lat, double lng,
      {double? zoom, double? pitch, double? bearing}) {
    _mapboxMap?.setCamera(CameraOptions(
      center: Point(coordinates: Position(lng, lat)),
      zoom: zoom,
      pitch: pitch,
      bearing: bearing,
    ));
    _flyToEndTime = 0;
  }

  @override
  void arriveAt(double lat, double lng,
      {double? zoom, double? pitch, double? bearing, int durationMs = 800}) {
    _mapboxMap?.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
        pitch: pitch,
        bearing: bearing,
      ),
      MapAnimationOptions(duration: durationMs),
    );
    // followTrain 이 첫 호출에서 또 다른 flyTo 띄우지 않게 lock,
    // 그리고 추적 setCamera 가 easeTo 끝날 때까지 무시되도록 _flyToEndTime 게이트.
    _isFollowing = true;
    _flyToEndTime = DateTime.now().millisecondsSinceEpoch + durationMs;
  }

  @override
  void setPitch(double pitch) =>
      _mapboxMap?.setCamera(CameraOptions(pitch: pitch));

  @override
  void setBearing(double bearing) =>
      _mapboxMap?.setCamera(CameraOptions(bearing: bearing));

  @override
  void setZoom(double zoom) => _mapboxMap?.setCamera(CameraOptions(zoom: zoom));

  @override
  void setStyle(String styleUri) {
    _failedSources.clear();
    _mapboxMap?.loadStyleURI(styleUri);
  }

  @override
  void toggleLayer(String layerId, bool visible) {
    _mapboxMap?.style.styleLayerExists(layerId).then((exists) {
      if (exists) {
        _mapboxMap?.style.setStyleLayerProperty(
          layerId,
          'visibility',
          visible ? 'visible' : 'none',
        );
      }
    });
  }

  @override
  void setFilter(String layerId, dynamic filter) {
    _mapboxMap?.style.setStyleLayerProperty(layerId, 'filter', filter);
  }

  @override
  void setLightPreset(String preset) {
    try {
      _mapboxMap?.style.setStyleImportConfigProperty(
        "basemap",
        "lightPreset",
        preset,
      );
    } catch (e) {
      DebugLog.log('[MapboxEngine] lightPreset 설정 실패: $e');
    }
  }

  bool _satelliteInitialized = false;
  bool _trafficInitialized = false;

  @override
  void setSatelliteVisible(bool visible) {
    if (_mapboxMap == null) return;
    _setSatelliteAsync(visible);
  }

  Future<void> _setSatelliteAsync(bool visible) async {
    final style = _mapboxMap!.style;

    if (!_satelliteInitialized) {
      try {
        await style.addSource(
          RasterSource(
            id: 'mapbox-satellite',
            tiles: [
              'https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}@2x.png?access_token=${ApiKeys.mapboxAccessToken}',
            ],
            tileSize: 256,
          ),
        );
        await style.addLayerAt(
          RasterLayer(
            id: 'satellite-layer',
            sourceId: 'mapbox-satellite',
            rasterOpacity: 0.85,
          ),
          LayerPosition(at: 0),
        );
        _satelliteInitialized = true;
      } catch (e) {
        DebugLog.log('[MapboxEngine] satellite 초기화 실패: $e');
        return;
      }
    }

    await style.setStyleLayerProperty(
      'satellite-layer',
      'visibility',
      visible ? 'visible' : 'none',
    );
  }

  @override
  void setTrafficVisible(bool visible) {
    if (_mapboxMap == null) return;
    _setTrafficAsync(visible);
  }

  Future<void> _setTrafficAsync(bool visible) async {
    final style = _mapboxMap!.style;

    if (!_trafficInitialized) {
      try {
        await style.addSource(
          RasterSource(
            id: 'mapbox-traffic',
            tiles: [
              'https://api.mapbox.com/v4/mapbox.mapbox-traffic-v1/{z}/{x}/{y}.png?access_token=${ApiKeys.mapboxAccessToken}',
            ],
            tileSize: 256,
          ),
        );
        await style.addLayer(
          RasterLayer(
            id: 'traffic-layer',
            sourceId: 'mapbox-traffic',
            rasterOpacity: 0.7,
          ),
        );
        _trafficInitialized = true;
      } catch (e) {
        DebugLog.log('[MapboxEngine] traffic 초기화 실패: $e');
        return;
      }
    }

    await style.setStyleLayerProperty(
      'traffic-layer',
      'visibility',
      visible ? 'visible' : 'none',
    );
  }

  @override
  void applyWeatherEffect({
    required String lightPreset,
    double fogOpacity = 0.0,
    double atmosphereRange = 1.0,
    double rainIntensity = 0.0,
    double snowIntensity = 0.0,
  }) {
    if (_mapboxMap == null) return;

    // 1) 라이트 프리셋 적용
    setLightPreset(lightPreset);

    // 2) Fog (안개/시정 효과) — Standard style atmosphere config
    if (fogOpacity > 0) {
      try {
        // Standard style의 fog 설정 — config property 사용
        _mapboxMap!.style.setStyleImportConfigProperty(
          "basemap",
          "fog",
          fogOpacity > 0.3 ? "high" : "low",
        );
      } catch (e) {
        DebugLog.log('[MapboxEngine] fog 설정 실패 (무시): $e');
      }
    }
  }

  @override
  void setTerrain(bool enabled) {
    // v2.x 스타일 레이어 속성 제어
  }

  // ── 마커 (Annotation) ──

  @override
  Future<void> addMarker(
    String id,
    double lat,
    double lng, {
    String? title,
    String? iconPath,
  }) async {
    if (_pointAnnotationManager == null) return;

    _pointAnnotationManager?.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        textField: title,
        textColor: Colors.white.toARGB32(),
        textSize: 12.0,
        textOffset: [0, 2.0],
        iconImage: 'marker-15',
      ),
    );
  }

  // ── 장소 핀 마커 (위치 아이콘) ──
  Uint8List? _pinIconBytes;
  bool _pinRegistered = false;

  Future<void> _ensurePinRegistered() async {
    if (_pinRegistered || _mapboxMap == null) return;
    final bytes = await _getPinIcon();
    try {
      final mbImg = MbxImage(width: 120, height: 120, data: bytes);
      await _mapboxMap!.style.addStyleImage(
        'location-pin',
        3.0,
        mbImg,
        false,
        [],
        [],
        null,
      );
      _pinRegistered = true;
    } catch (_) {
      _pinRegistered = true;
    }
  }

  Future<Uint8List> _getPinIcon() async {
    if (_pinIconBytes != null) return _pinIconBytes!;

    // Material Icons의 location_on 아이콘을 렌더링
    const size = 120.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.location_on.codePoint),
        style: TextStyle(
          fontSize: 100,
          fontFamily: Icons.location_on.fontFamily,
          package: Icons.location_on.fontPackage,
          color: const Color(0xFFE53935),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    _pinIconBytes = byteData!.buffer.asUint8List();
    return _pinIconBytes!;
  }

  @override
  Future<void> showPlacePin(double lat, double lng, {String? label}) async {
    if (_pointAnnotationManager == null) return;
    removePlacePin();

    await _ensurePinRegistered();
    // 작은 크기로 생성
    _placePinAnnotation = await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        iconImage: 'location-pin',
        iconSize: 0.0,
        iconAnchor: IconAnchor.BOTTOM,
      ),
    );

    // 부드러운 바운스 (60fps)
    final frames = <double>[];
    for (int i = 0; i <= 15; i++) frames.add(0.88 * (i / 15));
    for (int i = 1; i <= 6; i++) frames.add(0.88 - 0.16 * (i / 6));
    for (int i = 1; i <= 5; i++) frames.add(0.72 + 0.08 * (i / 5));
    for (final s in frames) {
      await Future.delayed(const Duration(milliseconds: 16));
      if (_placePinAnnotation == null) return;
      _placePinAnnotation!.iconSize = s;
      _pointAnnotationManager!.update(_placePinAnnotation!);
    }
  }

  @override
  void removePlacePin() {
    if (_placePinAnnotation != null && _pointAnnotationManager != null) {
      _pointAnnotationManager!.delete(_placePinAnnotation!);
      _placePinAnnotation = null;
    }
  }

  @override
  Future<void> addArrowMarker(
    String id,
    double lat,
    double lng, {
    required double bearing,
    Color color = Colors.white,
  }) async {
    // 개별 호출은 무시 — updateRouteArrows로 일괄 처리
  }

  /// 경로 화살표 일괄 업데이트 (SymbolLayer — 충돌 감지 없이 항상 표시)
  Future<void> updateRouteArrows(List<Map<String, dynamic>> arrows) async {
    if (_mapboxMap == null) return;
    await _ensureRouteArrowSourceAndLayer();

    // GeoJSON 데이터 업데이트
    final buf = StringBuffer('{"type":"FeatureCollection","features":[');
    for (int i = 0; i < arrows.length; i++) {
      if (i > 0) buf.write(',');
      final a = arrows[i];
      buf.write(
        '{"type":"Feature","geometry":{"type":"Point",'
        '"coordinates":[${a['lng']},${a['lat']}]},'
        '"properties":{"bearing":${a['bearing']},"color":"${a['color']}"}}',
      );
    }
    buf.write(']}');
    await _updateSourceData(_routeArrowSourceId, buf.toString());
  }

  Future<void> _ensureRouteArrowSourceAndLayer() async {
    final style = _mapboxMap!.style;
    final empty = '{"type":"FeatureCollection","features":[]}';

    if (!await style.styleSourceExists(_routeArrowSourceId)) {
      await style.addSource(
        GeoJsonSource(id: _routeArrowSourceId, data: empty),
      );
    }

    if (!await style.styleLayerExists(_routeArrowLayerId)) {
      await style.addLayer(
        SymbolLayer(
          id: _routeArrowLayerId,
          sourceId: _routeArrowSourceId,
          textField: '▶',
          textSize: 12.0,
          textColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          textHaloColor: Colors.white.toARGB32(),
          textHaloWidth: 1.5,
          textRotateExpression: ['get', 'bearing'],
          textAllowOverlap: true,
          textIgnorePlacement: true,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          textPitchAlignment: TextPitchAlignment.MAP,
          textRotationAlignment: TextRotationAlignment.MAP,
        ),
      );
    }
  }

  /// 경로 화살표 제거
  Future<void> clearRouteArrows() async {
    if (_mapboxMap == null) return;
    try {
      if (!await _mapboxMap!.style.styleSourceExists(_routeArrowSourceId)) {
        return;
      }
      await _updateSourceData(
        _routeArrowSourceId,
        '{"type":"FeatureCollection","features":[]}',
      );
    } catch (_) {}
  }

  @override
  void removeMarker(String id) {}

  @override
  void clearMarkers() {
    _pointAnnotationManager?.deleteAll();
  }

  // ── 폴리라인 (노선 경로) ──

  @override
  Future<void> addPolyline(
    String id,
    List<List<double>> coordinates, {
    Color color = Colors.blue,
    double width = 3.0,
    double opacity = 1.0,
  }) async {
    if (_polylineAnnotationManager == null) return;

    final points = coordinates
        .map(
          (c) => Point(
            coordinates: Position(c[1], c[0]),
          ), // [lat, lng] → Position(lng, lat)
        )
        .toList();

    if (points.length < 2) return;

    await _polylineAnnotationManager?.create(
      PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: points.map((p) => p.coordinates).toList(),
        ),
        lineColor: color.toARGB32(),
        lineWidth: width,
        lineOpacity: opacity,
      ),
    );
    _polylineIds.add(id);
  }

  @override
  void removePolyline(String id) {
    _polylineIds.remove(id);
  }

  @override
  void clearPolylines() {
    _polylineAnnotationManager?.deleteAll();
    _polylineIds.clear();
  }

  // ── 원형 마커 (열차 위치) ──

  @override
  Future<void> addCircleMarker(
    String id,
    double lat,
    double lng, {
    Color color = Colors.red,
    double radius = 6.0,
    Color strokeColor = Colors.white,
    double strokeWidth = 2.0,
  }) async {
    if (_circleAnnotationManager == null) return;

    await _circleAnnotationManager?.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        circleColor: color.toARGB32(),
        circleRadius: radius,
        circleStrokeColor: strokeColor.toARGB32(),
        circleStrokeWidth: strokeWidth,
        circleSortKey: 10, // 노선 위에 렌더링
      ),
    );
    _circleMarkerIds.add(id);
  }

  @override
  void removeCircleMarker(String id) {
    _circleMarkerIds.remove(id);
  }

  @override
  void clearCircleMarkers() {
    _circleAnnotationManager?.deleteAll();
    _circleMarkerIds.clear();
  }

  // ── 멀티플레이어 peer 핀 ──

  @override
  Future<void> upsertPeerPin(
    String id,
    double lat,
    double lng, {
    required Color color,
    String? label,
  }) async {
    final manager = _peerCircleManager;
    if (manager == null) return;
    final existing = _peerAnnotations[id];
    if (existing != null) {
      existing.geometry = Point(coordinates: Position(lng, lat));
      existing.circleColor = color.toARGB32();
      try {
        await manager.update(existing);
      } catch (_) {
        // 갱신 실패 시 재생성.
        _peerAnnotations.remove(id);
        await upsertPeerPin(id, lat, lng, color: color, label: label);
        return;
      }
    } else {
      final ann = await manager.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          circleColor: color.toARGB32(),
          circleRadius: 14.0, // 탭 영역 확보 + 가시성.
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 4.0,
          circleSortKey: 100, // 다른 마커보다 위.
        ),
      );
      _peerAnnotations[id] = ann;
    }

    await _upsertPeerLabel(id, lat, lng, label);
  }

  Future<void> _upsertPeerLabel(
      String id, double lat, double lng, String? label) async {
    final lblMgr = _peerLabelManager;
    if (lblMgr == null) return;
    final text = label?.trim() ?? '';
    final existing = _peerLabels[id];
    if (text.isEmpty) {
      if (existing != null) {
        _peerLabels.remove(id);
        try { await lblMgr.delete(existing); } catch (_) {}
      }
      return;
    }
    if (existing != null) {
      existing.geometry = Point(coordinates: Position(lng, lat));
      existing.textField = text;
      try {
        await lblMgr.update(existing);
        return;
      } catch (_) {
        _peerLabels.remove(id);
        try { await lblMgr.delete(existing); } catch (_) {}
      }
    }
    final ann = await lblMgr.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        textField: text,
        textSize: 11.0,
        textColor: Colors.white.toARGB32(),
        textHaloColor: const Color(0xCC000000).toARGB32(),
        textHaloWidth: 1.5,
        textOffset: [0.0, -2.2], // 핀 바로 위로.
        textAnchor: TextAnchor.BOTTOM,
        symbolSortKey: 110,
      ),
    );
    _peerLabels[id] = ann;
  }

  @override
  void removePeerPin(String id) {
    final ann = _peerAnnotations.remove(id);
    if (ann != null) {
      _peerCircleManager?.delete(ann);
    }
    final lbl = _peerLabels.remove(id);
    if (lbl != null) {
      _peerLabelManager?.delete(lbl);
    }
  }

  @override
  void clearPeerPins() {
    for (final ann in _peerAnnotations.values) {
      _peerCircleManager?.delete(ann);
    }
    _peerAnnotations.clear();
    for (final lbl in _peerLabels.values) {
      _peerLabelManager?.delete(lbl);
    }
    _peerLabels.clear();
  }

  void Function(String userId)? _onPeerPinTapped;
  @override
  void setOnPeerPinTapped(void Function(String userId)? callback) {
    _onPeerPinTapped = callback;
  }

  void _firePeerPinTap(CircleAnnotation tapped) {
    String? hitUserId;
    _peerAnnotations.forEach((uid, ann) {
      if (ann.id == tapped.id) hitUserId = uid;
    });
    debugPrint('[PeerPinClick] resolved userId=$hitUserId callback=${_onPeerPinTapped != null}');
    if (hitUserId != null) _onPeerPinTapped?.call(hitUserId!);
  }

  // ── 역 마커 ──

  @override
  Future<void> addStationMarker(
    String id,
    double lat,
    double lng, {
    String? name,
    Color color = Colors.white,
    double radius = 3.0,
  }) async {
    if (_circleAnnotationManager == null) return;

    await _circleAnnotationManager?.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        circleColor: color.toARGB32(),
        circleRadius: radius,
        circleStrokeColor: Colors.black.toARGB32(),
        circleStrokeWidth: 1.0,
        circleSortKey: 5,
      ),
    );
  }

  /// Color 밝게 만들기 (amount: 0.0~1.0)
  static Color _brightenColor(Color c, double amount) {
    final r = (c.r + (1.0 - c.r) * amount).clamp(0.0, 1.0);
    final g = (c.g + (1.0 - c.g) * amount).clamp(0.0, 1.0);
    final b = (c.b + (1.0 - c.b) * amount).clamp(0.0, 1.0);
    return Color.from(alpha: c.a, red: r, green: g, blue: b);
  }

  /// Color → CSS rgba 문자열
  static String _colorToRgba(Color c) {
    final r = (c.r * 255).round().clamp(0, 255);
    final g = (c.g * 255).round().clamp(0, 255);
    final b = (c.b * 255).round().clamp(0, 255);
    return 'rgba($r,$g,$b,1)';
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3D Style Layer 기반 지하철 시각화
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Future<void> init3DLayers() async {
    if (_mapboxMap == null || _layersInitialized3D) return;

    // 이전 세션에서 남은 소스/레이어가 있으면 정리
    cleanup3DLayers();

    final style = _mapboxMap!.style;
    const emptyGeoJson = '{"type":"FeatureCollection","features":[]}';

    try {
      // 1) 열차 위치 — FillExtrusionLayer (실제 3D 블록)
      await style.addSource(
        GeoJsonSource(id: _trainSourceId, data: emptyGeoJson),
      );

      // 3D 기둥 (메인 몸체) — emissive로 야간에도 자체 발광
      await style.addLayer(
        FillExtrusionLayer(
          id: _trainLayerId,
          sourceId: _trainSourceId,
          fillExtrusionColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          fillExtrusionBaseExpression: ['get', 'base'],
          fillExtrusionHeightExpression: ['get', 'top'],
          fillExtrusionOpacity: 0.85,
          fillExtrusionVerticalGradient: true,
          fillExtrusionEmissiveStrength: 1.0,
        ),
      );

      DebugLog.log('[MapboxEngine] ✅ 열차 FillExtrusionLayer 생성 완료');

      // 1-b) 선택된 열차 하이라이트 — 노선색 발광 링 (CircleLayer)
      await style.addSource(
        GeoJsonSource(id: _selectedTrainSourceId, data: emptyGeoJson),
      );

      // 외곽 발광 (큰 원 + 블러)
      await style.addLayer(
        CircleLayer(
          id: _selectedTrainLayerId,
          sourceId: _selectedTrainSourceId,
          circleColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            8.0,
            13,
            16.0,
            15,
            28.0,
            17,
            45.0,
          ],
          circleBlur: 0.6,
          circleOpacityExpression: ['get', 'opacity'],
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circleSortKey: 9,
          circleEmissiveStrength: 1.0,
        ),
      );

      // 내부 링 (선명한 작은 원)
      await style.addLayer(
        CircleLayer(
          id: '${_selectedTrainLayerId}-inner',
          sourceId: _selectedTrainSourceId,
          circleColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            4.0,
            13,
            8.0,
            15,
            14.0,
            17,
            22.0,
          ],
          circleOpacityExpression: ['get', 'innerOpacity'],
          circleStrokeColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          circleStrokeWidthExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            1.0,
            15,
            2.5,
          ],
          circleStrokeOpacity: 0.9,
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circleSortKey: 10,
          circleEmissiveStrength: 1.0,
        ),
      );

      // 1-c) 선택된 역 하이라이트 — 발광 링 (CircleLayer, 노선별 동심원)
      await style.addSource(
        GeoJsonSource(id: _selectedStationSourceId, data: emptyGeoJson),
      );
      await style.addLayer(
        CircleLayer(
          id: _selectedStationLayerId,
          sourceId: _selectedStationSourceId,
          circleColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            [
              '*',
              [
                'number',
                ['get', 'scale'],
                1.0,
              ],
              10.0,
            ],
            13,
            [
              '*',
              [
                'number',
                ['get', 'scale'],
                1.0,
              ],
              22.0,
            ],
            15,
            [
              '*',
              [
                'number',
                ['get', 'scale'],
                1.0,
              ],
              38.0,
            ],
            17,
            [
              '*',
              [
                'number',
                ['get', 'scale'],
                1.0,
              ],
              55.0,
            ],
          ],
          circleBlur: 0.5,
          circleOpacityExpression: ['get', 'opacity'],
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circleSortKey: 2,
          circleEmissiveStrength: 1.0,
        ),
      );

      // 2) 지상 노선 경로 — LineLayer (고가 철도 높이에 맞춰 3D 띄움)
      await style.addSource(
        GeoJsonSource(id: _routeSurfaceSourceId, data: emptyGeoJson),
      );

      await style.addLayer(
        LineLayer(
          id: _routeSurfaceLayerId,
          sourceId: _routeSurfaceSourceId,
          lineColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          lineWidthExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            8,
            1.5,
            11,
            3.0,
            14,
            5.0,
            17,
            8.0,
          ],
          lineOpacity: 0.9,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
          lineEmissiveStrength: 0.8,
        ),
      );

      DebugLog.log('[MapboxEngine] ✅ 지상 노선 LineLayer 생성 완료');

      // 3) 지하 노선 경로 — LineLayer (바닥, 점선으로 구분)
      await style.addSource(
        GeoJsonSource(id: _routeUndergroundSourceId, data: emptyGeoJson),
      );

      await style.addLayer(
        LineLayer(
          id: _routeUndergroundLayerId,
          sourceId: _routeUndergroundSourceId,
          lineColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          lineWidthExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            8,
            1.0,
            11,
            2.0,
            14,
            4.0,
            17,
            7.0,
          ],
          lineOpacity: 0.7,
          lineDasharray: [3.0, 2.0],
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
          lineEmissiveStrength: 1.0,
        ),
      );

      DebugLog.log('[MapboxEngine] ✅ 지하 노선 LineLayer 생성 완료');

      // 4) 역 마커 — MiniTokyo3D 스타일 캡슐/필(pill) 마커
      // 캡슐 배경 소스 (LineString — 둥근 끝캡으로 필 모양)
      await style.addSource(
        GeoJsonSource(id: _stationPillSourceId, data: emptyGeoJson),
      );
      // ���선별 도트 소스 (Point — 캡슐 안에 배치)
      await style.addSource(
        GeoJsonSource(id: _stationSourceId, data: emptyGeoJson),
      );

      // 4-a) 캡슐 외곽선 (어두운 테두리)
      await style.addLayer(
        LineLayer(
          id: _stationPillOutlineLayerId,
          sourceId: _stationPillSourceId,
          lineColor: const Color(0xFF333333).toARGB32(),
          lineWidthExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            8,
            4.0,
            11,
            7.0,
            13,
            12.0,
            15,
            18.0,
            17,
            26.0,
          ],
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
          lineEmissiveStrength: 0.8,
        ),
      );

      // 4-b) 캡슐 내부 (흰색 채움)
      await style.addLayer(
        LineLayer(
          id: _stationPillFillLayerId,
          sourceId: _stationPillSourceId,
          lineColor: Colors.white.toARGB32(),
          lineWidthExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            8,
            2.5,
            11,
            5.0,
            13,
            9.0,
            15,
            14.0,
            17,
            22.0,
          ],
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
          lineEmissiveStrength: 0.8,
        ),
      );

      // 4-c) 노선색 도트 (캡슐 안에 각 노선별 1개)
      await style.addLayer(
        CircleLayer(
          id: _stationOutlineLayerId,
          sourceId: _stationSourceId,
          circleColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            8,
            1.2,
            11,
            2.2,
            13,
            4.0,
            15,
            6.0,
            17,
            9.5,
          ],
          circleStrokeWidth: 0.0,
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circleSortKey: 4,
          circleEmissiveStrength: 0.8,
        ),
      );

      // 4-d) 도트 내부 흰색 점 (미니도쿄 스타일)
      await style.addLayer(
        CircleLayer(
          id: _stationDotLayerId,
          sourceId: _stationSourceId,
          circleColor: Colors.white.toARGB32(),
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            8,
            0.5,
            11,
            1.0,
            13,
            1.8,
            15,
            2.8,
            17,
            4.5,
          ],
          circleStrokeWidth: 0.0,
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circleSortKey: 5,
          circleEmissiveStrength: 0.8,
        ),
      );

      // 4-e) 역명 라벨 (줌 14 이상, 캡슐 소스 기준 — 역 1개당 1라벨)
      await style.addLayer(
        SymbolLayer(
          id: _stationLabelLayerId,
          sourceId: _stationPillSourceId,
          textFieldExpression: ['get', 'name'],
          textSize: 11.0,
          textColor: Colors.white.toARGB32(),
          textHaloColor: const Color(0xFF1a1a2e).toARGB32(),
          textHaloWidth: 1.5,
          textOffsetExpression: [
            'literal',
            [0, 1.5],
          ],
          textAnchor: TextAnchor.TOP,
          textOptional: true,
          textAllowOverlap: false,
          symbolPlacement: SymbolPlacement.POINT,
          minZoom: 14.0,
          textEmissiveStrength: 1.0,
        ),
      );

      DebugLog.log('[MapboxEngine] ✅ 역 마커 레이어 생성 완료 (MiniTokyo3D 캡슐 스타일)');

      // 5) 열차별 지연 표시 — 발광 링 + "N분" 라벨
      await style.addSource(
        GeoJsonSource(id: _delaySourceId, data: emptyGeoJson),
      );

      // 빨간 발광 링 (지연 열차 주변)
      await style.addLayer(
        CircleLayer(
          id: _delayGlowLayerId,
          sourceId: _delaySourceId,
          circleColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            10.0,
            13,
            18.0,
            15,
            30.0,
            17,
            48.0,
          ],
          circleBlur: 0.6,
          circleOpacityExpression: ['get', 'opacity'],
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circleSortKey: 8,
          circleEmissiveStrength: 1.0,
        ),
      );

      // "N분 지연" 라벨 — 확대 시(줌 14+)에만 표시
      await style.addLayer(
        SymbolLayer(
          id: _delayLabelLayerId,
          sourceId: _delaySourceId,
          textFieldExpression: ['get', 'label'],
          textSizeExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            16,
            9.0,
            17,
            11.0,
            18,
            13.0,
          ],
          textColor: Colors.white.toARGB32(),
          textHaloColor: const Color(0xFFCC2222).toARGB32(),
          textHaloWidth: 2.0,
          textOffsetExpression: [
            'literal',
            [0, -2.2],
          ],
          textAnchor: TextAnchor.BOTTOM,
          textAllowOverlap: true,
          textEmissiveStrength: 1.0,
          minZoom: 16.0,
        ),
      );

      DebugLog.log('[MapboxEngine] ✅ 열차 지연 표시 레이어 생성 완료');

      // 6) 혼잡도 시각화 레이어 (히트맵 + 원형 마커 + 라벨)
      await style.addSource(
        GeoJsonSource(id: _congestionSourceId, data: emptyGeoJson),
      );

      // 히트맵 (낮은 줌에서 표시)
      await style.addLayerAt(
        HeatmapLayer(
          id: _congestionHeatmapLayerId,
          sourceId: _congestionSourceId,
          heatmapWeightExpression: ['get', 'weight'],
          heatmapIntensityExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            8,
            0.8,
            13,
            1.5,
          ],
          heatmapRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            8,
            15.0,
            11,
            30.0,
            13,
            50.0,
          ],
          heatmapColorExpression: [
            'interpolate',
            ['linear'],
            ['heatmap-density'],
            0,
            'rgba(0,0,0,0)',
            0.2,
            'rgba(0,228,0,0.3)',
            0.4,
            'rgba(200,255,0,0.4)',
            0.6,
            'rgba(255,200,0,0.5)',
            0.8,
            'rgba(255,100,0,0.6)',
            1.0,
            'rgba(255,0,0,0.7)',
          ],
          heatmapOpacityExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            12,
            0.8,
            15,
            0.0,
          ],
          // visibility: 초기 숨김 (아래에서 setStyleLayerProperty로 처리)
        ),
        LayerPosition(below: _stationPillOutlineLayerId),
      );

      // 혼잡도 원형 마커 (높은 줌에서 표시)
      await style.addLayerAt(
        CircleLayer(
          id: _congestionCircleLayerId,
          sourceId: _congestionSourceId,
          circleColorExpression: [
            'interpolate',
            ['linear'],
            ['get', 'weight'],
            0.0,
            'rgba(76,175,80,0.6)',
            0.3,
            'rgba(255,235,59,0.7)',
            0.6,
            'rgba(255,152,0,0.8)',
            0.85,
            'rgba(244,67,54,0.9)',
          ],
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['get', 'weight'],
            0.0,
            4.0,
            0.3,
            8.0,
            0.6,
            14.0,
            1.0,
            24.0,
          ],
          circleOpacityExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            12,
            0.0,
            13,
            0.7,
          ],
          circleBlur: 0.3,
          // visibility: 초기 숨김 (아래에서 setStyleLayerProperty로 처리)
        ),
        LayerPosition(below: _stationPillOutlineLayerId),
      );

      // 혼잡도 라벨 (높은 줌에서)
      await style.addLayerAt(
        SymbolLayer(
          id: _congestionLabelLayerId,
          sourceId: _congestionSourceId,
          textFieldExpression: ['get', 'label'],
          textSize: 10.0,
          textColorExpression: [
            'interpolate',
            ['linear'],
            ['get', 'weight'],
            0.0,
            'rgba(56,142,60,1)',
            0.5,
            'rgba(230,81,0,1)',
            1.0,
            'rgba(198,40,40,1)',
          ],
          textHaloColor: Colors.white.toARGB32(),
          textHaloWidth: 1.5,
          textOffsetExpression: [
            'literal',
            [0, 2.0],
          ],
          textAllowOverlap: false,
          minZoom: 15.0,
          // visibility: 초기 숨김 (아래에서 setStyleLayerProperty로 처리)
        ),
        LayerPosition(above: _congestionCircleLayerId),
      );

      // 혼잡도 레이어 초기 숨김
      style.setStyleLayerProperty(
        _congestionHeatmapLayerId,
        'visibility',
        'none',
      );
      style.setStyleLayerProperty(
        _congestionCircleLayerId,
        'visibility',
        'none',
      );
      style.setStyleLayerProperty(
        _congestionLabelLayerId,
        'visibility',
        'none',
      );

      DebugLog.log('[MapboxEngine] ✅ 혼잡도 레이어 생성 완료');

      _layersInitialized3D = true;
    } catch (e) {
      DebugLog.log('[MapboxEngine] ❌ 3D 레이어 초기화 실패: $e');
    }
  }

  @override
  void cleanup3DLayers() {
    if (_mapboxMap == null) return;
    final style = _mapboxMap!.style;

    for (final layerId in [
      _congestionLabelLayerId,
      _congestionCircleLayerId,
      _congestionHeatmapLayerId,
      _delayLabelLayerId,
      _delayGlowLayerId,
      _stationLabelLayerId,
      _stationDotLayerId,
      _stationOutlineLayerId,
      _stationPillFillLayerId,
      _stationPillOutlineLayerId,
      _selectedStationLayerId,
      '${_selectedTrainLayerId}-inner',
      _selectedTrainLayerId,
      _trainLayerId,
      _routeSurfaceLayerId,
      _routeUndergroundLayerId,
    ]) {
      style.removeStyleLayer(layerId).catchError((_) {});
    }
    for (final sourceId in [
      _congestionSourceId,
      _delaySourceId,
      _stationSourceId,
      _stationPillSourceId,
      _selectedStationSourceId,
      _selectedTrainSourceId,
      _trainSourceId,
      _routeSurfaceSourceId,
      _routeUndergroundSourceId,
    ]) {
      style.removeStyleSource(sourceId).catchError((_) {});
    }
    _layersInitialized3D = false;
  }

  /// GeoJSON 소스 데이터 직접 업데이트 (getSource 대신 setStyleSourceProperty 사용)
  Future<void> _updateSourceData(String sourceId, String geojson) async {
    if (_disposed || _mapboxMap == null) return;
    if (_failedSources.contains(sourceId)) return;
    try {
      await _mapboxMap!.style.setStyleSourceProperty(sourceId, 'data', geojson);
    } catch (e) {
      // 채널 에러는 디스포즈 직후 잔여 호출. 한 번만 로그 후 추가 호출 차단.
      final msg = e.toString();
      if (msg.contains('channel-error') || msg.contains('Unable to establish connection')) {
        _failedSources.add(sourceId);
        return;
      }
      DebugLog.log('[MapboxEngine] ❌ 소스 업데이트 실패 ($sourceId): $e');
    }
  }

  // 복선 트랙 오프셋 (미터) — 상행/하행 분리 거리
  static const double _trackOffsetM = 15.0;

  /// 진행방향 기준 수직으로 오프셋된 좌표 계산
  /// direction: 0=상행(왼쪽), 1=하행(오른쪽)
  static List<double> _offsetPosition(
    double lat,
    double lng,
    double bearing,
    int direction,
  ) {
    final rad = bearing * 3.14159265 / 180.0;
    // 수직 방향: bearing + 90°(오른쪽) 또는 -90°(왼쪽)
    final sign = direction == 0 ? -1.0 : 1.0;
    final perpX = sign * cos(rad) * _trackOffsetM; // 수직 오프셋 X
    final perpY = sign * -sin(rad) * _trackOffsetM; // 수직 오프셋 Y
    return [lat + perpY / _mPerDegLat, lng + perpX / _mPerDegLng];
  }

  /// 열차 위치를 3D 블록용 Polygon으로 변환
  /// 진행방향(bearing)에 맞게 회전 + 상행/하행 오프셋 적용

  /// 노선 좌표를 상행/하행 방향으로 오프셋하여 복선 생성
  static List<List<double>> _offsetRoute(
    List<List<double>> coords, // [lng, lat] 형식
    double offsetM,
  ) {
    if (coords.length < 2) return coords;
    final result = <List<double>>[];

    for (int i = 0; i < coords.length; i++) {
      // 전후 점으로 방향 계산
      final prev = i > 0 ? coords[i - 1] : coords[i];
      final next = i < coords.length - 1 ? coords[i + 1] : coords[i];
      final dLng = next[0] - prev[0];
      final dLat = next[1] - prev[1];
      final len = sqrt(dLng * dLng + dLat * dLat);
      if (len == 0) {
        result.add(coords[i]);
        continue;
      }
      // 수직 방향 (오른쪽 90도)
      final perpLng = -dLat / len * offsetM / _mPerDegLng;
      final perpLat = dLng / len * offsetM / _mPerDegLat;
      result.add([coords[i][0] + perpLng, coords[i][1] + perpLat]);
    }
    return result;
  }

  // ── 성능 최적화용 캐시 ──
  // 노선 색상 문자열 캐시 (매 프레임 재계산 방지)
  final Map<String, String> _colorStrCache = {};
  final Map<String, String> _brightColorStrCache = {};
  // 선택 열차 하이라이트 캐시
  String? _lastSelectedHighlightTrainNo;
  // 선택 역 하이라이트 캐시
  String? _lastSelectedStationHighlight;
  String? _cachedStationHighlightJson;
  // 지연 표시 캐시
  int _lastDelayUpdateFrame = 0;
  static const _delayUpdateInterval = 10; // 10프레임(~160ms)마다 지연 표시 갱신
  int _frameCounter = 0;

  String _getCachedColorStr(String subwayId) {
    return _colorStrCache.putIfAbsent(subwayId, () {
      return _colorToRgba(SubwayColors.getColor(subwayId));
    });
  }

  String _getCachedBrightColorStr(String subwayId) {
    return _brightColorStrCache.putIfAbsent(subwayId, () {
      return _colorToRgba(_brightenColor(SubwayColors.getColor(subwayId), 0.3));
    });
  }

  @override
  Future<void> updateTrainPositions3D(
    List<InterpolatedTrainPosition> trains, {
    Map<String, int> trainDelays = const {},
  }) async {
    if (_mapboxMap == null || !_layersInitialized3D) return;
    _frameCounter++;

    // ── 메인 열차 GeoJSON: StringBuffer로 직접 빌드 (jsonEncode + Map 할당 제거) ──
    const trainHeight = 20.0;
    final sb = StringBuffer('{"type":"FeatureCollection","features":[');
    bool first = true;

    for (final train in trains) {
      if (!first) sb.write(',');
      first = false;

      final isSelected = train.trainNo == _selectedTrainNo;
      final delayMin = trainDelays[train.trainNo] ?? 0;
      final isDelayed = delayMin >= 2;
      final isExpress = train.expressType == 1;
      final isSuperExpress = train.expressType == 7;

      final String colorStr;
      if (isSelected) {
        colorStr = _getCachedBrightColorStr(train.subwayId);
      } else if (isDelayed) {
        final color = SubwayColors.getColor(train.subwayId);
        final blend = (delayMin / 15.0).clamp(0.0, 1.0);
        final r = (color.r + (1.0 - color.r) * blend).clamp(0.0, 1.0);
        final g = (color.g * (1.0 - blend * 0.7)).clamp(0.0, 1.0);
        final b = (color.b * (1.0 - blend * 0.7)).clamp(0.0, 1.0);
        colorStr =
            'rgba(${(r * 255).round()},${(g * 255).round()},${(b * 255).round()},1)';
      } else if (isSuperExpress) {
        // 초급행: 금색 하이라이트 (노선색 + 골드 블렌드)
        final color = SubwayColors.getColor(train.subwayId);
        final r = ((color.r * 0.5 + 0.5) * 255).round().clamp(0, 255);
        final g = ((color.g * 0.4 + 0.6 * 0.84) * 255).round().clamp(0, 255);
        final b = ((color.b * 0.3 + 0.7 * 0.0) * 255).round().clamp(0, 255);
        colorStr = 'rgba($r,$g,$b,1)';
      } else if (isExpress) {
        // 급행: 밝은 노선색
        colorStr = _getCachedBrightColorStr(train.subwayId);
      } else {
        colorStr = _getCachedColorStr(train.subwayId);
      }

      // 급행/초급행은 더 높은 3D 블록
      final double height;
      if (isSelected) {
        height = trainHeight + 10;
      } else if (isSuperExpress) {
        height = trainHeight + 15; // 초급행: 가장 높음
      } else if (isExpress) {
        height = trainHeight + 8; // 급행: 약간 높음
      } else {
        height = trainHeight;
      }

      // 텔레포트 페이드인: opacity < 1이면 색상 alpha에 반영
      final String finalColorStr;
      if (train.opacity < 1.0) {
        final op = train.opacity.clamp(0.0, 1.0);
        // rgba(...,1) → rgba(...,op) 변환
        if (colorStr.startsWith('rgba(')) {
          final lastComma = colorStr.lastIndexOf(',');
          finalColorStr = '${colorStr.substring(0, lastComma)},$op)';
        } else {
          finalColorStr = colorStr;
        }
      } else {
        finalColorStr = colorStr;
      }
      _writeTrainFeature(sb, train, finalColorStr, height, train.expressType);
    }

    sb.write(']}');
    await _updateSourceData(_trainSourceId, sb.toString());

    // ── 선택 열차 하이라이트: 선택 변경 시 + 매 프레임 좌표 업데이트 ──
    if (_selectedTrainNo != null) {
      for (final train in trains) {
        if (train.trainNo == _selectedTrainNo) {
          final colorStr = _getCachedColorStr(train.subwayId);
          // 펄스 (1500ms 삼각파)
          final p =
              (DateTime.now().millisecondsSinceEpoch % 1500) / 1500.0 * 2.0;
          final pulse = p < 1.0 ? p : 2.0 - p;
          final oOp = (0.15 + pulse * 0.35);
          final iOp = (0.05 + pulse * 0.15);

          await _updateSourceData(
            _selectedTrainSourceId,
            '{"type":"FeatureCollection","features":[{"type":"Feature",'
            '"geometry":{"type":"Point","coordinates":[${train.lng},${train.lat}]},'
            '"properties":{"color":"$colorStr","opacity":$oOp,"innerOpacity":$iOp}}]}',
          );
          break;
        }
      }
    } else if (_lastSelectedHighlightTrainNo != null) {
      await _updateSourceData(
        _selectedTrainSourceId,
        '{"type":"FeatureCollection","features":[]}',
      );
    }
    _lastSelectedHighlightTrainNo = _selectedTrainNo;

    // ── 지연 표시: N프레임마다만 갱신 (매 프레임 불필요) ──
    if (trainDelays.isNotEmpty &&
        _frameCounter - _lastDelayUpdateFrame >= _delayUpdateInterval) {
      _lastDelayUpdateFrame = _frameCounter;
      final dSb = StringBuffer('{"type":"FeatureCollection","features":[');
      bool dFirst = true;
      final p = (DateTime.now().millisecondsSinceEpoch % 2000) / 2000.0 * 2.0;
      final pulse = p < 1.0 ? p : 2.0 - p;
      final opacity = 0.2 + pulse * 0.4;

      for (final train in trains) {
        final delayMin = trainDelays[train.trainNo];
        if (delayMin == null || delayMin < 2) continue;
        if (!dFirst) dSb.write(',');
        dFirst = false;

        final delayColor = delayMin >= 10
            ? 'rgba(220,30,30,1)'
            : delayMin >= 5
            ? 'rgba(255,60,60,1)'
            : 'rgba(255,160,40,1)';

        dSb.write(
          '{"type":"Feature","geometry":{"type":"Point",'
          '"coordinates":[${train.lng},${train.lat}]},'
          '"properties":{"color":"$delayColor","opacity":$opacity,'
          '"label":"$delayMin분 지연"}}',
        );
      }
      dSb.write(']}');
      await _updateSourceData(_delaySourceId, dSb.toString());
    } else if (trainDelays.isEmpty && _lastDelayUpdateFrame > 0) {
      _lastDelayUpdateFrame = 0;
      await _updateSourceData(
        _delaySourceId,
        '{"type":"FeatureCollection","features":[]}',
      );
    }

    // ── 선택 역 하이라이트: 역 변경 시에만 갱신 (매 프레임 X) ──
    if (_selectedStationName != null &&
        _selectedStationName != _lastSelectedStationHighlight) {
      _lastSelectedStationHighlight = _selectedStationName;
      // 좌표: 탭 시 저장된 feature 좌표 우선 (지도 위 점과 동일 위치)
      double? hlLat = _selectedStationLat;
      double? hlLng = _selectedStationLng;
      // 없으면 StationInfo 폴백
      if (hlLat == null || hlLng == null) {
        final station = SeoulSubwayData.findStation(_selectedStationName!);
        hlLat = station?.lat;
        hlLng = station?.lng;
      }
      if (hlLat != null && hlLng != null) {
        // 역이 속한 모든 노선 색상 수집
        final lineColorList = <Color>[];
        for (final entry in SeoulSubwayData.lineIdToApiName.entries) {
          final stations = SeoulSubwayData.getLineStations(entry.key);
          if (stations.any((s) => s.name == _selectedStationName)) {
            lineColorList.add(SubwayColors.getColor(entry.key));
          }
        }
        if (lineColorList.isEmpty) lineColorList.add(Colors.blueAccent);

        // 모든 노선 색을 원형 배치 + blur로 그라데이션 글로우
        final buf = StringBuffer('{"type":"FeatureCollection","features":[');
        final n = lineColorList.length;
        if (n == 1) {
          final colorStr = _colorToRgba(lineColorList[0]);
          buf.write(
            '{"type":"Feature",'
            '"geometry":{"type":"Point","coordinates":[$hlLng,$hlLat]},'
            '"properties":{"color":"$colorStr","opacity":0.5,"scale":1.0}}',
          );
        } else {
          const offset = 0.00008; // ~9m
          for (int i = 0; i < n; i++) {
            if (i > 0) buf.write(',');
            final angle = 2 * pi * i / n;
            final oLng = hlLng! + offset * cos(angle);
            final oLat = hlLat! + offset * sin(angle);
            final colorStr = _colorToRgba(lineColorList[i]);
            buf.write(
              '{"type":"Feature",'
              '"geometry":{"type":"Point","coordinates":[$oLng,$oLat]},'
              '"properties":{"color":"$colorStr","opacity":0.5,"scale":1.0}}',
            );
          }
        }
        buf.write(']}');
        _cachedStationHighlightJson = buf.toString();
        await _updateSourceData(
          _selectedStationSourceId,
          _cachedStationHighlightJson!,
        );
      }
    } else if (_selectedStationName == null &&
        _lastSelectedStationHighlight != null) {
      _lastSelectedStationHighlight = null;
      _cachedStationHighlightJson = null;
      await _updateSourceData(
        _selectedStationSourceId,
        '{"type":"FeatureCollection","features":[]}',
      );
    }
  }

  /// 열차 Feature를 StringBuffer에 직접 기록 (Map/List 할당 없이)
  /// expressType: 0=일반, 1=급행, 7=특급(초급행)
  void _writeTrainFeature(
    StringBuffer sb,
    InterpolatedTrainPosition train,
    String colorStr,
    double height,
    int expressType,
  ) {
    // 폴리곤 좌표 계산 (인라인)
    final offset = _offsetPosition(
      train.lat,
      train.lng,
      train.bearing,
      train.direction,
    );
    final oLat = offset[0];
    final oLng = offset[1];

    // 급행/초급행은 더 큰 열차 블록
    final double lengthM, widthM;
    if (expressType == 7) {
      lengthM = 75.0;
      widthM = 28.0; // 초급행: 가장 큼
    } else if (expressType == 1) {
      lengthM = 60.0;
      widthM = 25.0; // 급행
    } else {
      lengthM = 45.0;
      widthM = 20.0; // 일반
    }
    final halfL = lengthM / 2;
    final halfW = widthM / 2;

    final rad = train.bearing * 3.14159265 / 180.0;
    final cosB = cos(rad);
    final sinB = sin(rad);

    // 4 vertices + close (직접 좌표 계산, List 할당 없음)
    final x0 = oLng + (-halfW * cosB + (-halfL) * sinB) / _mPerDegLng;
    final y0 = oLat + (-(-halfW) * sinB + (-halfL) * cosB) / _mPerDegLat;
    final x1 = oLng + (halfW * cosB + (-halfL) * sinB) / _mPerDegLng;
    final y1 = oLat + (-(halfW) * sinB + (-halfL) * cosB) / _mPerDegLat;
    final x2 = oLng + (halfW * cosB + halfL * sinB) / _mPerDegLng;
    final y2 = oLat + (-(halfW) * sinB + halfL * cosB) / _mPerDegLat;
    final x3 = oLng + (-halfW * cosB + halfL * sinB) / _mPerDegLng;
    final y3 = oLat + (-(-halfW) * sinB + halfL * cosB) / _mPerDegLat;

    // 최소한의 properties만 포함 (렌더링: color/base/top, 클릭: trainNo)
    sb.write(
      '{"type":"Feature","geometry":{"type":"Polygon","coordinates":'
      '[[[$x0,$y0],[$x1,$y1],[$x2,$y2],[$x3,$y3],[$x0,$y0]]]},'
      '"properties":{"color":"$colorStr",'
      '"base":${train.altitude},"top":${train.altitude + height},'
      '"trainNo":"${train.trainNo}"}}',
    );
  }

  @override
  Future<void> initRoutes3D(
    Map<String, List<List<double>>> routeCoordinates,
    Map<String, Color> lineColors,
    Map<String, List<bool>> segmentUnderground,
  ) async {
    if (_mapboxMap == null || !_layersInitialized3D) return;

    final surfaceFeatures = <Map<String, dynamic>>[];
    final undergroundFeatures = <Map<String, dynamic>>[];

    for (final entry in routeCoordinates.entries) {
      final lineId = entry.key;
      final coords = entry.value; // [[lat, lng], ...]
      final color = lineColors[lineId] ?? Colors.grey;
      final colorStr = _colorToRgba(color);
      final underground = segmentUnderground[lineId] ?? [];

      // 세그먼트를 지상/지하로 분할 후, 각각 복선(좌/우)으로 생성
      void addSegment(List<List<double>> seg, bool isUG) {
        if (seg.length < 2) return;
        // 복선: 좌우 오프셋
        final left = _offsetRoute(seg, -_trackOffsetM);
        final right = _offsetRoute(seg, _trackOffsetM);
        for (final track in [left, right]) {
          final feature = {
            'type': 'Feature',
            'geometry': {'type': 'LineString', 'coordinates': track},
            'properties': {'color': colorStr, 'lineId': lineId},
          };
          if (isUG) {
            undergroundFeatures.add(feature);
          } else {
            surfaceFeatures.add(feature);
          }
        }
      }

      List<List<double>> currentSegment = [];
      bool currentIsUnderground = underground.isNotEmpty && underground[0];

      for (int i = 0; i < coords.length; i++) {
        final isUG = i < underground.length ? underground[i] : true;
        final coord = [coords[i][1], coords[i][0]]; // [lat,lng] → [lng,lat]

        if (i > 0 && isUG != currentIsUnderground) {
          currentSegment.add(coord);
          addSegment(currentSegment, currentIsUnderground);
          currentSegment = [coord];
          currentIsUnderground = isUG;
        } else {
          currentSegment.add(coord);
        }
      }
      addSegment(currentSegment, currentIsUnderground);
    }

    // Source 업데이트 (setStyleSourceProperty 직접 사용)
    await _updateSourceData(
      _routeSurfaceSourceId,
      jsonEncode({'type': 'FeatureCollection', 'features': surfaceFeatures}),
    );

    await _updateSourceData(
      _routeUndergroundSourceId,
      jsonEncode({
        'type': 'FeatureCollection',
        'features': undergroundFeatures,
      }),
    );

    DebugLog.log(
      '[MapboxEngine] Routes 3D: ${surfaceFeatures.length} surface, '
      '${undergroundFeatures.length} underground segments',
    );
  }

  @override
  Future<void> updateStations3D(
    List<Map<String, dynamic>> pills,
    List<Map<String, dynamic>> dots,
  ) async {
    if (_mapboxMap == null || !_layersInitialized3D) return;

    // 캡슐 배경 (LineString — 둥근 끝캡으로 필 모양 생성)
    final pillFeatures = pills.map((p) {
      final n = p['lineCount'] as int;
      // 단일역: 극소 길이 LineString (둥근 끝캡 → 원형)
      final coords = n <= 1
          ? [
              [p['startLng'], p['startLat']],
              [p['startLng'] + 0.0000001, p['startLat'] + 0.0000001],
            ]
          : [
              [p['startLng'], p['startLat']],
              [p['endLng'], p['endLat']],
            ];
      return {
        'type': 'Feature',
        'geometry': {'type': 'LineString', 'coordinates': coords},
        'properties': {'name': p['name'], 'lineCount': n},
      };
    }).toList();

    await _updateSourceData(
      _stationPillSourceId,
      jsonEncode({'type': 'FeatureCollection', 'features': pillFeatures}),
    );

    // 노선별 컬러 도트 (Point)
    final dotFeatures = dots
        .map(
          (d) => {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [d['lng'], d['lat']],
            },
            'properties': {'name': d['name'], 'color': d['color']},
          },
        )
        .toList();

    await _updateSourceData(
      _stationSourceId,
      jsonEncode({'type': 'FeatureCollection', 'features': dotFeatures}),
    );

    DebugLog.log(
      '[MapboxEngine] 🚉 역 ${pills.length}개 (도트 ${dots.length}개) 업데이트',
    );
  }

  @override
  Future<void> updateDelayShield3D(Map<String, int> delayInfo) async {
    // 열차별 지연은 updateTrainPositions3D에서 직접 처리
  }

  @override
  Future<void> updateCongestionHeatmap(
    List<Map<String, dynamic>> points,
  ) async {
    if (_mapboxMap == null || !_layersInitialized3D) return;

    final sb = StringBuffer('{"type":"FeatureCollection","features":[');
    bool first = true;
    for (final p in points) {
      if (!first) sb.write(',');
      first = false;
      final lat = p['lat'];
      final lng = p['lng'];
      final weight = (p['weight'] as double).clamp(0.0, 1.0);
      final label = p['label'] ?? '';
      sb.write(
        '{"type":"Feature","geometry":{"type":"Point","coordinates":[$lng,$lat]},'
        '"properties":{"weight":$weight,"label":"$label"}}',
      );
    }
    sb.write(']}');
    await _updateSourceData(_congestionSourceId, sb.toString());
  }

  @override
  void setCongestionVisible(bool visible) {
    if (_mapboxMap == null || !_layersInitialized3D) return;
    final v = visible ? 'visible' : 'none';
    _mapboxMap!.style.setStyleLayerProperty(
      _congestionHeatmapLayerId,
      'visibility',
      v,
    );
    _mapboxMap!.style.setStyleLayerProperty(
      _congestionCircleLayerId,
      'visibility',
      v,
    );
    _mapboxMap!.style.setStyleLayerProperty(
      _congestionLabelLayerId,
      'visibility',
      v,
    );
  }

  @override
  void setUndergroundVisible(bool visible) {
    _undergroundVisible = visible;
    if (_mapboxMap != null && _layersInitialized3D) {
      _mapboxMap!.style.setStyleLayerProperty(
        _routeUndergroundLayerId,
        'visibility',
        visible ? 'visible' : 'none',
      );
    }
  }

  @override
  void setOnTrainTapped(void Function(String trainNo)? callback) {
    _onTrainTapped = callback;
  }

  @override
  void setOnStationTapped(void Function(String stationName)? callback) {
    _onStationTapped = callback;
  }

  @override
  void setOnBusTapped(void Function(String vehId)? callback) {
    _onBusTapped = callback;
  }

  @override
  void setOnFlightTapped(void Function(String icao24)? callback) {
    _onFlightTapped = callback;
  }

  @override
  void setOnPoiTapped(
    void Function(String name, double lat, double lng)? callback,
  ) {
    _onPoiTapped = callback;
  }

  @override
  void setOnMapCoordTapped(void Function(double lat, double lng)? callback) {
    _onMapCoordTapped = callback;
  }

  @override
  void setOnCameraIdle(
    void Function(double lat, double lng, double zoom)? callback,
  ) {
    _onCameraIdle = callback;
  }

  @override
  Future<void> showNearbyPoi(List<Map<String, dynamic>> pois) async {
    if (_mapboxMap == null) return;
    final style = _mapboxMap!.style;

    // GeoJSON 생성
    final features = pois
        .map(
          (poi) => {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [poi['lng'], poi['lat']],
            },
            'properties': {'name': poi['name'], 'category': poi['category']},
          },
        )
        .toList();

    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });

    try {
      if (_poiLayerInitialized) {
        // 소스 데이터만 업데이트
        await style.setStyleSourceProperty(_poiSourceId, 'data', geojson);
      } else {
        // 소스 + 레이어 생성
        await style.addSource(GeoJsonSource(id: _poiSourceId, data: geojson));

        // 원형 마커 레이어 (탭 가능하도록 충분히 큰 크기)
        await style.addLayer(
          CircleLayer(
            id: _poiLayerId,
            sourceId: _poiSourceId,
            circleRadius: 8.0,
            circleColor: const Color(0xFFE53935).toARGB32(),
            circleStrokeColor: Colors.white.toARGB32(),
            circleStrokeWidth: 2.0,
            circleOpacity: 0.9,
          ),
        );

        // 텍스트 라벨 레이어
        await style.addLayer(
          SymbolLayer(
            id: _poiLabelLayerId,
            sourceId: _poiSourceId,
            textField: '{name}',
            textSize: 12.0,
            textColor: Colors.white.toARGB32(),
            textHaloColor: const Color(0xFF222222).toARGB32(),
            textHaloWidth: 1.5,
            textOffset: [0.0, 1.5],
            textAnchor: TextAnchor.TOP,
            textOptional: true,
            textAllowOverlap: false,
          ),
        );

        _poiLayerInitialized = true;
      }
    } catch (e) {
      DebugLog.log('[MapboxEngine] POI 레이어 오류: $e');
    }
  }

  @override
  void clearNearbyPoi() {
    if (!_poiLayerInitialized || _mapboxMap == null) return;
    try {
      final emptyGeojson = jsonEncode({
        'type': 'FeatureCollection',
        'features': <dynamic>[],
      });
      _mapboxMap!.style.setStyleSourceProperty(
        _poiSourceId,
        'data',
        emptyGeojson,
      );
    } catch (_) {}
  }

  @override
  void setOnMapTappedEmpty(VoidCallback? callback) {
    _onMapTappedEmpty = callback;
  }

  @override
  void setOnAnyMapTap(VoidCallback? callback) {
    _onAnyMapTap = callback;
  }

  @override
  void setSelectedTrain(String? trainNo) {
    _selectedTrainNo = trainNo;
    if (trainNo == null) {
      _isFollowing = false;
    }
  }

  @override
  void setSelectedStation(String? stationName) {
    _selectedStationName = stationName;
    if (stationName == null) {
      _updateSourceData(
        _selectedStationSourceId,
        '{"type":"FeatureCollection","features":[]}',
      );
    }
  }

  static const _riverBusHighlightSourceId = 'riverbus-highlight-source';
  static const _riverBusHighlightLayerId = 'riverbus-highlight-layer';
  bool _riverBusHighlightInit = false;

  Future<void> _ensureRiverBusHighlight() async {
    if (_riverBusHighlightInit || _mapboxMap == null) return;
    final style = _mapboxMap!.style;
    try {
      await style.addSource(
        GeoJsonSource(
          id: _riverBusHighlightSourceId,
          data: '{"type":"FeatureCollection","features":[]}',
        ),
      );
      await style.addLayer(
        CircleLayer(
          id: _riverBusHighlightLayerId,
          sourceId: _riverBusHighlightSourceId,
          circleColor: const Color(0xFF00ACC1).toARGB32(),
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            10.0,
            13,
            22.0,
            15,
            38.0,
            17,
            55.0,
          ],
          circleBlur: 0.5,
          circleOpacity: 0.5,
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circleEmissiveStrength: 1.0,
        ),
      );
      _riverBusHighlightInit = true;
    } catch (_) {}
  }

  @override
  void showRiverBusHighlight(double lat, double lng) {
    if (!_riverBusHighlightInit) {
      _ensureRiverBusHighlight().then((_) {
        if (_riverBusHighlightInit) {
          _updateSourceData(
            _riverBusHighlightSourceId,
            '{"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[$lng,$lat]},"properties":{}}]}',
          );
        }
      });
      return;
    }
    _updateSourceData(
      _riverBusHighlightSourceId,
      '{"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[$lng,$lat]},"properties":{}}]}',
    );
  }

  @override
  void hideRiverBusHighlight() {
    if (!_riverBusHighlightInit) return;
    _updateSourceData(
      _riverBusHighlightSourceId,
      '{"type":"FeatureCollection","features":[]}',
    );
  }

  @override
  void followTrain(double lat, double lng, double bearing) {
    if (_mapboxMap == null) return;
    if (!_isFollowing) {
      // 최초 선택 또는 열차 전환 시 flyTo로 부드럽게 이동
      _isFollowing = true;
      _flyToEndTime = DateTime.now().millisecondsSinceEpoch + _flyToDurationMs;
      _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(lng, lat)),
          zoom: 15.5,
          pitch: 55,
        ),
        MapAnimationOptions(duration: _flyToDurationMs),
      );
    } else {
      // flyTo 진행 중이면 무시
      if (DateTime.now().millisecondsSinceEpoch < _flyToEndTime) return;
      // 추적 중: setCamera로 강제 고정
      _mapboxMap!.setCamera(
        CameraOptions(center: Point(coordinates: Position(lng, lat))),
      );
    }
  }

  static const int _flyToDurationMs = 800;
  int _flyToEndTime = 0;

  // ── 현재 위치: 3D 사람 아바타 ──

  @override
  Future<void> enableLocationPuck() async {
    if (_locationEnabled) return;
    _locationEnabled = true;

    // 위치 권한 확인 + 현재 위치 (플러그인 실패 시 서울 폴백)
    bool geoAvailable = true;
    try {
      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied ||
            permission == geo.LocationPermission.deniedForever) {
          DebugLog.log('[MapboxEngine] 위치 권한 거부됨 → 서울 폴백');
          geoAvailable = false;
        }
      }
    } catch (e) {
      DebugLog.log('[MapboxEngine] ⚠️ 위치 플러그인 사용 불가: $e');
      geoAvailable = false;
      _locationFailed = true;
    }

    // 초기 위치 가져오기
    if (geoAvailable) {
      try {
        _currentPosition = await geo.Geolocator.getCurrentPosition(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
          ),
        );
        // 서울 범위 밖이면 폴백 (시뮬레이터 미국 위치 등)
        if (_currentPosition != null) {
          final lat = _currentPosition!.latitude;
          final lng = _currentPosition!.longitude;
          if (lat < 37.0 || lat > 38.0 || lng < 126.5 || lng > 127.5) {
            DebugLog.log('[MapboxEngine] 위치가 서울 범위 밖 → 서울시청 폴백');
            _currentPosition = _seoulFallbackPosition();
          }
        }
      } catch (e) {
        DebugLog.log('[MapboxEngine] 위치 가져오기 실패 → 서울 폴백: $e');
        _currentPosition = _seoulFallbackPosition();
      }
    } else {
      _currentPosition = _seoulFallbackPosition();
    }

    // 3D 아바타 레이어 생성 (위치 실패해도 항상 표시)
    await _initLocationLayers();

    if (_currentPosition != null) {
      await _updateLocationAvatar(_currentPosition!);
    }

    // 실시간 위치 스트림 (geolocator 사용 가능할 때만)
    if (geoAvailable && !_locationFailed) {
      try {
        _positionSubscription =
            geo.Geolocator.getPositionStream(
              locationSettings: const geo.LocationSettings(
                accuracy: geo.LocationAccuracy.high,
                distanceFilter: 5,
              ),
            ).listen((position) {
              // 서울 범위 체크
              if (position.latitude >= 37.0 &&
                  position.latitude <= 38.0 &&
                  position.longitude >= 126.5 &&
                  position.longitude <= 127.5) {
                _currentPosition = position;
              } else {
                _currentPosition = _seoulFallbackPosition();
              }
              _updateLocationAvatar(_currentPosition!);
            });
      } catch (e) {
        DebugLog.log('[MapboxEngine] 위치 스트림 실패: $e');
      }
    }

    // 펄스 애니메이션
    _locationPulseTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_currentPosition != null && _mapboxMap != null) {
        _updateLocationPulse();
      }
    });
  }

  @override
  Future<void> moveToCurrentLocation() async {
    if (!_locationEnabled) await enableLocationPuck();
    if (_currentPosition != null) {
      moveTo(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        zoom: 16.0,
        pitch: 50.0,
      );
    }
  }

  @override
  Future<void> setUserLocation(double lat, double lng) async {
    if (_mapboxMap == null) {
      debugPrint('[MapboxEngine] setUserLocation: map==null');
      return;
    }
    // _locationEnabled 가 true 더라도 layers 가 아직 안 만들어졌을 수 있음
    // (enableLocationPuck 가 await getCurrentPosition 중일 때).
    if (!_locationLayersReady) {
      debugPrint('[MapboxEngine] setUserLocation: layers 없음 → init 시도');
      await _initLocationLayers();
    }
    final pos = geo.Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    _currentPosition = pos;
    await _updateLocationAvatar(pos);
    debugPrint('[MapboxEngine] setUserLocation 완료 ($lat,$lng) layersReady=$_locationLayersReady');
  }

  Future<void> _initLocationLayers() async {
    if (_mapboxMap == null) return;
    if (_locationLayersReady) return; // idempotent.
    final style = _mapboxMap!.style;
    const emptyGeoJson = '{"type":"FeatureCollection","features":[]}';

    // iOS 에서 source/layer 가 이미 존재하면 add* 가 throw → 존재 확인 후 add.
    Future<bool> srcExists(String id) async {
      try {
        return await style.styleSourceExists(id);
      } catch (_) {
        return false;
      }
    }
    Future<bool> lyrExists(String id) async {
      try {
        return await style.styleLayerExists(id);
      } catch (_) {
        return false;
      }
    }

    try {
      if (!await srcExists(_locationPulseSourceId)) {
        await style.addSource(
          GeoJsonSource(id: _locationPulseSourceId, data: emptyGeoJson),
        );
      }
      if (!await lyrExists(_locationPulseLayerId)) {
        await style.addLayer(
          CircleLayer(
            id: _locationPulseLayerId,
            sourceId: _locationPulseSourceId,
            circleColor: const Color(0xFF4A90D9).toARGB32(),
            circleRadiusExpression: [
              'interpolate',
              ['linear'],
              ['zoom'],
              10, 20.0,
              14, 40.0,
              17, 60.0,
            ],
            circleBlur: 0.7,
            circleOpacity: 0.3,
            circlePitchAlignment: CirclePitchAlignment.MAP,
            circleEmissiveStrength: 1.0,
          ),
        );
      }

      if (!await srcExists(_locationSourceId)) {
        await style.addSource(
          GeoJsonSource(id: _locationSourceId, data: emptyGeoJson),
        );
      }
      if (!await lyrExists(_locationBodyLayerId)) {
        await style.addLayer(
          FillExtrusionLayer(
            id: _locationBodyLayerId,
            sourceId: _locationSourceId,
            fillExtrusionColorExpression: [
              'to-color',
              ['get', 'color'],
            ],
            fillExtrusionBaseExpression: ['get', 'base'],
            fillExtrusionHeightExpression: ['get', 'top'],
            fillExtrusionOpacity: 0.92,
            fillExtrusionVerticalGradient: true,
            fillExtrusionEmissiveStrength: 1.0,
          ),
        );
      }

      if (!await lyrExists(_locationHeadLayerId)) {
        await style.addLayer(
          CircleLayer(
            id: _locationHeadLayerId,
            sourceId: _locationPulseSourceId,
            circleColor: const Color(0xFFFFD7A8).toARGB32(),
            circleRadiusExpression: [
              'interpolate',
              ['linear'],
              ['zoom'],
              10, 4.0,
              14, 8.0,
              17, 14.0,
            ],
            circleStrokeColor: const Color(0xFF4A90D9).toARGB32(),
            circleStrokeWidth: 2.0,
            circleOpacity: 1.0,
            circlePitchAlignment: CirclePitchAlignment.MAP,
            circleSortKey: 100,
            circleEmissiveStrength: 1.0,
          ),
        );
      }

      _locationLayersReady = true;
      debugPrint('[MapboxEngine] ✅ 3D 위치 아바타 레이어 생성 완료');
    } catch (e) {
      debugPrint('[MapboxEngine] ❌ 위치 레이어 초기화 실패: $e');
    }
  }

  /// 시뮬레이터용 서울시청 폴백 위치
  static geo.Position _seoulFallbackPosition() {
    return geo.Position(
      latitude: 37.5665,
      longitude: 126.9780,
      timestamp: DateTime.now(),
      accuracy: 10.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  Future<void> _updateLocationAvatar(geo.Position position) async {
    if (_mapboxMap == null) return;
    final lat = position.latitude;
    final lng = position.longitude;

    // 사람 몸체: 8각형 원기둥 (반지름 ~2.5m, 지면에 붙임)
    final bodyCoords = _generateOctagon(lat, lng, 2.5);
    final bodyJson =
        '{"type":"FeatureCollection","features":['
        // 하체 (진한 파란색 — 바닥부터)
        '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[${_coordsToJson(bodyCoords)}]},'
        '"properties":{"color":"rgba(55,120,200,1)","base":0,"top":8}},'
        // 상체 (밝은 파란색)
        '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[${_coordsToJson(bodyCoords)}]},'
        '"properties":{"color":"rgba(90,165,245,1)","base":8,"top":14}}'
        ']}';

    await _updateSourceData(_locationSourceId, bodyJson);

    // 펄스/머리 좌표
    final pulseJson =
        '{"type":"FeatureCollection","features":['
        '{"type":"Feature","geometry":{"type":"Point","coordinates":[$lng,$lat]},"properties":{}}'
        ']}';
    await _updateSourceData(_locationPulseSourceId, pulseJson);
  }

  void _updateLocationPulse() {
    if (_mapboxMap == null || _currentPosition == null) return;
    // 펄스 opacity 애니메이션
    final t = (DateTime.now().millisecondsSinceEpoch % 2000) / 2000.0;
    final opacity = (0.15 + 0.25 * sin(t * 2 * pi)).clamp(0.05, 0.4);
    try {
      _mapboxMap!.style.setStyleLayerProperty(
        _locationPulseLayerId,
        'circle-opacity',
        opacity,
      );
    } catch (_) {}
  }

  /// 8각형 좌표 생성 (사람 몸체용 원기둥 단면)
  List<List<double>> _generateOctagon(double lat, double lng, double radiusM) {
    final coords = <List<double>>[];
    for (int i = 0; i <= 8; i++) {
      final angle = (i % 8) * (2 * pi / 8);
      final dLat = radiusM * cos(angle) / _mPerDegLat;
      final dLng = radiusM * sin(angle) / _mPerDegLng;
      coords.add([lng + dLng, lat + dLat]);
    }
    return coords;
  }

  String _coordsToJson(List<List<double>> coords) {
    final buf = StringBuffer('[');
    for (int i = 0; i < coords.length; i++) {
      if (i > 0) buf.write(',');
      buf.write('[${coords[i][0]},${coords[i][1]}]');
    }
    buf.write(']');
    return buf.toString();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 버스 3D 시각화 (지하철과 동일한 패턴)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Future<void> initBusLayers() async {
    if (_mapboxMap == null || _busLayersInitialized) return;
    cleanupBusLayers();
    final style = _mapboxMap!.style;
    const emptyGeoJson = '{"type":"FeatureCollection","features":[]}';

    try {
      // 버스 위치 발광 링 (CircleLayer)
      await style.addSource(
        GeoJsonSource(id: _busGlowSourceId, data: emptyGeoJson),
      );
      await style.addLayer(
        CircleLayer(
          id: _busGlowLayerId,
          sourceId: _busGlowSourceId,
          circleColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            4.0,
            13,
            8.0,
            15,
            14.0,
            17,
            22.0,
          ],
          circleBlur: 0.4,
          circleOpacity: 0.6,
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circleEmissiveStrength: 0.8,
        ),
      );

      // 버스 몸체 (FillExtrusionLayer — 3D 블록)
      await style.addSource(
        GeoJsonSource(id: _busSourceId, data: emptyGeoJson),
      );
      await style.addLayer(
        FillExtrusionLayer(
          id: _busLayerId,
          sourceId: _busSourceId,
          fillExtrusionColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          fillExtrusionBaseExpression: ['get', 'base'],
          fillExtrusionHeightExpression: ['get', 'top'],
          fillExtrusionOpacity: 0.9,
          fillExtrusionVerticalGradient: true,
          fillExtrusionEmissiveStrength: 0.9,
        ),
      );

      _busLayersInitialized = true;
      DebugLog.log('[MapboxEngine] ✅ 버스 3D 레이어 생성 완료');
    } catch (e) {
      DebugLog.log('[MapboxEngine] ❌ 버스 레이어 초기화 실패: $e');
    }
  }

  @override
  void cleanupBusLayers() {
    if (_mapboxMap == null) return;
    final style = _mapboxMap!.style;
    style.removeStyleLayer(_busLayerId).catchError((_) {});
    style.removeStyleLayer(_busGlowLayerId).catchError((_) {});
    style.removeStyleSource(_busSourceId).catchError((_) {});
    style.removeStyleSource(_busGlowSourceId).catchError((_) {});
    _busLayersInitialized = false;
  }

  @override
  Future<void> updateBusPositions3D(List<BusRenderData> buses) async {
    if (_mapboxMap == null || !_busLayersInitialized) return;

    // 3D 블록 GeoJSON (지하철과 동일한 스타일 — 크기만 버스 스케일)
    final sb = StringBuffer('{"type":"FeatureCollection","features":[');
    // 발광 링 GeoJSON
    final glowSb = StringBuffer('{"type":"FeatureCollection","features":[');
    bool first = true;

    for (final bus in buses) {
      if (!first) {
        sb.write(',');
        glowSb.write(',');
      }
      first = false;

      // 버스 크기 (지하철 일반: 45x20, 버스: 30x15 — 지하철과 비슷한 비율)
      const lengthM = 30.0;
      const widthM = 15.0;
      const halfL = lengthM / 2;
      const halfW = widthM / 2;

      final rad = bus.bearing * 3.14159265 / 180.0;
      final cosB = cos(rad);
      final sinB = sin(rad);

      // 4꼭짓점 (지하철 _writeTrainFeature와 동일한 좌표 계산)
      final x0 = bus.lng + (-halfW * cosB + (-halfL) * sinB) / _mPerDegLng;
      final y0 = bus.lat + (-(-halfW) * sinB + (-halfL) * cosB) / _mPerDegLat;
      final x1 = bus.lng + (halfW * cosB + (-halfL) * sinB) / _mPerDegLng;
      final y1 = bus.lat + (-(halfW) * sinB + (-halfL) * cosB) / _mPerDegLat;
      final x2 = bus.lng + (halfW * cosB + halfL * sinB) / _mPerDegLng;
      final y2 = bus.lat + (-(halfW) * sinB + halfL * cosB) / _mPerDegLat;
      final x3 = bus.lng + (-halfW * cosB + halfL * sinB) / _mPerDegLng;
      final y3 = bus.lat + (-(-halfW) * sinB + halfL * cosB) / _mPerDegLat;

      // 높이: 지하철과 동일 (20m 기본)
      const busHeight = 20.0;

      sb.write(
        '{"type":"Feature","geometry":{"type":"Polygon","coordinates":'
        '[[[$x0,$y0],[$x1,$y1],[$x2,$y2],[$x3,$y3],[$x0,$y0]]]},'
        '"properties":{"color":"${bus.color}","base":0,"top":$busHeight,"vehId":"${bus.vehId}"}}',
      );

      // 발광 링 (지하철 선택 하이라이트와 비슷)
      glowSb.write(
        '{"type":"Feature","geometry":{"type":"Point",'
        '"coordinates":[${bus.lng},${bus.lat}]},'
        '"properties":{"color":"${bus.color}"}}',
      );
    }

    sb.write(']}');
    glowSb.write(']}');

    await _updateSourceData(_busSourceId, sb.toString());
    await _updateSourceData(_busGlowSourceId, glowSb.toString());
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 항공기 3D 시각화 (미니도쿄 스타일)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Future<void> initFlightLayers() async {
    if (_mapboxMap == null || _flightLayersInitialized) return;
    cleanupFlightLayers();
    final style = _mapboxMap!.style;
    const emptyGeoJson = '{"type":"FeatureCollection","features":[]}';

    try {
      // 비행 궤적 (LineLayer — 그림자/꼬리 효과)
      await style.addSource(
        GeoJsonSource(id: _flightTrailSourceId, data: emptyGeoJson),
      );
      await style.addLayer(
        CircleLayer(
          id: _flightTrailLayerId,
          sourceId: _flightTrailSourceId,
          circleColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            8,
            2.0,
            12,
            4.0,
            15,
            7.0,
          ],
          circleBlur: 0.5,
          circleOpacity: 0.4,
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circleEmissiveStrength: 0.6,
        ),
      );

      // 비행기 몸체 (FillExtrusionLayer — 고도 비례 높이)
      await style.addSource(
        GeoJsonSource(id: _flightSourceId, data: emptyGeoJson),
      );
      await style.addLayer(
        FillExtrusionLayer(
          id: _flightLayerId,
          sourceId: _flightSourceId,
          fillExtrusionColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          fillExtrusionBaseExpression: ['get', 'base'],
          fillExtrusionHeightExpression: ['get', 'top'],
          fillExtrusionOpacity: 0.95,
          fillExtrusionVerticalGradient: true,
          fillExtrusionEmissiveStrength: 1.0,
        ),
      );

      _flightLayersInitialized = true;
      DebugLog.log('[MapboxEngine] ✅ 항공기 3D 레이어 생성 완료');
    } catch (e) {
      DebugLog.log('[MapboxEngine] ❌ 항공기 레이어 초기화 실패: $e');
    }
  }

  @override
  void cleanupFlightLayers() {
    if (_mapboxMap == null) return;
    final style = _mapboxMap!.style;
    style.removeStyleLayer(_flightLayerId).catchError((_) {});
    style.removeStyleLayer(_flightTrailLayerId).catchError((_) {});
    style.removeStyleSource(_flightSourceId).catchError((_) {});
    style.removeStyleSource(_flightTrailSourceId).catchError((_) {});
    _flightLayersInitialized = false;
  }

  @override
  Future<void> updateFlightPositions3D(List<FlightRenderData> flights) async {
    if (_mapboxMap == null || !_flightLayersInitialized) return;

    final sb = StringBuffer('{"type":"FeatureCollection","features":[');
    final trailSb = StringBuffer('{"type":"FeatureCollection","features":[');
    bool first = true;
    bool trailFirst = true;

    for (final f in flights) {
      // 유효하지 않은 좌표 스킵
      if (f.lat == 0 || f.lng == 0 || f.lat.isNaN || f.lng.isNaN) continue;
      if (!first) {
        sb.write(',');
      }
      first = false;

      // 미니도쿄 스타일: 고도 → 3D 높이
      final alt = f.altitude.isNaN ? 0.0 : f.altitude;
      // 고도→3D높이: 낮은 고도를 과장 (100m→20, 500m→60, 3000m→150)
      final mapAlt = f.onGround ? 1.0 : (sqrt(alt) * 2.5).clamp(5.0, 300.0);

      final bearing = f.bearing.isNaN ? 0.0 : f.bearing;
      final rad = bearing * 3.14159265 / 180.0;
      final cosB = cos(rad);
      final sinB = sin(rad);

      // ── 미니도쿄 aircraft-geometry.js 그대로 재현 ──
      // 3개 박스: 동체(가로) + 날개(세로) + 수직꼬리
      // BoxGeometry(width, height, depth) → Polygon + FillExtrusion
      //
      // 동체: 길쭉한 박스 (길이 80m × 폭 15m × 높이 15m)
      // 날개: 넓은 박스 (길이 15m × 폭 80m × 높이 4m) — 동체와 십자
      // 꼬리: 세로 박스 (길이 4m × 폭 15m × 높이 80m) → 수직이니 높이로
      const bodyL = 80.0, bodyW = 15.0, bodyH = 15.0;
      const wingL = 15.0, wingW = 80.0, wingH = 4.0;
      const tailL = 4.0, tailW = 15.0, tailH = 25.0;

      // 각 박스를 Polygon으로 변환하는 헬퍼
      String box(
        double halfX,
        double halfY,
        double base,
        double top,
        double ofsX,
        double ofsY,
      ) {
        // 로컬 4점 + 오프셋
        final pts = [
          [-halfX + ofsX, -halfY + ofsY],
          [halfX + ofsX, -halfY + ofsY],
          [halfX + ofsX, halfY + ofsY],
          [-halfX + ofsX, halfY + ofsY],
        ];
        final buf = StringBuffer('[');
        for (int i = 0; i <= 4; i++) {
          final p = pts[i % 4];
          final rx = p[0] * cosB + p[1] * sinB;
          final ry = -p[0] * sinB + p[1] * cosB;
          if (i > 0) buf.write(',');
          buf.write(
            '[${f.lng + rx / _mPerDegLng},${f.lat + ry / _mPerDegLat}]',
          );
        }
        buf.write(']');
        return '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[$buf]},'
            '"properties":{"color":"${f.color}","base":${mapAlt + base},"top":${mapAlt + top},'
            '"icao24":"${f.icao24}","callsign":"${f.callsign}"}}';
      }

      // 동체 (중심, 바닥~bodyH)
      sb.write(box(bodyW / 2, bodyL / 2, 0, bodyH, 0, 0));
      sb.write(',');
      // 날개 (중심, 약간 아래 위치)
      sb.write(
        box(
          wingW / 2,
          wingL / 2,
          (bodyH - wingH) / 2,
          (bodyH + wingH) / 2,
          0,
          0,
        ),
      );
      sb.write(',');
      // 수직 꼬리 (뒤쪽에, 동체 위로 솟음)
      sb.write(
        box(
          tailW / 2,
          tailL / 2,
          bodyH * 0.3,
          bodyH * 0.3 + tailH,
          0,
          -bodyL * 0.35,
        ),
      );

      // 지면 그림자
      if (trailFirst) {
        trailFirst = false;
      } else {
        trailSb.write(',');
      }
      trailSb.write(
        '{"type":"Feature","geometry":{"type":"Point",'
        '"coordinates":[${f.lng},${f.lat}]},'
        '"properties":{"color":"${f.color}"}}',
      );
    }

    sb.write(']}');
    trailSb.write(']}');

    await _updateSourceData(_flightSourceId, sb.toString());
    await _updateSourceData(_flightTrailSourceId, trailSb.toString());
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 리버버스 3D (배 모양)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Future<void> initRiverBusLayers() async {
    if (_mapboxMap == null || _riverBusLayersInitialized) return;
    cleanupRiverBusLayers();
    final style = _mapboxMap!.style;
    const emptyGeoJson = '{"type":"FeatureCollection","features":[]}';
    try {
      await style.addSource(
        GeoJsonSource(id: _riverBusWakeSourceId, data: emptyGeoJson),
      );
      await style.addLayer(
        CircleLayer(
          id: _riverBusWakeLayerId,
          sourceId: _riverBusWakeSourceId,
          circleColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            5.0,
            14,
            12.0,
            17,
            20.0,
          ],
          circleBlur: 0.6,
          circleOpacity: 0.4,
          circlePitchAlignment: CirclePitchAlignment.MAP,
          circleEmissiveStrength: 0.8,
        ),
      );
      await style.addSource(
        GeoJsonSource(id: _riverBusSourceId, data: emptyGeoJson),
      );
      await style.addLayer(
        FillExtrusionLayer(
          id: _riverBusLayerId,
          sourceId: _riverBusSourceId,
          fillExtrusionColorExpression: [
            'to-color',
            ['get', 'color'],
          ],
          fillExtrusionBaseExpression: ['get', 'base'],
          fillExtrusionHeightExpression: ['get', 'top'],
          fillExtrusionOpacity: 0.92,
          fillExtrusionVerticalGradient: true,
          fillExtrusionEmissiveStrength: 1.0,
        ),
      );
      _riverBusLayersInitialized = true;
      DebugLog.log('[MapboxEngine] ✅ 리버버스 3D 레이어 생성 완료');
    } catch (e) {
      DebugLog.log('[MapboxEngine] ❌ 리버버스 레이어 실패: $e');
    }
  }

  @override
  void cleanupRiverBusLayers() {
    if (_mapboxMap == null) return;
    final style = _mapboxMap!.style;
    style.removeStyleLayer(_riverBusLayerId).catchError((_) {});
    style.removeStyleLayer(_riverBusWakeLayerId).catchError((_) {});
    style.removeStyleSource(_riverBusSourceId).catchError((_) {});
    style.removeStyleSource(_riverBusWakeSourceId).catchError((_) {});
    _riverBusLayersInitialized = false;
  }

  @override
  Future<void> updateRiverBusPositions3D(List<BusRenderData> vessels) async {
    if (_mapboxMap == null || !_riverBusLayersInitialized) return;

    final sb = StringBuffer('{"type":"FeatureCollection","features":[');
    final wakeSb = StringBuffer('{"type":"FeatureCollection","features":[');
    bool first = true, wakeFirst = true;

    for (final v in vessels) {
      if (v.lat == 0 || v.lng == 0) continue;
      final rad = (v.bearing.isNaN ? 0.0 : v.bearing) * 3.14159265 / 180.0;
      final cosB = cos(rad);
      final sinB = sin(rad);

      // ── 배 모양 (단순 육각형 — 앞이 좁은 박스) ──
      const len = 80.0;
      const beam = 25.0;
      const hB = beam / 2;
      // 6각형: 뱃머리(뾰족) + 몸통(직사각) + 선미(평평)
      final pts = <List<double>>[
        [0, len * 0.5], // 뱃머리 끝 (중앙)
        [hB, len * 0.2], // 우현 앞
        [hB, -len * 0.4], // 우현 뒤
        [hB * 0.7, -len * 0.5], // 선미 우
        [-hB * 0.7, -len * 0.5], // 선미 좌
        [-hB, -len * 0.4], // 좌현 뒤
        [-hB, len * 0.2], // 좌현 앞
      ];

      // 선체 (hull) — 시안색
      if (!first) sb.write(',');
      first = false;
      final hull = StringBuffer('[');
      for (int i = 0; i <= pts.length; i++) {
        final p = pts[i % pts.length];
        final rx = p[0] * cosB + p[1] * sinB;
        final ry = -p[0] * sinB + p[1] * cosB;
        if (i > 0) hull.write(',');
        hull.write('[${v.lng + rx / _mPerDegLng},${v.lat + ry / _mPerDegLat}]');
      }
      hull.write(']');
      // 선체를 갑판 높이까지 채움 (구멍 없음)
      sb.write(
        '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[$hull]},'
        '"properties":{"color":"${v.color}","base":0,"top":14,"vehId":"${v.vehId}"}}',
      );

      // 갑판 (deck) — 흰색, 선체 위에 얇게
      sb.write(',');
      sb.write(
        '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[$hull]},'
        '"properties":{"color":"rgba(240,248,255,1)","base":12,"top":14,"vehId":"${v.vehId}"}}',
      );

      // 조타실 (cabin) — 흰색, 배 뒤쪽에 높게
      sb.write(',');
      const cL = 15.0, cW = 14.0, cY = -12.0;
      final cPts = [
        [-cW / 2, -cL / 2 + cY],
        [cW / 2, -cL / 2 + cY],
        [cW / 2, cL / 2 + cY],
        [-cW / 2, cL / 2 + cY],
      ];
      final cab = StringBuffer('[');
      for (int i = 0; i <= 4; i++) {
        final p = cPts[i % 4];
        final rx = p[0] * cosB + p[1] * sinB;
        final ry = -p[0] * sinB + p[1] * cosB;
        if (i > 0) cab.write(',');
        cab.write('[${v.lng + rx / _mPerDegLng},${v.lat + ry / _mPerDegLat}]');
      }
      cab.write(']');
      sb.write(
        '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[$cab]},'
        '"properties":{"color":"rgba(255,255,255,1)","base":14,"top":22,"vehId":"${v.vehId}"}}',
      );

      // 물결
      if (!wakeFirst) wakeSb.write(',');
      wakeFirst = false;
      wakeSb.write(
        '{"type":"Feature","geometry":{"type":"Point",'
        '"coordinates":[${v.lng},${v.lat}]},"properties":{"color":"${v.color}"}}',
      );
    }

    sb.write(']}');
    wakeSb.write(']}');
    await _updateSourceData(_riverBusSourceId, sb.toString());
    await _updateSourceData(_riverBusWakeSourceId, wakeSb.toString());
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // 나침반: 우상단, 검색바 아래로 여유있게
    mapboxMap.compass.updateSettings(
      CompassSettings(
        position: OrnamentPosition.TOP_RIGHT,
        marginTop: 120,
        marginRight: 16,
      ),
    );
    // 로고: 좌하단, 어트리뷰션: 우하단 (탭바 위)
    mapboxMap.logo.updateSettings(
      LogoSettings(
        position: OrnamentPosition.BOTTOM_LEFT,
        marginBottom: 90,
        marginLeft: 8,
      ),
    );
    mapboxMap.attribution.updateSettings(
      AttributionSettings(
        position: OrnamentPosition.BOTTOM_RIGHT,
        marginBottom: 90,
        marginRight: 8,
      ),
    );
    // 스케일바 숨김
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    // POI 라벨 활성화 (줌 15+에서 주변 상점/카페/건물 이름 표시)
    mapboxMap.style.setStyleImportConfigProperty(
      'basemap',
      'showPointOfInterestLabels',
      true,
    );
    mapboxMap.style.setStyleImportConfigProperty(
      'basemap',
      'showPlaceLabels',
      true,
    );

    // Standard POI 탭 인터랙션 (Interactions API — 반드시 setOnMapTapListener보다 먼저)
    mapboxMap.addInteraction(
      TapInteraction(StandardPOIs(), (feature, context) {
        _onAnyMapTap?.call();
        final name = feature.name;
        if (name == null || name.isEmpty || _onPoiTapped == null) return;
        // ferry(한강버스) POI는 자체 마커로 처리
        final group = feature.group;
        if (group == 'transit' &&
            (feature.category == 'ferry' || name.contains('한강버스')))
          return;
        // 대중교통 POI(지하철역/버스정류장)는 기존 역 탭으로 처리
        if (feature.category == 'rail_station' ||
            feature.category == 'metro_rail' ||
            feature.category == 'station' ||
            group == 'transit')
          return;

        // POI를 먼저 저장 — _handleMapTap에서 역을 찾으면 덮어씀
        _pendingPoiName = name;
        _pendingPoiTriggered = true;

        try {
          final raw = feature.geometry['coordinates'];
          if (raw is List && raw.length >= 2) {
            final lng = (raw[0] as num).toDouble();
            final lat = (raw[1] as num).toDouble();
            _pendingPoiLat = lat;
            _pendingPoiLng = lng;
            // 50ms 후에 역 탭이 안 왔으면 POI 처리
            Future.delayed(const Duration(milliseconds: 50), () {
              if (_pendingPoiTriggered && _onPoiTapped != null) {
                _poiTappedThisFrame = true;
                _onPoiTapped!(
                  _pendingPoiName!,
                  _pendingPoiLat!,
                  _pendingPoiLng!,
                );
              }
              _pendingPoiTriggered = false;
            });
          } else {
            final point = context.point;
            _onPoiTapped!(
              name,
              point.coordinates.lat.toDouble(),
              point.coordinates.lng.toDouble(),
            );
          }
        } catch (e) {
          DebugLog.log('[POI] ERROR: $e');
        }
      }, stopPropagation: false),
    );

    // 맵 탭 리스너 — 열차/버스/역 클릭 감지
    mapboxMap.setOnMapTapListener((ctx) {
      _handleMapTap(ctx);
    });

    mapboxMap.annotations.createPointAnnotationManager().then((manager) {
      _pointAnnotationManager = manager;
    });

    mapboxMap.annotations.createCircleAnnotationManager().then((manager) {
      _circleAnnotationManager = manager;
    });

    // peer 핀 전용 — 지하철/열차 마커와 분리해 개별 update/delete 가능.
    mapboxMap.annotations.createCircleAnnotationManager().then((manager) {
      _peerCircleManager = manager;
      manager.addOnCircleAnnotationClickListener(_PeerPinClickListener(this));
    });

    // peer 닉네임 텍스트 라벨 전용 — 핀 위에 떠 있는 작은 글씨.
    mapboxMap.annotations.createPointAnnotationManager().then((manager) {
      _peerLabelManager = manager;
    });

    mapboxMap.annotations.createPolylineAnnotationManager().then((manager) {
      _polylineAnnotationManager = manager;
    });

    // 위치 핀 아이콘 미리 등록
    _ensurePinRegistered();

    widget.onMapCreated(this);
  }

  /// 맵 탭 처리: 열차 레이어 hit test
  Future<void> _handleMapTap(MapContentGestureContext context) async {
    // 탭 좌표 디버그 출력 (한강 좌표 확인용)
    final coord = context.point.coordinates;
    DebugLog.log(
      '[MapTap] 📍 lat=${coord.lat.toStringAsFixed(6)}, lng=${coord.lng.toStringAsFixed(6)}',
    );

    // POI Interaction이 이미 처리한 탭이면 스킵
    if (_poiTappedThisFrame) {
      _poiTappedThisFrame = false;
      return;
    }
    _onAnyMapTap?.call();
    if (_mapboxMap == null || !_layersInitialized3D) return;

    final screenPoint = context.touchPosition;
    // 탭 주변 영역에서 열차 레이어 feature 검색
    final screenBox = ScreenBox(
      min: ScreenCoordinate(x: screenPoint.x - 30, y: screenPoint.y - 30),
      max: ScreenCoordinate(x: screenPoint.x + 30, y: screenPoint.y + 30),
    );

    try {
      final features = await _mapboxMap!.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenBox(screenBox),
        RenderedQueryOptions(layerIds: [_trainLayerId]),
      );

      if (features.isNotEmpty) {
        final feature = features.first?.queriedFeature.feature;
        if (feature != null) {
          final props = feature['properties'];
          if (props is Map) {
            final trainNo = props['trainNo'];
            if (trainNo != null && _onTrainTapped != null) {
              _onTrainTapped!(trainNo.toString());
              return;
            }
          }
        }
      }

      // 열차 못 찾으면 버스 레이어 검색
      if (_busLayersInitialized) {
        final busFeatures = await _mapboxMap!.queryRenderedFeatures(
          RenderedQueryGeometry.fromScreenBox(screenBox),
          RenderedQueryOptions(layerIds: [_busLayerId]),
        );
        if (busFeatures.isNotEmpty) {
          final feature = busFeatures.first?.queriedFeature.feature;
          if (feature != null) {
            final props = feature['properties'];
            if (props is Map) {
              final vehId = props['vehId'];
              if (vehId != null && _onBusTapped != null) {
                _onBusTapped!(vehId.toString());
                return;
              }
            }
          }
        }
      }

      // 한강버스(리버버스) 레이어 검색
      if (_riverBusLayersInitialized) {
        final riverFeatures = await _mapboxMap!.queryRenderedFeatures(
          RenderedQueryGeometry.fromScreenBox(screenBox),
          RenderedQueryOptions(layerIds: [_riverBusLayerId]),
        );
        if (riverFeatures.isNotEmpty) {
          final feature = riverFeatures.first?.queriedFeature.feature;
          if (feature != null) {
            final props = feature['properties'];
            if (props is Map) {
              final vehId = props['vehId'];
              if (vehId != null && _onBusTapped != null) {
                _onBusTapped!(vehId.toString());
                return;
              }
            }
          }
        }
      }

      // 비행기 레이어 검색
      if (_flightLayersInitialized) {
        final flightFeatures = await _mapboxMap!.queryRenderedFeatures(
          RenderedQueryGeometry.fromScreenBox(screenBox),
          RenderedQueryOptions(layerIds: [_flightLayerId]),
        );
        if (flightFeatures.isNotEmpty) {
          final feature = flightFeatures.first?.queriedFeature.feature;
          if (feature != null) {
            final props = feature['properties'];
            if (props is Map) {
              final icao24 = props['icao24'];
              if (icao24 != null && _onFlightTapped != null) {
                _onFlightTapped!(icao24.toString());
                return;
              }
            }
          }
        }
      }

      // 역 레이어 검색
      final stationBox = ScreenBox(
        min: ScreenCoordinate(x: screenPoint.x - 40, y: screenPoint.y - 40),
        max: ScreenCoordinate(x: screenPoint.x + 40, y: screenPoint.y + 40),
      );
      final stationFeatures = await _mapboxMap!.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenBox(stationBox),
        RenderedQueryOptions(
          layerIds: [_stationOutlineLayerId, _stationDotLayerId],
        ),
      );

      if (stationFeatures.isNotEmpty) {
        // 같은 역 이름의 feature가 여러 개면(환승역) 가운데 것 선택
        final validFeatures = stationFeatures
            .where((f) => f?.queriedFeature.feature != null)
            .map((f) => f!.queriedFeature.feature)
            .toList();

        // 역 이름별로 그룹핑 → 가운데 feature 선택
        String? tappedName;
        Map<Object?, Object?>? chosenFeature;
        if (validFeatures.isNotEmpty) {
          final firstName =
              (validFeatures.first['properties'] as Map?)?['name'];
          final sameNameFeatures = validFeatures
              .where((f) => (f['properties'] as Map?)?['name'] == firstName)
              .toList();
          chosenFeature = sameNameFeatures[sameNameFeatures.length ~/ 2];
          tappedName = firstName?.toString();
        }

        if (chosenFeature != null && tappedName != null) {
          final geometry = chosenFeature['geometry'];
          if (geometry is Map && geometry['coordinates'] is List) {
            final coords = geometry['coordinates'] as List;
            if (coords.length >= 2) {
              _selectedStationLng = (coords[0] as num).toDouble();
              _selectedStationLat = (coords[1] as num).toDouble();
            }
          }
          if (_onStationTapped != null) {
            _pendingPoiTriggered = false; // 역 찾았으니 POI 취소
            _onStationTapped!(tappedName);
            return;
          }
        }
      }

      // 좌표 기반 탭 콜백 (선착장 등 체크용)
      if (_onMapCoordTapped != null) {
        final point = context.point;
        _onMapCoordTapped!(
          point.coordinates.lat.toDouble(),
          point.coordinates.lng.toDouble(),
        );
      }

      // 빈 곳 탭 — 선택 해제
      if (_isFollowing) {
        _isFollowing = false;
      }
      _onMapTappedEmpty?.call();
    } catch (e) {
      DebugLog.log('[MapboxEngine] 탭 쿼리 실패: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _positionSubscription?.cancel();
    _locationPulseTimer?.cancel();
    _mapboxMap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      onMapCreated: _onMapCreated,
      onMapIdleListener: (mapIdleEventData) async {
        if (_onCameraIdle == null || _mapboxMap == null) return;
        final cam = await _mapboxMap!.getCameraState();
        final center = cam.center.coordinates;
        _onCameraIdle!(center.lat.toDouble(), center.lng.toDouble(), cam.zoom);
      },
      textureView: true,
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(
            widget.initialCamera.lng,
            widget.initialCamera.lat,
          ),
        ),
        zoom: widget.initialCamera.zoom,
        pitch: widget.initialCamera.pitch,
        bearing: widget.initialCamera.bearing,
      ),
      styleUri: MapboxStyles.STANDARD,
    );
  }
}
