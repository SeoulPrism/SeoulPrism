import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/debug_log.dart';
import '../../../core/map_interface.dart';
import '../../../map_engines/mapbox_engine.dart';
import '../../../services/environment_service.dart';
import '../../../services/settings_service.dart';
import '../../../widgets/bus_overlay.dart';
import '../../../widgets/flight_overlay.dart';
import '../../../widgets/subway_overlay.dart';
import 'demo_bus_simulator.dart';

/// 온보딩 페이지가 백그라운드 맵을 제어하기 위한 싱글톤 컨트롤러.
class OnboardingMapController {
  OnboardingMapController._();
  static final instance = OnboardingMapController._();

  void Function(_Scene)? _setSceneCallback;
  VoidCallback? _zoomOutCallback;
  void _attach(void Function(_Scene) cb) => _setSceneCallback = cb;
  void _attachZoomOut(VoidCallback cb) => _zoomOutCallback = cb;
  void _detach() {
    _setSceneCallback = null;
    _zoomOutCallback = null;
  }

  void flyToSubway() => _setSceneCallback?.call(_Scene.subway);
  void flyToBus() => _setSceneCallback?.call(_Scene.bus);
  void flyToRiverBus() => _setSceneCallback?.call(_Scene.riverBus);
  void flyToFlight() => _setSceneCallback?.call(_Scene.flight);

  /// finish 시퀀스 — 카메라를 도시 광역 줌아웃 + 핵심 차량 follow 해제.
  void zoomOutToCity() => _zoomOutCallback?.call();
}

enum _Scene { initial, subway, bus, riverBus, flight }

class _SceneCamera {
  final double lat, lng, zoom, pitch, bearing;
  const _SceneCamera({
    required this.lat,
    required this.lng,
    required this.zoom,
    required this.pitch,
    required this.bearing,
  });
}

// 모든 씬을 zoom 14.5+ / pitch 65+ 로 통일 — 전환 중에도 3D 빌딩이 항상 보이도록.
// (zoom 이 14 미만으로 떨어지면 Mapbox Standard 가 3D extrusion 을 끔)
const _sceneCameras = <_Scene, _SceneCamera>{
  _Scene.initial: _SceneCamera(lat: 37.5665, lng: 126.9780, zoom: 15.5, pitch: 70, bearing: 0),
  _Scene.subway: _SceneCamera(lat: 37.5640, lng: 126.9750, zoom: 14.8, pitch: 65, bearing: 30),
  // 버스는 차량 자체가 작아 지하철보다 더 가까이 줌업해야 같은 체감 거리.
  _Scene.bus: _SceneCamera(lat: 37.5720, lng: 126.9769, zoom: 16.2, pitch: 65, bearing: -25),
  // 한강 — 마포대교 / 여의도 — 강 양쪽 빌딩이 3D 로 보이도록 줌업.
  _Scene.riverBus: _SceneCamera(lat: 37.5310, lng: 126.9367, zoom: 14.6, pitch: 65, bearing: 90),
  // 인천공항 — 비행기는 빠르게 움직이므로 더 줌인 + pitch 살짝 낮춰 비행 동선 잘 보이게.
  _Scene.flight: _SceneCamera(lat: 37.4486, lng: 126.4505, zoom: 15.6, pitch: 60, bearing: 25),
};

/// 온보딩 백그라운드 — 실제 MapboxEngine + 실 컨트롤러 (실시간 데이터 + 3D 렌더).
/// 사용자가 차량 아이콘 탭하면 그 차량을 "선택" 해 카메라 follow 모드로 전환.
/// 단, 상세 패널은 안 띄움 (콜백 미설정).
class OnboardingMapBackground extends StatefulWidget {
  const OnboardingMapBackground({super.key});

  @override
  State<OnboardingMapBackground> createState() => _OnboardingMapBackgroundState();
}

class _OnboardingMapBackgroundState extends State<OnboardingMapBackground> {
  IMapController? _mapController;
  Timer? _idleRotateTimer;
  Timer? _customFollowTimer;
  Timer? _busSimTimer;
  double _bearing = 0;
  bool _disposed = false;
  _Scene _scene = _Scene.initial;

