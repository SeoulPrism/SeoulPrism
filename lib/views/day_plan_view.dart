import 'package:flutter/material.dart';
import '../models/sns_content_models.dart';
import '../models/subway_models.dart';
import '../theme/app_colors.dart';
import '../widgets/adaptive/adaptive.dart';
import '../core/map_interface.dart';
import '../data/seoul_subway_data.dart';
import '../data/subway_geojson_loader.dart';
import 'dart:math';

class DayPlanView extends StatefulWidget {
  final List<DayPlan> plans;
  final IMapController? mapController;
  final VoidCallback? onClose;

  const DayPlanView({
    super.key,
    required this.plans,
    this.mapController,
    this.onClose,
  });

  @override
  State<DayPlanView> createState() => _DayPlanViewState();
}

class _DayPlanViewState extends State<DayPlanView> {
  int _selectedPlanIndex = 0;
  int _animId = 0;
  bool _animating = false;

  DayPlan get _currentPlan => widget.plans[_selectedPlanIndex];

  @override
  void initState() {
    super.initState();
    _drawPlanAnimated();
  }

  @override
  void dispose() {
    _animId++;
    _clearMap();
    super.dispose();
  }

  void _clearMap() {
    widget.mapController?.clearPolylines();
    widget.mapController?.clearCircleMarkers();
  }

  Future<void> _drawPlanAnimated() async {
    final mc = widget.mapController;
    if (mc == null) return;

    _clearMap();
    final animId = ++_animId;
    setState(() => _animating = true);

    final plan = _currentPlan;
    if (plan.stops.isEmpty) {
      setState(() => _animating = false);
      return;
    }

    // GeoJSON 선로 좌표 로드
    final geojsonRoutes = await SubwayGeoJsonLoader.load();

    // 바운딩 박스 계산
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final stop in plan.stops) {
      final p = stop.place;
      if (!p.hasCoordinates) continue;
      if (p.lat! < minLat) minLat = p.lat!;
      if (p.lat! > maxLat) maxLat = p.lat!;
      if (p.lng! < minLng) minLng = p.lng!;
      if (p.lng! > maxLng) maxLng = p.lng!;
    }

    // 카메라 이동 (하단 패널에 가리지 않도록 중심을 약간 위로)
    if (minLat < maxLat && minLng < maxLng) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final span = max(maxLat - minLat, maxLng - minLng);
      final zoom = span > 0.3 ? 10.0 : span > 0.15 ? 11.0 : span > 0.08 ? 12.0 : 12.5;
      // 패널이 하단을 차지하므로 중심을 살짝 북쪽으로
      mc.moveTo(centerLat - span * 0.15, centerLng, zoom: zoom - 0.5, pitch: 20);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (_animId != animId) return;

    // 장소별 순차 애니메이션
    for (int i = 0; i < plan.stops.length; i++) {
      if (_animId != animId) return;
      final stop = plan.stops[i];
      final place = stop.place;

      // 장소 마커
      if (place.hasCoordinates) {
        final color = _stopColor(i, plan.stops.length);
        await mc.addCircleMarker(
          'plan_$i', place.lat!, place.lng!,
          color: color,
          radius: i == 0 || i == plan.stops.length - 1 ? 14 : 10,
          strokeColor: Colors.white,
          strokeWidth: i == 0 || i == plan.stops.length - 1 ? 4 : 3,
        );
      }

      // 경로 애니메이션 (이전 장소에서 현재 장소까지)
      final route = stop.routeFromPrevious;
      if (route != null) {
        for (int s = 0; s < route.segments.length; s++) {
          if (_animId != animId) return;
          final seg = route.segments[s];
          if (seg.isTransfer || seg.stations.length < 2) continue;

          // GeoJSON에서 실제 선로 좌표 추출
          final firstStn = SeoulSubwayData.findStation(seg.stations.first);
          final lastStn = SeoulSubwayData.findStation(seg.stations.last);
          if (firstStn == null || lastStn == null) continue;

          final lineCoords = geojsonRoutes[seg.lineId];
          List<List<double>> segCoords;
          if (lineCoords != null && lineCoords.length >= 2) {
            segCoords = _extractSegmentFromRoute(lineCoords, firstStn, lastStn);
          } else {
            segCoords = seg.stations
                .map((n) => SeoulSubwayData.findStation(n))
                .where((st) => st != null)
                .map((st) => [st!.lat, st.lng])
                .toList();
          }
          if (segCoords.length < 2) continue;

          final lineColor = SubwayColors.lineColors[seg.lineId] ?? AppColors.accent;

          // 점진적으로 폴리라인 그리기
          final totalPoints = segCoords.length;
          final step = max(1, totalPoints ~/ 8);

          for (int p = step; p <= totalPoints; p += step) {
            if (_animId != animId) return;
            final partial = segCoords.sublist(0, min(p, totalPoints));
            if (partial.length >= 2) {
              mc.removePolyline('plan_route_${i}_$s');
              await mc.addPolyline('plan_route_${i}_$s', partial,
                  color: lineColor, width: 5.0, opacity: 0.85);
            }
            await Future.delayed(const Duration(milliseconds: 40));
          }

          // 전체 좌표로 확정
          if (_animId != animId) return;
          mc.removePolyline('plan_route_${i}_$s');
          await mc.addPolyline('plan_route_${i}_$s', segCoords,
              color: lineColor, width: 5.0, opacity: 0.85);
        }

        // 구간 사이 딜레이
        if (i < plan.stops.length - 1) {
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }
    }

    if (mounted) setState(() => _animating = false);
  }

  List<List<double>> _extractSegmentFromRoute(
    List<List<double>> routeCoords,
    StationInfo startStation,
    StationInfo endStation,
  ) {
    int startIdx = _findClosestIndex(routeCoords, startStation.lat, startStation.lng);
    int endIdx = _findClosestIndex(routeCoords, endStation.lat, endStation.lng);
    if (startIdx == endIdx) {
      return [[startStation.lat, startStation.lng], [endStation.lat, endStation.lng]];
    }
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
              if (_animating)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                ),
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
                  _animId++;
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
        _drawPlanAnimated();
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
    final isFirst = index == 0;
    final isLast = index == _currentPlan.stops.length - 1;
    final dotColor = _stopColor(index, _currentPlan.stops.length);

    return Column(
      children: [
        // 이동 구간
        if (!isFirst && stop.transitMinutes > 0)
          Padding(
            padding: const EdgeInsets.only(left: 19, bottom: 4),
            child: Row(
              children: [
                Container(width: 2, height: 20, color: isDark ? Colors.white12 : cs.outlineVariant),
                const SizedBox(width: 14),
                Icon(Icons.subway, size: 14, color: isDark ? Colors.white38 : cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '${stop.transitMinutes}분',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : cs.onSurfaceVariant),
                ),
                if (stop.routeFromPrevious != null && stop.routeFromPrevious!.transferCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '환승${stop.routeFromPrevious!.transferCount}',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : cs.onSurfaceVariant.withValues(alpha: 0.6)),
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: dotColor),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 16, color: isDark ? Colors.white12 : cs.outlineVariant),
              ],
            ),
            const SizedBox(width: 10),
            // 카드
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: AdaptiveSurfaceCard(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(12),
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
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        place.activity,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : cs.onSurfaceVariant),
                      ),
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
