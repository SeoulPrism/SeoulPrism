import 'dart:io';
import 'package:flutter/material.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_typography.dart';

class WelcomePage extends StatelessWidget {
  static const id = 'welcome_v1';
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Platform.isIOS
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    final subColor = Platform.isIOS
        ? Colors.white.withValues(alpha: 0.7)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.55),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.location_on,
                size: 44,
                color: Color(0xFF1E1E2E),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Seoul Vista',
            style: AppTypography.displayLg.copyWith(
              color: textColor,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppL10n.of(context).welcomePageSubtitle,
            style: AppTypography.bodyMd.copyWith(color: subColor),
          ),
        ],
      ),
    );
  }
}