  String? _followingBusVehId;
  String? _followingFlightIcao;
  // 튜토리얼은 보여주기용 — 모든 차량 데모 모드. 시간/API 한도 무관 안정.
  final DemoBusSimulator _busSim = DemoBusSimulator();
  // 사용자 원래 지하철 모드 — 튜토리얼 종료 시 복원.
  String? _origSubwayMode;

  late final SubwayOverlayController _subway;
  late final BusOverlayController _bus;
  late final FlightOverlayController _flight;

  @override
  void initState() {
    super.initState();
    _subway = SubwayOverlayController();
    _bus = BusOverlayController();
    _flight = FlightOverlayController();
    OnboardingMapController.instance._attach(_setScene);
    OnboardingMapController.instance._attachZoomOut(_zoomOutToCity);
  }

  @override
  void dispose() {
    _disposed = true;
    OnboardingMapController.instance._detach();
    _idleRotateTimer?.cancel();
    _customFollowTimer?.cancel();
    _busSimTimer?.cancel();
    _subway.dispose();
    _bus.dispose();
    _flight.dispose();
    if (_origSubwayMode != null) {
      SettingsService.instance.setMode(_origSubwayMode!);
    }
    super.dispose();
  }

  Future<void> _onMapCreated(IMapController controller) async {
    _mapController = controller;

    // 시작 시 강제로 야간 룩 — _subway.start() 가 곧 env 적용해 실제 시간/날씨로 매끄럽게 전환됨.
    // 첫 frame 부터 깜박임 없게 약간 어둡게 깔아둠.
    controller.applyWeatherEffect(
      lightPreset: 'dusk',
      fogOpacity: 0.3,
      atmosphereRange: 1.2,
    );

    // 지하철 — 데모 모드 강제 (튜토리얼은 보여주기). TrainSimulator 가 1호선 일반/급행/초급행 자동 생성.
    _origSubwayMode = SettingsService.instance.mode;
    _subway.attachMap(controller);
    _subway.setLineFilter({'1001'});
    _subway.setMode(SubwayMode.demo);
    await _subway.start();

    // 버스 — bus_overlay 의 3D 레이어 + 한강버스 sim 만 활용. 실 API 미사용.
    _bus.attachMap(controller);
    await _bus.start();
    _bus.toggleRiverBus(true);

    // 자체 버스 시뮬레이터 — 광화문 통과 5 노선, 각 6 대 양방향, 정류소 시퀀스 따라 부드럽게 운행.
    for (final name in ['150', '272', '472', '370', '402']) {
      _busSim.addRoute(name, busCount: 6);
    }
    DebugLog.log('[Onboarding] 버스 시뮬레이터 — 5 노선 × 6 대 = 30 대');

    // 30fps tick — 시뮬레이터 advance + 3D 렌더 일괄. 30대 버스라 60fps 는 과함.
    _busSimTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (_disposed || _mapController == null) return;
      _busSim.step();
      _busSim.flush(_mapController!);
    });

    _flight.attachMap(controller);
    await _flight.start();

    _idleRotateLoop();
  }

  Future<void> _setScene(_Scene s) async {
    if (_disposed || _mapController == null) return;

    // 이전 follow 정리
    _customFollowTimer?.cancel();
    _followingBusVehId = null;
    _followingFlightIcao = null;
    _subway.deselectTrain();
    _bus.deselectBus();
    _bus.deselectVessel();

    _scene = s;
    _idleRotateTimer?.cancel();

    final cam = _sceneCameras[s]!;

    // 차량 데이터를 먼저 찾아본다 — 있으면 그 위치 기반으로 한 번에 부드럽게 이동.
    // 없으면 씬 카메라로 가서 polling.
    final initialTarget = _findNearestForScene(s, cam);

    if (initialTarget != null) {
      // flyTo 포물선 — 살짝 올라갔다 내려오는 시네마틱 모션. 한강버스가 좋아 사용자가 좋아함.
      _mapController!.moveTo(
        initialTarget.$1,
        initialTarget.$2,
        zoom: cam.zoom,
        pitch: cam.pitch,
        bearing: cam.bearing,
        durationMs: 1200,
      );
      _mapController!.primeFollowMode();
      _bindFollow(s, initialTarget.$3);
    } else {
      _mapController!.moveTo(
        cam.lat,
        cam.lng,
        zoom: cam.zoom,
        pitch: cam.pitch,
        bearing: cam.bearing,
        durationMs: 1200,
      );
      // polling 후 데이터 도착하면 부드럽게 차량으로 bridge.
      await Future.delayed(const Duration(milliseconds: 600));
      if (_disposed || _scene != s) return;
      DebugLog.log(
        '[Onboarding] $s 진입. trains=${_subway.currentTrains.length} '
        'buses=${_bus.currentPositions.values.fold<int>(0, (n, l) => n + l.length)} '
        'vessels=${_bus.currentVessels.length} '
        'flights=${_flight.currentFlights.length}',
      );
      await _waitDataAndBridge(s, cam);
    }
  }

  /// 해당 씬의 가장 가까운 차량 정보 (없으면 null).
  /// 반환: (lat, lng, vehicleKey) — vehicleKey 는 follow 식별자 (트레인 no/vehId/vesselId/icao24).
  (double, double, String)? _findNearestForScene(_Scene s, _SceneCamera cam) {
    switch (s) {
      case _Scene.initial:
        return null;
      case _Scene.subway:
        final t = _nearest(_subway.currentTrains, cam.lat, cam.lng,
            (e) => (e.lat, e.lng));
        return t == null ? null : (t.lat, t.lng, t.trainNo);
      case _Scene.bus:
        // 시뮬레이터에서 가장 가까운 버스.
        return _busSim.nearest(cam.lat, cam.lng);
      case _Scene.riverBus:
        final v = _nearest(_bus.currentVessels, cam.lat, cam.lng,
            (e) => (e.lat, e.lng));
        return v == null ? null : (v.lat, v.lng, v.id);
      case _Scene.flight:
        // 보간된 위치 기준 — 매 프레임 부드러운 좌표.
        final f = _flight.nearestInterpolated(cam.lat, cam.lng);
        return f == null ? null : (f.lat, f.lng, f.icao24);
    }
  }

  /// 차량 키 기반으로 follow 시작 (4종 통합).
  void _bindFollow(_Scene s, String key) {
    DebugLog.log('[Onboarding] $s follow 시작: $key');
    switch (s) {
      case _Scene.initial:
        return;
      case _Scene.subway:
        // 지하철: 컨트롤러의 selectTrain 으로 highlight + 자동 follow.
        // primeFollowMode 가 selected 상태라 followTrain 이 setCamera 만 함.
        _subway.selectTrain(key);
      case _Scene.bus:
        _followingBusVehId = key;
        _runCustomFollow();
      case _Scene.riverBus:
        _bus.selectVessel(key);
      case _Scene.flight:
        _followingFlightIcao = key;
        _runCustomFollow();
    }
  }

  /// 데이터 도착할 때까지 기다린 후 차량 위치로 부드럽게 bridge + follow.
  /// 버스 씬에서 N초 안에 실시간 0대 그대로면 → 데모 모드로 폴백.
  Future<void> _waitDataAndBridge(_Scene s, _SceneCamera cam) async {
    const totalAttempts = 16;
    const intervalMs = 500;
    for (int i = 0; i < totalAttempts; i++) {
      if (_disposed || _scene != s) return;
      final target = _findNearestForScene(s, cam);
      if (target != null) {
        // bridge 도 flyTo (짧고 빠르게) — 일관된 포물선 느낌.
        _mapController!.moveTo(
          target.$1,
          target.$2,
          zoom: cam.zoom,
          pitch: cam.pitch,
          bearing: cam.bearing,
          durationMs: 700,
        );
        _mapController!.primeFollowMode();
        _bindFollow(s, target.$3);
        DebugLog.log('[Onboarding] $s 선택 성공 (attempt ${i + 1})');
        return;
      }
      await Future.delayed(const Duration(milliseconds: intervalMs));
    }
    DebugLog.log(
        '[Onboarding] ⚠️ $s 데이터 로드 안돼 follow 실패 (${totalAttempts * intervalMs / 1000}s 대기)');
  }

  /// 카메라 좌표에 가장 가까운 항목 (없으면 null).
  /// [latLngOf] 는 항목에서 (lat, lng) 튜플을 추출.
  T? _nearest<T>(List<T> items, double camLat, double camLng,
      (double, double) Function(T) latLngOf) {
    if (items.isEmpty) return null;
    T? best;
    double bestSq = double.infinity;
    for (final it in items) {
      final (lat, lng) = latLngOf(it);
      final dLat = lat - camLat;
      final dLng = lng - camLng;
      final sq = dLat * dLat + dLng * dLng;
      if (sq < bestSq) {
        bestSq = sq;
        best = it;
      }
    }
    return best;
  }

  /// 버스/항공기 — 컨트롤러에 내장 follow 가 없어 직접 Timer 로 카메라 추적.
  /// followTrain 은 primeFollowMode 덕분에 setCamera(center) 만 함 — 즉시 평면 스냅.
  void _runCustomFollow() {
    _customFollowTimer?.cancel();
    // 33ms = 30fps — 보간 컨트롤러의 갱신 주기와 매칭. 더 빠르면 같은 좌표 반복 호출.
    _customFollowTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (_disposed || _mapController == null) return;
      if (_followingBusVehId != null) {
        final pos = _busSim.findById(_followingBusVehId!);
        if (pos != null) {
          _mapController!.followTrain(pos.lat, pos.lng, pos.bearing);
        }
      } else if (_followingFlightIcao != null) {
        // 보간된 위치 — 16~33ms 마다 갱신되어 덜덜거림 없음.
        final pos = _flight.interpolatedById(_followingFlightIcao!);
        if (pos != null) {
          _mapController!.followTrain(pos.lat, pos.lng, pos.heading);
        }
      }
    });
  }

  void _idleRotateLoop() {
    _idleRotateTimer?.cancel();
    _idleRotateTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (_disposed || _mapController == null) return;
      if (_scene != _Scene.initial) return;
      _bearing = (_bearing + 0.06) % 360;
      _mapController!.setBearing(_bearing);
    });
  }

  /// 튜토리얼 종료 시퀀스 — 카메라를 HomeView 의 초기 카메라와 정확히 매칭.
  /// 페이드 아웃 시점에 두 맵이 같은 뷰를 보여 자연스러운 연속성.
  /// HomeView 의 _cameraInfo 와 동일하게 유지해야 함:
  ///   lat: 37.5665, lng: 126.9780, zoom: 14.0, pitch: 50, bearing: -15
  void _zoomOutToCity() {
    if (_disposed || _mapController == null) return;
    _customFollowTimer?.cancel();
    _idleRotateTimer?.cancel();
    _followingBusVehId = null;
    _followingFlightIcao = null;
    _subway.deselectTrain();
    _bus.deselectBus();
    _bus.deselectVessel();
    _scene = _Scene.initial;

    // HomeView 의 SubwayOverlay 가 곧 적용할 환경 (시간/날씨 기반) 을 미리 매칭.
    // 똑같은 lightPreset/fog 로 풀어주면 페이드 시 두 맵이 같은 룩으로 보임.
    final env = EnvironmentService.instance.current;
    _mapController!.applyWeatherEffect(
      lightPreset: env?.lightPreset ?? 'dusk',
      fogOpacity: 0.0,
      atmosphereRange: 1.0,
    );

    _mapController!.moveTo(
      37.5665,
      126.9780,
      zoom: 14.0,
      pitch: 50,
      bearing: -15,
      durationMs: 1800,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cam = _sceneCameras[_Scene.initial]!;
    return IgnorePointer(
      child: MapboxEngine(
        initialCamera: CameraInfo(
          lat: cam.lat,
          lng: cam.lng,
          zoom: cam.zoom,
          pitch: cam.pitch,
          bearing: cam.bearing,
        ),
        onMapCreated: _onMapCreated,
      ),
    );
  }

}
