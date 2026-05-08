import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/adaptive/adaptive.dart';

/// 여행 (Day Plan) 바텀시트 패널.
/// 현재는 비어있는 상태 + CTA — DayPlan 저장/생성 시스템은 후속 작업.
class TravelPanel extends StatelessWidget {
  /// AI 모드 진입 (일정 생성 — Gemini).
  final VoidCallback onUseAi;

  /// 즐겨찾기 / 방문 기록 기반 일정 생성 (TODO: 실제 동작은 후속).
  final VoidCallback onUseSaved;

  /// 패널 닫기.
  final VoidCallback onClose;

  const TravelPanel({
    super.key,
    required this.onUseAi,
    required this.onUseSaved,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isM3 = Platform.isAndroid;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

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
        // 드래그 핸들
        Padding(
          padding: const EdgeInsets.only(top: 12),
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
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '여행',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: txtPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            size: 32,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '서울 일정 만들기',
                          style: AppTypography.titleMd.copyWith(
                            color: txtPrimary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '하루 코스를 만들어 지도에 표시해 드려요.\n'
                            '경복궁부터 한강 야경까지, 시간 흐름대로.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm.copyWith(
                              color: txtMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _Cta(
                  icon: Icons.auto_awesome,
                  label: 'AI 가 추천해줘요',
                  subtitle: 'Gemini 가 시간/날씨 고려해 자동 생성',
                  onTap: onUseAi,
                  primary: true,
                ),
                const SizedBox(height: 12),
                _Cta(
                  icon: Icons.bookmark_outline_rounded,
                  label: '내 저장 장소로 만들기',
                  subtitle: '즐겨찾기 + 방문 기록 기반 동선 자동 생성',
                  onTap: onUseSaved,
                  primary: false,
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
              ],
            ),
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
              colors: isLight
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
}

class _Cta extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;
  const _Cta({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isM3 = Platform.isAndroid;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bg = primary
        ? AppColors.accent.withValues(alpha: 0.16)
        : (isM3
            ? cs.surfaceContainerHighest
            : (isLight
                ? Colors.black.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.08)));
    final iconColor = primary
        ? AppColors.accent
        : (isM3 ? cs.onSurface : (isLight ? Colors.black87 : Colors.white));
    final labelColor = primary
        ? AppColors.accent
        : (isM3 ? cs.onSurface : (isLight ? Colors.black87 : Colors.white));
    final subColor = isM3
        ? cs.onSurfaceVariant
        : (isLight
            ? const Color(0xFF6E6E73)
            : Colors.white.withValues(alpha: 0.55));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: primary
              ? Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMd.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: subColor),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: subColor,
            ),
          ],
        ),
      ),
    );
  }
}
