import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';

/// iOS: LiquidGlassContainer (리퀴드 글라스)
/// Android: Material 3 Surface 컨테이너
class AdaptiveGlassContainer extends StatelessWidget {
  final Widget child;
  final bool capsule;
  final double cornerRadius;
  final bool interactive;
  final bool prominent;

  const AdaptiveGlassContainer({
    super.key,
    required this.child,
    this.capsule = false,
    this.cornerRadius = 24,
    this.interactive = true,
    this.prominent = false,
  });

  const AdaptiveGlassContainer.capsule({
    super.key,
    required this.child,
    this.interactive = true,
  })  : capsule = true,
        cornerRadius = 999,
        prominent = false;

  const AdaptiveGlassContainer.rect({
    super.key,
    required this.child,
    this.cornerRadius = 24,
    this.interactive = true,
    this.prominent = false,
  }) : capsule = false;

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return LiquidGlassContainer(
        config: LiquidGlassConfig(
          effect: prominent ? CNGlassEffect.prominent : CNGlassEffect.regular,
          shape: capsule ? CNGlassEffectShape.capsule : CNGlassEffectShape.rect,
          cornerRadius: capsule ? null : cornerRadius,
          interactive: interactive,
        ),
        child: child,
      );
    }

    // Android: Material 3 surface container
    final cs = Theme.of(context).colorScheme;
    final radius = capsule
        ? BorderRadius.circular(999)
        : BorderRadius.circular(cornerRadius);

    return Material(
      elevation: prominent ? 3 : 1,
      shadowColor: Colors.transparent,
      surfaceTintColor: cs.surfaceTint,
      color: prominent ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
