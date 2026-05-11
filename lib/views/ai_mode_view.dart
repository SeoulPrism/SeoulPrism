import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

class AiModeView extends StatefulWidget {
  final VoidCallback? onClose;
  final bool closing;
  /// 글로우 컬러 팔레트. 정확히 7개 색 (마지막 = 첫 번째, wrap).
  /// null 이면 기본 Apple Intelligence 팔레트.
  final List<Color>? palette;

  const AiModeView({
    super.key,
    this.onClose,
    this.closing = false,
    this.palette,
  });

  @override
  State<AiModeView> createState() => _AiModeViewState();
}

class _AiModeViewState extends State<AiModeView>
    with TickerProviderStateMixin {
  late AnimationController _spreadController;

  // 4개 레이어, 각각 독립 AnimationController (스태거 핵심)
  late List<AnimationController> _layerControllers;
  late List<VoidCallback> _layerListeners;
  late List<List<double>> _layerCurrentStops;
  late List<List<double>> _layerFromStops;
  List<double> _targetStops = [0.0, 0.17, 0.33, 0.5, 0.67, 0.83, 1.0];

  // path deformation 용
  late AnimationController _deformController;

  Timer? _updateTimer;
  bool _dismissed = false;
  final _random = Random();

  // 레이어별 duration (ms) — 핵심: 스태거
  static const _layerDurations = [500, 600, 800, 1000];

  @override
  void initState() {
    super.initState();

    // 등장/퇴장
    _spreadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // path deformation (미세 진동)
    _deformController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 4레이어 각각의 stops 애니메이션
    final initialStops = [0.0, 0.17, 0.33, 0.5, 0.67, 0.83, 1.0];
    _layerCurrentStops = List.generate(4, (_) => List.from(initialStops));
    _layerFromStops = List.generate(4, (_) => List.from(initialStops));

    _layerListeners = <VoidCallback>[];
    _layerControllers = List.generate(4, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _layerDurations[i]),
      );
      void l() => _interpolateLayer(i);
      _layerListeners.add(l);
      ctrl.addListener(l);
      return ctrl;
    });

    // 0.4초마다 새 타겟 생성 → 4레이어 동시 출발 (도착 시간은 각각 다름)
    _updateTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      _generateNewTarget();
    });

    // 시작
    _spreadController.forward();
    // 첫 타겟 즉시
    _generateNewTarget();
  }

  void _generateNewTarget() {
    // 완전 랜덤 6개 위치 생성 → 정렬 (Apple 방식)
    final positions = List.generate(5, (_) => _random.nextDouble() * 0.9 + 0.05);
    positions.sort();

    _targetStops = [0.0, ...positions, 1.0];

    // 각 레이어의 현재값을 from으로 저장하고, 각자 속도로 새 타겟으로 출발
    for (int i = 0; i < 4; i++) {
      _layerFromStops[i] = List.from(_layerCurrentStops[i]);
      _layerControllers[i].forward(from: 0.0);
    }
  }

  void _interpolateLayer(int layerIndex) {
    if (!mounted) return;
    final t = Curves.easeInOut.transform(_layerControllers[layerIndex].value);
    final from = _layerFromStops[layerIndex];
    final newStops = List.generate(7, (i) {
      return from[i] + (_targetStops[i] - from[i]) * t;
    });
    setState(() {
      _layerCurrentStops[layerIndex] = newStops;
    });
  }

  @override
  void didUpdateWidget(AiModeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.closing && !oldWidget.closing) {
      _dismiss();
    }
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _updateTimer?.cancel();
    _spreadController.reverse().then((_) {
      widget.onClose?.call();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _spreadController.dispose();
    _deformController.dispose();
    for (var i = 0; i < _layerControllers.length; i++) {
      _layerControllers[i].removeListener(_layerListeners[i]);
      _layerControllers[i].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _spreadController,
        _deformController,
        ..._layerControllers,
      ]),
      builder: (context, _) {
        return IgnorePointer(
          child: ClipRect(
            clipBehavior: Clip.none,
            child: CustomPaint(
              painter: _AppleIntelligenceGlowPainter(
                layerStops: _layerCurrentStops,
                spreadProgress: _spreadController.value,
                deformPhase: _deformController.value * 2 * pi,
                palette: widget.palette,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

/// Apple Intelligence 글로우 페인터
/// - 4레이어 스태거 (각자 다른 속도로 같은 타겟에 도달)
/// - 회전 없음 — stops 움직임만으로 유기적 흐름
/// - path deformation으로 보더가 미세하게 숨쉼
class _AppleIntelligenceGlowPainter extends CustomPainter {
  final List<List<double>> layerStops; // 4개 레이어 각각의 현재 stops
  final double spreadProgress;
  final double deformPhase; // path 진동용
  final List<Color>? palette; // 외부에서 컬러 팔레트 오버라이드

  _AppleIntelligenceGlowPainter({
    required this.layerStops,
    required this.spreadProgress,
    required this.deformPhase,
    this.palette,
  });

  // Apple 기본 팔레트 (palette 미지정 시)
  static const _defaultColors = [
    Color(0xFFBC82F3), // purple
    Color(0xFFF5B9EA), // pink
    Color(0xFF8D9FFF), // blue
    Color(0xFFFF6778), // coral
    Color(0xFFFFBA71), // orange
    Color(0xFFC686FF), // lavender
    Color(0xFFBC82F3), // purple (wrap)
  ];

  List<Color> get _colors => palette ?? _defaultColors;

  // 레이어별: [strokeWidth, blurSigma]
  // Flutter에서는 iOS보다 값을 키워야 동일한 시각적 효과
  static const _layerParams = [
    [3.5, 0.0],   // Layer 1: core (선명, blur 없음)
    [10.0, 6.0],  // Layer 2: mid-inner
    [18.0, 15.0], // Layer 3: mid-outer
    [28.0, 30.0], // Layer 4: halo (넓은 번짐)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (spreadProgress <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 미세 진동이 적용된 path 생성
    final borderPath = _createDeformedPath(size);

    if (spreadProgress < 1.0) {
      _drawPartial(canvas, size, borderPath, rect);
    } else {
      _drawFull(canvas, borderPath, rect);
    }
  }

  /// 보더 path에 sin파 미세 진동 적용 (±1.5px)
  Path _createDeformedPath(Size size, [Offset origin = Offset.zero]) {
    const r = 44.0;
    const segments = 512; // 코너 곡선 완벽하게 부드럽게
    const amplitude = 1.5;

    final path = Path();

    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final basePoint = _pointOnRoundedRect(size, r, t);

      // sin파 변위 (각 점마다 다른 위상)
      final dx = amplitude * sin(deformPhase + t * 4 * pi) * cos(_normalAngle(size, r, t));
      final dy = amplitude * sin(deformPhase + t * 4 * pi) * sin(_normalAngle(size, r, t));

      final point = Offset(origin.dx + basePoint.dx + dx, origin.dy + basePoint.dy + dy);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  /// 라운드 렉트 위의 점 (t: 0~1)
  Offset _pointOnRoundedRect(Size size, double r, double t) {
    final w = size.width;
    final h = size.height;

    // 둘레 길이 계산
    final straight = 2 * (w - 2 * r) + 2 * (h - 2 * r);
    final curved = 2 * pi * r;
    final total = straight + curved;

    var dist = t * total;

    // 상단 (좌→우)
    final topLen = w - 2 * r;
    if (dist < topLen) return Offset(r + dist, 0);
    dist -= topLen;

    // 우상단 코너
    final cornerLen = pi * r / 2;
    if (dist < cornerLen) {
      final angle = -pi / 2 + dist / r;
      return Offset(w - r + r * cos(angle), r + r * sin(angle));
    }
    dist -= cornerLen;

    // 우측 (상→하)
    final rightLen = h - 2 * r;
    if (dist < rightLen) return Offset(w, r + dist);
    dist -= rightLen;

    // 우하단 코너
    if (dist < cornerLen) {
      final angle = 0.0 + dist / r;
      return Offset(w - r + r * cos(angle), h - r + r * sin(angle));
    }
    dist -= cornerLen;

    // 하단 (우→좌)
    if (dist < topLen) return Offset(w - r - dist, h);
    dist -= topLen;

    // 좌하단 코너
    if (dist < cornerLen) {
      final angle = pi / 2 + dist / r;
      return Offset(r + r * cos(angle), h - r + r * sin(angle));
    }
    dist -= cornerLen;

    // 좌측 (하→상)
    if (dist < rightLen) return Offset(0, h - r - dist);
    dist -= rightLen;

    // 좌상단 코너
    if (dist < cornerLen) {
      final angle = pi + dist / r;
      return Offset(r + r * cos(angle), r + r * sin(angle));
    }

    return Offset(r, 0);
  }

  /// 보더 법선 각도 (변위 방향)
  double _normalAngle(Size size, double r, double t) {
    final w = size.width;
    final h = size.height;
    final straight = 2 * (w - 2 * r) + 2 * (h - 2 * r);
    final curved = 2 * pi * r;
    final total = straight + curved;
    var dist = t * total;

    final topLen = w - 2 * r;
    if (dist < topLen) return -pi / 2; // 위로
    dist -= topLen;

    final cornerLen = pi * r / 2;
    if (dist < cornerLen) return -pi / 2 + dist / r;
    dist -= cornerLen;

    final rightLen = h - 2 * r;
    if (dist < rightLen) return 0; // 오른쪽
    dist -= rightLen;

    if (dist < cornerLen) return dist / r;
    dist -= cornerLen;

    if (dist < topLen) return pi / 2; // 아래
    dist -= topLen;

    if (dist < cornerLen) return pi / 2 + dist / r;
    dist -= cornerLen;

    if (dist < rightLen) return pi; // 왼쪽
    dist -= rightLen;

    if (dist < cornerLen) return pi + dist / r;

    return -pi / 2;
  }

  void _drawFull(Canvas canvas, Path borderPath, Rect rect) {
    // 4레이어 (뒤에서 앞으로: halo → core)
    for (int i = 3; i >= 0; i--) {
      final params = _layerParams[i];
      final gradient = SweepGradient(
        center: Alignment.center,
        colors: _colors,
        stops: layerStops[i],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = params[0]
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (params[1] > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, params[1]);
      }

      canvas.drawPath(borderPath, paint);
    }
  }

  void _drawPartial(Canvas canvas, Size size, Path fullPath, Rect rect) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(44),
    );
    final metricsPath = Path()..addRRect(rrect);
    final metrics = metricsPath.computeMetrics().first;
    final totalLength = metrics.length;

    // 양쪽 옆에서 퍼짐
    final originRight = totalLength * 0.25;
    final originLeft = totalLength * 0.75;
    final halfSpread = totalLength * 0.25 * spreadProgress;

    Path extractWrapped(double start, double end) {
      final p = Path();
      if (start < 0) {
        p.addPath(metrics.extractPath(totalLength + start, totalLength), Offset.zero);
        p.addPath(metrics.extractPath(0, end), Offset.zero);
      } else if (end > totalLength) {
        p.addPath(metrics.extractPath(start, totalLength), Offset.zero);
        p.addPath(metrics.extractPath(0, end - totalLength), Offset.zero);
      } else {
        p.addPath(metrics.extractPath(start, end), Offset.zero);
      }
      return p;
    }

    final visiblePath = Path();
    visiblePath.addPath(extractWrapped(originRight - halfSpread, originRight + halfSpread), Offset.zero);
    visiblePath.addPath(extractWrapped(originLeft - halfSpread, originLeft + halfSpread), Offset.zero);

    for (int i = 3; i >= 0; i--) {
      final params = _layerParams[i];
      final gradient = SweepGradient(
        center: Alignment.center,
        colors: _colors,
        stops: layerStops[i],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = params[0]
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (params[1] > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, params[1]);
      }

      canvas.drawPath(visiblePath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AppleIntelligenceGlowPainter oldDelegate) => true;
}

/// 팔레트 사이를 부드럽게 보간한 결과를 반환.
/// 두 팔레트 모두 7개 색이라고 가정.
List<Color> lerpPalette(List<Color> from, List<Color> to, double t) {
  final n = to.length;
  return [
    for (int i = 0; i < n; i++)
      Color.lerp(from[i % from.length], to[i], t.clamp(0.0, 1.0))!,
  ];
}
