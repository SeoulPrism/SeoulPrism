import 'dart:async';
import 'dart:io';
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
  void flyToLiveMeet() => _setSceneCallback?.call(_Scene.liveMeet);

  /// finish 시퀀스 — 카메라를 도시 광역 줌아웃 + 핵심 차량 follow 해제.
  void zoomOutToCity() => _zoomOutCallback?.call();
}

enum _Scene { initial, subway, bus, riverBus, flight, liveMeet }

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
  // Seoul Live — 광화문 광장. 친구 dot 데모(화면 좌표) 가 빌딩에 묻히지 않게
  // 광장 빈 공간 + 경복궁 위주의 시야로. pitch 55 로 살짝 낮춰 dot 가 빌딩
  // 입면에 가려지는 일을 줄임 (3D extrusion 은 zoom 16 + pitch 55 에서도 충분히 보임).
  _Scene.liveMeet: _SceneCamera(lat: 37.5731, lng: 126.9763, zoom: 16.0, pitch: 55, bearing: 0),
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
    // 데모 — 사용자 설정에 영향 X.
    _subway.setLineFilter({'1001'}, persist: false);
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
    _flight.onAnimationTick = null;
    _followingBusVehId = null;
    _followingFlightIcao = null;
    _subway.deselectTrain();
    _bus.deselectBus();
    _bus.deselectVessel();

    final prevCam = _sceneCameras[_scene]!;
    _scene = s;
    _idleRotateTimer?.cancel();

    final cam = _sceneCameras[s]!;

    // 차량 데이터를 먼저 찾아본다 — 있으면 그 위치 기반으로 한 번에 부드럽게 이동.
    // 없으면 씬 카메라로 가서 polling.
    final initialTarget = _findNearestForScene(s, cam);

    final tgtLat = initialTarget?.$1 ?? cam.lat;
    final tgtLng = initialTarget?.$2 ?? cam.lng;
    final useSnap = _shouldSnap(prevCam.lat, prevCam.lng, tgtLat, tgtLng);

    // 버스/비행기는 컨트롤러 자체에 arrival 애니메이션이 없어, snap 직후 setCamera 가
    // 즉시 박혀버려 "위로 올라오는" 시네마틱 효과 부재. 지하철/한강버스는 selectTrain/
    // selectVessel 내부에서 followTrain(첫 호출) flyTo 가 자동 발생해 OK.
    // → Android 에서 버스/비행기 진입 시: 살짝 wider+flatter 로 snap → arriveAt 으로
    //   target zoom/pitch 까지 800ms easeTo (지하철의 followTrain flyTo 와 동일한 톤).
    final needsArrival = useSnap && (s == _Scene.bus || s == _Scene.flight);

    if (useSnap) {
      if (needsArrival) {
        _mapController!.snapTo(tgtLat, tgtLng,
            zoom: cam.zoom - 1.5,
            pitch: (cam.pitch - 15).clamp(0, 85).toDouble(),
            bearing: cam.bearing);
      } else {
        // 지하철/한강버스 (또는 거리 기반으로 향후 변경 시 일반 snap)
        _mapController!.snapTo(tgtLat, tgtLng,
            zoom: cam.zoom, pitch: cam.pitch, bearing: cam.bearing);
      }
    } else {
      // iOS: flyTo 포물선 시네마틱 (출시본 그대로 유지)
      _mapController!.moveTo(tgtLat, tgtLng,
          zoom: cam.zoom,
          pitch: cam.pitch,
          bearing: cam.bearing,
          durationMs: 1200);
    }

    if (initialTarget != null) {
      if (needsArrival) {
        // arriveAt = easeTo + _isFollowing/_flyToEndTime lock.
        // custom follow 의 setCamera 가 800ms 동안 무시되어 easeTo 가 안 끊김.
        // primeFollowMode 는 부르지 말 것 (arriveAt 이 같은 flag 처리함).
        _mapController!.arriveAt(tgtLat, tgtLng,
            zoom: cam.zoom,
            pitch: cam.pitch,
            bearing: cam.bearing,
            durationMs: 900);
      } else {
        _mapController!.primeFollowMode();
      }
      _bindFollow(s, initialTarget.$3);
    } else {
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

  /// Android 는 onboarding 씬 전환을 모두 snap 으로. iOS 는 flyTo 시네마틱 유지.
  /// Mapbox Android 가 flyTo 호 모션 + 3D extrusion + 광역 타일 fetch 를 동시에
  /// 잘 못 처리해서 가까운 거리도 끊김/blank 가 발생하는 경우가 있고,
  /// 사용자 선호가 "Android 는 깔끔히 끊어가는 룩" 으로 일관 처리하는 것.
  bool _shouldSnap(double aLat, double aLng, double bLat, double bLng) =>
      Platform.isAndroid;

  /// 해당 씬의 가장 가까운 차량 정보 (없으면 null).
  /// 반환: (lat, lng, vehicleKey) — vehicleKey 는 follow 식별자 (트레인 no/vehId/vesselId/icao24).
  (double, double, String)? _findNearestForScene(_Scene s, _SceneCamera cam) {
    switch (s) {
      case _Scene.initial:
      case _Scene.liveMeet:
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
      case _Scene.liveMeet:
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
  ///
  /// 비행기는 flight overlay 의 `_animationTick` 안에서 직접 카메라 갱신 (콜백).
  /// 별도 Timer 를 쓰면 두 Timer 의 phase 가 마이크로초 단위로 어긋나
  /// 카메라가 icon 보다 한 프레임 앞/뒤로 흔들리는 sub-frame aliasing 발생 →
  /// Android Mapbox 가 그걸 그대로 화면에 드러내 "덜덜거림" 으로 보임.
  /// icon write 직후 같은 tick 에 setCamera 하면 두 좌표가 정확히 매치돼 안 흔들림.
  ///
  /// 버스는 _busSimTimer (33ms) 가 step + flush 모두 같은 tick 에 처리하니
  /// 그 옆에 별도 33ms 카메라 timer 가 있어도 Mapbox 입장에서 좌표가 일관.
  void _runCustomFollow() {
    _customFollowTimer?.cancel();
    _flight.onAnimationTick = null;

    if (_followingFlightIcao != null) {
      _flight.onAnimationTick = () {
        if (_disposed || _mapController == null) return;
        final pos = _flight.interpolatedById(_followingFlightIcao!);
        if (pos != null) {
          _mapController!.followTrain(pos.lat, pos.lng, pos.heading);
        }
      };
    } else if (_followingBusVehId != null) {
      _customFollowTimer =
          Timer.periodic(const Duration(milliseconds: 33), (_) {
        if (_disposed || _mapController == null) return;
        final pos = _busSim.findById(_followingBusVehId!);
        if (pos != null) {
          _mapController!.followTrain(pos.lat, pos.lng, pos.bearing);
        }
      });
    }
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
    _flight.onAnimationTick = null;
    _idleRotateTimer?.cancel();
    _followingBusVehId = null;
    _followingFlightIcao = null;
    _subway.deselectTrain();
    _bus.deselectBus();
    _bus.deselectVessel();
    _scene = _Scene.initial;

    // finish 시퀀스 (1.8s flyTo + fade) 동안 HomeView 가 뒤에서 mount 돼
    // 자기 SubwayOverlay/BusOverlay/FlightOverlay (각 422 trains 등) 를 띄움.
    // 두 맵의 시뮬레이터가 동시에 돌면 안드로이드에서 main thread blocking →
    // "Skipped 46 frames" 발생. zoom 14 광역 뷰에서는 차량 아이콘이 안 보이는 줌이라
    // 시각 손실 없이 즉시 정지해 GPU/CPU 부담을 절반으로 줄임.
    _busSimTimer?.cancel();
    _subway.stop();
    _bus.stop();
    _flight.stop();

    // HomeView 의 SubwayOverlay 가 곧 적용할 환경 (시간/날씨 기반) 을 미리 매칭.
    // 똑같은 lightPreset/fog 로 풀어주면 페이드 시 두 맵이 같은 룩으로 보임.
    final env = EnvironmentService.instance.current;
    _mapController!.applyWeatherEffect(
      lightPreset: env?.lightPreset ?? 'dusk',
      fogOpacity: 0.0,
      atmosphereRange: 1.0,
    );

    // 튜토리얼 → 홈뷰 전환 (앱 시작 시퀀스) 은 항상 부드러운 flyTo.
    // snap 효과는 in-tutorial 의 지하철/버스/한강버스/비행기 씬 전환에만 사용.
    _mapController!.moveTo(37.5665, 126.9780,
        zoom: 14.0, pitch: 50, bearing: -15, durationMs: 1800);
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
