import 'dart:io';
import 'package:flutter/material.dart';
import '../models/sns_content_models.dart';
import '../models/subway_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/adaptive/adaptive.dart';
import '../core/map_interface.dart';
import '../data/seoul_subway_data.dart';
import '../data/subway_geojson_loader.dart';
import 'dart:math';

class DayPlanView extends StatefulWidget {
  final List<DayPlan> plans;
  final IMapController? mapController;

  const DayPlanView({
    super.key,
    required this.plans,
    this.mapController,
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
    _drawPlanOnMap();
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

  Future<void> _drawPlanOnMap() async {
    final mc = widget.mapController;
    if (mc == null) return;
    _clearMap();

    final plan = _currentPlan;
    if (plan.stops.isEmpty) return;

    // 바운딩 박스 계산
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

    // 장소 마커
    for (int i = 0; i < plan.stops.length; i++) {
      final stop = plan.stops[i];
      final place = stop.place;
      if (!place.hasCoordinates) continue;

      final color = _stopColor(i, plan.stops.length);
      mc.addCircleMarker(
        'plan_$i', place.lat!, place.lng!,
        color: color,
        radius: 12,
        strokeColor: Colors.white,
        strokeWidth: 3,
      );

      if (place.lat! < minLat) minLat = place.lat!;
      if (place.lat! > maxLat) maxLat = place.lat!;
      if (place.lng! < minLng) minLng = place.lng!;
      if (place.lng! > maxLng) maxLng = place.lng!;
    }

    // 경로 폴리라인
    for (int i = 0; i < plan.stops.length; i++) {
      final route = plan.stops[i].routeFromPrevious;
      if (route == null) continue;

      for (int s = 0; s < route.segments.length; s++) {
        final seg = route.segments[s];
        if (seg.isTransfer || seg.stations.length < 2) continue;

        final coords = seg.stations
            .map((n) => SeoulSubwayData.findStation(n))
            .where((s) => s != null)
            .map((s) => [s!.lat, s.lng])
            .toList();

        if (coords.length >= 2) {
          final lineColor = SubwayColors.lineColors[seg.lineId] ?? AppColors.accent;
          await mc.addPolyline(
            'plan_route_${i}_$s', coords,
            color: lineColor, width: 4.0, opacity: 0.7,
          );
        }
      }
    }

    // 카메라 이동
    if (minLat < maxLat && minLng < maxLng) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final span = max(maxLat - minLat, maxLng - minLng);
      final zoom = span > 0.3 ? 10.0 : span > 0.15 ? 11.0 : span > 0.08 ? 12.0 : 13.0;
      mc.moveTo(centerLat, centerLng, zoom: zoom, pitch: 30);
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
    final isM3 = Platform.isAndroid;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isM3 ? cs.surface : const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            _clearMap();
            Navigator.pop(context);
          },
        ),
        title: Text(
          '하루 플랜',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isM3 ? cs.onSurface : Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: widget.plans.isEmpty
          ? Center(child: Text('플랜을 생성할 수 없습니다', style: TextStyle(color: isM3 ? cs.onSurfaceVariant : Colors.white60)))
          : Column(
              children: [
                // 스타일 선택 탭
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: widget.plans.length,
                    itemBuilder: (context, i) => _buildStyleCard(i, isM3, cs),
                  ),
                ),

                // 요약
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      _summaryChip('🕐 ${_currentPlan.startTime}–${_currentPlan.endTime}', isM3, cs),
                      const SizedBox(width: 8),
                      _summaryChip('🚇 이동 ${_currentPlan.totalTransitMinutes}분', isM3, cs),
                      const SizedBox(width: 8),
                      if (_currentPlan.transferCount > 0)
                        _summaryChip('🔄 환승 ${_currentPlan.transferCount}회', isM3, cs),
                    ],
                  ),
                ),

                // 타임라인
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 24),
                    itemCount: _currentPlan.stops.length,
                    itemBuilder: (context, i) => _buildStopItem(i, isM3, cs),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStyleCard(int index, bool isM3, ColorScheme cs) {
    final plan = widget.plans[index];
    final selected = index == _selectedPlanIndex;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPlanIndex = index);
        _drawPlanOnMap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? (isM3 ? cs.primaryContainer : AppColors.accent.withValues(alpha: 0.2))
              : (isM3 ? cs.surfaceContainerLow : Colors.white.withValues(alpha: 0.06)),
          border: Border.all(
            color: selected
                ? (isM3 ? cs.primary : AppColors.accent)
                : (isM3 ? cs.outlineVariant : Colors.white12),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(plan.style.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              plan.style.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected
                    ? (isM3 ? cs.onPrimaryContainer : Colors.white)
                    : (isM3 ? cs.onSurface : Colors.white70),
              ),
            ),
            Text(
              '${plan.stops.length}곳 · ${plan.totalTransitMinutes}분',
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? (isM3 ? cs.onPrimaryContainer.withValues(alpha: 0.7) : Colors.white60)
                    : (isM3 ? cs.onSurfaceVariant : Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String text, bool isM3, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isM3 ? cs.surfaceContainerHighest : Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isM3 ? cs.onSurface : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildStopItem(int index, bool isM3, ColorScheme cs) {
    final stop = _currentPlan.stops[index];
    final place = stop.place;
    final isFirst = index == 0;
    final isLast = index == _currentPlan.stops.length - 1;
    final dotColor = _stopColor(index, _currentPlan.stops.length);

    return Column(
      children: [
        // 이동 구간 (첫 번째 제외)
        if (!isFirst && stop.transitMinutes > 0)
          Padding(
            padding: const EdgeInsets.only(left: 19, bottom: 4),
            child: Row(
              children: [
                Container(width: 2, height: 24, color: isM3 ? cs.outlineVariant : Colors.white12),
                const SizedBox(width: 14),
                Icon(Icons.subway, size: 14, color: isM3 ? cs.onSurfaceVariant : Colors.white38),
                const SizedBox(width: 6),
                Text(
                  '${stop.transitMinutes}분 이동',
                  style: TextStyle(
                    fontSize: 12,
                    color: isM3 ? cs.onSurfaceVariant : Colors.white38,
                  ),
                ),
                if (stop.routeFromPrevious != null && stop.routeFromPrevious!.transferCount > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(환승 ${stop.routeFromPrevious!.transferCount}회)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isM3 ? cs.onSurfaceVariant.withValues(alpha: 0.6) : Colors.white24,
                    ),
                  ),
                ],
              ],
            ),
          ),

        // 장소 카드
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타임라인 도트
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor.withValues(alpha: 0.15),
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: dotColor,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 20,
                    color: isM3 ? cs.outlineVariant : Colors.white12,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // 카드
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AdaptiveSurfaceCard(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isM3 ? cs.onSurface : Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            '${stop.arrivalTime}–${stop.departureTime}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isM3 ? cs.primary : AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.activity,
                        style: TextStyle(
                          fontSize: 13,
                          color: isM3 ? cs.onSurfaceVariant : Colors.white70,
                        ),
                      ),
                      if (place.mood.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          place.mood,
                          style: TextStyle(
                            fontSize: 11,
                            color: isM3 ? cs.onSurfaceVariant.withValues(alpha: 0.7) : Colors.white38,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
