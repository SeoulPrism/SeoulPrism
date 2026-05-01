import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/adaptive/adaptive.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../core/map_interface.dart';
import '../core/api_keys.dart';
import '../map_engines/mapbox_engine.dart';
import '../models/subway_models.dart';
import '../widgets/subway_overlay.dart';
import '../widgets/weather_widget.dart';
import '../widgets/subway_panel.dart';
import '../widgets/station_search_bar.dart';
import '../data/seoul_subway_data.dart';
import '../services/device_profile_service.dart';
import '../services/settings_service.dart';
import 'sns_upload_view.dart';
import 'day_plan_view.dart';
import 'ai_view.dart';
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
  List<DayPlan>? _dayPlans;

  final CameraInfo _cameraInfo = CameraInfo(
    lat: 37.5665, lng: 126.9780, zoom: 13.0, pitch: 45.0, bearing: 0.0,
  );

  // 지하철 오버레이 컨트롤러
  final SubwayOverlayController _subwayController = SubwayOverlayController();

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
          _selectedMapStation = name;
          _selectedMapStationInfo = info;
          _selectedMapStationArrivals = arrivals;
          _mapStationLoading = loading;
          if (name != null) {
            _lastSelectedMapStation = name;
            _lastSelectedMapStationInfo = info;
            _lastMapStationArrivals = arrivals;
          }
          // 역 도착 데이터 갱신 시 last도 업데이트
          if (name != null && !loading) {
            _lastMapStationArrivals = arrivals;
          }
        });
      }
    };
  }

  @override
  void dispose() {
    _subwayController.dispose();
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

    // 카메라 이동 (먼저)
    if (minLat < maxLat && minLng < maxLng) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final span = max(maxLat - minLat, maxLng - minLng);
      final zoom = span > 0.3 ? 10.0 : span > 0.15 ? 11.0 : span > 0.08 ? 12.0 : 13.0;
      mc.moveTo(centerLat, centerLng, zoom: zoom, pitch: 30);
    }

    // 출발 마커 (먼저 표시)
    final depInfo = SeoulSubwayData.findStation(route.departure);
    if (depInfo != null) {
      mc.addCircleMarker('route_dep', depInfo.lat, depInfo.lng,
        color: AppColors.success, radius: 12, strokeColor: AppColors.textPrimary, strokeWidth: 4);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (_routeAnimId != animId) return;

    // 구간별 순차 애니메이션: 폴리라인을 점진적으로 그리기
    for (int s = 0; s < segmentData.length; s++) {
      if (_routeAnimId != animId) return;
      final seg = segmentData[s];

      // 구간 시작 마커
      mc.addCircleMarker('route_mk_${s}_s', seg.first.lat, seg.first.lng,
        color: seg.color, radius: 8, strokeColor: Colors.white, strokeWidth: 3);

      // 폴리라인을 점진적으로 늘리며 그리기
      final totalPoints = seg.coords.length;
      final step = max(1, totalPoints ~/ 8); // 8단계로 나눠서 그리기

      for (int i = step; i <= totalPoints; i += step) {
        if (_routeAnimId != animId) return;
        final partial = seg.coords.sublist(0, min(i, totalPoints));
        if (partial.length >= 2) {
          // 이전 폴리라인 제거 후 더 긴 것으로 교체
          mc.removePolyline('route_seg_$s');
          await mc.addPolyline('route_seg_$s', partial,
            color: seg.color, width: 6.0, opacity: 0.9);
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 마지막에 전체 좌표로 확정
      if (_routeAnimId != animId) return;
      mc.removePolyline('route_seg_$s');
      await mc.addPolyline('route_seg_$s', seg.coords,
        color: seg.color, width: 6.0, opacity: 0.9);

      // 구간 끝 마커
      mc.addCircleMarker('route_mk_${s}_e', seg.last.lat, seg.last.lng,
        color: seg.color, radius: 8, strokeColor: Colors.white, strokeWidth: 3);

      // 구간 사이 짧은 딜레이 (환승 느낌)
      if (s < segmentData.length - 1) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

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
  }

  bool _profileShown = false;
  bool _showProfileToast = false;

  void _onMapCreated(IMapController controller) {
    _mapController = controller;
    _subwayController.attachMap(controller);
    // 맵 탭 시 키보드 내림
    controller.setOnAnyMapTap(() {
      FocusManager.instance.primaryFocus?.unfocus();
    });
    // 자동으로 데모 모드 시작
    if (!_subwayController.isActive) {
      _subwayController.start();
    }
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
      bottomNavigationBar: _buildBottomTabBar(),
      body: AnimatedScale(
        scale: _aiOpen && !_aiClosing ? 0.995 : 1.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        child: Stack(
        children: [
          // 지도 엔진 (항상 렌더링)
          Positioned.fill(child: MapboxEngine(initialCamera: _cameraInfo, onMapCreated: _onMapCreated)),

          // 검색바 + 길찾기 + 프로필 (상단, 리퀴드 글라스)
          StationSearchBar(
            onStationSelected: (name) {
              _subwayController.selectStation(name);
            },
            onRouteFound: (route) => _drawRouteOnMap(route),
            onNavModeChanged: (isNav) {
              setState(() => _isNavMode = isNav);
              if (!isNav) _clearRouteFromMap();
            },
            onFocusChanged: (focused) {
              setState(() => _isSearchFocused = focused);
            },
            onProfileTap: widget.onProfileTap,
          ),

          // 날씨/시간 위젯 (검색바 아래 좌측, 검색 포커스/길찾기 시 페이드아웃)
          if (_subwayController.isActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 62,
              left: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                opacity: (_isNavMode || _isSearchFocused) ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: _isNavMode || _isSearchFocused,
                  child: WeatherTimeWidget(environment: _subwayController.environment),
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
                  ),
                ),
                ),
              ),
            ),

          // 설정 패널 오버레이 (바텀시트 스타일)
          _buildSettingsOverlay(context, screenHeight, bottomInset),

          // 하루 플랜 오버레이 (지도 위 바텀 패널)
          _buildDayPlanOverlay(context, bottomInset),

          // 통합 AI 오버레이 (풀스크린 Glow + Gemini Live)
          if (_aiOpen)
            Positioned.fill(
              child: AiView(
                closing: _aiClosing,
                onClose: () => setState(() {
                  _aiOpen = false;
                  _aiClosing = false;
                }),
                onAction: _handleAiAction,
              ),
            ),

          // 기기 프로필 토스트 (페이드인/아웃)
          _buildProfileToast(),
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

  void _dismissAi() {
    if (_aiOpen && !_aiClosing) {
      setState(() => _aiClosing = true);
    }
  }

  /// AI Function Calling 액션 처리
  void _handleAiAction(AiActionEvent event) {
    switch (event.action) {
      case AiAction.navigateToStation:
        final stationName = event.params['stationName'] as String?;
        if (stationName != null) {
          // AI 닫고 역으로 이동
          _dismissAi();
          Future.delayed(const Duration(milliseconds: 600), () {
            _subwayController.selectStation(stationName);
            // 역 좌표로 카메라 이동
            final station = SeoulSubwayData.findStation(stationName);
            if (station != null) {
              _mapController?.moveTo(station.lat, station.lng, zoom: 15, pitch: 45);
            }
          });
        }
        break;
      case AiAction.showStationInfo:
        final stationName = event.params['stationName'] as String?;
        if (stationName != null) {
          _dismissAi();
          Future.delayed(const Duration(milliseconds: 600), () {
            _subwayController.selectStation(stationName);
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
        _createPlanFromAi(style, event.params['places'] as String?);
        break;
      case AiAction.searchPlace:
        // 검색은 AI가 음성으로 결과를 안내
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

  /// AI 요청으로 플랜 생성
  Future<void> _createPlanFromAi(String style, String? placesJson) async {
    // 이전 분석 결과가 있으면 사용, 없으면 빈 리스트
    // 실제로는 _liveService에서 받은 장소 데이터를 활용
    debugPrint('[AI Action] Create plan: style=$style');
  }

  // ── 하단 탭바 (리퀴드 글라스) ──
  Widget _buildBottomTabBar() {
    // 순서: 설정(0) | 지도(1, 가운데) | AI(2)
    final currentIndex = _settingsOpen ? 0 : (_aiOpen ? 2 : 1);

    return AdaptiveTabBar(
      currentIndex: currentIndex,
      onTap: (index) {
        setState(() {
          if (index == 0) {
            _dismissAi();
            _settingsOpen = !_settingsOpen;
          } else if (index == 1) {
            _settingsOpen = false;
            _dismissAi();
          } else if (index == 2) {
            _settingsOpen = false;
            if (_aiOpen) {
              _dismissAi();
            } else {
              _aiOpen = true;
              _aiClosing = false;
            }
          }
        });
      },
      items: const [
        AdaptiveTabItem(label: '설정', icon: Icons.settings),
        AdaptiveTabItem(label: '지도', icon: Icons.map),
        AdaptiveTabItem(label: 'AI', icon: Icons.auto_awesome),
      ],
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
            mapController: _mapController,
            onClose: () => setState(() => _settingsOpen = false),
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
  final IMapController? mapController;
  final VoidCallback onClose;

  const SettingsPanel({
    super.key,
    required this.subwayController,
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
