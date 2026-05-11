import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/sns_content_models.dart';
import '../services/path_finding_service.dart';
import '../services/route_renderer.dart';
import '../theme/app_colors.dart';
import '../widgets/adaptive/adaptive.dart';
import '../core/map_interface.dart';

class DayPlanView extends StatefulWidget {
  final List<DayPlan> plans;
  final IMapController? mapController;
  final VoidCallback? onClose;

  /// 사용자가 stop 카드의 "길찾기" 버튼 누르면 호출 — 본 앱 길찾기로 이동.
  /// (place name, lat, lng) 전달.
  final void Function(String name, double lat, double lng)? onNavigateToStop;

  /// 위젯 상단 "전체 길찾기" 버튼 — 모든 stop 을 하나의 경로로 묶어 본 앱 길찾기/
  /// 네비 모드로 진입.
  final void Function(DayPlan plan)? onNavigateAllStops;

  /// 패널 높이 (px) 가 바뀔 때 호출 — map_view 가 다른 디테일 위젯을 그 위로
  /// 끌어올리는 데 사용 (드래그 리사이즈/스냅 시 실시간 보고).
  final void Function(double height)? onHeightChanged;

  const DayPlanView({
    super.key,
    required this.plans,
    this.mapController,
    this.onClose,
    this.onNavigateToStop,
    this.onNavigateAllStops,
    this.onHeightChanged,
  });

  @override
  State<DayPlanView> createState() => _DayPlanViewState();
}

