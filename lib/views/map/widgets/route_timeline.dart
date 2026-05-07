import 'package:flutter/material.dart';
import '../../../services/path_finding_service.dart';
import '../../../models/subway_models.dart';
import '../../../widgets/bus_overlay.dart';

/// 경로 결과 시트의 타임라인 한 행 (점 + 왼쪽 선 + 콘텐츠).
class TimelineRow extends StatelessWidget {
  final Color? dotColor;
  final bool dotHollow;
  final Color? lineColor;
  final bool lineDashed;
  final bool lineBelow;
  final Widget child;

  const TimelineRow({
    super.key,
    required this.dotColor,
    this.dotHollow = false,
    this.lineColor,
    this.lineDashed = false,
    this.lineBelow = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dot = dotColor != null
        ? Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotHollow ? Colors.transparent : dotColor,
              border: Border.all(color: dotColor!, width: dotHollow ? 3 : 0),
            ),
          )
        : const SizedBox(width: 14, height: 14);

    final lineDecor = lineBelow
        ? BoxDecoration(
            border: Border(
              left: BorderSide(
                color: lineColor ?? Colors.grey.withValues(alpha: 0.2),
                width: lineDashed ? 2 : 3.5,
              ),
            ),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 4), child: dot),
          const SizedBox(width: 5),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              decoration: lineDecor,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// 출발/도착 등 경유 지점 텍스트 — 탭하면 지도 카메라가 그 지점으로 이동.
class RoutePointText extends StatelessWidget {
  final String stationName;
  final TextStyle style;
  final VoidCallback onTap;

  const RoutePointText({
    super.key,
    required this.stationName,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(stationName, style: style, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.my_location,
            size: (style.fontSize ?? 14) - 1,
            color: style.color?.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

/// 경로 구간의 막대/도트 색상.
/// - 버스: 100~999 간선, 1000+ 지선, M 시작 광역.
/// - 도보: 회색.
/// - 지하철: 노선색.
Color segmentColorForBar(PathSegment seg) {
  if (seg.mode == TransportMode.bus) {
    final ref = seg.lineId.startsWith('bus_') ? seg.lineId.substring(4) : '';
    final num = int.tryParse(ref);
    if (num != null && num >= 100 && num <= 999) return BusColors.trunk;
    if (num != null && num >= 1000) return BusColors.branch;
    if (ref.startsWith('M')) return BusColors.express;
    return BusColors.branch;
  }
  if (seg.mode == TransportMode.walk) return Colors.grey;
  return SubwayColors.lineColors[seg.lineId] ?? Colors.grey;
}
