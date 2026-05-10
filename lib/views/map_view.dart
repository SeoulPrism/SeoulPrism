import '../core/debug_log.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/adaptive/adaptive.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../core/map_interface.dart';
import '../core/api_keys.dart';
import '../core/geo_distance.dart';
import '../core/format_utils.dart';
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
import '../services/multiplayer_service.dart';
import '../widgets/multiplayer/seoul_live_overlays.dart';
import '../widgets/multiplayer/peer_pin_renderer.dart';
import '../widgets/multiplayer/live_sharing_badge.dart';
import '../widgets/app_snackbar.dart';
import 'multiplayer/peer_profile_card.dart';
import '../widgets/search_bar.dart';
import '../services/place_search_service.dart';
import '../services/favorites_service.dart';
import '../services/directions_service.dart';
import '../services/saved_places_plan_builder.dart';
import '../services/live_activity_service.dart';
import '../services/incoming_url_service.dart';
import 'map/widgets/departure_time_picker.dart';
import 'map/widgets/place_action_button.dart';
import 'map/widgets/place_detail_panel.dart';
import 'map/widgets/river_bus_stop_panel.dart';
import 'map/widgets/vehicle_panels.dart';
import 'map/widgets/route_sheet_shell.dart';
import 'map/widgets/route_timeline.dart';
import 'map/widgets/navigation_banner.dart';
import 'map/widgets/saved_panel.dart';
import 'map/widgets/settings_panel.dart';
import 'map/widgets/travel_panel.dart';
import 'map/widgets/info_bars.dart';
import 'package:geolocator/geolocator.dart' as geo;
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
import '../data/seoul_bus_data.dart';
import '../services/seoul_subway_service.dart';
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
  bool _settingsOpen = false; // 더 이상 탭으로 진입 안 함 — ProfileView 의 톱니바퀴 아이콘으로만 진입.
  bool _travelOpen = false;
  bool _aiOpen = false;
  bool _aiClosing = false;
  bool _recommendOpen = false;
  bool _savedOpen = false;
  bool _hideButtonForPanel = false; // 패널 닫힌 후 버튼 딜레이용
  String _aiStatus = '';
  final GlobalKey<UnifiedSearchBarState> _searchBarKey =
      GlobalKey<UnifiedSearchBarState>();
  PlaceSearchResult? _selectedPlace;
  PlaceSearchResult? _lastSelectedPlace;
  RiverBusStop? _selectedRiverStop;
  RiverBusStop? _lastSelectedRiverStop;

  void _setSelectedPlace(PlaceSearchResult? place, {bool animate = true}) {
    if (place != null) {
      // 한강버스 패널 닫기
      _selectedRiverStop = null;
      // 같은 장소의 상세정보 업데이트면 그냥 교체
      if (_selectedPlace != null &&
          _selectedPlace!.lat == place.lat &&
          _selectedPlace!.lng == place.lng) {
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
    lat: 37.5665,
    lng: 126.9780,
    zoom: 14.0,
    pitch: 50.0,
    bearing: -15.0,
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
  PathResult? _routeResult; // 요약 바텀 패널용
  int _transportMode = 0; // 0: 대중교통, 1: 자동차, 2: 도보
  Map<int, DirectionsResult> _directionsCache = {};

  /// 도보 구간 턴바이턴 안내 캐시 (segment index → steps)
  Map<int, List<WalkStep>> _walkStepsCache = {};

  /// 첫 탑승역 도착 정보 — 1955줄 부근 폴링 후 reset 용 (write-only 라 analyzer 가 unused_field 경고).
  // ignore: unused_field
  List<String> _boardingArrivals = [];
  Timer? _arrivalRefreshTimer;

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

    // 위젯/Control 에서 들어온 URL 처리 (com.seoul.prism://route?dep=...&arr=...).
    IncomingUrlService.instance.onUrl(_handleIncomingUrl);

    // Seoul Live (멀티플레이) 상태 변동 시 탭바 모핑/인트로 트리거.
    MultiplayerService.instance.addListener(_onMultiplayerChanged);
    // 위치 권한 거부 시 사용자에게 안내 (1회).
    MultiplayerService.instance.addLocationDeniedListener(_onLocationDenied);
    // 처음 진입 시 이미 활성 + 튜토리얼 미시청이면 다음 frame 에 인트로 시작.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MultiplayerService.instance.seoulLiveActive) {
        SeoulLiveOverlays.maybeRunIntro(context);
      }
    });
  }

  bool _seoulLiveLastSeen =
      MultiplayerService.instance.seoulLiveActive;
  PeerPinRenderer? _peerPinRenderer;

  void _onMultiplayerChanged() {
    if (!mounted) return;
    final active = MultiplayerService.instance.seoulLiveActive;
    final flippedOn = !_seoulLiveLastSeen && active;
    _seoulLiveLastSeen = active;
    setState(() {});
    // G1: peer 핀 렌더러 attach/detach.
    _syncPeerPinRenderer();
    if (flippedOn) _waitForFocusThenRunIntro();
  }

  void _syncPeerPinRenderer() {
    final mc = _mapController;
    final active = MultiplayerService.instance.seoulLiveActive;
    if (mc == null) return;
    if (active && _peerPinRenderer == null) {
      _peerPinRenderer = PeerPinRenderer(mc)..attach();
    } else if (!active && _peerPinRenderer != null) {
      _peerPinRenderer?.detach();
      _peerPinRenderer = null;
    }
  }

  /// 프로필 생성은 보통 ProfileEditSheet (modal) 안에서 일어나므로
  /// 우리가 최상위 route 가 될 때까지 대기 후 인트로 실행.
  void _waitForFocusThenRunIntro() {
    void attempt() {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent) {
        SeoulLiveOverlays.maybeRunIntro(context);
      } else {
        Future.delayed(const Duration(milliseconds: 150), attempt);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

  void _handleIncomingUrl(Uri url) {
    if (url.host != 'route') return;
    final dep = url.queryParameters['dep'];
    final arr = url.queryParameters['arr'];
    if (dep == null || arr == null || dep.isEmpty || arr.isEmpty) return;
    _searchBarKey.currentState?.enterNavWithPair(
      dep,
      arr,
      depLat: double.tryParse(url.queryParameters['dep_lat'] ?? ''),
      depLng: double.tryParse(url.queryParameters['dep_lng'] ?? ''),
      arrLat: double.tryParse(url.queryParameters['arr_lat'] ?? ''),
      arrLng: double.tryParse(url.queryParameters['arr_lng'] ?? ''),
    );
  }

  @override
  void dispose() {
    _arrivalRefreshTimer?.cancel();
    _routeNavigationTimer?.cancel();
    _navLocationSub?.cancel();
    _subwayController.dispose();
    _busController.dispose();
    _flightController.dispose();
    MultiplayerService.instance.removeListener(_onMultiplayerChanged);
    MultiplayerService.instance.removeLocationDeniedListener(_onLocationDenied);
    _peerPinRenderer?.detach();
    super.dispose();
  }

  void _onLocationDenied() {
    if (!mounted) return;
    showAppSnackBar('위치 권한이 없어서 친구가 내 핀을 못 봐요. 설정 → 위치 에서 허용해주세요.');
  }

  // ── 경로 지도 표시 ──

  int _routeAnimId = 0; // 애니메이션 취소용

  Future<void> _drawRouteOnMap(PathResult route) async {
    final mc = _mapController;
    if (mc == null) return;

    _clearRouteFromMap();
    _walkStepsCache = {};
    final animId = ++_routeAnimId;

    // GeoJSON 선로 좌표 로드
    final geojsonRoutes = await SubwayGeoJsonLoader.load();

    // 첫 지하철 탑승역의 실시간 도착 정보 로드
    _loadBoardingArrival(route);

    // 전체 구간 좌표 미리 계산 (지하철 + 버스 + 도보)
    final segmentData =
        <
          ({
            List<List<double>> coords,
            Color color,
            double startLat,
            double startLng,
            double endLat,
            double endLng,
            bool isWalk,
          })
        >[];
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

    for (final segment in route.segments) {
      if (segment.isTransfer || segment.stations.length < 2) continue;

      List<List<double>> segCoords;
      Color color;

      if (segment.mode == TransportMode.walk) {
        // 도보 구간: PathSegment 좌표 → TMAP 도보 경로
        double? fromLat = segment.startLat;
        double? fromLng = segment.startLng;
        double? toLat = segment.endLat;
        double? toLng = segment.endLng;
        // 좌표 없으면 역명으로 폴백
        if (fromLat == null ||
            fromLng == null ||
            toLat == null ||
            toLng == null) {
          final stationCoords = _resolveStationCoords(segment.stations);
          if (stationCoords.length >= 2) {
            fromLat ??= stationCoords.first[0];
            fromLng ??= stationCoords.first[1];
            toLat ??= stationCoords.last[0];
            toLng ??= stationCoords.last[1];
          }
        }
        if (fromLat == null ||
            fromLng == null ||
            toLat == null ||
            toLng == null)
          continue;

        final walkRoute = await DirectionsService.instance.getWalkingRoute(
          fromLat,
          fromLng,
          toLat,
          toLng,
        );
        if (walkRoute != null && walkRoute.coordinates.length >= 2) {
          segCoords = walkRoute.coordinates;
          // 도보 안내 캐시 (출구 정보 포함)
          if (walkRoute.walkSteps.isNotEmpty) {
            _walkStepsCache[route.segments.indexOf(segment)] =
                walkRoute.walkSteps;
          }
        } else {
          segCoords = [
            [fromLat, fromLng],
            [toLat, toLng],
          ];
        }
        color = const Color(0xFF4FC3F7); // 도보: 밝은 파랑
      } else if (segment.mode == TransportMode.bus) {
        // 버스 구간: 정류소 좌표를 Mapbox Map Matching 으로 도로에 스냅.
        // 매칭 실패 시 직선 폴백 (이전 동작 보존).
        final stopCoords = _resolveBusStopCoords(
          segment.lineId,
          segment.stations,
        );
        if (stopCoords.length < 2) continue;
        final matched = await DirectionsService.instance.getMatchedRoute(
          stopCoords,
        );
        segCoords = (matched != null && matched.length >= 2)
            ? matched
            : stopCoords;
        // 버스 색상
        final ref = segment.lineId.startsWith('bus_')
            ? segment.lineId.substring(4)
            : '';
        final num = int.tryParse(ref);
        if (num != null && num >= 100 && num <= 999) {
          color = BusColors.trunk;
        } else if (num != null && num >= 1000) {
          color = BusColors.branch;
        } else if (ref.startsWith('M')) {
          color = BusColors.express;
        } else {
          color = BusColors.branch;
        }
      } else {
        // 지하철 구간
        final firstStn = SeoulSubwayData.findStation(segment.stations.first);
        final lastStn = SeoulSubwayData.findStation(segment.stations.last);
        if (firstStn == null || lastStn == null) continue;

        final lineCoords = geojsonRoutes[segment.lineId];
        if (lineCoords != null && lineCoords.length >= 2) {
          segCoords = _extractSegmentFromRoute(lineCoords, firstStn, lastStn);
        } else {
          segCoords = segment.stations
              .map((n) => SeoulSubwayData.findStation(n))
              .where((s) => s != null)
              .map((s) => [s!.lat, s.lng])
              .toList();
        }
        color = SubwayColors.lineColors[segment.lineId] ?? AppColors.accent;
      }

      if (segCoords.length < 2) continue;
      segmentData.add((
        coords: segCoords,
        color: color,
        startLat: segCoords.first[0],
        startLng: segCoords.first[1],
        endLat: segCoords.last[0],
        endLng: segCoords.last[1],
        isWalk: segment.mode == TransportMode.walk,
      ));

      for (final c in segCoords) {
        if (c[0] < minLat) minLat = c[0];
        if (c[0] > maxLat) maxLat = c[0];
        if (c[1] < minLng) minLng = c[1];
        if (c[1] > maxLng) maxLng = c[1];
      }
    }

    if (segmentData.isEmpty) return;

    // 카메라 이동
    if (minLat < maxLat && minLng < maxLng) {
      double bearing = 0;
      final first = segmentData.first;
      final last = segmentData.last;
      final dLng = (last.endLng - first.startLng) * pi / 180;
      final lat1 = first.startLat * pi / 180;
      final lat2 = last.endLat * pi / 180;
      final y = sin(dLng) * cos(lat2);
      final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
      bearing = (atan2(y, x) * 180 / pi + 360) % 360;

      final latSpan = maxLat - minLat;
      final centerLat = (minLat + maxLat) / 2 - latSpan * 0.1;
      final centerLng = (minLng + maxLng) / 2;
      final span = max(latSpan, maxLng - minLng);
      final zoom = span > 0.3
          ? 10.0
          : span > 0.15
          ? 11.0
          : span > 0.08
          ? 12.0
          : 13.0;
      mc.moveTo(centerLat, centerLng, zoom: zoom, pitch: 45, bearing: bearing);
    }

    // 출발 마커
    mc.addCircleMarker(
      'route_dep',
      segmentData.first.startLat,
      segmentData.first.startLng,
      color: AppColors.success,
      radius: 12,
      strokeColor: AppColors.textPrimary,
      strokeWidth: 4,
    );

    await Future.delayed(const Duration(milliseconds: 600));
    if (_routeAnimId != animId) return;

    // 구간별 순차 애니메이션
    for (int s = 0; s < segmentData.length; s++) {
      if (_routeAnimId != animId) return;
      final seg = segmentData[s];

      if (!seg.isWalk) {
        mc.addCircleMarker(
          'route_mk_${s}_s',
          seg.startLat,
          seg.startLng,
          color: seg.color,
          radius: 8,
          strokeColor: Colors.white,
          strokeWidth: 3,
        );
      }

      // 도보: 점선 스타일 (배경 흰색 + 위에 밝은 파랑), 나머지: 실선
      final lineWidth = seg.isWalk ? 4.0 : 5.0;
      final outlineWidth = seg.isWalk ? 6.0 : 8.0;

      await mc.addPolyline(
        'route_outline_$s',
        seg.coords,
        color: seg.isWalk ? Colors.white : Colors.black.withValues(alpha: 0.4),
        width: outlineWidth,
        opacity: 1.0,
      );

      // 애니메이션 (도보는 즉시 그리기)
      if (seg.isWalk) {
        await mc.addPolyline(
          'route_seg_$s',
          seg.coords,
          color: seg.color,
          width: lineWidth,
          opacity: 0.9,
        );
      } else {
        final totalPoints = seg.coords.length;
        final step = max(1, totalPoints ~/ 12);
        for (int i = step; i <= totalPoints; i += step) {
          if (_routeAnimId != animId) return;
          final partial = seg.coords.sublist(0, min(i, totalPoints));
          if (partial.length >= 2) {
            mc.removePolyline('route_seg_$s');
            await mc.addPolyline(
              'route_seg_$s',
              partial,
              color: seg.color,
              width: lineWidth,
              opacity: 1.0,
            );
          }
          await Future.delayed(const Duration(milliseconds: 80));
        }
        if (_routeAnimId != animId) return;
        mc.removePolyline('route_seg_$s');
        await mc.addPolyline(
          'route_seg_$s',
          seg.coords,
          color: seg.color,
          width: lineWidth,
          opacity: 1.0,
        );
      }

      if (!seg.isWalk) {
        mc.addCircleMarker(
          'route_mk_${s}_e',
          seg.endLat,
          seg.endLng,
          color: seg.color,
          radius: 8,
          strokeColor: Colors.white,
          strokeWidth: 3,
        );
      }

      if (s < segmentData.length - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    // 화살표
    if (_routeAnimId != animId) return;
    final allArrows = <Map<String, dynamic>>[];
    for (final seg in segmentData) {
      if (!seg.isWalk) _collectArrows(allArrows, seg.coords, seg.color);
    }
    if (allArrows.isNotEmpty) await mc.updateRouteArrows(allArrows);

    // 도착 마커
    if (_routeAnimId != animId) return;
    mc.addCircleMarker(
      'route_arr',
      segmentData.last.endLat,
      segmentData.last.endLng,
      color: AppColors.danger,
      radius: 12,
      strokeColor: AppColors.textPrimary,
      strokeWidth: 4,
    );
  }

  /// 역/정류소명 리스트 → 좌표 리스트 (지하철+버스 통합)
  List<List<double>> _resolveStationCoords(List<String> names) {
    final coords = <List<double>>[];
    for (final name in names) {
      final sub = SeoulSubwayData.findStation(name);
      if (sub != null) {
        coords.add([sub.lat, sub.lng]);
        continue;
      }
      // 버스 정류소
      for (final route in SeoulBusData.allRoutes) {
        final stop = route.stops.where((s) => s.name == name).firstOrNull;
        if (stop != null) {
          coords.add([stop.lat, stop.lng]);
          break;
        }
      }
    }
    return coords;
  }

  /// 버스 노선의 정류소 좌표 추출
  List<List<double>> _resolveBusStopCoords(
    String lineId,
    List<String> stationNames,
  ) {
    final routeRef = lineId.startsWith('bus_') ? lineId.substring(4) : lineId;
    final busRoute = SeoulBusData.getRouteByName(routeRef);
    if (busRoute == null) {
      // 폴백: 이름으로 좌표 찾기
      return _resolveStationCoords(stationNames);
    }
    // 노선 정류소에서 매칭
    final coords = <List<double>>[];
    for (final name in stationNames) {
      final stop = busRoute.stops.where((s) => s.name == name).firstOrNull;
      if (stop != null) {
        coords.add([stop.lat, stop.lng]);
      }
    }
    return coords.length >= 2 ? coords : _resolveStationCoords(stationNames);
  }

  /// GeoJSON 선로 좌표에서 두 역 사이 구간만 추출
  List<List<double>> _extractSegmentFromRoute(
    List<List<double>> routeCoords,
    StationInfo startStation,
    StationInfo endStation,
  ) {
    // 선로 좌표에서 각 역에 가장 가까운 인덱스 찾기
    int startIdx = _findClosestIndex(
      routeCoords,
      startStation.lat,
      startStation.lng,
    );
    int endIdx = _findClosestIndex(routeCoords, endStation.lat, endStation.lng);

    if (startIdx == endIdx)
      return [
        [startStation.lat, startStation.lng],
        [endStation.lat, endStation.lng],
      ];

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
    _arrivalRefreshTimer?.cancel();
    _routeNavigationTimer?.cancel();
    _navLocationSub?.cancel();
    _navLocationSub = null;
    LiveActivityService.instance.stop();
    _boardingArrivals = [];
    _segmentArrivals = {};
    _routeNavigationActive = false;
    final mc = _mapController;
    if (mc == null) return;
    mc.clearPolylines();
    mc.clearCircleMarkers();
    mc.clearRouteArrows();
  }

  /// 경로를 따라 화살표 데이터를 수집
  void _collectArrows(
    List<Map<String, dynamic>> arrows,
    List<List<double>> coords,
    Color color,
  ) {
    if (coords.length < 2) return;

    final colorStr =
        'rgba(${(color.r * 255).round()},${(color.g * 255).round()},${(color.b * 255).round()},1)';
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
    // G1: 맵 ready 시점에 Seoul Live active 면 즉시 peer 핀 렌더러 attach.
    _syncPeerPinRenderer();
    // R1: peer 핀 탭 → 프로필 카드.
    controller.setOnPeerPinTapped((userId) {
      if (mounted) PeerProfileCard.show(context, userId);
    });
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

    // 온보딩 / 설정에서 선택한 레이어 활성화 상태 적용 (성능 부담 큰 레이어 끄기 가능).
    final s = SettingsService.instance;
    _busController.toggleBuses(s.showBuses);
    _busController.toggleRiverBus(s.showRiverBus);
    _flightController.toggle(s.showFlights);

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
        name: name,
        address: '',
        category: '장소',
        lat: lat,
        lng: lng,
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
      bottomNavigationBar: (_routeResult != null && _isNavMode)
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI 상태 텍스트 (탭바 바로 위)
                if (_aiOpen && _aiStatus.isNotEmpty) AiStatusBar(aiStatus: _aiStatus),
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
            Positioned.fill(
              child: MapboxEngine(
                initialCamera: _cameraInfo,
                onMapCreated: _onMapCreated,
              ),
            ),

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

            // G1: Seoul Live "위치 공유 중" 배지 (방 입장 + ghost 아닐 때).
            Positioned(
              top: MediaQuery.of(context).padding.top + 64,
              left: 0,
              right: 0,
              child: Center(child: LiveSharingBadge()),
            ),

            // 날씨/시간 위젯 (검색바 아래 좌측, 패널/검색/길찾기 시 페이드아웃)
            if (_subwayController.isActive)
              Positioned(
                top: MediaQuery.of(context).padding.top + 62,
                left: 16,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  opacity:
                      (_isNavMode ||
                          _isSearchFocused ||
                          _settingsOpen ||
                          _travelOpen)
                      ? 0.0
                      : 1.0,
                  child: IgnorePointer(
                    ignoring:
                        _isNavMode ||
                        _isSearchFocused ||
                        _settingsOpen ||
                        _travelOpen,
                    child: WeatherTimeWidget(
                      environment: _subwayController.environment,
                    ),
                  ),
                ),
              ),

            // 위성지도 토글 버튼 (우상단)
            Positioned(
              top: MediaQuery.of(context).padding.top + 64,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity:
                    (_isNavMode ||
                        _isSearchFocused ||
                        _settingsOpen ||
                        _travelOpen)
                    ? 0.0
                    : 1.0,
                child: IgnorePointer(
                  ignoring:
                      _isNavMode ||
                      _isSearchFocused ||
                      _settingsOpen ||
                      _travelOpen,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: AdaptiveGlassIconButton(
                      key: ValueKey(_satelliteOn),
                      icon: _satelliteOn
                          ? Icons.map_outlined
                          : Icons.travel_explore,
                      size: 44,
                      iconSize: 20,
                      tint: _satelliteOn
                          ? Colors.greenAccent
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
                opacity:
                    (_isNavMode ||
                        _selectedTrain != null ||
                        _selectedMapStation != null ||
                        _hideButtonForPanel)
                    ? 0.0
                    : 1.0,
                child: IgnorePointer(
                  ignoring:
                      _isNavMode ||
                      _selectedTrain != null ||
                      _selectedMapStation != null ||
                      _hideButtonForPanel,
                  child: AdaptiveGlassIconButton(
                    icon: Icons.my_location,
                    size: 48,
                    iconSize: 22,
                    tint: const Color(0xFF4A90D9),
                    onPressed: () async {
                      debugPrint('[Loc] 내 위치 버튼 눌림');
                      showAppSnackBar('위치 확인 중...');
                      try {
                        var permission = await geo.Geolocator.checkPermission();
                        debugPrint('[Loc] checkPermission: $permission');
                        if (permission == geo.LocationPermission.denied) {
                          permission = await geo.Geolocator.requestPermission();
                          debugPrint('[Loc] requestPermission: $permission');
                        }
                        if (permission == geo.LocationPermission.denied ||
                            permission ==
                                geo.LocationPermission.deniedForever) {
                          showAppSnackBar(
                              '위치 권한 거부됨 → iOS 설정 → Seoul Vista → 위치');
                          return;
                        }
                        final svc =
                            await geo.Geolocator.isLocationServiceEnabled();
                        debugPrint('[Loc] serviceEnabled: $svc');
                        if (!svc) {
                          showAppSnackBar('iOS 설정 → 개인정보 → 위치 서비스 가 꺼져있어요');
                          return;
                        }
                        // 직접 GPS fix 받아서 카메라 이동.
                        final pos = await geo.Geolocator.getCurrentPosition(
                          locationSettings: const geo.LocationSettings(
                            accuracy: geo.LocationAccuracy.high,
                            timeLimit: Duration(seconds: 20),
                          ),
                        );
                        debugPrint('[Loc] 위치 fix: ${pos.latitude},${pos.longitude}');
                        // 아바타 위치도 카메라와 함께 갱신 (스트림 distanceFilter 5m 로 인해
                        // 카메라만 이동하고 아바타는 옛 자리에 남아있는 현상 방지).
                        await _mapController?.setUserLocation(
                            pos.latitude, pos.longitude);
                        _mapController?.moveTo(pos.latitude, pos.longitude,
                            zoom: 16.0, pitch: 50.0);
                        showAppSnackBar('내 위치로 이동했어요');
                      } catch (e) {
                        debugPrint('[Loc] 실패: $e');
                        showAppSnackBar('위치 가져오기 실패: ${e.toString().substring(0, 50)}');
                      }
                    },
                  ),
                ),
              ),
            ),

            // 열차 상세 패널 (바텀 슬라이드 애니메이션)
            if (_lastSelectedTrain != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: _selectedTrain != null
                    ? Curves.easeOutCubic
                    : Curves.easeInCubic,
                bottom: _selectedTrain != null ? bottomInset : -280,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _selectedTrain != null ? 1.0 : 0.0,
                  child: TrainDetailPanel(
                    train: (_selectedTrain ?? _lastSelectedTrain)!,
                    delayMinutes:
                        _subwayController.trainDelays[(_selectedTrain ??
                                _lastSelectedTrain)!
                            .trainNo] ??
                        0,
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
                child: _busController.selectedBus != null &&
                        _busController.selectedBusRoute != null
                    ? BusDetailPanel(
                        bus: _busController.selectedBus!,
                        route: _busController.selectedBusRoute!,
                        onClose: () {
                          _busController.deselectBus();
                          setState(() {});
                        },
                      )
                    : const SizedBox.shrink(),
              ),

            // 비행기 상세 패널
            if (_flightController.selectedFlight != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                bottom: bottomInset,
                left: 0,
                right: 0,
                child: FlightDetailPanel(
                  flight: _flightController.selectedFlight!,
                  onClose: () {
                    _flightController.deselectFlight();
                    setState(() {});
                  },
                ),
              ),

            // 한강버스 상세 패널 (슬라이드 애니메이션)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: _busController.selectedVessel != null
                  ? Curves.easeOutCubic
                  : Curves.easeInCubic,
              bottom: _busController.selectedVessel != null
                  ? bottomInset
                  : -250,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: _busController.selectedVessel != null ? 1.0 : 0.0,
                child: () {
                  final v = _busController.selectedVessel;
                  if (v != null) _lastVessel = v;
                  final display = v ?? _lastVessel;
                  if (display == null) return const SizedBox(height: 150);
                  return VesselDetailPanel(
                    vessel: display,
                    onClose: () {
                      _busController.deselectVessel();
                      setState(() {});
                    },
                  );
                }(),
              ),
            ),

            // 역 상세 패널 (바텀 슬라이드 — 화면 30% 제한)
            if (_lastSelectedMapStation != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: _selectedMapStation != null
                    ? Curves.easeOutCubic
                    : Curves.easeInCubic,
                bottom: _selectedMapStation != null
                    ? bottomInset
                    : -(stationPanelMaxHeight + 50),
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _selectedMapStation != null ? 1.0 : 0.0,
                  child: ClipRect(
                    child: SizedBox(
                      height: stationPanelMaxHeight,
                      child: StationDetailPanel(
                        stationName:
                            (_selectedMapStation ?? _lastSelectedMapStation)!,
                        stationInfo: _selectedMapStation != null
                            ? _selectedMapStationInfo
                            : _lastSelectedMapStationInfo,
                        arrivals: _selectedMapStation != null
                            ? _selectedMapStationArrivals
                            : _lastMapStationArrivals,
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
              curve: _selectedPlace != null
                  ? Curves.easeOutCubic
                  : Curves.easeInCubic,
              bottom: _selectedPlace != null ? bottomInset : -250,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: _selectedPlace != null ? 1.0 : 0.0,
                child: _lastSelectedPlace != null
                    ? PlaceDetailPanel(
                        place: (_selectedPlace ?? _lastSelectedPlace)!,
                        onClose: () => setState(() {
                          _setSelectedPlace(null);
                          _removePlaceMarker();
                        }),
                        onShowWebView: () =>
                            _showPlaceWebView(_selectedPlace ?? _lastSelectedPlace!),
                        onDeparture: _startNavWithDeparture,
                        onArrival: _startNavWithArrival,
                      )
                    : const SizedBox(height: 200),
              ),
            ),

            // 한강버스 선착장 패널 (바텀 슬라이드 애니메이션)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: _selectedRiverStop != null
                  ? Curves.easeOutCubic
                  : Curves.easeInCubic,
              bottom: _selectedRiverStop != null ? bottomInset : -250,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: _selectedRiverStop != null ? 1.0 : 0.0,
                child: _lastSelectedRiverStop != null
                    ? RiverBusStopPanel(
                        stop: (_selectedRiverStop ?? _lastSelectedRiverStop)!,
                        onClose: () => setState(() => _setSelectedRiverStop(null)),
                        onDeparture: _startNavWithDeparture,
                        onArrival: _startNavWithArrival,
                      )
                    : const SizedBox(height: 200),
              ),
            ),

            // 경로 결과 바텀 패널 (설정 패널 스타일)
            _buildRouteResultOverlay(context, screenHeight),

            // 설정 패널 오버레이 — ProfileView 의 톱니바퀴에서만 진입.
            _buildSettingsOverlay(context, screenHeight, bottomInset),

            // 여행 패널 오버레이 (탭 3)
            _buildTravelOverlay(context, screenHeight),

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
            ProfileToast(visible: _showProfileToast),
          ],
        ),
      ),
    );
  }




  RiverBusVessel? _lastVessel;




  void _dismissAi() {
    if (_aiOpen && !_aiClosing) {
      setState(() => _aiClosing = true);
    }
  }

  void _delayShowButton() {
    // 패널 닫힌 후 0.5초 뒤에 버튼 표시
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_settingsOpen && !_recommendOpen && !_travelOpen) {
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
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProfileView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
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
            name: name,
            address: '',
            category: '저장된 장소',
            lat: lat,
            lng: lng,
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
              if (d < bestDist) {
                bestDist = d;
                best = r;
              }
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
    Future.delayed(
      const Duration(milliseconds: 100),
      () => _riverStopJustOpened = false,
    );
    _mapController?.moveTo(stop.lat, stop.lng, zoom: 16.0, pitch: 50.0);
    // 바닥 glow 효과 (한강버스 전용)
    _mapController?.showRiverBusHighlight(stop.lat, stop.lng);
    setState(() {
      _setSelectedRiverStop(stop);
      _setSelectedPlace(null);
      _removePlaceMarker();
    });
  }



  /// 각 구간별 실시간 열차/버스 도착 정보 (segment index → 도착 메시지)
  Map<int, List<String>> _segmentArrivals = {};
  bool _routeNavigationActive = false;
  // 사용자가 "시작" 버튼을 눌러 명시적 turn-by-turn 모드인지.
  // true: 카메라가 사용자 위치/방향을 따라 이동.
  // false: 길찾기 결과 받자마자 자동으로 켜진 백그라운드 추적 — 활성 구간/도착 정보만 갱신, 카메라는 사용자 컨트롤 보존.
  bool _routeNavigationManual = false;
  int _activeNavigationSegmentIndex = 0;
  Timer? _routeNavigationTimer;
  // 실시간 위치 스트림 — 길찾기 결과 표시 중 활성 구간 추적/도착 정보 즉시 갱신용.
  StreamSubscription<geo.Position>? _navLocationSub;

  /// 사용자가 지정한 출발 시각. null 이면 현재 시각.
  /// 결과 시트의 "출발 → 도착" 시각 표시에만 사용 (그래프 비용은 시간 의존성 없음).
  DateTime? _customDepartureTime;

  /// 모든 탑승 구간의 실시간 도착 정보 시작 (15초 주기) + 자동 위치 추적.
  void _loadBoardingArrival(PathResult route) {
    _arrivalRefreshTimer?.cancel();
    _boardingArrivals = [];
    _segmentArrivals = {};

    _updateAllSegmentArrivals(route);
    _arrivalRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        _updateAllSegmentArrivals(route);
        _pushLiveActivityUpdate(); // 도착 정보 갱신마다 Live Activity 도 함께
      },
    );

    // 길찾기 결과 표시되자마자 자동으로 위치 추적 시작 — 사용자가 "시작" 누르지 않아도 됨.
    if (!_routeNavigationActive) {
      _startRouteNavigation(shrinkSheet: false);
    }
    // 다이나믹 아일랜드/Live Activity 시작 (도착 정보가 채워지기 전이라도 헤드라인은 표시).
    _pushLiveActivityUpdate(forceStart: true);
  }

  /// 모든 지하철/버스 구간의 도착 정보 갱신
  void _updateAllSegmentArrivals(PathResult route) {
    for (int i = 0; i < route.segments.length; i++) {
      final seg = route.segments[i];
      if (seg.isTransfer) continue;
      if (seg.mode == TransportMode.subway) {
        _updateSegmentArrival(i, seg);
      } else if (seg.mode == TransportMode.bus) {
        _updateBusSegmentArrival(i, seg);
      }
    }
  }

  Future<void> _updateBusSegmentArrival(int segIdx, PathSegment seg) async {
    final routeName = seg.lineId.startsWith('bus_')
        ? seg.lineId.substring(4)
        : seg.lineName.replaceAll('번 버스', '');
    final route = SeoulBusData.getRouteByName(routeName);
    if (route == null || seg.stations.isEmpty) {
      if (mounted) setState(() => _segmentArrivals[segIdx] = ['버스 도착 정보 확인 중']);
      return;
    }
    if (!RegExp(r'^\d{9}$').hasMatch(route.routeId)) {
      if (mounted)
        setState(() => _segmentArrivals[segIdx] = ['버스 실시간 데이터 갱신 필요']);
      return;
    }

    final stopName = seg.stations.first;
    final stop = route.stops.where((s) => s.name == stopName).firstOrNull;
    if (stop == null || stop.stId.isEmpty) {
      if (mounted) setState(() => _segmentArrivals[segIdx] = ['정류소 정보 확인 중']);
      return;
    }

    final info = await SeoulBusService.instance.fetchArrivalByRouteAndStation(
      route.routeId,
      stop.stId,
      stop.seq,
    );
    if (!mounted) return;

    final msgs = <String>[];
    if (info != null) {
      if (info.arrmsg1.isNotEmpty && info.arrmsg1 != '정보없음') {
        msgs.add(_compactBusArrivalMessage(info.arrmsg1));
      }
      if (info.arrmsg2.isNotEmpty && info.arrmsg2 != '정보없음') {
        msgs.add(_compactBusArrivalMessage(info.arrmsg2));
      }
    }
    if (msgs.isEmpty) msgs.add('${seg.lineName} 도착 정보 없음');
    setState(() => _segmentArrivals[segIdx] = msgs.take(2).toList());
  }

  String _compactBusArrivalMessage(String message) {
    return message
        .replaceAll('분후 도착', '분')
        .replaceAll('곧 도착', '곧 도착')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 개별 구간의 실시간 도착 정보 갱신 (네이버 열차 위치 기반)
  void _updateSegmentArrival(int segIdx, PathSegment seg) {
    final stationName = seg.stations.first;
    final lineId = seg.lineId;
    final lineName = SubwayColors.lineNames[lineId] ?? '';

    final trains = _subwayController.currentTrains;
    final lineTrains = trains.where((t) => t.subwayId == lineId).toList();

    if (lineTrains.isEmpty) {
      if (mounted) {
        setState(() => _segmentArrivals[segIdx] = ['$lineName 열차 정보 로딩 중']);
      }
      return;
    }

    final lineStations = SeoulSubwayData.getLineStations(lineId);
    final boardingIdx = lineStations.indexWhere((s) => s.name == stationName);
    if (boardingIdx < 0) return;

    // 방향 판단
    int targetDir = 1;
    if (seg.stations.length >= 2) {
      final nextIdx = lineStations.indexWhere((s) => s.name == seg.stations[1]);
      if (nextIdx >= 0) targetDir = nextIdx > boardingIdx ? 1 : 0;
    }

    // 해당 방향 + 탑승역 앞에 있는 열차
    final approaching = <({String terminal, int stationsAway})>[];
    for (final t in lineTrains) {
      if (t.direction != targetDir) continue;
      final trainIdx = lineStations.indexWhere((s) => s.name == t.stationName);
      if (trainIdx < 0) continue;
      final ahead = targetDir == 1
          ? trainIdx <= boardingIdx
          : trainIdx >= boardingIdx;
      if (!ahead) continue;
      approaching.add((
        terminal: t.terminalName,
        stationsAway: (boardingIdx - trainIdx).abs(),
      ));
    }

    approaching.sort((a, b) => a.stationsAway.compareTo(b.stationsAway));

    final msgs = <String>[];
    for (int i = 0; i < approaching.length && i < 2; i++) {
      final t = approaching[i];
      final etaMin = t.stationsAway * 2;
      msgs.add(
        etaMin == 0 ? '${t.terminal}행 곧 도착' : '${t.terminal}행 ${etaMin}분',
      );
    }

    if (msgs.isEmpty) msgs.add('$lineName 열차 접근 중');
    if (mounted) setState(() => _segmentArrivals[segIdx] = msgs);
  }

  /// 경로 스텝 탭 → 해당 구간으로 카메라 줌인
  void _focusOnSegment(PathSegment seg) {
    final mc = _mapController;
    if (mc == null || seg.stations.isEmpty) return;

    // 구간 좌표 수집
    List<List<double>> coords;
    if (seg.mode == TransportMode.bus) {
      coords = _resolveBusStopCoords(seg.lineId, seg.stations);
    } else {
      coords = _resolveStationCoords(seg.stations);
    }

    if (coords.isEmpty) return;

    // bounding box 계산
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final c in coords) {
      if (c[0] < minLat) minLat = c[0];
      if (c[0] > maxLat) maxLat = c[0];
      if (c[1] < minLng) minLng = c[1];
      if (c[1] > maxLng) maxLng = c[1];
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final span = max(maxLat - minLat, maxLng - minLng);

    // 구간 크기에 맞는 줌
    final zoom = span < 0.002
        ? 17.0
        : span < 0.005
        ? 16.0
        : span < 0.01
        ? 15.0
        : span < 0.03
        ? 14.0
        : span < 0.08
        ? 13.0
        : 12.0;

    // 출발→도착 방향 bearing
    double bearing = 0;
    if (coords.length >= 2) {
      final first = coords.first;
      final last = coords.last;
      final dLng = (last[1] - first[1]) * pi / 180;
      final lat1 = first[0] * pi / 180;
      final lat2 = last[0] * pi / 180;
      final y = sin(dLng) * cos(lat2);
      final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
      bearing = (atan2(y, x) * 180 / pi + 360) % 360;
    }

    mc.moveTo(centerLat, centerLng, zoom: zoom, pitch: 50, bearing: bearing);
  }

  void _focusOnRoutePoint(PathSegment seg, String stationName) {
    final coord = _resolveRoutePointCoord(seg, stationName);
    if (coord == null) {
      _focusOnSegment(seg);
      return;
    }
    _mapController?.moveTo(coord[0], coord[1], zoom: 17.0, pitch: 55);
  }

  List<double>? _resolveRoutePointCoord(PathSegment seg, String stationName) {
    if (seg.mode == TransportMode.bus) {
      final routeName = seg.lineId.startsWith('bus_')
          ? seg.lineId.substring(4)
          : seg.lineName.replaceAll('번 버스', '');
      final route = SeoulBusData.getRouteByName(routeName);
      final stop = route?.stops.where((s) => s.name == stationName).firstOrNull;
      if (stop != null) return [stop.lat, stop.lng];
    }
    final direct = _resolveStationCoord(stationName);
    if (direct != null) return direct;
    if (seg.stations.first == stationName &&
        seg.startLat != null &&
        seg.startLng != null) {
      return [seg.startLat!, seg.startLng!];
    }
    if (seg.stations.last == stationName &&
        seg.endLat != null &&
        seg.endLng != null) {
      return [seg.endLat!, seg.endLng!];
    }
    return null;
  }

  /// 위치 추적 + 활성 구간 추적 시작.
  /// [shrinkSheet] 가 true 면 시트를 축소해 카메라/턴바이턴 모드로 전환.
  /// 길찾기 결과 자동 트리거 시에는 false (사용자 결과 시트 보존).
  void _startRouteNavigation({bool shrinkSheet = true}) {
    if (_routeResult == null) return;
    final firstIndex = _routeResult!.segments.indexWhere((s) => !s.isTransfer);
    if (firstIndex < 0) return;
    setState(() {
      _routeNavigationActive = true;
      _routeNavigationManual = shrinkSheet;
      _activeNavigationSegmentIndex = firstIndex;
      if (shrinkSheet) _routeSheetFraction = 0.24;
    });
    if (shrinkSheet) _focusNavigationStep();

    // 8초 백업 폴링 (스트림이 일시 정지되거나 권한 문제 시 안전망).
    _routeNavigationTimer?.cancel();
    _routeNavigationTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _syncNavigationToCurrentLocation(),
    );

    // 실시간 위치 스트림 구독 — 10m 이동마다 즉시 활성 구간/도착 정보 갱신.
    _navLocationSub?.cancel();
    _navLocationSub =
        geo.Geolocator.getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          _syncNavigationToCurrentLocation(pos: pos);
        }, onError: (_) {});

    _syncNavigationToCurrentLocation();
  }

  void _stopRouteNavigation() {
    _routeNavigationTimer?.cancel();
    _navLocationSub?.cancel();
    _navLocationSub = null;
    setState(() {
      _routeNavigationActive = false;
      _routeNavigationManual = false;
    });
  }

  Future<void> _showDepartureTimePicker() async {
    final result = await showDepartureTimePicker(
      context,
      current: _customDepartureTime,
    );
    if (!mounted || !result.changed) return;
    setState(() => _customDepartureTime = result.time);
  }

  void _advanceNavigationStep() {
    final route = _routeResult;
    if (route == null) return;
    for (
      int i = _activeNavigationSegmentIndex + 1;
      i < route.segments.length;
      i++
    ) {
      if (!route.segments[i].isTransfer) {
        setState(() => _activeNavigationSegmentIndex = i);
        _refreshActiveSegmentArrival(); // 새 구간 도착 정보 즉시 갱신
        _focusNavigationStep();
        return;
      }
    }
    _stopRouteNavigation();
  }

  /// 현재 활성 구간의 도착 정보를 즉시 새로고침 (다음 폴링 사이클을 기다리지 않음).
  void _refreshActiveSegmentArrival() {
    final route = _routeResult;
    if (route == null) return;
    final idx = _activeNavigationSegmentIndex;
    if (idx < 0 || idx >= route.segments.length) return;
    final seg = route.segments[idx];
    if (seg.isTransfer) return;
    if (seg.mode == TransportMode.subway) {
      _updateSegmentArrival(idx, seg);
    } else if (seg.mode == TransportMode.bus) {
      _updateBusSegmentArrival(idx, seg);
    }
    _pushLiveActivityUpdate();
  }

  /// 활성 구간 정보를 다이나믹 아일랜드/잠금화면 Live Activity 로 push.
  /// [forceStart] = true 면 새 Activity 시작 (아직 없을 때).
  void _pushLiveActivityUpdate({bool forceStart = false}) {
    final route = _routeResult;
    if (route == null) return;
    final idx = _activeNavigationSegmentIndex;
    if (idx < 0 || idx >= route.segments.length) return;
    final seg = route.segments[idx];
    if (seg.isTransfer) return;

    // 도착 메시지에서 ETA 분 추출 ("143번 5분", "곧 도착").
    final arrivals = _segmentArrivals[idx];
    int eta = 0;
    String detail = '';
    if (arrivals != null && arrivals.isNotEmpty) {
      detail = arrivals.first;
      final m = RegExp(r'(\d+)\s*분').firstMatch(detail);
      if (m != null) {
        eta = int.tryParse(m.group(1)!) ?? 0;
      } else if (detail.contains('곧 도착')) {
        eta = 0;
      }
    }

    final headline = '${seg.lineName} → ${seg.stations.last}';
    final remainingMin = (route.totalTimeSec / 60).ceil();
    final color = seg.mode == TransportMode.subway
        ? SubwayColors.lineColors[seg.lineId]
        : (seg.mode == TransportMode.bus ? BusColors.trunk : null);
    final hex = color == null ? null : _colorToHex(color);

    if (forceStart) {
      LiveActivityService.instance.start(
        headline: headline,
        detail: detail,
        etaMinutes: eta,
        lineColorHex: hex,
        totalMinutes: remainingMin,
        destination: route.arrival,
      );
    } else {
      LiveActivityService.instance.update(
        headline: headline,
        detail: detail,
        etaMinutes: eta,
        lineColorHex: hex,
        totalMinutes: remainingMin,
        destination: route.arrival,
      );
    }
  }

  String _colorToHex(Color c) {
    final argb = c.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// 위치 동기화 — 위치 스트림 콜백 또는 백업 폴링이 호출.
  /// [pos] 가 주어지면 사용, 아니면 현재 위치를 강제 새로고침해 받음.
  Future<void> _syncNavigationToCurrentLocation({geo.Position? pos}) async {
    final route = _routeResult;
    if (!_routeNavigationActive || route == null) return;

    pos ??= await PlaceSearchService.instance.getCurrentPosition(
      forceRefresh: true,
    );
    if (!mounted || !_routeNavigationActive || _routeResult == null) return;

    final lat = pos.latitude;
    final lng = pos.longitude;
    int bestIndex = _activeNavigationSegmentIndex;
    double bestDistance = double.infinity;

    for (int i = 0; i < route.segments.length; i++) {
      final seg = route.segments[i];
      if (seg.isTransfer) continue;
      final coords = _segmentNavigationCoords(seg);
      if (coords.length < 2) continue;
      final dist = distanceToPolylineMeters(lat, lng, coords);
      if (dist < bestDistance) {
        bestDistance = dist;
        bestIndex = i;
      }
    }

    final indexChanged =
        bestDistance < 300 && bestIndex != _activeNavigationSegmentIndex;
    if (indexChanged) {
      setState(() => _activeNavigationSegmentIndex = bestIndex);
      _refreshActiveSegmentArrival(); // 활성 구간 변경 시 새 구간 도착 정보 즉시 갱신
    }

    final active = _activeNavigationSegment;
    if (active == null) return;
    final coords = _segmentNavigationCoords(active);
    if (coords.isEmpty) return;

    final end = coords.last;
    final endDistance = distanceMeters(lat, lng, end[0], end[1]);
    if (endDistance < 80) {
      _advanceNavigationStep();
      return;
    }

    // 카메라 이동은 사용자가 명시적으로 "시작" 한 turn-by-turn 모드일 때만.
    // 자동 시작(_loadBoardingArrival 트리거) 시에는 도착 정보만 갱신하고 카메라는 사용자 컨트롤 보존.
    if (_routeNavigationManual) {
      final bearing = bearingBetween(lat, lng, end[0], end[1]);
      _mapController?.moveTo(lat, lng, zoom: 17.0, pitch: 60, bearing: bearing);
    }
  }

  List<List<double>> _segmentNavigationCoords(PathSegment seg) {
    if (seg.mode == TransportMode.bus) {
      return _resolveBusStopCoords(seg.lineId, seg.stations);
    }
    if (seg.mode == TransportMode.walk) {
      final coords = <List<double>>[];
      if (seg.startLat != null && seg.startLng != null) {
        coords.add([seg.startLat!, seg.startLng!]);
      } else if (seg.stations.isNotEmpty) {
        final start = _resolveRoutePointCoord(seg, seg.stations.first);
        if (start != null) coords.add(start);
      }
      if (seg.endLat != null && seg.endLng != null) {
        coords.add([seg.endLat!, seg.endLng!]);
      } else if (seg.stations.isNotEmpty) {
        final end = _resolveRoutePointCoord(seg, seg.stations.last);
        if (end != null) coords.add(end);
      }
      return coords;
    }
    return _resolveStationCoords(seg.stations);
  }


  void _focusNavigationStep() {
    final route = _routeResult;
    if (route == null || _activeNavigationSegmentIndex >= route.segments.length)
      return;
    _focusOnSegment(route.segments[_activeNavigationSegmentIndex]);
  }

  PathSegment? get _activeNavigationSegment {
    final route = _routeResult;
    if (route == null ||
        _activeNavigationSegmentIndex >= route.segments.length) {
      return null;
    }
    return route.segments[_activeNavigationSegmentIndex];
  }

  Widget _routePointText(
    PathSegment seg,
    String stationName, {
    required TextStyle style,
  }) {
    return RoutePointText(
      stationName: stationName,
      style: style,
      onTap: () => _focusOnRoutePoint(seg, stationName),
    );
  }





  Future<void> _preloadDirections() async {
    if (_routeResult == null) return;
    final dep = _routeResult!.departure;
    final arr = _routeResult!.arrival;
    final fromCoord = _resolveStationCoord(dep);
    final toCoord = _resolveStationCoord(arr);
    if (fromCoord == null || toCoord == null) return;

    final ds = DirectionsService.instance;
    // 자동차
    ds.getDrivingRoute(fromCoord[0], fromCoord[1], toCoord[0], toCoord[1]).then(
      (r) {
        if (r != null && mounted) setState(() => _directionsCache[1] = r);
      },
    );
    // 도보
    ds.getWalkingRoute(fromCoord[0], fromCoord[1], toCoord[0], toCoord[1]).then(
      (r) {
        if (r != null && mounted) setState(() => _directionsCache[2] = r);
      },
    );
  }

  List<double>? _resolveStationCoord(String name) {
    if (name == '내 위치') return null;
    // 지하철역
    for (final e in SubwayColors.lineColors.entries) {
      for (final s in SeoulSubwayData.getLineStations(e.key)) {
        if (s.name == name) return [s.lat, s.lng];
      }
    }
    // 버스 정류소
    for (final route in SeoulBusData.allRoutes) {
      for (final stop in route.stops) {
        if (stop.name == name) return [stop.lat, stop.lng];
      }
    }
    // 한강버스 선착장
    for (final s in RiverBusData.stops) {
      if (name.contains(s.name)) return [s.lat, s.lng];
    }
    // PathResult의 첫/마지막 구간에서 좌표 추출 (장소명일 때)
    if (_routeResult != null) {
      final segs = _routeResult!.segments;
      if (segs.isNotEmpty) {
        if (name == _routeResult!.departure) {
          final coords = _resolveStationCoords(segs.first.stations);
          if (coords.isNotEmpty) return coords.first;
        }
        if (name == _routeResult!.arrival) {
          final coords = _resolveStationCoords(segs.last.stations);
          if (coords.isNotEmpty) return coords.last;
        }
      }
    }
    return null;
  }

  void _switchTransportMode(int mode) {
    setState(() => _transportMode = mode);
    _clearRouteFromMap();
    if (mode == 0) {
      // 대중교통 — 로컬 통합 길찾기 (지하철+버스)
      if (_routeResult != null) {
        _drawRouteOnMap(_routeResult!);
      }
    } else {
      final result = _directionsCache[mode];
      if (result != null) _drawDirectionsOnMap(result);
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
    _mapController?.addPolyline(
      'directions_route',
      coords,
      color: color,
      width: 5.0,
      opacity: 0.8,
    );
  }

  void _startNavWithDeparture(String name, {double? lat, double? lng}) {
    _searchBarKey.currentState?.enterNavWithDeparture(
      name,
      lat: lat,
      lng: lng,
    );
  }

  void _startNavWithArrival(String name, {double? lat, double? lng}) {
    _searchBarKey.currentState?.enterNavWithArrival(name, lat: lat, lng: lng);
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
          ..setUserAgent(
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) {
                controller.runJavaScript(hideHeaderJS);
                Future.delayed(const Duration(milliseconds: 800), () {
                  controller.runJavaScript(hideHeaderJS);
                });
                Future.delayed(const Duration(seconds: 2), () {
                  controller.runJavaScript(hideHeaderJS);
                });
              },
            ),
          )
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
                    Expanded(
                      child: Text(
                        place.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.open_in_new,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () => launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(0),
                  ),
                  child: WebViewWidget(controller: controller),
                ),
              ),
            ],
          ),
        );
      },
    );
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
              _mapController?.moveTo(
                station.lat,
                station.lng,
                zoom: 16,
                pitch: 50,
              );
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
              _mapController?.moveTo(
                station.lat,
                station.lng,
                zoom: 15,
                pitch: 45,
              );
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
          FavoritesService.instance.toggle(
            FavoritePlace(
              name: _selectedPlace!.name,
              address: _selectedPlace!.address,
              category: _selectedPlace!.category,
              lat: _selectedPlace!.lat,
              lng: _selectedPlace!.lng,
            ),
          );
          setState(() {});
        }
        break;
      case AiAction.openRecommendation:
        _dismissAi();
        Future.delayed(const Duration(milliseconds: 600), () {
          setState(() {
            _recommendOpen = true;
            _hideButtonForPanel = true;
          });
        });
        break;
      case AiAction.openSaved:
        _dismissAi();
        Future.delayed(const Duration(milliseconds: 600), () {
          setState(() {
            _savedOpen = true;
            _hideButtonForPanel = true;
          });
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
        final geoPlaces = await GeminiService.instance.geocodeAll(
          result.places,
        );
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
      DebugLog.log('[AI Action] URL 분석 실패: $e');
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
      DebugLog.log('[AI Action] 플랜 생성 실패: $e');
    }
  }

  /// AI 요청으로 플랜 생성 (텍스트 기반)
  Future<void> _createPlanFromAi(String style, String? placesJson) async {
    DebugLog.log('[AI Action] Create plan: style=$style');
  }

  // ── 하단 탭바 (리퀴드 글라스) ──
  Widget _buildBottomTabBar() {
    // 순서: 추천(0) | 저장(1) | 지도(2, 가운데) | 여행(3) | AI(4)
    // 설정은 더 이상 탭에 없음 — ProfileView 의 톱니바퀴 아이콘에서 진입.
    final currentIndex = _recommendOpen
        ? 0
        : _savedOpen
        ? 1
        : _travelOpen
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
            _travelOpen = false;
            _savedOpen = false;
            _dismissAi();
            if (_recommendOpen) {
              _recommendOpen = false;
              _delayShowButton();
            } else {
              _recommendOpen = true;
              _hideButtonForPanel = true;
            }
          } else if (index == 1) {
            // 저장
            _travelOpen = false;
            _recommendOpen = false;
            _dismissAi();
            if (_savedOpen) {
              _savedOpen = false;
              _delayShowButton();
            } else {
              _savedOpen = true;
              _hideButtonForPanel = true;
            }
          } else if (index == 2) {
            // 지도
            final wasOpen = _travelOpen || _recommendOpen || _savedOpen;
            _travelOpen = false;
            _recommendOpen = false;
            _savedOpen = false;
            _dismissAi();
            if (wasOpen) _delayShowButton();
          } else if (index == 3) {
            // 여행
            _recommendOpen = false;
            _savedOpen = false;
            _dismissAi();
            if (_travelOpen) {
              _travelOpen = false;
              _delayShowButton();
            } else {
              _travelOpen = true;
              _hideButtonForPanel = true;
            }
          } else if (index == 4) {
            // AI
            final wasOpen = _travelOpen || _recommendOpen || _savedOpen;
            _travelOpen = false;
            _recommendOpen = false;
            _savedOpen = false;
            if (wasOpen) _delayShowButton();
            if (_aiOpen) {
              _dismissAi();
            } else {
              _aiOpen = true;
              _aiClosing = false;
            }
          }
        });
      },
      // Seoul Live 활성 시 가운데 탭이 '지도'→'세계' (Icons.map→Icons.public_rounded) 로 모핑.
      // 같은 탭 인덱스(2) 를 유지해 onTap 동작은 동일.
      items: [
        const AdaptiveTabItem(label: '추천', icon: Icons.explore),
        const AdaptiveTabItem(label: '저장', icon: Icons.bookmark),
        MultiplayerService.instance.seoulLiveActive
            ? const AdaptiveTabItem(label: '세계', icon: Icons.public_rounded)
            : const AdaptiveTabItem(label: '지도', icon: Icons.map),
        const AdaptiveTabItem(label: '여행', icon: Icons.calendar_month),
        const AdaptiveTabItem(label: 'AI', icon: Icons.auto_awesome),
      ],
    );
  }

  // ── 경로 결과 바텀 시트 (구글맵 스타일 세로 타임라인) ──
  final Set<int> _expandedSegments = {};

  Widget _buildRouteResultOverlay(BuildContext context, double screenHeight) {
    final hasRoute = _routeResult != null && _isNavMode;
    if (!hasRoute) return const SizedBox.shrink();

    final r = _routeResult!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final mutedColor = onSurface.withValues(alpha: 0.5);

    // 세로 타임라인 위젯 빌드
    final timelineItems = <Widget>[];

    // ── 출발 ──
    timelineItems.add(
      _timelineRow(
        dotColor: const Color(0xFF34C759),
        dotHollow: true,
        lineColor: null,
        lineBelow: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: r.segments.isNotEmpty
              ? _routePointText(
                  r.segments.first,
                  r.departure,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                )
              : Text(
                  r.departure,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
        ),
      ),
    );

    for (int i = 0; i < r.segments.length; i++) {
      final seg = r.segments[i];
      if (seg.isTransfer) continue;

      final segColor = segmentColorForBar(seg);
      final timeMins = (seg.travelTimeSec / 60).ceil();
      final isWalk = seg.mode == TransportMode.walk;
      final isBus = seg.mode == TransportMode.bus;
      final isSubway = seg.mode == TransportMode.subway;
      final isExpanded = _expandedSegments.contains(i);

      if (isWalk) {
        // ── 도보 구간 ──
        String walkDesc = '도보';
        final walkSteps = _walkStepsCache[i];
        if (walkSteps != null && walkSteps.isNotEmpty) {
          final exitStep = walkSteps
              .where((s) => s.description.contains('출구'))
              .firstOrNull;
          if (exitStep != null) walkDesc = exitStep.description;
        }
        timelineItems.add(
          _timelineRow(
            dotColor: null,
            lineColor: Colors.grey.withValues(alpha: 0.3),
            lineDashed: true,
            lineBelow: true,
            child: GestureDetector(
              onTap: () => _focusOnSegment(seg),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.directions_walk, size: 16, color: mutedColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        walkDesc,
                        style: TextStyle(fontSize: 13, color: mutedColor),
                      ),
                    ),
                    Text(
                      '$timeMins분',
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        // ── 지하철/버스 구간 ──
        final stationCount = seg.stations.length;
        final hasMiddleStations = stationCount > 2;

        timelineItems.add(
          _timelineRow(
            dotColor: segColor,
            dotHollow: false,
            lineColor: segColor,
            lineBelow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _routePointText(
                  seg,
                  seg.stations.first,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                // 노선 뱃지 + 방면
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: segColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBus ? Icons.directions_bus : Icons.train,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            seg.lineName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${seg.stations.last} 방면',
                        style: TextStyle(
                          fontSize: 14,
                          color: onSurface.withValues(alpha: 0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 실시간 열차/버스 도착
                if ((isSubway || isBus) && _segmentArrivals.containsKey(i)) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: segColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: segColor.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isBus ? Icons.directions_bus : Icons.train,
                          size: 14,
                          color: segColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _segmentArrivals[i]!.join('  ·  '),
                            style: TextStyle(
                              fontSize: 13,
                              color: segColor,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // 역 수 + 펼침 (AnimatedSize로 부드럽게)
                GestureDetector(
                  onTap: hasMiddleStations
                      ? () => setState(() {
                          if (isExpanded)
                            _expandedSegments.remove(i);
                          else
                            _expandedSegments.add(i);
                        })
                      : null,
                  child: Row(
                    children: [
                      if (hasMiddleStations)
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: segColor,
                          ),
                        ),
                      if (hasMiddleStations) const SizedBox(width: 4),
                      Text(
                        '$stationCount개 ${isBus ? "정류장" : "역"} 이동 · $timeMins분',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasMiddleStations ? segColor : mutedColor,
                          fontWeight: hasMiddleStations
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // 중간역 펼침 (AnimatedSize)
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: isExpanded && hasMiddleStations
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            children: seg.stations
                                .sublist(1, stationCount - 1)
                                .map(
                                  (name) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: segColor.withValues(
                                                alpha: 0.5,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _routePointText(
                                            seg,
                                            name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: onSurface.withValues(
                                                alpha: 0.65,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 10),
                // 하차역
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: segColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _routePointText(
                      seg,
                      seg.stations.last,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: mutedColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '하차',
                        style: TextStyle(
                          fontSize: 10,
                          color: mutedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }

    // ── 도착 ──
    timelineItems.add(
      _timelineRow(
        dotColor: const Color(0xFFFF453A),
        dotHollow: true,
        lineColor: null,
        lineBelow: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: r.segments.isNotEmpty
              ? _routePointText(
                  r.segments.last,
                  r.arrival,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                )
              : Text(
                  r.arrival,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
        ),
      ),
    );

    return RouteSheetShell(
      isDark: isDark,
      timelineItems: timelineItems,
      sheetFraction: _routeSheetFraction,
      onFractionChange: (next) =>
          setState(() => _routeSheetFraction = next),
      headerChildren: [
      // 핸들
      Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : Colors.black12,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      // ── 경로 타입 + 교통수단 탭 ──
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              r.searchType == PathSearchType.duration
                  ? '최적'
                  : r.searchType == PathSearchType.distance
                  ? '최단'
                  : '최소환승',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ),
          if (r.transferCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '환승 ${r.transferCount}회',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
          const Spacer(),
          // 교통수단 미니 탭
          ...[0, 1, 2].map((m) {
            final icons = [
              Icons.directions_transit,
              Icons.directions_car,
              Icons.directions_walk,
            ];
            final selected = _transportMode == m;
            return GestureDetector(
              onTap: () => _switchTransportMode(m),
              child: Container(
                padding: const EdgeInsets.all(7),
                margin: const EdgeInsets.only(left: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? onSurface.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icons[m],
                  size: 18,
                  color: selected ? onSurface : mutedColor,
                ),
              ),
            );
          }),
        ],
      ),
      const SizedBox(height: 12),
      if (_routeNavigationActive && _activeNavigationSegment != null) ...[
        NavigationBanner(
          activeSegment: _activeNavigationSegment,
          onSurface: onSurface,
          mutedColor: mutedColor,
          onAdvance: _advanceNavigationStep,
        ),
        const SizedBox(height: 12),
      ],
      // ── 큰 시간 + 출발~도착 시각 + 요금 ──
      () {
        // _customDepartureTime 이 지정돼 있으면 그 시각, 아니면 현재 시각 기준.
        final depTime = _customDepartureTime ?? DateTime.now();
        final totalSec = _transportMode == 0
            ? r.totalTimeSec
            : (_directionsCache[_transportMode]?.durationSec ?? 0);
        final arriveTime = depTime.add(Duration(seconds: totalSec));
        final depStr =
            '${depTime.hour.toString().padLeft(2, '0')}:${depTime.minute.toString().padLeft(2, '0')}';
        final arrStr =
            '${arriveTime.hour.toString().padLeft(2, '0')}:${arriveTime.minute.toString().padLeft(2, '0')}';
        // 기본 요금 계산 (지하철 1,400원 + 환승 0원)
        final fare =
            1400 +
            (r.segments
                    .where((s) => s.mode == TransportMode.bus && !s.isTransfer)
                    .length *
                0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 소요시간 큰 글자
            Text(
              _transportMode == 0
                  ? r.totalTimeFormatted
                  : _directionsCache[_transportMode] != null
                  ? formatDuration(
                      _directionsCache[_transportMode]!.durationSec,
                    )
                  : '...',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: onSurface,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            // 출발 시각 → 도착 시각 + 요금. 출발 시각 탭하면 변경 picker.
            Row(
              children: [
                GestureDetector(
                  onTap: _showDepartureTimePicker,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$depStr 출발',
                        style: TextStyle(
                          fontSize: 14,
                          color: _customDepartureTime != null
                              ? onSurface
                              : mutedColor,
                          fontWeight: _customDepartureTime != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 11,
                        color: mutedColor,
                      ),
                    ],
                  ),
                ),
                Text(' — ', style: TextStyle(fontSize: 14, color: mutedColor)),
                Text(
                  '$arrStr 도착',
                  style: TextStyle(fontSize: 14, color: mutedColor),
                ),
                const Spacer(),
                if (_transportMode == 0)
                  Text(
                    '₩${formatWon(fare)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                const SizedBox(width: 8),
                if (_transportMode == 0)
                  GestureDetector(
                    onTap: _routeNavigationActive
                        ? _stopRouteNavigation
                        : _startRouteNavigation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _routeNavigationActive
                            ? AppColors.danger.withValues(alpha: 0.12)
                            : AppColors.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _routeNavigationActive
                                ? Icons.stop_rounded
                                : Icons.navigation_rounded,
                            size: 14,
                            color: _routeNavigationActive
                                ? AppColors.danger
                                : AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _routeNavigationActive ? '종료' : '시작',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _routeNavigationActive
                                  ? AppColors.danger
                                  : AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }(),
      const SizedBox(height: 14),
      // ── 가로 모드 바 (도보→지하철→도보 시각화) ──
      () {
        final segs = r.segments.where((s) => !s.isTransfer).toList();
        final total = segs.fold<int>(0, (s, seg) => s + seg.travelTimeSec);
        if (total == 0) return const SizedBox.shrink();
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    for (int i = 0; i < segs.length; i++) ...[
                      if (i > 0) const SizedBox(width: 1),
                      Expanded(
                        flex: (segs[i].travelTimeSec * 100 / total)
                            .round()
                            .clamp(1, 100),
                        child: Container(
                          decoration: BoxDecoration(
                            color: segmentColorForBar(segs[i]),
                            borderRadius: i == 0
                                ? const BorderRadius.horizontal(
                                    left: Radius.circular(4),
                                  )
                                : i == segs.length - 1
                                ? const BorderRadius.horizontal(
                                    right: Radius.circular(4),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // 바 아래 모드 라벨
            Row(
              children: [
                for (int i = 0; i < segs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    flex: (segs[i].travelTimeSec * 100 / total).round().clamp(
                      1,
                      100,
                    ),
                    child: Text(
                      segs[i].mode == TransportMode.walk
                          ? '도보'
                          : segs[i].mode == TransportMode.bus
                          ? segs[i].lineName
                          : segs[i].lineName,
                      style: TextStyle(
                        fontSize: 10,
                        color: segmentColorForBar(segs[i]),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      }(),
      const SizedBox(height: 6),
    ]);
  }

  double _routeSheetFraction = 0.30;


  /// 세로 타임라인 한 행 (IntrinsicHeight 미사용 — AnimatedSize 호환)
  Widget _timelineRow({
    required Color? dotColor,
    bool dotHollow = false,
    Color? lineColor,
    bool lineDashed = false,
    bool lineBelow = true,
    required Widget child,
  }) => TimelineRow(
        dotColor: dotColor,
        dotHollow: dotHollow,
        lineColor: lineColor,
        lineDashed: lineDashed,
        lineBelow: lineBelow,
        child: child,
      );

  // ── 설정 오버레이 패널 ──
  /// 즐겨찾기 + 방문 기록 기반 DayPlan 자동 생성 → 지도 위 오버레이로 표시.
  /// 마커만 표시 — 사용자가 stop 별 "길찾기" 버튼 누르면 본 앱 길찾기로 진입.
  void _buildPlanFromSavedPlaces() {
    final plans = SavedPlacesPlanBuilder.buildPlans();
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '장소가 더 필요해요 — 즐겨찾기/방문 기록 ${SavedPlacesPlanBuilder.minPlaces}곳 이상이면 자동 생성돼요',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() {
      _travelOpen = false;
      _dayPlans = plans;
    });
  }

  // ── 여행 패널 오버레이 (바텀시트) ──
  Widget _buildTravelOverlay(BuildContext context, double screenHeight) {
    final panelHeight = screenHeight * 0.55;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: _travelOpen ? Curves.easeOutCubic : Curves.easeInCubic,
      bottom: _travelOpen ? 0 : -panelHeight - 50,
      left: 0,
      right: 0,
      height: panelHeight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: _travelOpen ? 1.0 : 0.0,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.dy > 200) {
              setState(() => _travelOpen = false);
            }
          },
          child: TravelPanel(
            onUseAi: () {
              setState(() {
                _travelOpen = false;
                _aiOpen = true;
                _aiClosing = false;
              });
            },
            onUseSaved: () => _buildPlanFromSavedPlaces(),
            onClose: () => setState(() => _travelOpen = false),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOverlay(
    BuildContext context,
    double screenHeight,
    double bottomInset,
  ) {
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
          child: SavedPanel(
            onClose: () => setState(() => _savedOpen = false),
            onPlaceTap: (lat, lng, name) {
              setState(() => _savedOpen = false);
              Future.delayed(const Duration(milliseconds: 400), () {
                if (!mounted) return;
                _mapController?.moveTo(lat, lng, zoom: 16.0);
                final place = PlaceSearchResult(
                  name: name,
                  address: '',
                  category: '저장된 장소',
                  lat: lat,
                  lng: lng,
                );
                _showPlaceMarker(place);
                setState(() => _setSelectedPlace(place));
                PlaceSearchService.instance.search(name).then((results) {
                  if (!mounted || _selectedPlace?.name != name) return;
                  PlaceSearchResult? best;
                  double bestDist = double.infinity;
                  for (final r in results) {
                    final d = (r.lat - lat).abs() + (r.lng - lng).abs();
                    if (d < bestDist) {
                      bestDist = d;
                      best = r;
                    }
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                    onNavigateToStop: (name, lat, lng) {
                      // 하루 플랜 닫고 본 앱 길찾기로 이동 (도착지 자동 채움 + 출발지=내 위치).
                      setState(() => _dayPlans = null);
                      _startNavWithArrival(name, lat: lat, lng: lng);
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

