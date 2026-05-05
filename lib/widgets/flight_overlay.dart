import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/map_interface.dart';
import '../services/flight_service.dart';
import '../services/settings_service.dart';
import '../data/airport_data.dart';

/// 비행기 색상 (미니도쿄 스타일)
class FlightColors {
  static const Color climbing = Color(0xFF00E676);    // 상승 — 초록
  static const Color cruising = Color(0xFFFFFFFF);    // 순항 — 흰색
  static const Color descending = Color(0xFFFF9100);  // 하강 — 주황
  static const Color ground = Color(0xFF757575);      // 지상 — 회색
  static const Color landing = Color(0xFFFF5252);     // 이착륙 — 빨강

  static Color fromPhase(FlightPosition flight) {
    if (flight.onGround) return ground;
    if (flight.altitude < 1000) return landing;
    if (flight.verticalRate > 2) return climbing;
    if (flight.verticalRate < -2) return descending;
    return cruising;
  }

  static String toRgba(Color c) {
    final r = (c.r * 255).round().clamp(0, 255);
    final g = (c.g * 255).round().clamp(0, 255);
    final b = (c.b * 255).round().clamp(0, 255);
    return 'rgba($r,$g,$b,1)';
  }
}

/// 항공기 시각화 오버레이 컨트롤러
/// 지하철 SubwayOverlayController와 동일한 패턴:
/// - API 15초마다 갱신 (스냅샷)
/// - 매 프레임(16ms) dead reckoning으로 보간 렌더링
enum FlightMode { live, demo }

class FlightOverlayController {
  final FlightService _api = FlightService.instance;
  IMapController? _mapController;

  Timer? _refreshTimer;
  Timer? _animTimer;
  bool _isActive = false;
  bool _showFlights = true;
  FlightMode _mode = FlightMode.demo; // 기본 데모

  // ── 비행기 상태 (지하철의 _currentTrains에 해당) ──
  final Map<String, _FlightState> _states = {};
  DateTime _lastFetchTime = DateTime.now();
  int _lastUIUpdate = 0;

  // 선택된 비행기
  FlightPosition? _selectedFlight;

  // 콜백
  VoidCallback? onStateChanged;
  void Function(FlightPosition flight)? onFlightSelected;

  // ── Getters ──
  bool get isActive => _isActive;
  FlightMode get mode => _mode;
  bool get showFlights => _showFlights;
  int get flightCount => _states.length;
  FlightPosition? get selectedFlight => _selectedFlight;
  List<FlightPosition> get currentFlights =>
      _states.values.map((s) => s.position).toList();

