import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../../data/travel_styles.dart';
import '../../../services/settings_service.dart';

/// AI Companion 페이지 데모 — ai_view.dart 의 무드 Glow UI 와 동일 구조.
/// 풀스크린 둥근 직사각 ring 위에 7색 sweep gradient 4 레이어를 겹치고,
/// stops 가 400ms 마다 흩어지며 회전. 무드 팔레트는 Pathfinding 페이지에서
/// 사용자가 고른 스타일 (없으면 kDefaultStylePalette) 사용.
///
/// 탭하면 잠깐 strokeBoost + brightness 증가 (speaking mock).
class OnboardingAiGlowDemo extends StatefulWidget {
  const OnboardingAiGlowDemo({super.key});

  @override
  State<OnboardingAiGlowDemo> createState() => _OnboardingAiGlowDemoState();
}

class _OnboardingAiGlowDemoState extends State<OnboardingAiGlowDemo>
    with TickerProviderStateMixin {
  late final AnimationController _spread;
  late final AnimationController _deform;
  late final List<AnimationController> _layerCtrls;
  late final List<List<double>> _currentStops;
  late final List<List<double>> _fromStops;
  List<double> _target = [0.0, 0.17, 0.33, 0.5, 0.67, 0.83, 1.0];
  Timer? _retarget;
  final _rand = Random();

  static const _layerDurations = [500, 600, 800, 1000];

  double _strokeBoost = 0.0;
  double _brightness = 1.0;

  List<Color> _colors = kDefaultStylePalette;

  @override
  void initState() {
    super.initState();
    _resolveMoodPalette();

    _spread = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _deform = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    final init = [0.0, 0.17, 0.33, 0.5, 0.67, 0.83, 1.0];
    _currentStops = List.generate(4, (_) => List<double>.from(init));
    _fromStops = List.generate(4, (_) => List<double>.from(init));

    _layerCtrls = List.generate(4, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _layerDurations[i]),
      );
      c.addListener(() => _interpolate(i));
      return c;
    });

    _retarget = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => _newTarget(),
    );
    _spread.forward();
    _newTarget();
  }

  void _resolveMoodPalette() {
    final key = SettingsService.instance.getString(kTravelStylePrefKey);
    final style = travelStyleByKey(key);
    _colors = style?.palette ?? kDefaultStylePalette;
  }

  void _newTarget() {
    final positions = List.generate(5, (_) => _rand.nextDouble() * 0.9 + 0.05);
    positions.sort();
    _target = [0.0, ...positions, 1.0];
    for (var i = 0; i < 4; i++) {
      _fromStops[i] = List<double>.from(_currentStops[i]);
      _layerCtrls[i].forward(from: 0.0);
    }
  }

  void _interpolate(int i) {
    if (!mounted) return;
    final t = Curves.easeInOut.transform(_layerCtrls[i].value);
    final from = _fromStops[i];
    final stops = _currentStops[i];
    for (var k = 0; k < 7; k++) {
      stops[k] = from[k] + (_target[k] - from[k]) * t;
    }
  }

  void _onTap() {
    setState(() {
      _strokeBoost = 2.0;
      _brightness = 1.2;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _strokeBoost = 0.0;
        _brightness = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _retarget?.cancel();
    _spread.dispose();
    _deform.dispose();
    for (final c in _layerCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spread, _deform, ..._layerCtrls]),
        builder: (_, _) => CustomPaint(
          painter: _GlowPainter(
            colors: _colors,
            layerStops: _currentStops,
            spreadProgress: _spread.value,
            deformPhase: _deform.value * 2 * pi,
            strokeBoost: _strokeBoost,
            brightness: _brightness,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// ai_view.dart 의 _AiGlowPainter 와 동일 구조.
/// 차이: _baseColors 대신 외부 주입된 colors 사용.
class _GlowPainter extends CustomPainter {
  final List<Color> colors;
  final List<List<double>> layerStops;
  final double spreadProgress;
  final double deformPhase;
  final double strokeBoost;
  final double brightness;

  _GlowPainter({
    required this.colors,
    required this.layerStops,
    required this.spreadProgress,
    required this.deformPhase,
    required this.strokeBoost,
    required this.brightness,
  });

  static const _layerParams = [
    [3.5, 0.0],
    [10.0, 6.0],
    [18.0, 15.0],
    [28.0, 30.0],
  ];

  List<Color> get _adjusted {
    if (brightness == 1.0) return colors;
    return colors.map((c) {
      final hsv = HSVColor.fromColor(c);
      return hsv
          .withValue((hsv.value * brightness).clamp(0.0, 1.0))
          .withSaturation((hsv.saturation * (2 - brightness)).clamp(0.0, 1.0))
          .toColor();
    }).toList();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (spreadProgress <= 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = _deformedPath(size);
    if (spreadProgress < 1.0) {
      _drawPartial(canvas, size, rect);
    } else {
      _drawFull(canvas, path, rect);
    }
  }

  Path _deformedPath(Size size, [Offset origin = Offset.zero]) {
    const r = 44.0;
    const segments = 512;
    const amplitude = 1.5;
    final path = Path();
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final base = _pointOnRoundedRect(size, r, t);
      final angle = _normalAngle(size, r, t);
      final dx = amplitude * sin(deformPhase + t * 4 * pi) * cos(angle);
      final dy = amplitude * sin(deformPhase + t * 4 * pi) * sin(angle);
      final p = Offset(origin.dx + base.dx + dx, origin.dy + base.dy + dy);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  Offset _pointOnRoundedRect(Size size, double r, double t) {
    final w = size.width;
    final h = size.height;
    final straight = 2 * (w - 2 * r) + 2 * (h - 2 * r);
    final curved = 2 * pi * r;
    final total = straight + curved;
    var d = t * total;

    final topLen = w - 2 * r;
    if (d < topLen) return Offset(r + d, 0);
    d -= topLen;
    final cornerLen = pi * r / 2;
    if (d < cornerLen) {
      final a = -pi / 2 + d / r;
      return Offset(w - r + r * cos(a), r + r * sin(a));
    }
    d -= cornerLen;
    final rightLen = h - 2 * r;
    if (d < rightLen) return Offset(w, r + d);
    d -= rightLen;
    if (d < cornerLen) {
      final a = 0.0 + d / r;
      return Offset(w - r + r * cos(a), h - r + r * sin(a));
    }
    d -= cornerLen;
    if (d < topLen) return Offset(w - r - d, h);
    d -= topLen;
    if (d < cornerLen) {
      final a = pi / 2 + d / r;
      return Offset(r + r * cos(a), h - r + r * sin(a));
    }
    d -= cornerLen;
    if (d < rightLen) return Offset(0, h - r - d);
    d -= rightLen;
    if (d < cornerLen) {
      final a = pi + d / r;
      return Offset(r + r * cos(a), r + r * sin(a));
    }
    return Offset(r, 0);
  }

  double _normalAngle(Size size, double r, double t) {
    final w = size.width;
    final h = size.height;
    final straight = 2 * (w - 2 * r) + 2 * (h - 2 * r);
    final curved = 2 * pi * r;
    final total = straight + curved;
    var d = t * total;
    final topLen = w - 2 * r;
    if (d < topLen) return -pi / 2;
    d -= topLen;
    final cornerLen = pi * r / 2;
    if (d < cornerLen) return -pi / 2 + d / r;
    d -= cornerLen;
    final rightLen = h - 2 * r;
    if (d < rightLen) return 0;
    d -= rightLen;
    if (d < cornerLen) return d / r;
    d -= cornerLen;
    if (d < topLen) return pi / 2;
    d -= topLen;
    if (d < cornerLen) return pi / 2 + d / r;
    d -= cornerLen;
    if (d < rightLen) return pi;
    d -= rightLen;
    if (d < cornerLen) return pi + d / r;
    return -pi / 2;
  }

  void _drawFull(Canvas canvas, Path path, Rect rect) {
    final cs = _adjusted;
    for (var i = 3; i >= 0; i--) {
      final p = _layerParams[i];
      final gradient = SweepGradient(
        center: Alignment.center,
        colors: cs,
        stops: layerStops[i],
      );
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = p[0] + strokeBoost
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (p[1] > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, p[1]);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawPartial(Canvas canvas, Size size, Rect rect) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(44),
    );
    final metricsPath = Path()..addRRect(rrect);
    final metrics = metricsPath.computeMetrics().first;
    final total = metrics.length;
    final originRight = total * 0.25;
    final originLeft = total * 0.75;
    final halfSpread = total * 0.25 * spreadProgress;

    Path extractWrapped(double start, double end) {
      final pp = Path();
      if (start < 0) {
        pp.addPath(metrics.extractPath(total + start, total), Offset.zero);
        pp.addPath(metrics.extractPath(0, end), Offset.zero);
      } else if (end > total) {
        pp.addPath(metrics.extractPath(start, total), Offset.zero);
        pp.addPath(metrics.extractPath(0, end - total), Offset.zero);
      } else {
        pp.addPath(metrics.extractPath(start, end), Offset.zero);
      }
      return pp;
    }

    final visible = Path();
    visible.addPath(
        extractWrapped(originRight - halfSpread, originRight + halfSpread),
        Offset.zero);
    visible.addPath(
        extractWrapped(originLeft - halfSpread, originLeft + halfSpread),
        Offset.zero);

    final cs = _adjusted;
    for (var i = 3; i >= 0; i--) {
      final p = _layerParams[i];
      final gradient = SweepGradient(
        center: Alignment.center,
        colors: cs,
        stops: layerStops[i],
      );
      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = p[0] + strokeBoost
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (p[1] > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, p[1]);
      }
      canvas.drawPath(visible, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => true;
}
