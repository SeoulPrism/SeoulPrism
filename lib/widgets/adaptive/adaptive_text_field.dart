import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS: CupertinoTextField
/// Android: Material 3 TextField
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

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.style,
    this.placeholderStyle,
    this.decoration,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
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
        decoration: decoration,
        padding: padding,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      );
    }

    // Android: Material 3 TextField
    final cs = Theme.of(context).colorScheme;

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
        fillColor: decoration?.color ?? cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        isDense: true,
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
