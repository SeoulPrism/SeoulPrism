import 'dart:io';
import 'package:flutter/material.dart';
import 'adaptive_glass_button.dart';

/// 표준 어댑티브 AppBar:
/// - iOS: 투명 배경 + AdaptiveGlassIconButton 백버튼 (settings_view 패턴 재사용)
/// - Android: 투명 + Material AppBar 기본 백 화살표
///
/// title 은 좌측 정렬(centerTitle: false 가 기본). centerTitle 옵션으로 가운데 가능.
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBack;

  const AdaptiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: !showBack
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Center(
                child: Platform.isIOS
                    ? AdaptiveGlassIconButton(
                        icon: Icons.arrow_back_ios_rounded,
                        onPressed: () => Navigator.of(context).maybePop(),
                        iconSize: 18,
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
              ),
            ),
      title: Text(
        title,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
    );
  }
}
