import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'adaptive_glass_container.dart';

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
      final field = CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        placeholderStyle: placeholderStyle ??
            const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
        style: style ?? const TextStyle(color: Colors.white, fontSize: 15),
        // glass=true 일 때 내부 데코는 투명 (글라스가 배경 담당).
        decoration: glass ? const BoxDecoration() : decoration,
        padding: padding,
        cursorColor: const Color(0xFF7C5CFF),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      );
      if (glass) {
        return AdaptiveGlassContainer.rect(
          cornerRadius: glassRadius,
          child: field,
        );
      }
      return field;
    }

    // Android: Material 3 TextField (컴팩트)
    final cs = Theme.of(context).colorScheme;
    final bgColor = decoration?.color ?? cs.surfaceContainerHighest;
    final radius = decoration?.borderRadius as BorderRadius? ?? BorderRadius.circular(12);

    return TextField(
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
