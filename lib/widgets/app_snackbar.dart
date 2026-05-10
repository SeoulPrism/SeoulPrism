import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

/// 전역 ScaffoldMessenger 키 — main.dart 의 MaterialApp 에 주입.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// 어디서나 안전하게 토스트 표시. 디자인:
/// - iOS: 리퀴드 글라스 (다크/라이트 자동)
/// - Android: Material 3 inverseSurface
void showAppSnackBar(String text, {Duration? duration}) {
  final state = rootScaffoldMessengerKey.currentState;
  if (state == null) return;
  // 큐 쌓이는 것 방지 — 기존 거 클리어 후 새로 표시.
  state.clearSnackBars();
  state.showSnackBar(SnackBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    dismissDirection: DismissDirection.down,
    duration: duration ?? const Duration(seconds: 3),
    content: _AppSnackContent(text: text),
  ));
}

class _AppSnackContent extends StatelessWidget {
  final String text;
  const _AppSnackContent({required this.text});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _IosGlassContent(text: text);
    }
    return _MaterialContent(text: text);
  }
}

// ─── iOS: 리퀴드 글라스 ─────────────────────────────────────────

class _IosGlassContent extends StatelessWidget {
  final String text;
  const _IosGlassContent({required this.text});

  @override
  Widget build(BuildContext context) {
    // 시스템 다크/라이트 모드 자동 감지.
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    final bg = isDark
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.78);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.08);
    final fg = isDark ? Colors.white : Colors.black.withValues(alpha: 0.85);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Android: Material 3 ────────────────────────────────────────

class _MaterialContent extends StatelessWidget {
  final String text;
  const _MaterialContent({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: cs.inverseSurface,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          text,
          style: TextStyle(
            color: cs.onInverseSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
