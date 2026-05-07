import 'package:flutter/material.dart';
import '../../../services/path_finding_service.dart';
import 'route_timeline.dart';

/// 길찾기 turn-by-turn 모드의 상단 배너 — 현재 활성 구간 액션 + "다음" 버튼.
class NavigationBanner extends StatelessWidget {
  final PathSegment? activeSegment;
  final Color onSurface;
  final Color mutedColor;
  final VoidCallback onAdvance;

  const NavigationBanner({
    super.key,
    required this.activeSegment,
    required this.onSurface,
    required this.mutedColor,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final seg = activeSegment;
    if (seg == null) return const SizedBox.shrink();
    final segColor = segmentColorForBar(seg);
    final icon = seg.mode == TransportMode.walk
        ? Icons.directions_walk
        : seg.mode == TransportMode.bus
            ? Icons.directions_bus
            : Icons.train;
    final action = seg.mode == TransportMode.walk
        ? '${seg.stations.last}까지 도보'
        : '${seg.stations.first}에서 ${seg.lineName} 승차';
    final detail = seg.mode == TransportMode.walk
        ? '${(seg.travelTimeSec / 60).ceil()}분 이동'
        : '${seg.stations.last} 방면 · ${(seg.travelTimeSec / 60).ceil()}분';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: segColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: segColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, color: segColor),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(fontSize: 12, color: mutedColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAdvance,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: segColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '다음',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: segColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