class _DayPlanViewState extends State<DayPlanView>
    with SingleTickerProviderStateMixin {
  int _selectedPlanIndex = 0;
  int _renderId = 0;

  // 패널 리사이즈 상태 — 사용자가 상단 핸들 드래그로 위/아래 늘리고 줄임.
  // 절대 픽셀이 아닌 화면 높이에 대한 비율로 저장 → 회전/멀티윈도우에서도 안정.
  double? _panelHeight;
  static const double _kMinHeight = 220.0; // 헤더 + 스타일카드 + 요약
  static const double _kMidHeight = 480.0; // 기본 (타임라인 약 240)
  static const double _kHandleSize = 28.0;

  // dragEnd 시 target 으로 부드럽게 애니메이션 (즉시 setState 점프 X).
  late AnimationController _snapCtrl;
  Animation<double>? _snapAnim;

  // onHeightChanged 중복 호출 방지용 — 직전에 보고한 높이.
  double? _lastReportedHeight;

  DayPlan get _currentPlan => widget.plans[_selectedPlanIndex];

  /// 좌표 있는 stop 이 2개 이상이면 전체 길찾기 가능 (route 가 precompute 안 된
  /// 테마 plan 도 좌표만 있으면 map_view 에서 on-the-fly 계산).
  bool get _canNavigateAll =>
      _currentPlan.stops.where((s) => s.place.hasCoordinates).length >= 2;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _renderMap();
  }

  @override
  void dispose() {
    _clearMap();
    _snapCtrl.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _snapCtrl.stop();
    final from = _panelHeight ?? _kMidHeight;
    if ((from - target).abs() < 0.5) return;
    _snapAnim = Tween<double>(begin: from, end: target).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOutCubic),
    );
    void tick() {
      if (!mounted) return;
      setState(() => _panelHeight = _snapAnim!.value);
    }
    _snapAnim!.addListener(tick);
    _snapCtrl.forward(from: 0).whenCompleteOrCancel(() {
      _snapAnim?.removeListener(tick);
    });
  }

  void _clearMap() {
    ++_renderId;
    widget.mapController?.clearPolylines();
    widget.mapController?.clearCircleMarkers();
    widget.mapController?.clearRouteArrows();
  }

  /// stops 마커 + stop 간 leg 경로 + 화살표.
  /// 시각은 길찾기 (`_drawRouteOnMap`) 와 동일 — outline + colored line + arrows +
  /// 큰 출발/도착 마커 + 환승 마커.
  ///
  /// `PlanStop.routeFromPrevious` 가 precompute 안 된 plan (테마 / AI 코스) 은
  /// 좌표 기반으로 `PathFindingService.findPath` 를 호출해 on-the-fly 로 계산.
  Future<void> _renderMap() async {
    final mc = widget.mapController;
    if (mc == null) return;

    _clearMap();
    final renderId = ++_renderId;

    final plan = _currentPlan;
    if (plan.stops.isEmpty) return;

    // 좌표 있는 stop 만 추출 (마커/경로 대상).
    final geoStops = plan.stops.where((s) => s.place.hasCoordinates).toList();
    if (geoStops.isEmpty) return;

    // ── 1. 카메라 ── 모든 stop 보이도록 + bearing (출발→도착 방향).
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final s in geoStops) {
      if (s.place.lat! < minLat) minLat = s.place.lat!;
      if (s.place.lat! > maxLat) maxLat = s.place.lat!;
      if (s.place.lng! < minLng) minLng = s.place.lng!;
      if (s.place.lng! > maxLng) maxLng = s.place.lng!;
    }
    if (minLat < maxLat && minLng < maxLng) {
      final first = geoStops.first.place;
      final last = geoStops.last.place;
      double bearing = 0;
      if (geoStops.length >= 2) {
        final dLng = (last.lng! - first.lng!) * pi / 180;
        final lat1 = first.lat! * pi / 180;
        final lat2 = last.lat! * pi / 180;
        final y = sin(dLng) * cos(lat2);
        final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
        bearing = (atan2(y, x) * 180 / pi + 360) % 360;
      }
      final latSpan = maxLat - minLat;
      final centerLat = (minLat + maxLat) / 2 - latSpan * 0.12;
      final centerLng = (minLng + maxLng) / 2;
      final span = max(latSpan, maxLng - minLng);
      final zoom = span > 0.3
          ? 10.0
          : span > 0.15
              ? 11.0
              : span > 0.08
                  ? 12.0
                  : 12.5;
      mc.moveTo(centerLat, centerLng, zoom: zoom, pitch: 30, bearing: bearing);
    }

    // ── 2. leg 별 경로 ── 마커보다 먼저 그려서 마커가 위에 오게.
    // routeFromPrevious 가 precompute 돼 있으면 그대로, 아니면 PathFinding 으로 lazily.
    final allArrows = <Map<String, dynamic>>[];
    final pathService = PathFindingService();
    for (int i = 1; i < geoStops.length; i++) {
      final from = geoStops[i - 1].place;
      final to = geoStops[i].place;
      PathResult? leg = geoStops[i].routeFromPrevious;
      if (leg == null) {
        try {
          leg = await pathService.findPath(
            departure: from.name,
            arrival: to.name,
            departureLat: from.lat,
            departureLng: from.lng,
            arrivalLat: to.lat,
            arrivalLng: to.lng,
          );
        } catch (_) {
          leg = null;
        }
        if (renderId != _renderId) return;
      }
      if (leg == null || leg.segments.isEmpty) continue;
      await RouteRenderer.render(
        mc,
        leg,
        prefix: 'plan_route_$i',
        drawTransitMarkers: true,
        arrowsOut: allArrows,
      );
      if (renderId != _renderId) return;
    }
    if (allArrows.isNotEmpty) await mc.updateRouteArrows(allArrows);
    if (renderId != _renderId) return;

    // ── 3. 중간 stop 번호 마커 (출발/도착은 따로 큰 마커로 덮어씌움). ──
    for (int i = 1; i < geoStops.length - 1; i++) {
      final place = geoStops[i].place;
      await mc.addCircleMarker(
        'plan_$i',
        place.lat!,
        place.lng!,
        color: AppColors.accent,
        radius: 10,
        strokeColor: Colors.white,
        strokeWidth: 3,
      );
    }

    // ── 4. 출발 / 도착 큰 마커 (길찾기 _drawRouteOnMap 과 동일 스타일). ──
    final dep = geoStops.first.place;
    await mc.addCircleMarker(
      'plan_dep',
      dep.lat!,
      dep.lng!,
      color: AppColors.success,
      radius: 14,
      strokeColor: AppColors.textPrimary,
      strokeWidth: 4,
    );
    if (geoStops.length >= 2) {
      final arr = geoStops.last.place;
      await mc.addCircleMarker(
        'plan_arr',
        arr.lat!,
        arr.lng!,
        color: AppColors.danger,
        radius: 14,
        strokeColor: AppColors.textPrimary,
        strokeWidth: 4,
      );
    }
  }

  Color _stopColor(int index, int total) {
    if (index == 0) return AppColors.success;
    if (index == total - 1) return AppColors.danger;
    return AppColors.accent;
  }

  void _handleDragUpdate(DragUpdateDetails d, double maxHeight) {
    // 진행 중 snap 애니메이션 있으면 중단 — 손가락 따라감.
    _snapCtrl.stop();
    setState(() {
      final base = _panelHeight ?? _kMidHeight;
      // 위로 끌면 패널이 커져야 함 → primaryDelta 가 음수일 때 height 증가.
      final next = (base - d.delta.dy).clamp(_kMinHeight, maxHeight);
      _panelHeight = next;
    });
  }

  void _handleDragEnd(DragEndDetails d, double maxHeight) {
    final v = d.velocity.pixelsPerSecond.dy;
    final current = _panelHeight ?? _kMidHeight;
    // 속도 기반 projected 위치 (100ms 후 미끄러진 자리) — flick 도 살짝 미끄럼.
    final projected = (current - v * 0.1).clamp(_kMinHeight, maxHeight);
    // 스냅 포인트 (min, mid, max) 중 projected 와 가장 가까운 곳으로.
    final candidates = <double>[_kMinHeight, _kMidHeight, maxHeight];
    candidates
        .sort((a, b) => (projected - a).abs().compareTo((projected - b).abs()));
    _animateTo(candidates.first);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.plans.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final topInset = MediaQuery.of(context).padding.top;
    final maxHeight = screenHeight - topInset - 80;
    final height = (_panelHeight ?? _kMidHeight).clamp(_kMinHeight, maxHeight);

    // 높이 변화를 parent 에 알려 디테일 위젯/플로팅 등이 위로 lift 되게.
    if (_lastReportedHeight != height) {
      _lastReportedHeight = height;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onHeightChanged?.call(height);
      });
    }

    return SizedBox(
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들 (위아래 리사이즈) + 전체 길찾기 / 닫기.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) => _handleDragUpdate(d, maxHeight),
            onVerticalDragEnd: (d) => _handleDragEnd(d, maxHeight),
            child: _buildHandleBar(cs, isDark),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
            child: Row(
              children: [
                Text(
                  AppL10n.of(context).dayPlanTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : cs.onSurface,
                  ),
                ),
                const Spacer(),
                if (_canNavigateAll && widget.onNavigateAllStops != null)
                  TextButton.icon(
                    onPressed: () =>
                        widget.onNavigateAllStops!(_currentPlan),
                    style: TextButton.styleFrom(
                      backgroundColor: cs.primary.withValues(alpha: 0.12),
                      foregroundColor: cs.primary,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.alt_route_rounded, size: 16),
                    label: Text(
                      AppL10n.of(context).dayPlanNavigateAll,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: isDark ? Colors.white70 : cs.onSurfaceVariant),
                  onPressed: () {
                    _clearMap();
                    widget.onClose?.call();
                  },
                ),
              ],
            ),
          ),

          // 스타일 선택 탭
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: widget.plans.length,
              itemBuilder: (context, i) => _buildStyleCard(i, cs, isDark),
            ),
          ),

          // 요약
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                _summaryChip(
                    '🕐 ${_currentPlan.startTime}–${_currentPlan.endTime}',
                    cs,
                    isDark),
                const SizedBox(width: 8),
                _summaryChip(
                    AppL10n.of(context)
                        .dayPlanTransitSummary(_currentPlan.totalTransitMinutes),
                    cs,
                    isDark),
                if (_currentPlan.transferCount > 0) ...[
                  const SizedBox(width: 8),
                  _summaryChip(
                      AppL10n.of(context)
                          .dayPlanTransfersSummary(_currentPlan.transferCount),
                      cs,
                      isDark),
                ],
              ],
            ),
          ),

          // 타임라인 — 남는 공간 채움.
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
              itemCount: _currentPlan.stops.length,
              itemBuilder: (context, i) => _buildStopItem(i, cs, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandleBar(ColorScheme cs, bool isDark) {
    return SizedBox(
      height: _kHandleSize,
      child: Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.28)
                : cs.onSurfaceVariant.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildStyleCard(int index, ColorScheme cs, bool isDark) {
    final plan = widget.plans[index];
    final selected = index == _selectedPlanIndex;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPlanIndex = index);
        _renderMap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 130,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? cs.primaryContainer
              : (isDark ? Colors.white.withValues(alpha: 0.06) : cs.surfaceContainerLow),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(plan.style.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              plan.style.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? cs.onPrimaryContainer : (isDark ? Colors.white70 : cs.onSurface),
              ),
            ),
            Text(
              AppL10n.of(context)
                  .dayPlanStyleStats(plan.stops.length, plan.totalTransitMinutes),
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                    : (isDark ? Colors.white38 : cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String text, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isDark ? Colors.white.withValues(alpha: 0.08) : cs.surfaceContainerHighest,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildStopItem(int index, ColorScheme cs, bool isDark) {
    final stop = _currentPlan.stops[index];
    final place = stop.place;
    final isLast = index == _currentPlan.stops.length - 1;
    final dotColor = _stopColor(index, _currentPlan.stops.length);
    final hasCoords =
        place.lat != null && place.lng != null && place.hasCoordinates;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타임라인 도트 + 점선 연결선 (다음 stop 까지) — 도트 탭 시 해당 좌표로 카메라.
        Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: hasCoords
                  ? () => widget.mapController?.moveTo(
                        place.lat!,
                        place.lng!,
                        zoom: 16.0,
                      )
                  : null,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor.withValues(alpha: 0.15),
                  border: Border.all(color: dotColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: dotColor,
                    ),
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isDark ? Colors.white12 : cs.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 10),
        // 카드
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AdaptiveSurfaceCard(
              borderRadius: 12,
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : cs.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${stop.arrivalTime}–${stop.departureTime}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.activity,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      // 길찾기 버튼 — 본 앱 길찾기로 이동.
                      if (hasCoords && widget.onNavigateToStop != null)
                        TextButton.icon(
                          onPressed: () {
                            widget.onNavigateToStop!(
                              place.name,
                              place.lat!,
                              place.lng!,
                            );
                          },
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 28),
                          ),
                          icon: Icon(
                            Icons.directions_rounded,
                            size: 16,
                            color: cs.primary,
                          ),
                          label: Text(
                            AppL10n.of(context).dayPlanNavigateStop,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
