// 일반 사용자 프로필 아바타 (Seoul Live 와 무관).
// avatarUrl 있으면 NetworkImage, 없으면 이름 이니셜 + 색상.
// iOS = LiquidGlass 외곽, Android = M3 surfaceContainer + outlineVariant.

import 'dart:io';

import 'package:flutter/material.dart';

class UserProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  /// fallback 으로 사용할 이름/이메일. 첫 글자만 사용.
  final String? fallbackName;
  final double size;
  /// 외곽 테두리 표시 여부. 기본은 platform 별 컨벤션 적용:
  ///   iOS = 흰색/검정 반투명 헤어라인
  ///   Android = outlineVariant 1.5px
  final bool showBorder;
  final VoidCallback? onTap;

  const UserProfileAvatar({
    super.key,
    required this.avatarUrl,
    this.fallbackName,
    this.size = 80,
    this.showBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isM3 = Platform.isAndroid;

    final fontSize = size * 0.42;
    final fallback = Container(
      color: isM3
          ? cs.secondaryContainer
          : Colors.white.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: _initialOrIcon(context, fontSize),
    );

    final image = (avatarUrl ?? '').isEmpty
        ? fallback
        : Image.network(
            avatarUrl!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            loadingBuilder: (_, child, prog) {
              if (prog == null) return child;
              return Container(
                color: cs.surfaceContainerHighest,
                alignment: Alignment.center,
                child: SizedBox(
                  width: size * 0.22,
                  height: size * 0.22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              );
            },
            errorBuilder: (_, _, _) => fallback,
          );

    final circle = ClipOval(
      child: SizedBox(width: size, height: size, child: image),
    );

    final bordered = !showBorder
        ? circle
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isM3
                    ? cs.outlineVariant
                    : Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: circle,
          );

    if (onTap == null) return bordered;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: bordered,
    );
  }

  Widget _initialOrIcon(BuildContext context, double fontSize) {
    final cs = Theme.of(context).colorScheme;
    final isM3 = Platform.isAndroid;
    final name = (fallbackName ?? '').trim();
    if (name.isEmpty) {
      return Icon(
        Icons.person_rounded,
        size: fontSize,
        color: isM3
            ? cs.onSecondaryContainer
            : Colors.white.withValues(alpha: 0.50),
      );
    }
    return Text(
      name.characters.first.toUpperCase(),
      style: TextStyle(
        fontSize: fontSize * 0.95,
        fontWeight: FontWeight.w800,
        color: isM3
            ? cs.onSecondaryContainer
            : Colors.white.withValues(alpha: 0.85),
      ),
    );
  }
}
