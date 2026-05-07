import 'package:flutter/material.dart';

/// 페이지 인디케이터 — 활성 페이지가 캡슐로 길어지며 색이 모핑.
/// 비활성 페이지는 작은 점.
class LiquidPageIndicator extends StatelessWidget {
  final int count;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  const LiquidPageIndicator({
    super.key,
    required this.count,
    required this.progress,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0x66FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final dist = (i - progress).abs().clamp(0.0, 1.0);
        final t = 1.0 - dist;
        final width = 8.0 + 20.0 * t;
        final color = Color.lerp(inactiveColor, activeColor, t)!;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: width,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
