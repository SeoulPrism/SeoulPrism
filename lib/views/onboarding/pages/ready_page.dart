import 'dart:io';
import 'package:flutter/material.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_typography.dart';

class ReadyPage extends StatelessWidget {
  static const id = 'ready_v1';
  const ReadyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final isIos = Platform.isIOS;
    final titleColor = isIos ? Colors.white : cs.onSurface;
    final bodyColor = isIos ? Colors.white.withValues(alpha: 0.75) : cs.onSurfaceVariant;
    final ringBg = isIos
        ? Colors.white.withValues(alpha: 0.15)
        : cs.primaryContainer;
    final ringBorder = isIos
        ? Colors.white.withValues(alpha: 0.3)
        : cs.outlineVariant;
    final iconColor = isIos ? Colors.white : cs.onPrimaryContainer;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ringBg,
              border: Border.all(color: ringBorder, width: 1),
            ),
            child: Icon(Icons.check_rounded, size: 44, color: iconColor),
          ),
          const SizedBox(height: 28),
          Text(
            l.readyPageTitle,
            style: AppTypography.displayLg.copyWith(
              color: titleColor,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              l.readyPageBody,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: bodyColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
