import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

/// iOS: BackdropFilter 글라스 카드
/// Android: Material 3 Surface Card
class AdaptiveSurfaceCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const AdaptiveSurfaceCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      );
    }

    // Android: Material 3 Card
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}

/// 설정/프로필 등 페이지용 섹션 카드 — 테마 따름
class AdaptiveSectionCard extends StatelessWidget {
  final List<Widget> children;
  final double borderRadius;

  const AdaptiveSectionCard({
    super.key,
    required this.children,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      color: cs.surfaceContainerLow,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(children: children),
      ),
    );
  }
}

/// iOS: 반투명 배경
/// Android: M3 Surface
class AdaptiveScaffoldBackground extends StatelessWidget {
  final Widget child;

  const AdaptiveScaffoldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return ColoredBox(
        color: const Color(0xFF0A0A0A),
        child: child,
      );
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}
