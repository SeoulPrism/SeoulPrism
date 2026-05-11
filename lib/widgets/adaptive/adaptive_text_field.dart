import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS: CupertinoTextField (glass=true 면 LiquidGlassContainer 로 래핑)
/// Android: Material 3 TextField (filled tonal)
class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final TextStyle? style;
  final TextStyle? placeholderStyle;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry padding;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  /// iOS 에서 LiquidGlass 컨테이너로 감쌀지. 기본 true 로 변경 — 앱 전체 글라스 일관성.
  final bool glass;
  /// 글라스 컨테이너 코너 반경.
  final double glassRadius;

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.style,
    this.placeholderStyle,
    this.decoration,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.onChanged,
    this.onSubmitted,
    this.glass = true,
    this.glassRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      // 테마 기반 색 — 라이트 모드 백색 텍스트는 안 보임 (예전 하드코딩 버그).
      final cs = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final field = CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        placeholderStyle: placeholderStyle ??
            TextStyle(
              color: isDark
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6B7280),
              fontSize: 14,
            ),
        style: style ??
            TextStyle(color: cs.onSurface, fontSize: 15),
        // glass=true 일 때 내부 데코는 투명 (글라스가 배경 담당).
        decoration: glass ? const BoxDecoration() : decoration,
        padding: padding,
        cursorColor: cs.primary,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      );
      if (!glass) {
        return SizedBox(width: double.infinity, child: field);
      }
      // 텍스트 필드는 LiquidGlass 네이티브 컨테이너를 안 쓴다 — UiKitView 기반
      // 이라 첫 빌드는 child 직접 반환하다가, 두 번째 빌드에서 Stack(passthrough)
      // 로 전환되면서 placeholder 폭으로 collapse 되는 버그가 있다. 동일한
      // 글라스 룩을 ClipRRect + BackdropFilter 로 직접 그려 사이즈를 확정한다.
      return _GlassTextFieldFrame(
        cornerRadius: glassRadius,
        isDark: isDark,
        child: field,
      );
    }

    // Android: Material 3 TextField (컴팩트)
    final cs = Theme.of(context).colorScheme;
    final bgColor = decoration?.color ?? cs.surfaceContainerHighest;
    final radius = decoration?.borderRadius as BorderRadius? ?? BorderRadius.circular(12);

    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: style,
        cursorColor: cs.primary,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: placeholderStyle ??
              TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          contentPadding: padding,
          filled: true,
          fillColor: bgColor,
          border: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          isDense: true,
          isCollapsed: true,
        ),
      ),
    );
  }
}

/// iOS 텍스트 필드용 글라스 프레임 — LiquidGlass 네이티브 컨테이너의 Stack
/// passthrough 사이즈 버그를 우회. 풀폭 고정 + BackdropFilter 로 글라스 룩.
class _GlassTextFieldFrame extends StatelessWidget {
  final Widget child;
  final double cornerRadius;
  final bool isDark;
  const _GlassTextFieldFrame({
    required this.child,
    required this.cornerRadius,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.04);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.10);
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              color: fill,
              border: Border.all(color: border, width: 0.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 검색바 전용: iOS에서는 CupertinoTextField (decoration: null),
/// Android에서는 Material 3 naked TextField
class AdaptiveSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final TextStyle? style;
  final TextStyle? placeholderStyle;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  const AdaptiveSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.placeholder = '',
    this.style,
    this.placeholderStyle,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        placeholderStyle: placeholderStyle,
        style: style,
        decoration: null,
        padding: EdgeInsets.zero,
        onChanged: onChanged,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
      );
    }

    // Android: 장식 없는 Material TextField (검색바 내부용)
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: style,
      cursorColor: cs.primary,
      onChanged: onChanged,
      onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: placeholderStyle,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        isDense: true,
      ),
    );
  }
}
