import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/adaptive/adaptive.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../core/map_interface.dart';
import '../core/api_keys.dart';
import '../map_engines/mapbox_engine.dart';
import '../models/subway_models.dart';
import '../widgets/subway_overlay.dart';
import '../widgets/bus_overlay.dart';
import '../widgets/flight_overlay.dart';
import '../services/flight_service.dart';
import '../models/bus_models.dart';
import '../services/seoul_bus_service.dart';
import '../widgets/weather_widget.dart';
import '../widgets/subway_panel.dart';
import '../widgets/search_bar.dart';
import '../services/place_search_service.dart';
import '../services/favorites_service.dart';
import '../services/directions_service.dart';
import '../services/visit_history_service.dart';
import '../data/seoul_subway_data.dart';
import '../services/device_profile_service.dart';
import '../services/settings_service.dart';
import 'sns_upload_view.dart';
import 'day_plan_view.dart';
import 'ai_view.dart';
import 'recommendation_view.dart';
import 'profile_view.dart';
import '../data/river_bus_data.dart';

import '../models/sns_content_models.dart';
import '../services/gemini_live_service.dart';
import '../services/gemini_service.dart';
import '../services/day_plan_service.dart';
import '../services/path_finding_service.dart';
import '../data/subway_geojson_loader.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_badge.dart';
import 'dart:math';

