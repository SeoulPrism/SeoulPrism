import 'dart:io';
import 'package:flutter/material.dart';
import '../../../widgets/adaptive/adaptive_glass_container.dart';

/// 튜토리얼 페이지 카드 컨테이너.
/// iOS — 리퀴드 글라스 (어두운 배경 위에 떠있는 frosted card).
/// Android — Material 3 surfaceContainer (Material You tonal palette).
class PageCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const PageCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(28, 32, 28, 32),
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return AdaptiveGlassContainer.rect(
        cornerRadius: 32,
        interactive: false,
        child: Padding(padding: padding, child: child),
      );
    }
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      surfaceTintColor: cs.surfaceTint,
      elevation: 1,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
