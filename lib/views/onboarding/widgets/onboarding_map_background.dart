import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../data/subway_geojson_loader.dart';

/// 온보딩 배경: Mapbox 위에 1호선 라인만 렌더 + 카메라 자동 회전.
/// 사용자 인터랙션 차단. iOS 어두운 backdrop 위에 살짝 보이도록 의도됨.
class OnboardingMapBackground extends StatefulWidget {
  const OnboardingMapBackground({super.key});

  @override
  State<OnboardingMapBackground> createState() => _OnboardingMapBackgroundState();
}

class _OnboardingMapBackgroundState extends State<OnboardingMapBackground> {
  static const _line1Id = '1001';
  static const _seoulCenter = (lat: 37.5665, lng: 126.9780);

  MapboxMap? _map;
  Timer? _rotateTimer;
  double _bearing = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _rotateTimer?.cancel();
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    // 인터랙션 모두 차단 — 튜토리얼 배경.
    await map.gestures.updateSettings(
      GesturesSettings(
        rotateEnabled: false,
        scrollEnabled: false,
        pinchToZoomEnabled: false,
        doubleTapToZoomInEnabled: false,
        doubleTouchToZoomOutEnabled: false,
        quickZoomEnabled: false,
        pitchEnabled: false,
      ),
    );
    await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await map.compass.updateSettings(CompassSettings(enabled: false));
    await map.attribution.updateSettings(AttributionSettings(enabled: false));
    await map.logo.updateSettings(LogoSettings(enabled: false));
    await _addLine1Layer();
    _startRotateLoop();
  }

  Future<void> _addLine1Layer() async {
    if (_map == null) return;
    final geo = await SubwayGeoJsonLoader.load();
    final coords = geo[_line1Id];
    if (coords == null || coords.isEmpty) return;

    // [lat, lng] → GeoJSON [lng, lat]
    final lineString = {
      'type': 'Feature',
      'geometry': {
        'type': 'LineString',
        'coordinates': coords.map((c) => [c[1], c[0]]).toList(),
      },
      'properties': {},
    };

    if (_disposed || _map == null) return;
    final style = _map!.style;
    try {
      await style.addSource(GeoJsonSource(
        id: 'onboarding-line1',
        data: jsonEncode(lineString),
      ));
      await style.addLayer(LineLayer(
        id: 'onboarding-line1-glow',
        sourceId: 'onboarding-line1',
        lineColor: 0xFF0052A4,
        lineWidth: 14.0,
        lineBlur: 8.0,
        lineOpacity: 0.45,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ));
      await style.addLayer(LineLayer(
        id: 'onboarding-line1-core',
        sourceId: 'onboarding-line1',
        lineColor: 0xFF66B0FF,
        lineWidth: 3.5,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ));
    } catch (_) {
      // 스타일 미준비/disposed 등 — 무시.
    }
  }

  void _startRotateLoop() {
    _rotateTimer?.cancel();
    _rotateTimer = Timer.periodic(const Duration(milliseconds: 60), (_) async {
      if (_disposed || _map == null) return;
      _bearing = (_bearing + 0.08) % 360;
      try {
        await _map!.setCamera(CameraOptions(bearing: _bearing));
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: MapWidget(
        styleUri: MapboxStyles.DARK,
        textureView: true,
        cameraOptions: CameraOptions(
          center: Point(
            coordinates: Position(_seoulCenter.lng, _seoulCenter.lat),
          ),
          zoom: 10.5,
          pitch: 55,
          bearing: 0,
        ),
        onMapCreated: _onMapCreated,
      ),
    );
  }
}
