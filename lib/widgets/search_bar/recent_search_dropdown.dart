import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// 검색 입력 비어있고 포커스 시 표시되는 최근 검색어 드롭다운.
class RecentSearchDropdown extends StatelessWidget {
  final List<String> items;
  final void Function(String query) onSelect;
  final void Function(String query) onRemove;
  final VoidCallback onClearAll;
  final double radius;

  const RecentSearchDropdown({
    super.key,
    required this.items,
    required this.onSelect,
    required this.onRemove,
    required this.onClearAll,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final list = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
          child: Row(
            children: [
              Text(
                '최근 검색',
                style: AppTypography.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClearAll,
                child: Text(
                  '전체 삭제',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        ...items.take(8).map(
              (q) => GestureDetector(
                onTap: () => onSelect(q),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 16, color: AppColors.textDisabled),
                      const SizedBox(width: 10),
                      Expanded(child: Text(q, style: AppTypography.bodyMd)),
                      GestureDetector(
                        onTap: () => onRemove(q),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: 6),
      ],
    );

    if (Platform.isAndroid) {
      final cs = Theme.of(context).colorScheme;
      return Material(
        elevation: 3,
        shadowColor: cs.shadow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(radius),
        color: cs.surfaceContainer,
        surfaceTintColor: cs.surfaceTint,
        clipBehavior: Clip.antiAlias,
        child: list,
      );
    }
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
          child: list,
        ),
      ),
    );
  }
}
