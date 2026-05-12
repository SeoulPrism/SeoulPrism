import 'dart:io';
import 'package:flutter/material.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../main.dart';
import '../../../services/settings_service.dart';
import '../../../theme/app_typography.dart';

class WelcomePage extends StatefulWidget {
  static const id = 'welcome_v1';
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // 칩 4종 — system 은 제외 (사용자가 직접 고르는 액션이므로 명시적인 4개만).
  static const _langs = <(String code, String label)>[
    ('ko', '한국어'),
    ('en', 'English'),
    ('ja', '日本語'),
    ('zh', '中文'),
  ];

  void _select(String code) {
    SeoulPrismApp.setAppLanguage(context, code);
    setState(() {}); // 칩 선택 표시 즉시 반영.
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Platform.isIOS
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    final subColor = Platform.isIOS
        ? Colors.white.withValues(alpha: 0.7)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final currentLang = SettingsService.instance.appLanguage;

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
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              AppL10n.of(context).welcomePageLanguagesHint,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: subColor.withValues(alpha: 0.85),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 언어 chips — 'system' 일 땐 어떤 chip 도 선택 표시 안 함 (사용자가 명시
          // 선택하기 전까지는 OS 추종 상태이므로 칩 강조 X).
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final (code, label) in _langs)
                _LangChip(
                  label: label,
                  selected: currentLang == code,
                  onTap: () => _select(code),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Colors.white.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.12);
    final fg = selected ? const Color(0xFF1E1E2E) : Colors.white;
    final border = selected
        ? Colors.transparent
        : Colors.white.withValues(alpha: 0.35);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
