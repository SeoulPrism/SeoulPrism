import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';

/// iOS: CNButton (리퀴드 글라스)
/// Android: Material 3 FilledTonalButton
class AdaptiveGlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double minHeight;

  const AdaptiveGlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.minHeight = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CNButton(
        label: label,
        onPressed: onPressed,
        config: CNButtonConfig(
          style: CNButtonStyle.glass,
          minHeight: minHeight,
        ),
      );
    }

    // Android: Material 3 FilledTonalButton
    return SizedBox(
      height: minHeight,
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(minHeight / 2),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// iOS: CNButton.icon (리퀴드 글라스)
/// Android: Material 3 IconButton.filledTonal
class AdaptiveGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double iconSize;
  final double? size;
  final Color? tint;

  const AdaptiveGlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconSize = 22,
    this.size,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CNButton.icon(
        customIcon: icon,
        onPressed: onPressed,
        tint: tint,
        config: CNButtonConfig(
          style: CNButtonStyle.glass,
          customIconSize: iconSize,
          minHeight: size,
          width: size,
        ),
      );
    }

    // Android: Material 3 IconButton
    final btnSize = size ?? 44.0;

    return SizedBox(
      width: btnSize,
      height: btnSize,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        color: tint,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(btnSize / 2),
          ),
        ),
      ),
    );
  }
}
