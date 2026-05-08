import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sns_content_models.dart';
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

  const DayPlanView({
    super.key,
    required this.plans,
    this.mapController,
    this.onClose,
    this.onNavigateToStop,
  });

  @override
  State<DayPlanView> createState() => _DayPlanViewState();
}

class _DayPlanViewState extends State<DayPlanView> {
  int _selectedPlanIndex = 0;

  DayPlan get _currentPlan => widget.plans[_selectedPlanIndex];

  @override
  void initState() {
    super.initState();
    _renderMarkers();
  }

  @override
  void dispose() {
    _clearMap();
    super.dispose();
  }

  void _clearMap() {
    widget.mapController?.clearPolylines();
    widget.mapController?.clearCircleMarkers();
  }

  /// stops 위치에 마커만 — 이동 경로 polyline 그리지 않음 (사용자 요청).
  /// 사용자가 각 카드의 "길찾기" 버튼 누르면 본 앱 길찾기 시스템으로 이동.
  Future<void> _renderMarkers() async {
    final mc = widget.mapController;
    if (mc == null) return;

    _clearMap();

    final plan = _currentPlan;
    if (plan.stops.isEmpty) return;

    // 바운딩 박스 → 모든 stop 보이도록 카메라.
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final stop in plan.stops) {
      final p = stop.place;
      if (!p.hasCoordinates) continue;
      if (p.lat! < minLat) minLat = p.lat!;
      if (p.lat! > maxLat) maxLat = p.lat!;
      if (p.lng! < minLng) minLng = p.lng!;
      if (p.lng! > maxLng) maxLng = p.lng!;
    }
    if (minLat < maxLat && minLng < maxLng) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final span = max(maxLat - minLat, maxLng - minLng);
      final zoom = span > 0.3
          ? 10.0
          : span > 0.15
              ? 11.0
              : span > 0.08
                  ? 12.0
                  : 12.5;
      // 패널이 하단을 차지하므로 중심을 살짝 북쪽으로.
      mc.moveTo(centerLat - span * 0.15, centerLng, zoom: zoom - 0.5, pitch: 20);
    }

    // 모든 마커 일괄 추가 (애니메이션 없이 곧장).
    for (int i = 0; i < plan.stops.length; i++) {
      final place = plan.stops[i].place;
      if (!place.hasCoordinates) continue;
      final color = _stopColor(i, plan.stops.length);
      final isEdge = i == 0 || i == plan.stops.length - 1;
      await mc.addCircleMarker(
        'plan_$i',
        place.lat!,
        place.lng!,
        color: color,
        radius: isEdge ? 14 : 10,
        strokeColor: Colors.white,
        strokeWidth: isEdge ? 4 : 3,
      );
    }
  }

  Color _stopColor(int index, int total) {
    if (index == 0) return AppColors.success;
    if (index == total - 1) return AppColors.danger;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (widget.plans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
          child: Row(
            children: [
              Text(
                '하루 플랜',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : cs.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white70 : cs.onSurfaceVariant),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: widget.plans.length,
            itemBuilder: (context, i) => _buildStyleCard(i, cs, isDark),
          ),
        ),

        // 요약
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              _summaryChip('🕐 ${_currentPlan.startTime}–${_currentPlan.endTime}', cs, isDark),
              const SizedBox(width: 8),
              _summaryChip('🚇 ${_currentPlan.totalTransitMinutes}분', cs, isDark),
              if (_currentPlan.transferCount > 0) ...[
                const SizedBox(width: 8),
                _summaryChip('🔄 ${_currentPlan.transferCount}회', cs, isDark),
              ],
            ],
          ),
        ),

        // 타임라인
        SizedBox(
          height: 280,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding + 16),
            itemCount: _currentPlan.stops.length,
            itemBuilder: (context, i) => _buildStopItem(i, cs, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildStyleCard(int index, ColorScheme cs, bool isDark) {
    final plan = widget.plans[index];
    final selected = index == _selectedPlanIndex;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPlanIndex = index);
        _renderMarkers();
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
              '${plan.stops.length}곳 · ${plan.totalTransitMinutes}분',
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
        // 타임라인 도트 + 점선 연결선 (다음 stop 까지)
        Column(
          children: [
            Container(
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
                            '길찾기',
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
