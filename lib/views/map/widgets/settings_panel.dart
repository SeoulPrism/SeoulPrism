import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/map_interface.dart';
import '../../../data/seoul_subway_data.dart';
import '../../../models/bus_models.dart';
import '../../../models/subway_models.dart';
import '../../../services/device_profile_service.dart';
import '../../../services/onboarding_service.dart';
import '../../../services/settings_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/adaptive/adaptive.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/bus_overlay.dart';
import '../../../widgets/flight_overlay.dart';
import '../../../widgets/subway_overlay.dart';

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
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              MediaQuery.of(context).padding.bottom + 80,
            ),
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
              const SizedBox(height: 24),
              _sectionHeader('개발자'),
              _buildDebugSection(),
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

  Color get _panelTextPrimary => _isLightTheme
      ? Colors.black.withValues(alpha: 0.85)
      : Colors.white.withValues(alpha: 0.85);
  Color get _panelTextSecondary => _isLightTheme
      ? Colors.black.withValues(alpha: 0.55)
      : Colors.white.withValues(alpha: 0.45);
  Color get _panelTextMuted => _isLightTheme
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.white.withValues(alpha: 0.35);

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
                Icon(
                  Icons.train,
                  size: 18,
                  color: isActive ? AppColors.success : Colors.grey,
                ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (isDemo ? AppColors.warning : AppColors.accent)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
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
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.surfaceOverlay,
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
                  Text(
                    '열차 ${ctrl.currentTrains.length}대',
                    style: AppTypography.caption.copyWith(
                      color: _panelTextSecondary,
                    ),
                  ),
                  if (ctrl.lastUpdate != null)
                    Text(
                      '갱신 ${ctrl.lastUpdate!.hour.toString().padLeft(2, '0')}:${ctrl.lastUpdate!.minute.toString().padLeft(2, '0')}:${ctrl.lastUpdate!.second.toString().padLeft(2, '0')}',
                      style: AppTypography.caption.copyWith(
                        color: _panelTextMuted,
                      ),
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
                Icon(
                  Icons.directions_bus,
                  size: 18,
                  color: isActive ? BusColors.trunk : Colors.grey,
                ),
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
                    onTap: () {
                      ctrl.stop();
                      setState(() {});
                    },
                    child: Text(
                      '전체 끄기',
                      style: TextStyle(color: _panelTextMuted, fontSize: 12),
                    ),
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
                    onTap: () {
                      ctrl.removeRoute(route.routeId);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: route.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: route.color, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            route.routeName,
                            style: TextStyle(
                              color: route.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
            Text(
              '노선 추가',
              style: TextStyle(fontSize: 12, color: _panelTextSecondary),
            ),
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
                  onTap: added
                      ? null
                      : () async {
                          await ctrl.addRoute(
                            BusRouteInfo(
                              busRouteId: id,
                              busRouteNm: name,
                              routeType: type,
                              stStationNm: '',
                              edStationNm: '',
                            ),
                          );
                          setState(() {});
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: added
                          ? color.withValues(alpha: 0.3)
                          : color.withValues(alpha: 0.08),
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
                Icon(
                  Icons.flight,
                  size: 18,
                  color: ctrl.isActive ? Colors.white : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  ctrl.isActive
                      ? '${isDemo ? "DEMO" : "LIVE"} ${ctrl.flightCount}대'
                      : '항공기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ctrl.isActive
                        ? _panelTextPrimary
                        : _panelTextSecondary,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (isDemo ? AppColors.warning : AppColors.accent)
                            .withValues(alpha: 0.2),
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
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
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
            _toggleRow(
              '서울시 공공 API (60s)',
              widget.subwayController.useSeoulApi,
              (v) {
                widget.subwayController.setUseSeoulApi(v);
                setState(() {});
              },
            ),
            _toggleRow('네이버 API (5s)', widget.subwayController.useNaverApi, (
              v,
            ) {
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
                Text(
                  '표시할 노선 선택',
                  style: AppTypography.caption.copyWith(
                    color: _panelTextSecondary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ctrl.setLineFilter(null);
                    setState(() {});
                  },
                  child: Text(
                    '전체',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
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
                final isSelected =
                    ctrl.selectedLines == null ||
                    ctrl.selectedLines!.contains(lineId);

                return AppFilterChip(
                  label: name,
                  color: color,
                  isSelected: isSelected,
                  onTap: () {
                    final current =
                        ctrl.selectedLines ??
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
                                color: _panelTextPrimary.withValues(
                                  alpha: 0.15,
                                ),
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
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
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
                    value: ctrl.animFps.toDouble().clamp(
                      5,
                      isAndroid ? 30 : 60,
                    ),
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

  Widget _sliderRow({
    required String label,
    required String value,
    required Widget slider,
  }) {
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
    final selectedIndex = presets
        .indexOf(_lightPreset)
        .clamp(0, presets.length - 1);

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
                      widget.mapController?.applyWeatherEffect(
                        lightPreset: env.lightPreset,
                      );
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
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
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
              child: Divider(
                height: 1,
                color: _panelTextMuted.withValues(alpha: 0.15),
              ),
            ),
            _settingTile(
              icon: Icons.phone_android,
              title: '기기',
              subtitle: dp.rawModel,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Divider(
                height: 1,
                color: _panelTextMuted.withValues(alpha: 0.15),
              ),
            ),
            _settingTile(
              icon: Icons.speed,
              title: '성능 등급',
              subtitle:
                  '$tierLabel (${dp.profile.animFps}fps · ${dp.profile.naverPollMs}ms)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSection() {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _toggleRow(
              '디버그 로그 출력',
              SettingsService.instance.debugLogs,
              (v) {
                SettingsService.instance.setDebugLogs(v);
                setState(() {});
              },
            ),
            Divider(
              height: 1,
              color: _panelTextMuted.withValues(alpha: 0.15),
            ),
            _AdaptiveActionRow(
              icon: Icons.replay,
              label: '튜토리얼 다시 보기',
              onTap: _resetTutorial,
              labelColor: _panelTextPrimary,
              iconColor: _panelTextSecondary,
              chevronColor: _panelTextMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetTutorial() async {
    final confirmed = await _showResetConfirmDialog();
    if (!mounted || confirmed != true) return;
    await OnboardingService.instance.reset();
  }

  Future<bool?> _showResetConfirmDialog() {
    const title = '튜토리얼 다시 보기';
    const message = '저장된 진행 상태를 지우고 다음 앱 실행 시 튜토리얼을 처음부터 보여드려요.';
    if (Platform.isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text(title),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('다시 보기'),
            ),
          ],
        ),
      );
    }
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(title),
        content: const Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('다시 보기'),
          ),
        ],
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _panelTextPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: _panelTextMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 액션 행 — iOS = 리퀴드 글라스 톤의 부드러운 highlight, Android = M3 InkWell 잉크 효과.
class _AdaptiveActionRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color labelColor;
  final Color iconColor;
  final Color chevronColor;

  const _AdaptiveActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.labelColor,
    required this.iconColor,
    required this.chevronColor,
  });

  @override
  State<_AdaptiveActionRow> createState() => _AdaptiveActionRowState();
}

class _AdaptiveActionRowState extends State<_AdaptiveActionRow> {
  bool _pressed = false;

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      child: Row(
        children: [
          Icon(widget.icon, size: 18, color: widget.iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.labelColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: widget.chevronColor),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      // iOS: 리퀴드 글라스 톤 — 잉크 없이 부드러운 fill 하이라이트
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _content(),
        ),
      );
    }

    // Android: Material 3 — 표준 InkWell 잉크/리플
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: cs.primary.withValues(alpha: 0.12),
        highlightColor: cs.primary.withValues(alpha: 0.06),
        child: _content(),
      ),
    );
  }
}
