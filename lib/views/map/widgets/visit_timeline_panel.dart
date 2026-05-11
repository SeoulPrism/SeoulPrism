import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/visit_history_service.dart';
import '../../../theme/app_typography.dart';

/// 프로필 → 타임라인 지도 탭 시 메인 지도에 뜨는 방문 기록 패널.
/// 네이버 지도 "내 발자국" 스타일 — 시간순 카드 리스트, 탭하면 해당 위치로
/// 카메라 이동. 기본 5개만 노출, "더 보기" 로 펼침.
class VisitTimelinePanel extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(double lat, double lng, String name) onPlaceTap;

  const VisitTimelinePanel({
    super.key,
    required this.onClose,
    required this.onPlaceTap,
  });

  @override
  State<VisitTimelinePanel> createState() => _VisitTimelinePanelState();
}

class _VisitTimelinePanelState extends State<VisitTimelinePanel> {
  static const int _previewCount = 5;
  bool _expandedAll = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isM3 = Platform.isAndroid;
    final visits = VisitHistoryService.instance.recentVisits;

    final txtPrimary = isM3
        ? cs.onSurface
        : (isLight ? const Color(0xFF1C1C1E) : Colors.white);
    final txtMuted = isM3
        ? cs.onSurfaceVariant
        : (isLight
            ? const Color(0xFF6E6E73)
            : Colors.white.withValues(alpha: 0.55));

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: txtMuted.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내 발자국',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: txtPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${visits.length}곳 · 가장 최근 ${_relativeTime(visits.isNotEmpty ? visits.first.visitedAt : null)}',
                      style: AppTypography.bodySm.copyWith(color: txtMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: txtMuted, size: 20),
                onPressed: widget.onClose,
                tooltip: '닫기',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        // 시간순 리스트 — 기본 5개 + 더보기.
        Expanded(
          child: visits.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      '방문 기록이 없어요.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm
                          .copyWith(color: txtMuted, height: 1.5),
                    ),
                  ),
                )
              : _buildList(visits, txtPrimary, txtMuted, cs, isLight, isM3),
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLight
                  ? [
                      Colors.white.withValues(alpha: 0.70),
                      Colors.white.withValues(alpha: 0.78),
                      Colors.white.withValues(alpha: 0.88),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.52),
                      Colors.black.withValues(alpha: 0.68),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: (isLight ? Colors.black : Colors.white)
                    .withValues(alpha: 0.10),
                width: 0.5,
              ),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildList(
    List<VisitRecord> visits,
    Color txtPrimary,
    Color txtMuted,
    ColorScheme cs,
    bool isLight,
    bool isM3,
  ) {
    final hasMore = visits.length > _previewCount;
    final shown = (_expandedAll || !hasMore)
        ? visits
        : visits.sublist(0, _previewCount);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      itemCount: shown.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index < shown.length) {
          return _buildVisitTile(
              shown[index], index, txtPrimary, txtMuted, cs, isLight, isM3);
        }
        // 마지막 아이템 — 더보기/접기 버튼.
        final remaining = visits.length - _previewCount;
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _expandedAll = !_expandedAll),
              icon: Icon(
                _expandedAll
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
              ),
              label: Text(
                _expandedAll ? '접기' : '$remaining곳 더 보기',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisitTile(
    VisitRecord v,
    int index,
    Color txtPrimary,
    Color txtMuted,
    ColorScheme cs,
    bool isLight,
    bool isM3,
  ) {
    final tileBg = isM3
        ? cs.surfaceContainerHighest.withValues(alpha: 0.6)
        : (isLight
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.05));
    final tileBorder = (isLight ? Colors.black : Colors.white)
        .withValues(alpha: 0.05);
    final color = _categoryColor(v.category);
    final timeStr =
        '${v.visitedAt.hour.toString().padLeft(2, '0')}:${v.visitedAt.minute.toString().padLeft(2, '0')}';
    final dateStr = _shortDate(v.visitedAt);
    final isFirst = index == 0;
    return InkWell(
      onTap: () => widget.onPlaceTap(v.lat, v.lng, v.name),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFirst
                ? const Color(0xFFFB6340).withValues(alpha: 0.45)
                : tileBorder,
            width: isFirst ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // 좌측 인덱스 + 컬러 점.
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst
                        ? const Color(0xFFFB6340)
                        : color.withValues(alpha: 0.18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isFirst ? Colors.white : color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: txtPrimary,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text('$dateStr · $timeStr',
                          style: AppTypography.caption.copyWith(
                              color: txtMuted,
                              fontWeight: FontWeight.w600)),
                      if (v.category.isNotEmpty)
                        Text('· ${v.category}',
                            style: AppTypography.caption
                                .copyWith(color: txtMuted)),
                      if (v.visitCount > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${v.visitCount}회',
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: txtMuted),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dDay = DateTime(d.year, d.month, d.day);
    final diff = today.difference(dDay).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    if (diff < 7) return '$diff일 전';
    return '${d.month}/${d.day}';
  }

  String _relativeTime(DateTime? d) {
    if (d == null) return '없음';
    final ago = DateTime.now().difference(d);
    if (ago.inMinutes < 60) return '${ago.inMinutes}분 전';
    if (ago.inHours < 24) return '${ago.inHours}시간 전';
    return '${ago.inDays}일 전';
  }

  Color _categoryColor(String cat) {
    if (cat.contains('맛') || cat.contains('식')) return Colors.orange;
    if (cat.contains('카페')) return const Color(0xFF795548);
    if (cat.contains('쇼')) return Colors.pink;
    if (cat.contains('관광') || cat.contains('명소')) return Colors.blue;
    if (cat.contains('문화') || cat.contains('전시')) return Colors.purple;
    if (cat.contains('자연') || cat.contains('공원')) return Colors.green;
    return Colors.blueAccent;
  }
}