/// SeoulPrism 3D 지도 뷰 (SeoulPrism_Map 통합)
typedef MapView = DashboardScreen;

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const DashboardScreen({super.key, this.onProfileTap});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  IMapController? _mapController;
  bool _settingsOpen = false;
  bool _aiOpen = false;
  bool _aiClosing = false;
  bool _recommendOpen = false;
  bool _savedOpen = false;
  bool _hideButtonForPanel = false; // 패널 닫힌 후 버튼 딜레이용
  String _aiStatus = '';
  final GlobalKey<UnifiedSearchBarState> _searchBarKey = GlobalKey<UnifiedSearchBarState>();
  PlaceSearchResult? _selectedPlace;
  PlaceSearchResult? _lastSelectedPlace;
  RiverBusStop? _selectedRiverStop;
  RiverBusStop? _lastSelectedRiverStop;

  void _setSelectedPlace(PlaceSearchResult? place, {bool animate = true}) {
    if (place != null) {
      // 한강버스 패널 닫기
      _selectedRiverStop = null;
      // 같은 장소의 상세정보 업데이트면 그냥 교체
      if (_selectedPlace != null && _selectedPlace!.lat == place.lat && _selectedPlace!.lng == place.lng) {
        _lastSelectedPlace = place;
        _selectedPlace = place;
        return;
      }
      // 다른 장소인데 패널이 열려있으면 내리고 새 정보로 올리기
      if (_selectedPlace != null && animate) {
        _lastSelectedPlace = place;
        _selectedPlace = null;
        setState(() {});
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _selectedPlace = place;
            setState(() {});
          }
        });
        return;
      }
      _lastSelectedPlace = place;
    }
    _selectedPlace = place;
  }

  void _setSelectedRiverStop(RiverBusStop? stop) {
    if (stop != null) _lastSelectedRiverStop = stop;
    if (stop == null) {
      _mapController?.hideRiverBusHighlight();
    }
    _selectedRiverStop = stop;
  }
  bool _satelliteOn = false;
  List<DayPlan>? _dayPlans;

  final CameraInfo _cameraInfo = CameraInfo(
    lat: 37.5665, lng: 126.9780, zoom: 14.0, pitch: 50.0, bearing: -15.0,
  );

  // 지하철 오버레이 컨트롤러
  final SubwayOverlayController _subwayController = SubwayOverlayController();

  // 버스 오버레이 컨트롤러
  final BusOverlayController _busController = BusOverlayController();

  // 항공기 오버레이 컨트롤러
  final FlightOverlayController _flightController = FlightOverlayController();

  // 선택된 열차 정보
  InterpolatedTrainPosition? _selectedTrain;
  InterpolatedTrainPosition? _lastSelectedTrain;

  // 역 클릭 상세 패널
  String? _selectedMapStation;
  StationInfo? _selectedMapStationInfo;
  List<ArrivalInfo> _selectedMapStationArrivals = [];
  bool _mapStationLoading = false;
  // 길찾기 모드 / 검색 포커스 상태
  bool _isNavMode = false;
  bool _isSearchFocused = false;
  PathResult? _routeResult;         // 요약 바텀 패널용
  int _transportMode = 0; // 0: 대중교통, 1: 자동차, 2: 도보
  Map<int, DirectionsResult> _directionsCache = {};
  List<DirectionsResult> _transitRoutes = [];
  bool _directionsLoading = false;

  // 슬라이드아웃 애니메이션용
  String? _lastSelectedMapStation;
  StationInfo? _lastSelectedMapStationInfo;
  List<ArrivalInfo> _lastMapStationArrivals = [];

  @override
  void initState() {
    super.initState();
    _subwayController.onStateChanged = () {
      if (mounted) setState(() {});
    };
    _subwayController.onTrainSelected = (train) {
      if (mounted) {
        setState(() {
          _selectedTrain = train;
          if (train != null) _lastSelectedTrain = train;
        });
      }
    };
    _subwayController.onStationSelected = (name, info, arrivals, loading) {
      if (mounted) {
        setState(() {
          // 다른 패널 닫기
          if (name != null) {
            _setSelectedPlace(null);
            _removePlaceMarker();
            _setSelectedRiverStop(null);
            _busController.deselectVessel();
          }
          _selectedMapStation = name;
          _selectedMapStationInfo = info;
          _selectedMapStationArrivals = arrivals;
          _mapStationLoading = loading;
          if (name != null) {
            _lastSelectedMapStation = name;
            _lastSelectedMapStationInfo = info;
            _lastMapStationArrivals = arrivals;
          }
          if (name != null && !loading) {
            _lastMapStationArrivals = arrivals;
          }
        });
      }
    };

    // AI WebSocket 미리 연결 (탭 전환 시 렉 방지)
    Future.delayed(const Duration(seconds: 2), () {
      GeminiLiveService.instance.startSession();
    });
  }

  @override
  void dispose() {
    _subwayController.dispose();
    _busController.dispose();
    _flightController.dispose();
    super.dispose();
  }

  // ── 경로 지도 표시 ──

  int _routeAnimId = 0; // 애니메이션 취소용

  Future<void> _drawRouteOnMap(PathResult route) async {
    final mc = _mapController;
    if (mc == null) return;

    _clearRouteFromMap();
    final animId = ++_routeAnimId;

    // GeoJSON 선로 좌표 로드
    final geojsonRoutes = await SubwayGeoJsonLoader.load();

    // 전체 구간 좌표 미리 계산
    final segmentData = <({List<List<double>> coords, Color color, StationInfo first, StationInfo last})>[];
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

    for (final segment in route.segments) {
      if (segment.isTransfer || segment.stations.length < 2) continue;
      final firstStn = SeoulSubwayData.findStation(segment.stations.first);
      final lastStn = SeoulSubwayData.findStation(segment.stations.last);
      if (firstStn == null || lastStn == null) continue;

      final lineCoords = geojsonRoutes[segment.lineId];
      List<List<double>> segCoords;
      if (lineCoords != null && lineCoords.length >= 2) {
        segCoords = _extractSegmentFromRoute(lineCoords, firstStn, lastStn);
      } else {
        segCoords = segment.stations
            .map((n) => SeoulSubwayData.findStation(n))
            .where((s) => s != null)
            .map((s) => [s!.lat, s.lng])
            .toList();
      }
      if (segCoords.length < 2) continue;

      final color = SubwayColors.lineColors[segment.lineId] ?? AppColors.accent;
      segmentData.add((coords: segCoords, color: color, first: firstStn, last: lastStn));

      for (final c in segCoords) {
        if (c[0] < minLat) minLat = c[0];
        if (c[0] > maxLat) maxLat = c[0];
        if (c[1] < minLng) minLng = c[1];
        if (c[1] > maxLng) maxLng = c[1];
      }
    }

    if (segmentData.isEmpty) return;

    // 카메라 이동 — 경로 방향에 맞춘 bearing + 적응 zoom
    if (minLat < maxLat && minLng < maxLng) {
      // 출발→도착 bearing 계산
      final depInfo0 = SeoulSubwayData.findStation(route.departure);
      final arrInfo0 = SeoulSubwayData.findStation(route.arrival);
      double bearing = 0;
      if (depInfo0 != null && arrInfo0 != null) {
        final dLng = (arrInfo0.lng - depInfo0.lng) * pi / 180;
        final lat1 = depInfo0.lat * pi / 180;
        final lat2 = arrInfo0.lat * pi / 180;
        final y = sin(dLng) * cos(lat2);
        final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
        bearing = (atan2(y, x) * 180 / pi + 360) % 360;
      }
      // 바텀 패널이 하단을 가리므로 중심을 살짝 아래로 (위도 -20%)
      final latSpan = maxLat - minLat;
      final centerLat = (minLat + maxLat) / 2 - latSpan * 0.1;
      final centerLng = (minLng + maxLng) / 2;
      final span = max(latSpan, maxLng - minLng);
      final zoom = span > 0.3 ? 10.0 : span > 0.15 ? 11.0 : span > 0.08 ? 12.0 : 13.0;
      mc.moveTo(centerLat, centerLng, zoom: zoom, pitch: 45, bearing: bearing);
    }

    // 출발 마커 (먼저 표시)
    final depInfo = SeoulSubwayData.findStation(route.departure);
    if (depInfo != null) {
      mc.addCircleMarker('route_dep', depInfo.lat, depInfo.lng,
        color: AppColors.success, radius: 12, strokeColor: AppColors.textPrimary, strokeWidth: 4);
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (_routeAnimId != animId) return;

    // 구간별 순차 애니메이션 — 부드럽게
    for (int s = 0; s < segmentData.length; s++) {
      if (_routeAnimId != animId) return;
      final seg = segmentData[s];

      mc.addCircleMarker('route_mk_${s}_s', seg.first.lat, seg.first.lng,
        color: seg.color, radius: 8, strokeColor: Colors.white, strokeWidth: 3);

      // 외곽선 (어두운 테두리 — 밝은 지도에서도 보이도록)
      await mc.addPolyline('route_outline_$s', seg.coords,
        color: Colors.black.withValues(alpha: 0.4), width: 8.0, opacity: 1.0);

      final totalPoints = seg.coords.length;
      final step = max(1, totalPoints ~/ 12);

      for (int i = step; i <= totalPoints; i += step) {
        if (_routeAnimId != animId) return;
        final partial = seg.coords.sublist(0, min(i, totalPoints));
        if (partial.length >= 2) {
          mc.removePolyline('route_seg_$s');
          await mc.addPolyline('route_seg_$s', partial,
            color: seg.color, width: 5.0, opacity: 1.0);
        }
        await Future.delayed(const Duration(milliseconds: 80));
      }

      if (_routeAnimId != animId) return;
      mc.removePolyline('route_seg_$s');
      await mc.addPolyline('route_seg_$s', seg.coords,
        color: seg.color, width: 5.0, opacity: 1.0);

      mc.addCircleMarker('route_mk_${s}_e', seg.last.lat, seg.last.lng,
        color: seg.color, radius: 8, strokeColor: Colors.white, strokeWidth: 3);

      if (s < segmentData.length - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    // 화살표 마커 — 모든 구간의 화살표를 한 번에 생성
    if (_routeAnimId != animId) return;
    final allArrows = <Map<String, dynamic>>[];
    for (final seg in segmentData) {
      _collectArrows(allArrows, seg.coords, seg.color);
    }
    await mc.updateRouteArrows(allArrows);

    // 도착 마커 (마지막에 표시)
    if (_routeAnimId != animId) return;
    final arrInfo = SeoulSubwayData.findStation(route.arrival);
    if (arrInfo != null) {
      mc.addCircleMarker('route_arr', arrInfo.lat, arrInfo.lng,
        color: AppColors.danger, radius: 12, strokeColor: AppColors.textPrimary, strokeWidth: 4);
    }
  }

  /// GeoJSON 선로 좌표에서 두 역 사이 구간만 추출
  List<List<double>> _extractSegmentFromRoute(
    List<List<double>> routeCoords,
    StationInfo startStation,
    StationInfo endStation,
  ) {
    // 선로 좌표에서 각 역에 가장 가까운 인덱스 찾기
    int startIdx = _findClosestIndex(routeCoords, startStation.lat, startStation.lng);
    int endIdx = _findClosestIndex(routeCoords, endStation.lat, endStation.lng);

    if (startIdx == endIdx) return [[startStation.lat, startStation.lng], [endStation.lat, endStation.lng]];

    // 방향 보정 (startIdx가 endIdx보다 뒤에 있을 수 있음)
    if (startIdx > endIdx) {
      final temp = startIdx;
      startIdx = endIdx;
      endIdx = temp;
    }

    return routeCoords.sublist(startIdx, endIdx + 1);
  }

  int _findClosestIndex(List<List<double>> coords, double lat, double lng) {
    int bestIdx = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < coords.length; i++) {
      final dLat = coords[i][0] - lat;
      final dLng = coords[i][1] - lng;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  void _clearRouteFromMap() {
    final mc = _mapController;
    if (mc == null) return;
    mc.clearPolylines();
    mc.clearCircleMarkers();
    mc.clearRouteArrows();
  }

  /// 경로를 따라 화살표 데이터를 수집
  void _collectArrows(List<Map<String, dynamic>> arrows, List<List<double>> coords, Color color) {
    if (coords.length < 2) return;

    final colorStr = 'rgba(${(color.r * 255).round()},${(color.g * 255).round()},${(color.b * 255).round()},1)';
    const intervalDeg = 0.0012; // 약 130m 간격
    double accumulated = 0;

    for (int i = 1; i < coords.length; i++) {
      final dLat = coords[i][0] - coords[i - 1][0];
      final dLng = coords[i][1] - coords[i - 1][1];
      final dist = sqrt(dLat * dLat + dLng * dLng);
      accumulated += dist;

      if (accumulated >= intervalDeg) {
        accumulated = 0;
        final bearing = (atan2(dLng, dLat) * 180 / pi + 360) % 360;
        arrows.add({
          'lat': coords[i][0],
          'lng': coords[i][1],
          'bearing': bearing - 90, // ▶ 보정
          'color': colorStr,
        });
      }
    }
  }

  bool _profileShown = false;
  bool _showProfileToast = false;

  void _onMapCreated(IMapController controller) {
    _mapController = controller;
    _subwayController.attachMap(controller);
    _busController.attachMap(controller);
    _busController.onStateChanged = () {
      if (mounted) setState(() {});
    };
    _busController.onBusSelected = (bus, route) {
      if (mounted) setState(() {});
    };
    _busController.onVesselSelected = (vessel) {
      if (mounted) {
        _setSelectedPlace(null);
        _removePlaceMarker();
        _setSelectedRiverStop(null);
        _subwayController.deselectTrain();
        _subwayController.deselectStation();
        _busController.deselectBus();
        _flightController.deselectFlight();
        _mapController?.moveTo(vessel.lat, vessel.lng, zoom: 16.0, pitch: 50.0);
        _mapController?.showRiverBusHighlight(vessel.lat, vessel.lng);
        setState(() {});
      }
    };
    _flightController.attachMap(controller);
    _flightController.onStateChanged = () {
      if (mounted) setState(() {});
    };
    _flightController.onFlightSelected = (_) {
      if (mounted) {
        _setSelectedPlace(null);
        _removePlaceMarker();
        _setSelectedRiverStop(null);
        _busController.deselectVessel();
        setState(() {});
      }
    };
    // 맵 탭 시 키보드 내림 + 선택 해제
    controller.setOnAnyMapTap(() {
      FocusManager.instance.primaryFocus?.unfocus();
      if (_busController.selectedBus != null) {
        _busController.deselectBus();
        setState(() {});
      }
      if (_flightController.selectedFlight != null) {
        _flightController.deselectFlight();
        setState(() {});
      }
      if (_busController.selectedVessel != null) {
        _busController.deselectVessel();
        setState(() {});
      }
      if (_selectedPlace != null) {
        _removePlaceMarker();
        setState(() => _setSelectedPlace(null));
      }
      if (_selectedRiverStop != null && !_riverStopJustOpened) {
        setState(() => _setSelectedRiverStop(null));
      }
    });
    // POI 탭 콜백 (지도 위 장소 아이콘 클릭 시 → 카카오에서 상세정보 가져오기)
    controller.setOnPoiTapped((name, lat, lng) {
      // 한강버스 기본 POI만 무시 (선착장이 아닌 다른 곳의 "선착장"은 허용)
      if (name == '한강버스') return;

      // 모든 다른 패널 닫기
      _subwayController.deselectTrain();
      _subwayController.deselectStation();
      _busController.deselectBus();
      _busController.deselectVessel();
      _flightController.deselectFlight();
      _mapController?.hideRiverBusHighlight();
      _setSelectedRiverStop(null);

      final basicPlace = PlaceSearchResult(
        name: name, address: '', category: '장소', lat: lat, lng: lng,
      );
      _showPlaceMarker(basicPlace);
      setState(() => _setSelectedPlace(null));

      // 방문 기록 저장
      VisitHistoryService.instance.recordVisit(name, '장소', lat, lng);

      // 카카오 API 완료 후 패널 표시
      PlaceSearchService.instance.search(name).then((results) {
        if (!mounted) return;
        PlaceSearchResult? best;
        double bestDist = double.infinity;
        for (final r in results) {
          final d = (r.lat - lat).abs() + (r.lng - lng).abs();
          if (d < bestDist) {
            bestDist = d;
            best = r;
          }
        }
        setState(() => _setSelectedPlace(best ?? basicPlace));
      });
    });


    // 한강버스 선착장 좌표 탭 감지
    controller.setOnMapCoordTapped((lat, lng) {
      for (final stop in RiverBusData.stops) {
        final dLat = (stop.lat - lat).abs();
        final dLng = (stop.lng - lng).abs();
        if (dLat < 0.001 && dLng < 0.001) {
          if (_selectedPlace != null) {
            _removePlaceMarker();
            _setSelectedPlace(null);
          }
          _showRiverBusStopPanel(stop);
          // 빈 곳 처리 스킵하도록 — 플래그는 엔진에서
          return;
        }
      }
    });

    // 자동으로 데모 모드 시작
    if (!_subwayController.isActive) {
      _subwayController.start();
    }
    // 항공기 자동 시작
    _flightController.start();
    // 한강 한강버스 자동 시작
    _busController.start();
    // 현재 위치 3D 아바타 활성화
    controller.enableLocationPuck();
    // 기기 프로필 안내 (최초 1회, 페이드 토스트)
    if (!_profileShown) {
      _profileShown = true;
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() => _showProfileToast = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showProfileToast = false);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 65;
    final screenHeight = MediaQuery.of(context).size.height;
    final stationPanelMaxHeight = screenHeight * 0.3;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: (_routeResult != null && _isNavMode) ? null : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI 상태 텍스트 (탭바 바로 위)
          if (_aiOpen && _aiStatus.isNotEmpty)
            _buildAiStatusBar(),
          _buildBottomTabBar(),
        ],
      ),
      body: AnimatedScale(
        scale: (_aiOpen && !_aiClosing) ? 0.995 : 1.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        child: Stack(
        children: [
          // 지도 엔진 (항상 렌더링)
          Positioned.fill(child: MapboxEngine(initialCamera: _cameraInfo, onMapCreated: _onMapCreated)),

          // 검색바 + 길찾기 + 프로필 (상단, 리퀴드 글라스)
          UnifiedSearchBar(
            key: _searchBarKey,
            onStationSelected: (name) {
              _subwayController.selectStation(name);
            },
            onPlaceSelected: (place) {
              // 장소 선택 시 지도 카메라 이동 + 마커 + 상세 패널
              _mapController?.moveTo(place.lat, place.lng, zoom: 16.0);
              _showPlaceMarker(place);
              setState(() => _setSelectedPlace(place));
            },
            onBusSelected: (route) {
              // 버스 노선 선택 시 추적 시작
              _busController.addRoute(route);
              setState(() {});
            },
            onRiverBusStopSelected: (stop) {
              // 한강버스 선착장 선택 시 카메라 이동 + 상세 패널
              _mapController?.moveTo(stop.lat, stop.lng, zoom: 16.0);
              _showRiverBusStopPanel(stop);
            },
            onRouteFound: (route) {
              _drawRouteOnMap(route);
              setState(() {
                _routeResult = route;
                _transportMode = 0;
                _directionsCache.clear();
              });
              // 다른 모드도 백그라운드로 로드
              _preloadDirections();
            },
            onNavModeChanged: (isNav) {
              setState(() {
                _isNavMode = isNav;
                if (!isNav) _routeResult = null;
              });
              if (!isNav) _clearRouteFromMap();
            },
            onFocusChanged: (focused) {
              setState(() => _isSearchFocused = focused);
            },
            onProfileTap: () => _openProfile(),
          ),

          // 날씨/시간 위젯 (검색바 아래 좌측, 패널/검색/길찾기 시 페이드아웃)
          if (_subwayController.isActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 62,
              left: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                opacity: (_isNavMode || _isSearchFocused || _settingsOpen || _recommendOpen) ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: _isNavMode || _isSearchFocused || _settingsOpen || _recommendOpen,
                  child: WeatherTimeWidget(environment: _subwayController.environment),
                ),
              ),
            ),

          // 위성지도 토글 버튼 (우상단)
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: (_isNavMode || _isSearchFocused || _settingsOpen || _recommendOpen) ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _isNavMode || _isSearchFocused || _settingsOpen || _recommendOpen,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: AdaptiveGlassIconButton(
                    key: ValueKey(_satelliteOn),
                    icon: _satelliteOn ? Icons.map_outlined : Icons.travel_explore,
                    size: 44,
                    iconSize: 20,
                    tint: _satelliteOn ? Colors.greenAccent : Theme.of(context).colorScheme.onSurfaceVariant,
                    onPressed: () {
                      setState(() => _satelliteOn = !_satelliteOn);
                      _mapController?.setSatelliteVisible(_satelliteOn);
                    },
                  ),
                ),
              ),
            ),
          ),

          // 내 위치 버튼 (우측 하단, Mapbox 어트리뷰션 위)
          Positioned(
            bottom: bottomInset + 60,
            right: 6,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: (_isNavMode || _selectedTrain != null || _selectedMapStation != null || _hideButtonForPanel) ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _isNavMode || _selectedTrain != null || _selectedMapStation != null || _hideButtonForPanel,
                child: AdaptiveGlassIconButton(
                  icon: Icons.my_location,
                  size: 48,
                  iconSize: 22,
                  tint: const Color(0xFF4A90D9),
                  onPressed: () {
                    _mapController?.moveToCurrentLocation();
                  },
                ),
              ),
            ),
          ),

          // 열차 상세 패널 (바텀 슬라이드 애니메이션)
          if (_lastSelectedTrain != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: _selectedTrain != null ? Curves.easeOutCubic : Curves.easeInCubic,
              bottom: _selectedTrain != null ? bottomInset : -280,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _selectedTrain != null ? 1.0 : 0.0,
                child: TrainDetailPanel(
                  train: (_selectedTrain ?? _lastSelectedTrain)!,
                  delayMinutes: _subwayController.trainDelays[(_selectedTrain ?? _lastSelectedTrain)!.trainNo] ?? 0,
                  onClose: () {
                    _subwayController.deselectTrain();
                  },
                ),
              ),
            ),

          // 버스 상세 패널 (바텀 슬라이드)
          if (_busController.selectedBus != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              bottom: bottomInset,
              left: 0,
              right: 0,
              child: _buildBusDetailPanel(),
            ),

          // 비행기 상세 패널 (바텀 슬라이드)
          if (_flightController.selectedFlight != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              bottom: bottomInset,
              left: 0,
              right: 0,
              child: _buildFlightDetailPanel(),
            ),

          // 한강버스 상세 패널 (슬라이드 애니메이션)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: _busController.selectedVessel != null ? Curves.easeOutCubic : Curves.easeInCubic,
            bottom: _busController.selectedVessel != null ? bottomInset : -250,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: _busController.selectedVessel != null ? 1.0 : 0.0,
              child: _buildVesselDetailPanel(),
            ),
          ),

          // 역 상세 패널 (바텀 슬라이드 — 화면 30% 제한)
          if (_lastSelectedMapStation != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: _selectedMapStation != null ? Curves.easeOutCubic : Curves.easeInCubic,
              bottom: _selectedMapStation != null ? bottomInset : -(stationPanelMaxHeight + 50),
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _selectedMapStation != null ? 1.0 : 0.0,
                child: ClipRect(
                  child: SizedBox(
                    height: stationPanelMaxHeight,
                    child: StationDetailPanel(
                    stationName: (_selectedMapStation ?? _lastSelectedMapStation)!,
                    stationInfo: _selectedMapStation != null ? _selectedMapStationInfo : _lastSelectedMapStationInfo,
                    arrivals: _selectedMapStation != null ? _selectedMapStationArrivals : _lastMapStationArrivals,
                    isLoading: _mapStationLoading,
                    onClose: () {
                      _subwayController.deselectStation();
                    },
                    onSetDeparture: (name) {
                      _subwayController.deselectStation();
                      _startNavWithDeparture(name);
                    },
                    onSetArrival: (name) {
                      _subwayController.deselectStation();
                      _startNavWithArrival(name);
                    },
                  ),
                ),
                ),
              ),
            ),

          // 장소 상세 패널 (바텀 슬라이드 애니메이션)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: _selectedPlace != null ? Curves.easeOutCubic : Curves.easeInCubic,
            bottom: _selectedPlace != null ? bottomInset : -250,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: _selectedPlace != null ? 1.0 : 0.0,
              child: _lastSelectedPlace != null
                  ? _buildPlaceDetailPanel((_selectedPlace ?? _lastSelectedPlace)!)
                  : const SizedBox(height: 200),
            ),
          ),

          // 한강버스 선착장 패널 (바텀 슬라이드 애니메이션)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: _selectedRiverStop != null ? Curves.easeOutCubic : Curves.easeInCubic,
            bottom: _selectedRiverStop != null ? bottomInset : -250,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: _selectedRiverStop != null ? 1.0 : 0.0,
              child: _lastSelectedRiverStop != null
                  ? _buildRiverBusStopPanel((_selectedRiverStop ?? _lastSelectedRiverStop)!)
                  : const SizedBox(height: 200),
            ),
          ),

          // 경로 결과 바텀 패널 (설정 패널 스타일)
          _buildRouteResultOverlay(context, screenHeight),

          // 설정 패널 오버레이 (바텀시트 스타일)
          _buildSettingsOverlay(context, screenHeight, bottomInset),

          // 하루 플랜 오버레이 (지도 위 바텀 패널)
          _buildDayPlanOverlay(context, bottomInset),

          // 추천 패널 오버레이 (바텀시트 스타일, 설정 패널과 동일)
          _buildRecommendOverlay(context, screenHeight),

          // 저장 패널 오버레이 (바텀시트)
          _buildSavedOverlay(context, screenHeight),

          // 통합 AI 오버레이 (풀스크린 Glow + Gemini Live)
          if (_aiOpen)
            Positioned.fill(
              child: AiView(
                closing: _aiClosing,
                onClose: () => setState(() {
                  _aiOpen = false;
                  _aiClosing = false;
                  _aiStatus = '';
                }),
                onAction: _handleAiAction,
                onStatusChanged: (status) {
                  if (mounted) setState(() => _aiStatus = status);
                },
              ),
            ),

          // 기기 프로필 토스트 (페이드인/아웃)
          _buildProfileToast(),
        ],
      ),
      ),
    );
  }


  Widget _buildBusDetailPanel() {
    final bus = _busController.selectedBus;
    final route = _busController.selectedBusRoute;
    if (bus == null || route == null) return const SizedBox.shrink();

    final color = route.color;
    final congestionText = switch (bus.congestion) {
      0 => '정보없음',
      1 => '여유',
      2 => '여유',
      3 => '보통',
      4 => '혼잡',
      5 => '매우혼잡',
      6 => '만차',
      _ => '정보없음',
    };
    final congestionColor = switch (bus.congestion) {
      1 || 2 => AppColors.success,
      3 => AppColors.warning,
      4 || 5 => AppColors.danger,
      6 => const Color(0xFF8B0000),
      _ => AppColors.textMuted,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: const Center(child: Icon(Icons.directions_bus, size: 20, color: Colors.white)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(route.routeName, style: AppTypography.titleMd.copyWith(color: color)),
                        Text(
                          '${bus.plainNo} · ${bus.busType == 1 ? "저상버스" : "일반버스"}',
                          style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () { _busController.deselectBus(); setState(() {}); },
                    child: Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            // 정보
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // 혼잡도
                  Expanded(child: _busInfoItem('혼잡도', congestionText, congestionColor)),
                  // 상태
                  Expanded(child: _busInfoItem('상태', bus.stopFlag == 1 ? '정차 중' : '운행 중', color)),
                  // 구간
                  if (bus.sectOrd != null)
                    Expanded(child: _busInfoItem('구간', '${bus.sectOrd}번째', AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _busInfoItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.bodySm.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFlightDetailPanel() {
    final flight = _flightController.selectedFlight;
    if (flight == null) return const SizedBox.shrink();

    final phaseColor = switch (flight.phase) {
      '상승' => const Color(0xFF00E676),
      '순항' => Colors.white,
      '하강' => const Color(0xFFFF9100),
      '이착륙' => const Color(0xFFFF5252),
      '지상' => Colors.grey,
      _ => Colors.white,
    };

    final altText = flight.onGround ? '지상' : '${(flight.altitude / 1000).toStringAsFixed(1)}km';
    final speedText = '${(flight.velocity * 3.6).round()}km/h';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: phaseColor.withValues(alpha: 0.4), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: phaseColor.withValues(alpha: 0.12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: phaseColor.withValues(alpha: 0.3), shape: BoxShape.circle),
                    child: Center(child: Icon(Icons.flight, size: 20, color: phaseColor)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flight.callsign.isNotEmpty ? flight.callsign : flight.icao24,
                          style: AppTypography.titleMd.copyWith(color: phaseColor),
                        ),
                        Text(
                          '${flight.airline} · ${flight.originCountry}',
                          style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () { _flightController.deselectFlight(); setState(() {}); },
                    child: Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            // 정보
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(child: _busInfoItem('상태', flight.phase, phaseColor)),
                  Expanded(child: _busInfoItem('고도', altText, AppColors.textSecondary)),
                  Expanded(child: _busInfoItem('속도', speedText, AppColors.textSecondary)),
                  Expanded(child: _busInfoItem('방향', '${flight.heading.round()}°', AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  RiverBusVessel? _lastVessel;

  Widget _buildVesselDetailPanel() {
    final v = _busController.selectedVessel;
    if (v != null) _lastVessel = v;
    final display = v ?? _lastVessel;
    if (display == null) return const SizedBox(height: 150);

    const color = Color(0xFF00ACC1);
    final dirText = display.direction == 0 ? '정방향' : '역방향';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12)),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.3), shape: BoxShape.circle),
                    child: const Center(child: Icon(Icons.directions_boat, size: 20, color: color)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('한강버스 ${display.routeName}', style: AppTypography.titleMd.copyWith(color: color)),
                        Text('$dirText · ${display.phase}', style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () { _busController.deselectVessel(); setState(() {}); },
                    child: Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(child: _busInfoItem(
                    display.phase == '정차' ? '정차 중' : '다음',
                    display.currentStopName ?? display.nextStopName,
                    color,
                  )),
                  Expanded(child: _busInfoItem('진행', '${(display.progress * 100).round()}%', AppColors.textSecondary)),
                  Expanded(child: _busInfoItem('상태', display.phase, display.phase == '정차' ? AppColors.warning : color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileToast() {
    final dp = DeviceProfileService.instance;
    final tierLabel = switch (dp.profile.tier) {
      DeviceTier.flagship => '플래그십',
      DeviceTier.high => '상위',
      DeviceTier.mid => '중급',
      DeviceTier.low => '저사양',
    };

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 80,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          opacity: _showProfileToast ? 1.0 : 0.0,
          child: Center(
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark
                        ? null
                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                  ),
                  child: Text(
                    '${dp.rawModel} · $tierLabel\n'
                    '${dp.profile.animFps}fps · 폴링 ${dp.profile.naverPollMs}ms 최적화 적용',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFBC82F3).withValues(alpha: 0.2),
            const Color(0xFF8D9FFF).withValues(alpha: 0.15),
            const Color(0xFFF5B9EA).withValues(alpha: 0.1),
          ],
        ),
        border: Border(top: BorderSide(color: const Color(0xFFBC82F3).withValues(alpha: 0.4))),
      ),
      child: _AiStatusText(text: _aiStatus),
    );
  }

  void _dismissAi() {
    if (_aiOpen && !_aiClosing) {
      setState(() => _aiClosing = true);
    }
  }

  void _delayShowButton() {
    // 패널 닫힌 후 0.5초 뒤에 버튼 표시
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_settingsOpen && !_recommendOpen) {
        setState(() => _hideButtonForPanel = false);
      }
    });
  }

  void _showPlaceMarker(PlaceSearchResult place) {
    _mapController?.showPlacePin(place.lat, place.lng, label: place.name);
  }

  void _removePlaceMarker() {
    _mapController?.removePlacePin();
  }

  Future<void> _openProfile() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ProfileView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (result != null && mounted) {
      final lat = result['lat'] as double?;
      final lng = result['lng'] as double?;
      final name = result['name'] as String? ?? '';
      if (lat != null && lng != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          _mapController?.moveTo(lat, lng, zoom: 16.0);
          // 장소 패널도 표시
          final place = PlaceSearchResult(
            name: name, address: '', category: '저장된 장소', lat: lat, lng: lng,
          );
          _showPlaceMarker(place);
          setState(() => _setSelectedPlace(place));
          // 카카오에서 상세정보 가져오기
          PlaceSearchService.instance.search(name).then((results) {
            if (!mounted || _selectedPlace?.name != name) return;
            PlaceSearchResult? best;
            double bestDist = double.infinity;
            for (final r in results) {
              final d = (r.lat - lat).abs() + (r.lng - lng).abs();
              if (d < bestDist) { bestDist = d; best = r; }
            }
            if (best != null) setState(() => _setSelectedPlace(best));
          });
        });
      }
    }
  }

  bool _riverStopJustOpened = false;

  void _showRiverBusStopPanel(RiverBusStop stop) {
    _riverStopJustOpened = true;
    Future.delayed(const Duration(milliseconds: 100), () => _riverStopJustOpened = false);
    _mapController?.moveTo(stop.lat, stop.lng, zoom: 16.0, pitch: 50.0);
    // 바닥 glow 효과 (한강버스 전용)
    _mapController?.showRiverBusHighlight(stop.lat, stop.lng);
    setState(() {
      _setSelectedRiverStop(stop);
      _setSelectedPlace(null);
      _removePlaceMarker();
    });
  }

  Widget _buildRiverBusStopPanel(RiverBusStop stop) {
    final cs = Theme.of(context).colorScheme;
    // 이 선착장을 지나는 노선 찾기
    final routes = RiverBusData.routes.where((r) => r.stopIds.contains(stop.id)).toList();
    // 다음 운항 시간 계산
    final now = DateTime.now();
    final currentMin = now.hour * 60 + now.minute;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00ACC1).withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: const Color(0xFF00ACC1).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.directions_boat, size: 18, color: Color(0xFF00ACC1)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${stop.name} 선착장', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: cs.onSurface)),
                    Text(stop.address, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                )),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
                  onPressed: () => setState(() => _setSelectedRiverStop(null)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 노선 정보
            ...routes.map((r) {
              final isActive = r.isActive;
              String nextTime = '운항 종료';
              if (isActive) {
                for (int dep = r.firstDeparture; dep <= r.lastDeparture; dep += r.intervalMin) {
                  if (dep > currentMin) {
                    final h = dep ~/ 60;
                    final m = dep % 60;
                    nextTime = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
                    break;
                  }
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(r.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(r.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(r.color))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.displayName, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
                    Text(
                      isActive ? '다음 $nextTime' : '정비 중',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF00ACC1) : cs.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            // 출발/도착 버튼
            Row(
              children: [
                _placeActionButton(icon: Icons.trip_origin, label: '출발', color: cs.primary, onTap: () {
                  setState(() => _setSelectedRiverStop(null));
                  _startNavWithDeparture('${stop.name} 선착장');
                }),
                const SizedBox(width: 8),
                _placeActionButton(icon: Icons.place, label: '도착', color: Colors.redAccent, onTap: () {
                  setState(() => _setSelectedRiverStop(null));
                  _startNavWithArrival('${stop.name} 선착장');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportModeBar(Color onSurface) {
    final modes = [
      (Icons.directions_transit, '대중교통', 0),
      (Icons.directions_car, '자동차', 1),
      (Icons.directions_walk, '도보', 2),
    ];

    return Row(
      children: modes.map((m) {
        final selected = _transportMode == m.$3;
        final hasResult = m.$3 == 0 || _directionsCache.containsKey(m.$3);
        final timeStr = m.$3 == 0
            ? null
            : _directionsCache[m.$3] != null
                ? _formatDurationShort(_directionsCache[m.$3]!.durationSec)
                : null;

        return Expanded(
          child: GestureDetector(
            onTap: () => _switchTransportMode(m.$3),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: selected ? onSurface.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m.$1, size: 18, color: selected ? onSurface : onSurface.withValues(alpha: 0.4)),
                  if (timeStr != null)
                    Text(timeStr, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: selected ? onSurface : onSurface.withValues(alpha: 0.4)))
                  else if (m.$3 != 0 && !hasResult)
                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1, color: onSurface.withValues(alpha: 0.3)))
                  else
                    Text(m.$2, style: TextStyle(fontSize: 9, color: selected ? onSurface : onSurface.withValues(alpha: 0.4))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDuration(int sec) {
    final min = sec ~/ 60;
    final hr = min ~/ 60;
    return hr > 0 ? '${hr}시간 ${min % 60}분' : '$min분';
  }

  String _formatDurationShort(int sec) {
    final min = sec ~/ 60;
    final hr = min ~/ 60;
    return hr > 0 ? '${hr}h${min % 60}m' : '${min}분';
  }

  Future<void> _preloadDirections() async {
    if (_routeResult == null) return;
    final dep = _routeResult!.departure;
    final arr = _routeResult!.arrival;
    final fromCoord = _resolveStationCoord(dep);
    final toCoord = _resolveStationCoord(arr);
    if (fromCoord == null || toCoord == null) return;

    final ds = DirectionsService.instance;
    // 대중교통 (TMAP — 지하철+버스+도보 통합)
    ds.getTransitRoutes(fromCoord[0], fromCoord[1], toCoord[0], toCoord[1]).then((routes) {
      if (mounted && routes.isNotEmpty) {
        setState(() {
          _transitRoutes = routes;
          _directionsCache[0] = routes.first;
        });
      }
    });
    // 자동차
    ds.getDrivingRoute(fromCoord[0], fromCoord[1], toCoord[0], toCoord[1]).then((r) {
      if (r != null && mounted) setState(() => _directionsCache[1] = r);
    });
    // 도보
    ds.getWalkingRoute(fromCoord[0], fromCoord[1], toCoord[0], toCoord[1]).then((r) {
      if (r != null && mounted) setState(() => _directionsCache[2] = r);
    });
  }

  List<double>? _resolveStationCoord(String name) {
    if (name == '내 위치') return null; // 비동기라 여기서 못 함
    // 지하철역
    for (final e in SubwayColors.lineColors.entries) {
      for (final s in SeoulSubwayData.getLineStations(e.key)) {
        if (s.name == name) return [s.lat, s.lng];
      }
    }
    // 한강버스 선착장
    for (final s in RiverBusData.stops) {
      if (name.contains(s.name)) return [s.lat, s.lng];
    }
    return null;
  }

  void _switchTransportMode(int mode) {
    setState(() => _transportMode = mode);
    _clearRouteFromMap();
    if (mode == 0) {
      // 대중교통 — TMAP 결과가 있으면 사용, 없으면 기존 지하철
      final transit = _directionsCache[0];
      if (transit != null && transit.legs.isNotEmpty) {
        _drawTransitOnMap(transit);
      } else if (_routeResult != null) {
        _drawRouteOnMap(_routeResult!);
      }
    } else {
      final result = _directionsCache[mode];
      if (result != null) _drawDirectionsOnMap(result);
    }
  }

  void _drawTransitOnMap(DirectionsResult result) {
    _clearRouteFromMap();
    for (int i = 0; i < result.legs.length; i++) {
      final leg = result.legs[i];
      if (leg.coordinates.length < 2) continue;
      final color = leg.mode == 'WALK'
          ? Colors.grey
          : leg.color != null
              ? Color(leg.color!)
              : Colors.blue;
      _mapController?.addPolyline(
        'transit_leg_$i', leg.coordinates,
        color: color,
        width: leg.mode == 'WALK' ? 3.0 : 5.0,
        opacity: leg.mode == 'WALK' ? 0.5 : 0.8,
      );
    }
  }

  void _drawDirectionsOnMap(DirectionsResult result) {
    _clearRouteFromMap();
    final color = switch (result.mode) {
      TravelMode.walking => Colors.green,
      TravelMode.driving => Colors.blue,
      TravelMode.transit => Colors.purple,
    };
    // coordinates는 이미 [lat, lng]
    final coords = result.coordinates;
    _mapController?.addPolyline('directions_route', coords, color: color, width: 5.0, opacity: 0.8);
  }

  void _startNavWithDeparture(String name) {
    _searchBarKey.currentState?.enterNavWithDeparture(name);
  }

  void _startNavWithArrival(String name) {
    _searchBarKey.currentState?.enterNavWithArrival(name);
  }

  Widget _buildPlaceDetailPanel(PlaceSearchResult place) {
    final cs = Theme.of(context).colorScheme;
    final hasDetail = place.address.isNotEmpty;
    final hasDistance = place.distance != null && place.distance!.isNotEmpty;
    final hasPhone = place.phone != null && place.phone!.isNotEmpty;
    final hasUrl = place.placeUrl != null && place.placeUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: hasUrl ? () => _showPlaceWebView(place) : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: cs.onSurface)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (place.category.isNotEmpty)
                              Text(place.category, style: TextStyle(fontSize: 12, color: cs.primary)),
                            if (hasDistance) ...[
                              Text('  ·  ', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                              Text(_formatPlaceDistance(place.distance!), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      FavoritesService.instance.isFavorite(place.name) ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: FavoritesService.instance.isFavorite(place.name) ? Colors.redAccent : cs.onSurfaceVariant,
                    ),
                    onPressed: () async {
                      await FavoritesService.instance.toggle(FavoritePlace(
                        name: place.name,
                        address: place.address,
                        category: place.category,
                        lat: place.lat,
                        lng: place.lng,
                      ));
                      setState(() {});
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
                    onPressed: () => setState(() { _setSelectedPlace(null); _removePlaceMarker(); }),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              // 주소 + 전화
              if (hasDetail || hasPhone) ...[
                const SizedBox(height: 6),
                if (hasDetail)
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(child: Text(place.address, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                if (hasPhone) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse('tel:${place.phone}')),
                    child: Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(place.phone!, style: TextStyle(fontSize: 12, color: cs.primary)),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 12),

              // 액션 버튼
              Row(
                children: [
                  _placeActionButton(icon: Icons.trip_origin, label: '출발', color: cs.primary, onTap: () {
                    setState(() { _setSelectedPlace(null); _removePlaceMarker(); });
                    _startNavWithDeparture(place.name);
                  }),
                  const SizedBox(width: 8),
                  _placeActionButton(icon: Icons.place, label: '도착', color: Colors.redAccent, onTap: () {
                    setState(() { _setSelectedPlace(null); _removePlaceMarker(); });
                    _startNavWithArrival(place.name);
                  }),
                  const SizedBox(width: 8),
                  _placeActionButton(icon: Icons.info_outline, label: '정보', color: cs.tertiary, onTap: () {
                    if (hasUrl) _showPlaceWebView(place);
                  }),
                ],
              ),

              // 하단 힌트
              if (hasUrl)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text('탭하여 사진·리뷰·영업시간 보기', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaceWebView(PlaceSearchResult place) {
    final url = place.placeUrl!.replaceFirst('http://', 'https://');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false, // WebView 스크롤 충돌 방지
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final height = MediaQuery.of(ctx).size.height * 0.85;
        final hideHeaderJS = '''
          (function() {
            var style = document.createElement('style');
            style.textContent = `
              /* 상단 네비/헤더/탭바 전부 제거 */
              header, nav, .direct-link,
              [class*="Header"], [class*="header"],
              [class*="Gnb"], [class*="gnb"],
              [class*="TopBanner"], [class*="topBanner"],
              [class*="Navigation"], [class*="navigation"],
              [class*="floating"], [class*="Floating"],
              [class*="footer"], [class*="Footer"],
              [class*="banner"], [class*="Banner"],
              [class*="kakaonavi"], [class*="KakaoNavi"]
              {
                display: none !important;
              }
              /* sticky/fixed 요소 전부 static으로 */
              *[style*="position: fixed"],
              *[style*="position: sticky"],
              *[style*="position:fixed"],
              *[style*="position:sticky"] {
                position: static !important;
              }
              body, .container-doc, #app {
                padding-top: 0 !important;
                margin-top: 0 !important;
              }
            `;
            document.head.appendChild(style);

            /* JS로 fixed/sticky 요소도 강제 제거 */
            var all = document.querySelectorAll('*');
            for (var i = 0; i < all.length; i++) {
              var cs = getComputedStyle(all[i]);
              if (cs.position === 'fixed' || cs.position === 'sticky') {
                var tag = all[i].tagName.toLowerCase();
                var h = all[i].offsetHeight;
                /* 메인 콘텐츠(큰 영역)는 유지, 작은 바/헤더만 제거 */
                if (h < 120 && tag !== 'main' && tag !== 'section') {
                  all[i].style.display = 'none';
                } else {
                  all[i].style.position = 'static';
                }
              }
            }
          })();
        ''';

        late final WebViewController controller;
        controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1')
          ..setNavigationDelegate(NavigationDelegate(
            onPageFinished: (_) {
              controller.runJavaScript(hideHeaderJS);
              Future.delayed(const Duration(milliseconds: 800), () {
                controller.runJavaScript(hideHeaderJS);
              });
              Future.delayed(const Duration(seconds: 2), () {
                controller.runJavaScript(hideHeaderJS);
              });
            },
          ))
          ..loadRequest(Uri.parse(url));

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(child: Text(place.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface))),
                    IconButton(
                      icon: Icon(Icons.open_in_new, size: 20, color: cs.onSurfaceVariant),
                      onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
                child: WebViewWidget(controller: controller),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _placeActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPlaceDistance(String distance) {
    final m = int.tryParse(distance) ?? 0;
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)}km';
    return '${m}m';
  }

  /// AI가 보낸 역명으로 StationInfo 찾기
  /// "서울" → "서울역", "강남" → "강남" 등 유연하게 매칭
  StationInfo? _resolveStation(String name) {
    // 1) 정확히 매칭
    var station = SeoulSubwayData.findStation(name);
    if (station != null) return station;

    // 2) "역" 붙여서 매칭 (AI가 "서울"로 보내면 "서울역"으로)
    station = SeoulSubwayData.findStation('$name역');
    if (station != null) return station;

    // 3) "역" 떼고 매칭 ("서울역" → "서울")
    if (name.endsWith('역')) {
      station = SeoulSubwayData.findStation(name.substring(0, name.length - 1));
      if (station != null) return station;
    }

    return null;
  }

  /// AI Function Calling 액션 처리
  void _handleAiAction(AiActionEvent event) {
    switch (event.action) {
      case AiAction.navigateToStation:
        final stationName = event.params['stationName'] as String?;
        if (stationName != null) {
          final station = _resolveStation(stationName);
          if (station != null) {
            // AI 닫고 → 카메라 줌 이동 → 역 선택
            _dismissAi();
            Future.delayed(const Duration(milliseconds: 600), () {
              _mapController?.moveTo(station.lat, station.lng, zoom: 16, pitch: 50);
              // 카메라 이동 후 역 선택
              Future.delayed(const Duration(milliseconds: 800), () {
                _subwayController.selectStation(station.name);
              });
            });
          }
        }
        break;
      case AiAction.showStationInfo:
        final stationName = event.params['stationName'] as String?;
        if (stationName != null) {
          final station = _resolveStation(stationName);
          _dismissAi();
          Future.delayed(const Duration(milliseconds: 600), () {
            if (station != null) {
              _mapController?.moveTo(station.lat, station.lng, zoom: 15, pitch: 45);
            }
            _subwayController.selectStation(station?.name ?? stationName);
          });
        }
        break;
      case AiAction.analyzeUrl:
        // URL 분석 → 기존 GeminiService 활용
        final url = event.params['url'] as String?;
        if (url != null) {
          _analyzeUrlAndCreatePlan(url);
        }
        break;
      case AiAction.analyzeImage:
        // 이미지 분석은 AI View 내부에서 처리
        break;
      case AiAction.createPlan:
        final style = event.params['style'] as String? ?? 'efficient';
        final places = event.params['extractedPlaces'] as List<ExtractedPlace>?;
        if (places != null && places.isNotEmpty) {
          _createPlanFromPlaces(places);
        } else {
          _createPlanFromAi(style, event.params['places'] as String?);
        }
        break;
      case AiAction.searchPlace:
        final query = event.params['query'] as String?;
        if (query != null) {
          _dismissAi();
          Future.delayed(const Duration(milliseconds: 600), () {
            _searchBarKey.currentState?.performSearch(query);
          });
        }
        break;
      case AiAction.findRoute:
        final from = event.params['from'] as String?;
        final to = event.params['to'] as String?;
        _dismissAi();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (to != null) _startNavWithArrival(to);
        });
        break;
      case AiAction.toggleSatellite:
        setState(() => _satelliteOn = !_satelliteOn);
        _mapController?.setSatelliteVisible(_satelliteOn);
        break;
      case AiAction.addFavorite:
        if (_selectedPlace != null) {
          FavoritesService.instance.toggle(FavoritePlace(
            name: _selectedPlace!.name,
            address: _selectedPlace!.address,
            category: _selectedPlace!.category,
            lat: _selectedPlace!.lat,
            lng: _selectedPlace!.lng,
          ));
          setState(() {});
        }
        break;
      case AiAction.openRecommendation:
        _dismissAi();
        Future.delayed(const Duration(milliseconds: 600), () {
          setState(() { _recommendOpen = true; _hideButtonForPanel = true; });
        });
        break;
      case AiAction.openSaved:
        _dismissAi();
        Future.delayed(const Duration(milliseconds: 600), () {
          setState(() { _savedOpen = true; _hideButtonForPanel = true; });
        });
        break;
      case AiAction.moveToLocation:
        final lat = (event.params['lat'] as num?)?.toDouble();
        final lng = (event.params['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _dismissAi();
          Future.delayed(const Duration(milliseconds: 600), () {
            _mapController?.moveTo(lat, lng, zoom: 15.0);
          });
        }
        break;
      case AiAction.requestPhoto:
      case AiAction.addPlaces:
      case AiAction.removePlace:
      case AiAction.confirmPlan:
        break;
    }
  }

  /// URL 분석 후 플랜 생성
  Future<void> _analyzeUrlAndCreatePlan(String url) async {
    try {
      final result = await GeminiService.instance.analyzeContent(
        SnsContent(imagePaths: [], text: '', url: url),
      );
      if (result.places.isNotEmpty) {
        final geoPlaces = await GeminiService.instance.geocodeAll(result.places);
        final dayPlanService = DayPlanService.instance;
        final plans = await dayPlanService.generatePlans(geoPlaces);
        if (plans.isNotEmpty && mounted) {
          _dismissAi();
          Future.delayed(const Duration(milliseconds: 600), () {
            setState(() => _dayPlans = plans);
          });
        }
      }
    } catch (e) {
      debugPrint('[AI Action] URL 분석 실패: $e');
    }
  }

  /// 추출된 장소로 플랜 생성
  Future<void> _createPlanFromPlaces(List<ExtractedPlace> places) async {
    try {
      final plans = await DayPlanService.instance.generatePlans(places);
      if (plans.isNotEmpty && mounted) {
        _dismissAi();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _dayPlans = plans);
        });
      }
    } catch (e) {
      debugPrint('[AI Action] 플랜 생성 실패: $e');
    }
  }

  /// AI 요청으로 플랜 생성 (텍스트 기반)
  Future<void> _createPlanFromAi(String style, String? placesJson) async {
    debugPrint('[AI Action] Create plan: style=$style');
  }

  // ── 하단 탭바 (리퀴드 글라스) ──
  Widget _buildBottomTabBar() {
    // 순서: 추천(0) | 저장(1) | 지도(2, 가운데) | 설정(3) | AI(4)
    final currentIndex = _recommendOpen
        ? 0
        : _savedOpen
            ? 1
            : _settingsOpen
                ? 3
                : _aiOpen
                    ? 4
                    : 2;

    return AdaptiveTabBar(
      currentIndex: currentIndex,
      onTap: (index) {
        setState(() {
          if (index == 0) {
            // 추천
            _settingsOpen = false; _savedOpen = false;
            _dismissAi();
            if (_recommendOpen) { _recommendOpen = false; _delayShowButton(); }
            else { _recommendOpen = true; _hideButtonForPanel = true; }
          } else if (index == 1) {
            // 저장
            _settingsOpen = false; _recommendOpen = false;
            _dismissAi();
            if (_savedOpen) { _savedOpen = false; _delayShowButton(); }
            else { _savedOpen = true; _hideButtonForPanel = true; }
          } else if (index == 2) {
            // 지도
            final wasOpen = _settingsOpen || _recommendOpen || _savedOpen;
            _settingsOpen = false; _recommendOpen = false; _savedOpen = false;
            _dismissAi();
            if (wasOpen) _delayShowButton();
          } else if (index == 3) {
            // 설정
            _recommendOpen = false; _savedOpen = false;
            _dismissAi();
            if (_settingsOpen) { _settingsOpen = false; _delayShowButton(); }
            else { _settingsOpen = true; _hideButtonForPanel = true; }
          } else if (index == 4) {
            // AI
            final wasOpen = _settingsOpen || _recommendOpen || _savedOpen;
            _settingsOpen = false; _recommendOpen = false; _savedOpen = false;
            if (wasOpen) _delayShowButton();
            if (_aiOpen) { _dismissAi(); }
            else { _aiOpen = true; _aiClosing = false; }
          }
        });
      },
      items: const [
        AdaptiveTabItem(label: '추천', icon: Icons.explore),
        AdaptiveTabItem(label: '저장', icon: Icons.bookmark),
        AdaptiveTabItem(label: '지도', icon: Icons.map),
        AdaptiveTabItem(label: '설정', icon: Icons.settings),
        AdaptiveTabItem(label: 'AI', icon: Icons.auto_awesome),
      ],
    );
  }


  // ── 경로 결과 바텀 시트 (드래그로 요약↔상세 전환) ──
  Widget _buildRouteResultOverlay(BuildContext context, double screenHeight) {
    final hasRoute = _routeResult != null && _isNavMode;
    if (!hasRoute) return const SizedBox.shrink();

    final r = _routeResult!;
    final rideSegments = r.segments.where((s) => !s.isTransfer).toList();
    final totalTime = rideSegments.fold<int>(0, (sum, s) => sum + s.travelTimeSec);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // 경로 스텝 빌드
    final steps = <Widget>[];
    for (int i = 0; i < r.segments.length; i++) {
      final seg = r.segments[i];
      final lineColor = SubwayColors.lineColors[seg.lineId] ?? Colors.grey;
      final isLast = i == r.segments.length - 1;

      if (seg.isTransfer) {
        steps.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Icon(Icons.swap_horiz, size: 16, color: onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text('환승 · ~3분', style: AppTypography.bodySm.copyWith(color: onSurface.withValues(alpha: 0.5))),
          ]),
        ));
      } else {
        final timeMins = (seg.travelTimeSec / 60).ceil();
        steps.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: lineColor, borderRadius: BorderRadius.circular(6)),
              child: Text(seg.lineName, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                seg.stations.length > 1
                    ? '${seg.stations.first} → ${seg.stations.last} · ${seg.stations.length}개 역'
                    : seg.stations.firstOrNull ?? '',
                style: AppTypography.bodySm.copyWith(color: onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('$timeMins분', style: AppTypography.bodySm.copyWith(color: onSurface.withValues(alpha: 0.6))),
          ]),
        ));
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.06,
      maxChildSize: 0.50,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [Colors.black.withValues(alpha: 0.40), Colors.black.withValues(alpha: 0.50), Colors.black.withValues(alpha: 0.65)]
                      : [Colors.white.withValues(alpha: 0.70), Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0.85)],
                ),
                border: Border(top: BorderSide(color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.08), width: 0.5)),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
                children: [
                  // 핸들
                  Center(child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)),
                  )),
                  // 교통수단 탭
                  _buildTransportModeBar(onSurface),
                  const SizedBox(height: 10),
                  // 시간 + 뱃지
                  Row(children: [
                    Text(_transportMode == 0
                        ? r.totalTimeFormatted
                        : _directionsCache[_transportMode] != null
                            ? _formatDuration(_directionsCache[_transportMode]!.durationSec)
                            : '...',
                      style: AppTypography.displayLg.copyWith(color: onSurface)),
                    const SizedBox(width: 12),
                    if (_transportMode == 0) ...[
                      if (r.transferCount > 0) AppBadge(text: '환승 ${r.transferCount}회', color: AppColors.warning, fontWeight: FontWeight.w600),
                      const SizedBox(width: 6),
                      AppBadge(text: '${r.totalDistanceKm.toStringAsFixed(1)}km', color: AppColors.textDisabled, fontWeight: FontWeight.w600),
                    ] else if (_directionsCache[_transportMode] != null) ...[
                      AppBadge(text: '${_directionsCache[_transportMode]!.distanceKm.toStringAsFixed(1)}km', color: AppColors.textDisabled, fontWeight: FontWeight.w600),
                      if (_directionsCache[_transportMode]!.fare != null) ...[
                        const SizedBox(width: 6),
                        AppBadge(text: '택시 ~${(_directionsCache[_transportMode]!.fare! / 10000).toStringAsFixed(1)}만원', color: AppColors.warning, fontWeight: FontWeight.w600),
                      ],
                    ],
                  ]),
                  const SizedBox(height: 6),
                  // 출발 → 도착
                  Row(children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34C759))),
                    const SizedBox(width: 6),
                    Text(r.departure, style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 12, color: AppColors.textMuted)),
                    const Icon(Icons.location_on_rounded, color: Color(0xFFFF453A), size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(r.arrival, style: AppTypography.bodySm.copyWith(color: onSurface, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 10),
                  // 타임라인 바
                  if (totalTime > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(height: 8, child: Row(children: [
                        for (int i = 0; i < rideSegments.length; i++) ...[
                          if (i > 0) const SizedBox(width: 2),
                          Expanded(
                            flex: (rideSegments[i].travelTimeSec * 100 / totalTime).round().clamp(1, 100),
                            child: Container(color: SubwayColors.lineColors[rideSegments[i].lineId] ?? Colors.grey),
                          ),
                        ],
                      ])),
                    ),
                  const SizedBox(height: 14),
                  // 경로 스텝 (위로 당기면 보임)
                  ...steps,
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  // ── 설정 오버레이 패널 ──
  Widget _buildSettingsOverlay(BuildContext context, double screenHeight, double bottomInset) {
    final panelHeight = screenHeight * 0.58;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: _settingsOpen ? Curves.easeOutCubic : Curves.easeInCubic,
      bottom: _settingsOpen ? 0 : -panelHeight - 50,
      left: 0,
      right: 0,
      height: panelHeight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: _settingsOpen ? 1.0 : 0.0,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.dy > 200) {
              setState(() => _settingsOpen = false);
            }
          },
          child: SettingsPanel(
            subwayController: _subwayController,
            busController: _busController,
            flightController: _flightController,
            mapController: _mapController,
            onClose: () => setState(() => _settingsOpen = false),
          ),
        ),
      ),
    );
  }

  // ── 추천 패널 오버레이 (바텀시트) ──
  Widget _buildRecommendOverlay(BuildContext context, double screenHeight) {
    final panelHeight = screenHeight * 0.50;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: _recommendOpen ? Curves.easeOutCubic : Curves.easeInCubic,
      bottom: _recommendOpen ? 0 : -panelHeight - 50,
      left: 0,
      right: 0,
      height: panelHeight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: _recommendOpen ? 1.0 : 0.0,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.dy > 200) {
              setState(() => _recommendOpen = false);
            }
          },
          child: RecommendationPanel(
            onClose: () => setState(() => _recommendOpen = false),
          ),
        ),
      ),
    );
  }

  // ── 저장 패널 오버레이 (바텀시트) ──
  Widget _buildSavedOverlay(BuildContext context, double screenHeight) {
    final panelHeight = screenHeight * 0.50;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: _savedOpen ? Curves.easeOutCubic : Curves.easeInCubic,
      bottom: _savedOpen ? 0 : -panelHeight - 50,
      left: 0,
      right: 0,
      height: panelHeight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: _savedOpen ? 1.0 : 0.0,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.dy > 200) {
              setState(() => _savedOpen = false);
            }
          },
          child: _SavedPanel(
            onClose: () => setState(() => _savedOpen = false),
            onPlaceTap: (lat, lng, name) {
              setState(() => _savedOpen = false);
              Future.delayed(const Duration(milliseconds: 400), () {
                if (!mounted) return;
                _mapController?.moveTo(lat, lng, zoom: 16.0);
                final place = PlaceSearchResult(
                  name: name, address: '', category: '저장된 장소', lat: lat, lng: lng,
                );
                _showPlaceMarker(place);
                setState(() => _setSelectedPlace(place));
                PlaceSearchService.instance.search(name).then((results) {
                  if (!mounted || _selectedPlace?.name != name) return;
                  PlaceSearchResult? best;
                  double bestDist = double.infinity;
                  for (final r in results) {
                    final d = (r.lat - lat).abs() + (r.lng - lng).abs();
                    if (d < bestDist) { bestDist = d; best = r; }
                  }
                  if (best != null) setState(() => _setSelectedPlace(best));
                });
              });
            },
          ),
        ),
      ),
    );
  }

  // ── 하루 플랜 오버레이 ──
  Widget _buildDayPlanOverlay(BuildContext context, double bottomInset) {
    final show = _dayPlans != null && _dayPlans!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: show ? Curves.easeOutCubic : Curves.easeInCubic,
      bottom: show ? 0 : -600,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: show ? 1.0 : 0.0,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.dy > 200) {
              setState(() => _dayPlans = null);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: show
                ? DayPlanView(
                    plans: _dayPlans!,
                    mapController: _mapController,
                    onClose: () => setState(() => _dayPlans = null),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 설정 오버레이 패널 (지도 위 바텀시트)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class SettingsPanel extends StatefulWidget {
  final SubwayOverlayController subwayController;
  final BusOverlayController busController;
  final FlightOverlayController flightController;
  final IMapController? mapController;
  final VoidCallback onClose;

  const SettingsPanel({
    super.key,
    required this.subwayController,
    required this.busController,
    required this.flightController,
    this.mapController,
    required this.onClose,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  String _lightPreset = SettingsService.instance.lightPreset;

  /// 현재 지도가 밝은 모드인지 판별
  bool get _isBrightMap {
    final preset = _lightPreset;
    if (preset == 'day' || preset == 'dawn') return true;
    if (preset == 'auto') {
      final env = widget.subwayController.environment;
      if (env != null) {
        return env.lightPreset == 'day' || env.lightPreset == 'dawn';
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bright = _isBrightMap;
    final isM3 = Platform.isAndroid;
    final cs = Theme.of(context).colorScheme;

    final content = Column(
      children: [
        // 드래그 핸들
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _panelTextMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 타이틀
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '설정',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _panelTextPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 컨텐츠 스크롤
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 80),
            children: [
              _sectionHeader('지하철'),
              _buildSubwaySection(),
              const SizedBox(height: 24),
              _sectionHeader('버스'),
              _buildBusSection(),
              const SizedBox(height: 24),
              _sectionHeader('항공기'),
              _buildFlightSection(),
              const SizedBox(height: 24),
              _sectionHeader('표시'),
              _buildToggleSection(),
              const SizedBox(height: 24),
              _sectionHeader('노선 필터'),
              _buildLineFilterSection(),
              const SizedBox(height: 24),
              _sectionHeader('성능'),
              _buildQualitySection(),
              const SizedBox(height: 24),
              _sectionHeader('라이팅'),
              _buildLightingSection(),
              const SizedBox(height: 24),
              _sectionHeader('정보'),
              _buildInfoSection(),
            ],
          ),
        ),
      ],
    );

    if (isM3) {
      return Material(
        elevation: 6,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        color: cs.surfaceContainerHigh,
        surfaceTintColor: cs.surfaceTint,
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    final lightPanel = _isLightTheme;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: lightPanel
                  ? [
                      Colors.white.withValues(alpha: 0.70),
                      Colors.white.withValues(alpha: 0.75),
                      Colors.white.withValues(alpha: 0.85),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.50),
                      Colors.black.withValues(alpha: 0.65),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: lightPanel
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.white24,
                width: 0.5,
              ),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  /// 패널 내 텍스트 색상 — 앱 테마 모드 기준
  /// 라이트모드: 밝은 글라스 + 검정 글씨, 다크모드: 어두운 글라스 + 흰 글씨
  bool get _isLightTheme => Theme.of(context).brightness == Brightness.light;

  Color get _panelTextPrimary =>
      _isLightTheme ? Colors.black.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85);
  Color get _panelTextSecondary =>
      _isLightTheme ? Colors.black.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.45);
  Color get _panelTextMuted =>
      _isLightTheme ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.35);

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _panelTextSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    if (Platform.isAndroid) {
      final cs = Theme.of(context).colorScheme;
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        color: cs.surfaceContainerLow,
        child: child,
      );
    }

    final light = _isLightTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: light
                ? Colors.white.withValues(alpha: 0.30)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: light
                  ? Colors.black.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.10),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSubwaySection() {
    final ctrl = widget.subwayController;
    final isActive = ctrl.isActive;
    final isDemo = ctrl.mode == SubwayMode.demo;

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // 전원 + 모드
            Row(
              children: [
                Icon(Icons.train, size: 18, color: isActive ? AppColors.success : Colors.grey),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isActive ? (isDemo ? 'DEMO 실행 중' : 'LIVE 실행 중') : '꺼짐',
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isActive ? _panelTextPrimary : Colors.grey,
                  ),
                ),
                const Spacer(),
                // 모드 전환
                Semantics(
                  label: isDemo ? 'LIVE 모드로 전환' : 'DEMO 모드로 전환',
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      ctrl.setMode(isDemo ? SubwayMode.live : SubwayMode.demo);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isDemo ? AppColors.warning : AppColors.accent).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: isDemo ? AppColors.warning : AppColors.accent,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isDemo ? 'DEMO' : 'LIVE',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDemo ? AppColors.warning : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // 전원 버튼
                AppCircleButton(
                  icon: Icons.power_settings_new,
                  onTap: () {
                    if (isActive) {
                      ctrl.stop();
                    } else {
                      ctrl.start();
                    }
                    setState(() {});
                  },
                  semanticLabel: isActive ? '지하철 끄기' : '지하철 켜기',
                  size: AppSpacing.buttonSm,
                  iconSize: 14,
                  color: isActive ? AppColors.success.withValues(alpha: 0.2) : AppColors.surfaceOverlay,
                  borderColor: isActive ? AppColors.success : Colors.grey,
                ),
              ],
            ),
            // 상태 정보
            if (isActive) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('열차 ${ctrl.currentTrains.length}대',
                      style: AppTypography.caption.copyWith(color: _panelTextSecondary)),
                  if (ctrl.lastUpdate != null)
                    Text(
                      '갱신 ${ctrl.lastUpdate!.hour.toString().padLeft(2, '0')}:${ctrl.lastUpdate!.minute.toString().padLeft(2, '0')}:${ctrl.lastUpdate!.second.toString().padLeft(2, '0')}',
                      style: AppTypography.caption.copyWith(color: _panelTextMuted),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBusSection() {
    final ctrl = widget.busController;
    final isActive = ctrl.isActive;

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 표시
            Row(
              children: [
                Icon(Icons.directions_bus, size: 18, color: isActive ? BusColors.trunk : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  isActive ? '버스 ${ctrl.totalBusCount}대 표시 중' : '노선을 선택하세요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? _panelTextPrimary : Colors.grey,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  GestureDetector(
                    onTap: () { ctrl.stop(); setState(() {}); },
                    child: Text('전체 끄기', style: TextStyle(color: _panelTextMuted, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 추적 중인 노선 (탭하면 제거)
            if (ctrl.trackedRoutes.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ctrl.trackedRoutes.map((route) {
                  return GestureDetector(
                    onTap: () { ctrl.removeRoute(route.routeId); setState(() {}); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: route.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: route.color, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(route.routeName,
                            style: TextStyle(color: route.color, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Icon(Icons.close, size: 12, color: route.color),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              _toggleRow('버스 위치', ctrl.showBuses, (v) {
                ctrl.toggleBuses(v);
                setState(() {});
              }),
              const Divider(height: 16, color: AppColors.divider),
            ],
            // 한강 한강버스
            _toggleRow('🚢 한강 한강버스', ctrl.showRiverBus, (v) {
              ctrl.toggleRiverBus(v);
              setState(() {});
            }),
            const SizedBox(height: 12),
            // 인기 노선 프리셋 (탭해서 추가)
            Text('노선 추가', style: TextStyle(fontSize: 12, color: _panelTextSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: BusPresets.popular.map((preset) {
                final id = preset['id'] as String;
                final name = preset['name'] as String;
                final type = preset['type'] as int;
                final color = BusColors.fromRouteType(type);
                final added = ctrl.trackedRoutes.any((r) => r.routeId == id);
                return GestureDetector(
                  onTap: added ? null : () async {
                    await ctrl.addRoute(BusRouteInfo(
                      busRouteId: id,
                      busRouteNm: name,
                      routeType: type,
                      stStationNm: '',
                      edStationNm: '',
                    ));
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: added ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: added ? color : color.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: added ? color : _panelTextSecondary,
                        fontSize: 13,
                        fontWeight: added ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightSection() {
    final ctrl = widget.flightController;
    final isDemo = ctrl.mode == FlightMode.demo;
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.flight, size: 18,
                    color: ctrl.isActive ? Colors.white : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  ctrl.isActive
                      ? '${isDemo ? "DEMO" : "LIVE"} ${ctrl.flightCount}대'
                      : '항공기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ctrl.isActive ? _panelTextPrimary : _panelTextSecondary,
                  ),
                ),
                const Spacer(),
                // DEMO/LIVE 전환
                Semantics(
                  label: isDemo ? 'LIVE 모드로 전환' : 'DEMO 모드로 전환',
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      ctrl.setMode(isDemo ? FlightMode.live : FlightMode.demo);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isDemo ? AppColors.warning : AppColors.accent).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDemo ? AppColors.warning : AppColors.accent,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isDemo ? 'DEMO' : 'LIVE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isDemo ? AppColors.warning : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.75,
                  child: Switch.adaptive(
                    value: ctrl.showFlights,
                    onChanged: (v) {
                      ctrl.toggle(v);
                      setState(() {});
                    },
                    activeColor: AppColors.success,
                  ),
                ),
              ],
            ),
            if (ctrl.isActive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _flightLegend(const Color(0xFF00E676), '상승'),
                  _flightLegend(Colors.white, '순항'),
                  _flightLegend(const Color(0xFFFF9100), '하강'),
                  _flightLegend(const Color(0xFFFF5252), '이착륙'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _flightLegend(Color color, String label) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: _panelTextMuted)),
        ],
      ),
    );
  }

  Widget _buildToggleSection() {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _toggleRow('노선 경로', widget.subwayController.showRoutes, (v) {
              widget.subwayController.toggleRoutes(v);
              setState(() {});
            }),
            _toggleRow('열차 위치', widget.subwayController.showTrains, (v) {
              widget.subwayController.toggleTrains(v);
              setState(() {});
            }),
            _toggleRow('역 표시', widget.subwayController.showStations, (v) {
              widget.subwayController.toggleStations(v);
              setState(() {});
            }),
            const Divider(height: AppSpacing.md, color: AppColors.divider),
            _toggleRow('서울시 공공 API (60s)', widget.subwayController.useSeoulApi, (v) {
              widget.subwayController.setUseSeoulApi(v);
              setState(() {});
            }),
            _toggleRow('네이버 API (5s)', widget.subwayController.useNaverApi, (v) {
              widget.subwayController.setUseNaverApi(v);
              setState(() {});
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLineFilterSection() {
    final ctrl = widget.subwayController;
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('표시할 노선 선택', style: AppTypography.caption.copyWith(color: _panelTextSecondary)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ctrl.setLineFilter(null);
                    setState(() {});
                  },
                  child: Text('전체', style: AppTypography.caption.copyWith(color: AppColors.accent)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: SubwayColors.lineColors.entries.map((entry) {
                final lineId = entry.key;
                final color = entry.value;
                final name = SubwayColors.lineNames[lineId] ?? lineId;
                final isSelected = ctrl.selectedLines == null ||
                    ctrl.selectedLines!.contains(lineId);

                return AppFilterChip(
                  label: name,
                  color: color,
                  isSelected: isSelected,
                  onTap: () {
                    final current = ctrl.selectedLines ??
                        Set<String>.from(SubwayColors.lineColors.keys);
                    if (current.contains(lineId)) {
                      current.remove(lineId);
                    } else {
                      current.add(lineId);
                    }
                    ctrl.setLineFilter(current.isEmpty ? null : current);
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _panelTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySection() {
    final ctrl = widget.subwayController;
    final current = ctrl.qualityPreset;
    final isAndroid = Platform.isAndroid;

    final presetKeys = ['high', 'medium', 'low'];
    final presetLabels = ['높음', '보통', '낮음'];
    final selectedIndex = presetKeys.indexOf(current).clamp(0, 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 세그먼트 프리셋 (전 디자인 스타일)
        _glassCard(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: List.generate(presetLabels.length, (i) {
                final isSelected = i == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ctrl.setQualityPreset(presetKeys[i]);
                      setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? _panelTextPrimary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        border: isSelected
                            ? Border.all(
                                color: _panelTextPrimary.withValues(alpha: 0.15),
                                width: 0.5,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          presetLabels[i],
                          style: TextStyle(
                            color: isSelected
                                ? _panelTextPrimary
                                : _panelTextSecondary,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // FPS 슬라이더
        _glassCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _sliderRow(
                  label: '프레임',
                  value: '${ctrl.animFps} fps',
                  slider: Slider(
                    value: ctrl.animFps.toDouble().clamp(5, isAndroid ? 30 : 60),
                    min: 5,
                    max: isAndroid ? 30 : 60,
                    divisions: isAndroid ? 5 : 11,
                    onChanged: (v) {
                      ctrl.setAnimFps(v.round());
                      setState(() {});
                    },
                  ),
                ),
                _sliderRow(
                  label: '네이버 폴링',
                  value: '${ctrl.naverPollMs}ms',
                  slider: Slider(
                    value: ctrl.naverPollMs.toDouble(),
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    onChanged: (v) {
                      ctrl.setNaverPollMs(v.round());
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 시스템 정보
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Icon(Icons.memory, size: 14, color: _panelTextMuted),
              const SizedBox(width: 8),
              Text(
                '렌더링: ${isAndroid ? "OpenGL ES" : "Metal"} · GeoJSON 캐싱',
                style: TextStyle(fontSize: 12, color: _panelTextMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sliderRow({required String label, required String value, required Widget slider}) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: _panelTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: slider),
        SizedBox(
          width: 52,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _panelTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLightingSection() {
    final presets = ['auto', 'day', 'night', 'dawn', 'dusk'];
    final labels = ['자동', '주간', '야간', '새벽', '석양'];
    final selectedIndex = presets.indexOf(_lightPreset).clamp(0, presets.length - 1);

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(presets.length, (i) {
            final isSelected = i == selectedIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  final preset = presets[i];
                  setState(() => _lightPreset = preset);
                  widget.subwayController.autoLighting = (preset == 'auto');
                  SettingsService.instance.setLightPreset(preset);
                  SettingsService.instance.setAutoLighting(preset == 'auto');
                  if (preset == 'auto') {
                    final env = widget.subwayController.environment;
                    if (env != null) {
                      widget.mapController?.applyWeatherEffect(lightPreset: env.lightPreset);
                    }
                  } else {
                    widget.mapController?.setLightPreset(preset);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? _panelTextPrimary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    border: isSelected
                        ? Border.all(
                            color: _panelTextPrimary.withValues(alpha: 0.15),
                            width: 0.5,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: isSelected
                            ? _panelTextPrimary
                            : _panelTextSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final dp = DeviceProfileService.instance;
    final tierLabel = switch (dp.profile.tier) {
      DeviceTier.flagship => '플래그십',
      DeviceTier.high => '상위',
      DeviceTier.mid => '중급',
      DeviceTier.low => '저사양',
    };

    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _settingTile(
              icon: Icons.info_outline,
              title: '맵 엔진',
              subtitle: 'Mapbox Maps SDK v11',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Divider(height: 1, color: _panelTextMuted.withValues(alpha: 0.15)),
            ),
            _settingTile(
              icon: Icons.phone_android,
              title: '기기',
              subtitle: dp.rawModel,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Divider(height: 1, color: _panelTextMuted.withValues(alpha: 0.15)),
            ),
            _settingTile(
              icon: Icons.speed,
              title: '성능 등급',
              subtitle: '$tierLabel (${dp.profile.animFps}fps · ${dp.profile.naverPollMs}ms)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _panelTextSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _panelTextPrimary,
              )),
              Text(subtitle, style: TextStyle(
                fontSize: 12,
                color: _panelTextMuted,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

/// AI 상태 텍스트 (타이핑 효과)
class _AiStatusText extends StatefulWidget {
  final String text;
  const _AiStatusText({required this.text});

  @override
  State<_AiStatusText> createState() => _AiStatusTextState();
}

class _AiStatusTextState extends State<_AiStatusText> {
  String _fullText = '';
  String _displayed = '';
  Timer? _timer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping(widget.text);
  }

  @override
  void didUpdateWidget(_AiStatusText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      if (widget.text.isEmpty) {
        // 클리어
        _timer?.cancel();
        setState(() { _fullText = ''; _displayed = ''; _charIndex = 0; });
      } else if (widget.text.length > _fullText.length && widget.text.startsWith(_fullText)) {
        // 이어붙이기 (같은 턴에서 텍스트가 추가됨)
        _fullText = widget.text;
        _continueTyping();
      } else {
        // 새 텍스트
        _startTyping(widget.text);
      }
    }
  }

  void _startTyping(String target) {
    _timer?.cancel();
    _fullText = target;
    _displayed = '';
    _charIndex = 0;
    _continueTyping();
  }

  void _continueTyping() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted || _charIndex >= _fullText.length) { t.cancel(); return; }
      _charIndex++;
      setState(() => _displayed = _fullText.substring(0, _charIndex));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayed.isEmpty) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 60),
      child: SingleChildScrollView(
        reverse: true,
        child: Text(
          _displayed,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 저장 패널
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SavedPanel extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(double lat, double lng, String name) onPlaceTap;
  const _SavedPanel({required this.onClose, required this.onPlaceTap});
  @override
  State<_SavedPanel> createState() => _SavedPanelState();
}

class _SavedPanelState extends State<_SavedPanel> {
  int _tab = 0;
  bool get _isLightTheme => Theme.of(context).brightness == Brightness.light;
  Color get _tp => _isLightTheme ? Colors.black.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85);
  Color get _ts => _isLightTheme ? Colors.black.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.45);
  Color get _tm => _isLightTheme ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isM3 = Platform.isAndroid;
    final content = Column(children: [
      Padding(padding: const EdgeInsets.only(top: 12), child: Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: _tm)))),
      Padding(padding: const EdgeInsets.fromLTRB(24, 16, 12, 8), child: Row(children: [
        Text('저장', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _tp)),
        const Spacer(),
        IconButton(icon: Icon(Icons.close, size: 20, color: _ts), onPressed: widget.onClose, visualDensity: VisualDensity.compact),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(
        height: 36,
        decoration: BoxDecoration(color: _tm.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [_tabBtn('즐겨찾기', 0), _tabBtn('최근 방문', 1), _tabBtn('자주 방문', 2)]),
      )),
      const SizedBox(height: 8),
      Expanded(child: _tab == 0 ? _buildFavorites() : _tab == 1 ? _buildRecent() : _buildFrequent()),
    ]);

    if (isM3) return Material(elevation: 6, borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), color: cs.surfaceContainerHigh, surfaceTintColor: cs.surfaceTint, clipBehavior: Clip.antiAlias, child: content);

    final lp = _isLightTheme;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: lp ? [Colors.white.withValues(alpha: 0.70), Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0.85)]
                      : [Colors.black.withValues(alpha: 0.40), Colors.black.withValues(alpha: 0.50), Colors.black.withValues(alpha: 0.65)]),
          border: Border(top: BorderSide(color: lp ? Colors.black.withValues(alpha: 0.08) : Colors.white24, width: 0.5)),
        ),
        child: content,
      )),
    );
  }

  Widget _tabBtn(String label, int index) {
    final sel = _tab == index;
    return Expanded(child: GestureDetector(onTap: () => setState(() => _tab = index), child: AnimatedContainer(
      duration: const Duration(milliseconds: 200), margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: sel ? _tp.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? _tp : _ts)),
    )));
  }

  Widget _buildFavorites() {
    final items = FavoritesService.instance.favorites;
    if (items.isEmpty) return Center(child: Text('저장한 장소가 없습니다', style: TextStyle(color: _tm)));
    return ListView.builder(padding: const EdgeInsets.fromLTRB(24, 4, 24, 20), itemCount: items.length, itemBuilder: (_, i) {
      final f = items[i];
      return _row(f.name, f.category, f.lat, f.lng, trailing: IconButton(icon: const Icon(Icons.favorite, size: 18, color: Colors.redAccent),
        onPressed: () async { await FavoritesService.instance.remove(f.name); setState(() {}); }, visualDensity: VisualDensity.compact));
    });
  }

  Widget _buildRecent() {
    final items = VisitHistoryService.instance.recentVisits;
    if (items.isEmpty) return Center(child: Text('방문 기록이 없습니다', style: TextStyle(color: _tm)));
    return ListView.builder(padding: const EdgeInsets.fromLTRB(24, 4, 24, 20), itemCount: items.length, itemBuilder: (_, i) {
      final r = items[i];
      final ago = DateTime.now().difference(r.visitedAt);
      final s = ago.inDays > 0 ? '${ago.inDays}일 전' : ago.inHours > 0 ? '${ago.inHours}시간 전' : '방금';
      return _row(r.name, r.category, r.lat, r.lng, trailing: Text(s, style: TextStyle(fontSize: 10, color: _tm)));
    });
  }

  Widget _buildFrequent() {
    final items = VisitHistoryService.instance.frequentVisits;
    if (items.isEmpty) return Center(child: Text('방문 기록이 없습니다', style: TextStyle(color: _tm)));
    return ListView.builder(padding: const EdgeInsets.fromLTRB(24, 4, 24, 20), itemCount: items.length, itemBuilder: (_, i) {
      final r = items[i];
      return _row(r.name, r.category, r.lat, r.lng, trailing: Text('${r.visitCount}회', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _ts)));
    });
  }

  Widget _row(String name, String category, double lat, double lng, {Widget? trailing}) {
    return GestureDetector(onTap: () => widget.onPlaceTap(lat, lng, name), behavior: HitTestBehavior.opaque, child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(Icons.place, size: 18, color: _ts), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _tp)),
          if (category.isNotEmpty) Text(category, style: TextStyle(fontSize: 11, color: _ts)),
        ])),
        if (trailing != null) trailing,
      ]),
    ));
  }
}

