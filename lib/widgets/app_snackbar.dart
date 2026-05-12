import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

/// 전역 ScaffoldMessenger 키 — main.dart 의 MaterialApp 에 주입.
/// (Overlay 기반 토스트 도입 후 직접 사용은 거의 없음. 외부 호환 유지용)
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

OverlayEntry? _activeToast;
Timer? _activeToastTimer;

/// 상단 슬라이드-다운 토스트. 어떤 화면에서도 균일한 모양.
/// - iOS: 리퀴드 글라스
/// - Android: M3 inverseSurface
/// 기존 토스트가 있으면 즉시 교체.
void showAppSnackBar(String text, {Duration? duration}) {
  final ctx = rootScaffoldMessengerKey.currentContext;
  if (ctx == null) return;
  final overlay = Overlay.maybeOf(ctx, rootOverlay: true);
  if (overlay == null) return;

  // 기존 토스트 정리.
  _activeToastTimer?.cancel();
  _activeToast?.remove();
  _activeToast = null;

  final dur = duration ?? const Duration(seconds: 3);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastHost(
      text: text,
      onDone: () {
        if (_activeToast == entry) {
          _activeToast?.remove();
          _activeToast = null;
        }
      },
      visibleDuration: dur,
    ),
  );
  _activeToast = entry;
  overlay.insert(entry);
}

class _ToastHost extends StatefulWidget {
  final String text;
  final Duration visibleDuration;
  final VoidCallback onDone;
  const _ToastHost({
    required this.text,
    required this.visibleDuration,
    required this.onDone,
  });

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _hideTimer = Timer(widget.visibleDuration, _dismiss);
  }

  Future<void> _dismiss() async {
    _hideTimer?.cancel();
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) {
              return Opacity(
                opacity: _fade.value,
                child: Transform.translate(
                  offset: Offset(
                      0, -((1 - _slide.value) * (40 + topPad))),
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.opaque,
              child: _AppSnackContent(text: widget.text),
            ),
          ),
        ),
      ),
    );
  }
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
