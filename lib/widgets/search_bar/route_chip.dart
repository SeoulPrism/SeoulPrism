import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import '../../theme/app_typography.dart';

/// 결과 헤더의 경로 칩 (최적/최단/최소환승 + 시간).
/// iOS 는 CNButton (glass), Android 는 M3 FilledButton/OutlinedButton.
class RouteChip extends StatelessWidget {
  final String label;
  final String time;
  final bool selected;
  final VoidCallback onTap;

  const RouteChip({
    super.key,
    required this.label,
    required this.time,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    if (Platform.isIOS) {
      return CNButton(
        label: '$label  |  $time',
        onPressed: onTap,
        tint: textColor,
        config: CNButtonConfig(
          style: selected ? CNButtonStyle.prominentGlass : CNButtonStyle.glass,
          minHeight: 40,
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: selected
          ? FilledButton.tonal(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                foregroundColor: textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: AppTypography.bodySm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text('$label  |  $time'),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: textColor.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: AppTypography.bodySm,
              ),
              child: Text('$label  |  $time'),
            ),
    );
  }
}
