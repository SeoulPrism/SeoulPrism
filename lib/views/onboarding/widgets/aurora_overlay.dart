import 'dart:math';
import 'package:flutter/material.dart';

/// 지도 위에 깔리는 오로라 — 천천히 드리프트하는 보라/시안 광원 두 개.
/// BlendMode.screen 으로 합성해 어두운 야간 맵에 광채 추가.
class AuroraOverlay extends StatefulWidget {
  const AuroraOverlay({super.key});

  @override
  State<AuroraOverlay> createState() => _AuroraOverlayState();
}

class _AuroraOverlayState extends State<AuroraOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _AuroraPainter(_ctrl.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t; // 0..1
  _AuroraPainter(this.t);

  static const _purple = Color(0xFFBC82F3);
  static const _cyan = Color(0xFF8FE3FF);
  static const _coral = Color(0xFFFF6B9C);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.saveLayer(Offset.zero & size, Paint());

    // 광원 1 — 보라 (좌상→우중)
    final p1 = Offset(
      w * (0.15 + 0.5 * sin(t * 2 * pi)),
      h * (0.18 + 0.15 * cos(t * 2 * pi)),
    );
    canvas.drawCircle(
      p1,
      max(w, h) * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [_purple.withValues(alpha: 0.45), _purple.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: p1, radius: max(w, h) * 0.55))
        ..blendMode = BlendMode.screen,
    );

    // 광원 2 — 시안 (우하→좌중)
    final p2 = Offset(
      w * (0.85 - 0.4 * sin(t * 2 * pi + pi / 3)),
      h * (0.78 + 0.12 * sin(t * 2 * pi)),
    );
    canvas.drawCircle(
      p2,
      max(w, h) * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [_cyan.withValues(alpha: 0.32), _cyan.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: p2, radius: max(w, h) * 0.5))
        ..blendMode = BlendMode.screen,
    );

    // 광원 3 — 코랄 (드리프트 강함, 작음)
    final p3 = Offset(
      w * (0.5 + 0.35 * cos(t * 2 * pi - pi / 2)),
      h * (0.45 + 0.3 * sin(t * 2 * pi - pi / 2)),
    );
    canvas.drawCircle(
      p3,
      max(w, h) * 0.32,
      Paint()
        ..shader = RadialGradient(
          colors: [_coral.withValues(alpha: 0.22), _coral.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: p3, radius: max(w, h) * 0.32))
        ..blendMode = BlendMode.screen,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}
