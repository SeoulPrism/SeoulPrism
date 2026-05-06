import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/path_finding_service.dart';
import '../models/subway_models.dart';
import '../widgets/bus_overlay.dart';

class RouteSearchOverlay extends StatefulWidget {
  const RouteSearchOverlay({
    super.key,
    required this.pathResult,
    required this.onClose,
  });

  final PathResult pathResult;
  final VoidCallback onClose;

  @override
  State<RouteSearchOverlay> createState() => _RouteSearchOverlayState();
}

/// 구간 색상 헬퍼: 지하철 → SubwayColors, 버스 → BusColors
Color _segmentColor(PathSegment seg) {
  if (seg.mode == TransportMode.bus) {
    final ref = seg.lineId.startsWith('bus_') ? seg.lineId.substring(4) : '';
    final num = int.tryParse(ref);
    if (num != null && num >= 100 && num <= 999) return BusColors.trunk;
    if (num != null && num >= 1000) return BusColors.branch;
    if (ref.startsWith('M')) return BusColors.express;
    if (ref.startsWith('N')) return BusColors.night;
    return BusColors.branch;
  }
  return SubwayColors.lineColors[seg.lineId] ?? Colors.grey;
}

class _RouteSearchOverlayState extends State<RouteSearchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  final Set<int> _expandedSegments = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _close() {
    _animController.reverse().then((_) => widget.onClose());
  }

  PathResult get _r => widget.pathResult;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _close,
              child: Container(
                color: Colors.black.withValues(alpha: 0.35 * _fadeAnim.value),
              ),
            ),
            SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.50,
                  minChildSize: 0.25,
                  maxChildSize: 0.90,
                  snap: true,
                  snapSizes: const [0.50],
                  builder: (context, scrollController) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            color: const Color(0xFF1A1A1A).withValues(alpha: 0.85),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListView(
                              controller: scrollController,
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              children: [
                                // 핸들
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                                    width: 36,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                _buildHeader(),
                                _buildTimeSummary(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: _buildTimelineBar(),
                                ),
                                _buildRouteSteps(),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF34C759),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _r.departure,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Color(0xFFFF453A), size: 12),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _r.arrival,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _close,
            icon: Icon(Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.60), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSummary() {
    final totalMin = _r.totalTimeSec ~/ 60;
    final hours = totalMin ~/ 60;
    final mins = totalMin % 60;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (hours > 0) ...[
            Text(
              '$hours',
              style: const TextStyle(
                color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, height: 1,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('시간', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70), fontSize: 16, fontWeight: FontWeight.w600,
              )),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '$mins',
            style: const TextStyle(
              color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, height: 1,
            ),
          ),
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('분', style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70), fontSize: 16, fontWeight: FontWeight.w600,
            )),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_r.transferCount > 0)
                Text(
                  '환승 ${_r.transferCount}회',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50), fontSize: 13,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                '${_r.totalDistanceKm.toStringAsFixed(1)}km',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40), fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineBar() {
    final segments = _r.segments.where((s) => !s.isTransfer).toList();
    final totalTime = segments.fold<int>(0, (sum, s) => sum + s.travelTimeSec);
    if (totalTime <= 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            for (int i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                flex: (segments[i].travelTimeSec * 100 / totalTime).round().clamp(1, 100),
                child: Container(
                  color: _segmentColor(segments[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSteps() {
    final steps = <Widget>[];

    // 출발역
    steps.add(_RouteStep(
      dotColor: const Color(0xFF34C759),
      lineColor: _r.segments.isNotEmpty
          ? (_segmentColor(_r.segments.first))
          : Colors.grey,
      title: _r.departure,
      subtitle: '출발',
      icon: Icons.my_location_rounded,
    ));

    for (int i = 0; i < _r.segments.length; i++) {
      final seg = _r.segments[i];
      final lineColor = _segmentColor(seg);

      if (seg.isTransfer) {
        // 환승 구간
        final nextColor = i + 1 < _r.segments.length
            ? (_segmentColor(_r.segments[i + 1]))
            : Colors.grey;
        steps.add(_RouteStep(
          dotColor: Colors.white,
          lineColor: nextColor,
          title: '환승',
          subtitle: '${seg.lineName} · ~3분',
          icon: Icons.swap_horiz_rounded,
        ));
      } else {
        // 승차 구간
        final stationCount = seg.stations.length;
        final timeMins = (seg.travelTimeSec / 60).ceil();
        final isExpanded = _expandedSegments.contains(i);
        final isLast = i == _r.segments.length - 1;
        final nextLineColor = !isLast && i + 1 < _r.segments.length
            ? (_segmentColor(_r.segments[i + 1]))
            : null;

        final isBus = seg.mode == TransportMode.bus;
        steps.add(_RouteStep(
          dotColor: lineColor,
          lineColor: isLast ? null : (nextLineColor ?? lineColor),
          title: '${seg.lineName} 승차',
          subtitle: stationCount > 1
              ? '${seg.stations.first} → ${seg.stations.last} · ${stationCount}개 ${isBus ? "정류장" : "역"} · $timeMins분'
              : '${seg.stations.firstOrNull ?? ""} · $timeMins분',
          icon: isBus ? Icons.directions_bus_rounded : Icons.train_rounded,
          badge: seg.lineName,
          badgeColor: lineColor,
          expandable: stationCount > 2,
          showExpanded: isExpanded,
          onToggle: () => setState(() {
            if (isExpanded) {
              _expandedSegments.remove(i);
            } else {
              _expandedSegments.add(i);
            }
          }),
          expandedStations: isExpanded ? seg.stations : null,
          isLast: isLast,
        ));
      }
    }

    // 도착역
    steps.add(_RouteStep(
      dotColor: const Color(0xFFFF453A),
      lineColor: null,
      title: _r.arrival,
      subtitle: '도착',
      icon: Icons.location_on_rounded,
      isLast: true,
    ));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: steps),
    );
  }
}

class _RouteStep extends StatelessWidget {
  const _RouteStep({
    required this.dotColor,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.lineColor,
    this.badge,
    this.badgeColor,
    this.expandable = false,
    this.showExpanded = false,
    this.onToggle,
    this.expandedStations,
    this.isLast = false,
  });

  final Color? lineColor;
  final Color dotColor;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  final bool expandable;
  final bool showExpanded;
  final VoidCallback? onToggle;
  final List<String>? expandedStations;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor ?? Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon,
                          color: Colors.white.withValues(alpha: 0.60), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: badgeColor,
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45), fontSize: 13,
                    ),
                  ),
                  if (expandable) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onToggle,
                      child: Text(
                        showExpanded ? '접기 ▲' : '정류장 보기 ▼',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35), fontSize: 12,
                        ),
                      ),
                    ),
                    if (showExpanded && expandedStations != null) ...[
                      const SizedBox(height: 8),
                      ...expandedStations!.map((name) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '  · $name',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.30), fontSize: 12,
                          ),
                        ),
                      )),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