  void attachMap(IMapController controller) {
    _mapController = controller;
    controller.setOnFlightTapped((icao24) {
      final state = _states[icao24];
      if (state != null) {
        _selectedFlight = state.position;
        _mapController?.moveTo(state.position.lat, state.position.lng,
            zoom: 14.0, pitch: 50.0);
        onFlightSelected?.call(_selectedFlight!);
        onStateChanged?.call();
      }
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 시작/중지
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> start() async {
    if (_isActive) return;
    _isActive = true;

    await _mapController?.initFlightLayers();

    if (_mode == FlightMode.live) {
      // LIVE: OpenSky API 실시간
      await _fetchPositions();
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _fetchPositions();
      });
    }
    // DEMO: API 호출 없이 시뮬레이션만 (_animationTick에서 처리)

    // quality preset에 따라 프레임 조절
    final flightMs = switch (SettingsService.instance.qualityPreset) {
      'low' => 100,
      'medium' => 33,
      _ => 16,
    };
    _animTimer = Timer.periodic(Duration(milliseconds: flightMs), (_) {
      _animationTick();
    });

    onStateChanged?.call();
  }

  void stop() {
    _isActive = false;
    _refreshTimer?.cancel();
    _animTimer?.cancel();
    _refreshTimer = null;
    _animTimer = null;
    _states.clear();
    _mapController?.cleanupFlightLayers();
    onStateChanged?.call();
  }

  void dispose() {
    stop();
  }

  void toggle(bool show) {
    _showFlights = show;
    if (show && !_isActive) {
      start();
    } else if (!show && _isActive) {
      stop();
    }
    onStateChanged?.call();
  }

  void setMode(FlightMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    _states.clear();
    if (_isActive) {
      stop();
      start();
    }
    onStateChanged?.call();
  }

  void deselectFlight() {
    _selectedFlight = null;
    onStateChanged?.call();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // API Fetch (15초마다)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _fetchPositions() async {
    final flights = await _api.fetchFlights();
    // OpenSky 결과 (빈 배열이어도 시뮬레이션은 항상 추가)
    final allFlights = [...flights];

    // 공항 시뮬레이션 항상 병합 (OpenSky 실패해도 공항 비행기는 보임)
    final simFlights = _api.getSimulatedAirportFlights();
    if (simFlights.isEmpty) {
      final fallback = AirportData.getActiveFlights();
      for (final f in fallback) {
        allFlights.add(FlightPosition(
          icao24: 'sim_${f.id}',
          callsign: f.callsign,
          lat: f.lat, lng: f.lng,
          altitude: f.altitude,
          velocity: 200,
          heading: f.bearing,
          verticalRate: f.isDeparture ? 10.0 : -5.0,
          onGround: f.altitude == 0 && f.phase == '유도로',
          originCountry: 'Republic of Korea',
        ));
      }
    } else {
      final existingCallsigns = allFlights.map((f) => f.callsign).toSet();
      for (final sim in simFlights) {
        if (!existingCallsigns.contains(sim.callsign)) {
          allFlights.add(sim);
        }
      }
    }

    if (allFlights.isEmpty) return; // 둘 다 비어있을 때만 스킵
    _lastFetchTime = DateTime.now();

    // 상태 업데이트
    final newIds = <String>{};
    for (final f in allFlights) {
      newIds.add(f.icao24);
      final existing = _states[f.icao24];
      if (existing != null) {
        // 기존 비행기: 새 위치를 목표로 설정 (보간용)
        existing.prevLat = existing.currentLat;
        existing.prevLng = existing.currentLng;
        existing.prevAlt = existing.currentAlt;
        existing.targetLat = f.lat;
        existing.targetLng = f.lng;
        existing.targetAlt = f.altitude;
        existing.position = f;
        existing.interpProgress = 0.0;
        existing.missCount = 0; // 다시 나타남
      } else {
        // 새 비행기
        _states[f.icao24] = _FlightState(
          position: f,
          currentLat: f.lat,
          currentLng: f.lng,
          currentAlt: f.altitude,
          prevLat: f.lat,
          prevLng: f.lng,
          prevAlt: f.altitude,
          targetLat: f.lat,
          targetLng: f.lng,
          targetAlt: f.altitude,
        );
      }
    }

    // 사라진 비행기: dead reckoning으로 계속 유지, 오래되면 제거
    // API 실패(빈 응답) 시에는 아무것도 제거 안 함
    if (flights.isNotEmpty) {
      final toRemove = <String>[];
      for (final entry in _states.entries) {
        if (!newIds.contains(entry.key)) {
          entry.value.missCount++;
          // 10회 (100초) 이상 안 잡히면 제거
          if (entry.value.missCount >= 10) {
            toRemove.add(entry.key);
          }
        }
      }
      for (final id in toRemove) {
        _states.remove(id);
      }
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 60fps 애니메이션 틱 (지하철과 동일 패턴)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _animationTick() {
    if (!_isActive || !_showFlights) return;

    final mc = _mapController;
    if (mc == null) return;

    // 보간 진행 (10초 동안 0→1, API 갱신 주기와 동일)
    const interpDuration = 10.0;
    final elapsed = DateTime.now().difference(_lastFetchTime).inMilliseconds / 1000.0;
    final globalProgress = (elapsed / interpDuration).clamp(0.0, 1.0);

    final renderData = <FlightRenderData>[];

    // 시뮬레이션 비행기: 매 프레임 새로 계산 (시간 기반이라 계속 변함)
    final simFlights = AirportData.getActiveFlights();
    for (final f in simFlights) {
      final id = 'sim_${f.id}';
      final pos = FlightPosition(
        icao24: id, callsign: f.callsign,
        lat: f.lat, lng: f.lng, altitude: f.altitude,
        velocity: 200, heading: f.bearing,
        verticalRate: f.isDeparture ? 10.0 : -5.0,
        onGround: f.altitude == 0 && f.phase == '유도로',
        originCountry: 'Republic of Korea',
      );

      final state = _states[id];
      if (state != null) {
        state.currentLat = f.lat;
        state.currentLng = f.lng;
        state.currentAlt = f.altitude;
        state.position = pos;
      } else {
        // 없으면 새로 생성
        _states[id] = _FlightState(
          position: pos,
          currentLat: f.lat, currentLng: f.lng, currentAlt: f.altitude,
          prevLat: f.lat, prevLng: f.lng, prevAlt: f.altitude,
          targetLat: f.lat, targetLng: f.lng, targetAlt: f.altitude,
        );
      }
    }

    for (final state in _states.values) {
      final isSim = state.position.icao24.startsWith('sim_');

      if (!isSim) {
        // OpenSky 비행기: 보간 + dead reckoning
        final t = _smoothStep(globalProgress);
        state.currentLat = state.prevLat + (state.targetLat - state.prevLat) * t;
        state.currentLng = state.prevLng + (state.targetLng - state.prevLng) * t;
        state.currentAlt = state.prevAlt + (state.targetAlt - state.prevAlt) * t;

        if (globalProgress >= 1.0) {
          final overTime = elapsed - interpDuration;
          final f = state.position;
          final dist = f.velocity * overTime;
          final headingRad = f.heading * 3.14159265 / 180.0;
          state.currentLat = state.targetLat + dist * cos(headingRad) / 111320.0;
          state.currentLng = state.targetLng + dist * sin(headingRad) / 88000.0;
          state.currentAlt = (state.targetAlt + f.verticalRate * overTime).clamp(0.0, 15000.0);
        }
      }
      // sim 비행기는 위에서 이미 갱신됨

      final f = state.position;
      final color = FlightColors.fromPhase(f);
      renderData.add(FlightRenderData(
        icao24: f.icao24,
        callsign: f.callsign,
        lat: state.currentLat,
        lng: state.currentLng,
        altitude: f.onGround ? 0 : state.currentAlt,
        bearing: f.heading,
        color: FlightColors.toRgba(color),
        onGround: f.onGround,
      ));
    }

    mc.updateFlightPositions3D(renderData);

    // 선택된 비행기: 카메라 추적 + 실시간 정보 갱신
    if (_selectedFlight != null) {
      final state = _states[_selectedFlight!.icao24];
      if (state != null) {
        // 실시간 정보 업데이트 (속도계, 고도, 방향 등)
        _selectedFlight = state.position;
        mc.followTrain(state.currentLat, state.currentLng, state.position.heading);
        // UI 갱신은 200ms마다 (60fps → ~12fps로 쓰로틀)
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastUIUpdate > 200) {
          _lastUIUpdate = now;
          onStateChanged?.call();
        }
      }
    }
  }

  /// Smooth step (ease in-out)
  double _smoothStep(double t) {
    return t * t * (3 - 2 * t);
  }
}

/// 비행기 보간 상태 (지하철의 InterpolatedTrainPosition에 해당)
class _FlightState {
  FlightPosition position;
  double currentLat, currentLng, currentAlt;
  double prevLat, prevLng, prevAlt;
  double targetLat, targetLng, targetAlt;
  double interpProgress;
  int missCount; // API에서 연속 미감지 횟수

  _FlightState({
    required this.position,
    required this.currentLat,
    required this.currentLng,
    required this.currentAlt,
    required this.prevLat,
    required this.prevLng,
    required this.prevAlt,
    required this.targetLat,
    required this.targetLng,
    required this.targetAlt,
    this.interpProgress = 0.0,
    this.missCount = 0,
  });
}
