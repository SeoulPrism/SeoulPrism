import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/recent_route_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

/// 최근 길찾기 페어 패널 — 출발/도착이 비어있을 때 빠른 재선택용.
class RecentRoutesPanel extends StatelessWidget {
  final List<RecentRoute> routes;
  final double radius;
  final void Function(RecentRoute route) onSelect;
  final void Function(RecentRoute route) onRemove;

  const RecentRoutesPanel({
    super.key,
    required this.routes,
    required this.onSelect,
    required this.onRemove,
    this.radius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: AppColors.glassDropOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  '최근 길찾기',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...routes.map(
                (r) => InkWell(
                  onTap: () => onSelect(r),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: 15,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            '${r.departure}  →  ${r.arrival}',
                            style: AppTypography.bodyMd,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (r.useCount > 1) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${r.useCount}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => onRemove(r),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 13,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
