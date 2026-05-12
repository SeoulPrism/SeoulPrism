import 'package:flutter/material.dart';

/// 종료 시퀀스 동안 화면 위에 깔리는 지하철 라인 그려지는 오버레이.
/// 실 지도 좌표가 아닌 스타일라이즈된 곡선들 — 9 호선 컬러로 스태거 reveal.
class SubwayDrawingOverlay extends StatelessWidget {
  /// 0..1 진행 — 0: 안 그려진 상태, 1: 모두 그려져 페이드 끝.
  final Animation<double> progress;
  const SubwayDrawingOverlay({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: progress,
        builder: (_, __) => CustomPaint(
          painter: _SubwayDrawingPainter(progress.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SubwayDrawingPainter extends CustomPainter {
  final double t; // 0..1

  _SubwayDrawingPainter(this.t);

  // 9 호선 + 부가 라인 컬러 (SubwayColors 직접 참조 안 하고 인라인 — 의존성 최소).
  // 좌표는 [0,1] 정규화 화면 비율.
  static const _lines = [
    _LineDef(color: Color(0xFF0052A4), startStagger: 0.00, points: [
      [0.05, 0.18], [0.25, 0.30], [0.45, 0.42], [0.65, 0.55], [0.88, 0.70],
    ]), // 1호선 — 좌상 → 우하 사선
    _LineDef(color: Color(0xFF00A84D), startStagger: 0.05, points: [
      [0.50, 0.20], [0.75, 0.30], [0.85, 0.50], [0.75, 0.70], [0.50, 0.80],
      [0.25, 0.70], [0.15, 0.50], [0.25, 0.30], [0.50, 0.20],
    ]), // 2호선 — 순환
    _LineDef(color: Color(0xFFEF7C1C), startStagger: 0.10, points: [
      [0.95, 0.10], [0.78, 0.30], [0.55, 0.50], [0.32, 0.70], [0.10, 0.88],
    ]), // 3호선 — 우상 → 좌하 사선
    _LineDef(color: Color(0xFF00A5DE), startStagger: 0.15, points: [
      [0.55, 0.05], [0.50, 0.30], [0.48, 0.55], [0.50, 0.80], [0.52, 0.95],
    ]), // 4호선 — 위 → 아래
    _LineDef(color: Color(0xFF996CAC), startStagger: 0.20, points: [
      [0.05, 0.55], [0.30, 0.52], [0.55, 0.50], [0.80, 0.48], [0.95, 0.45],
    ]), // 5호선 — 좌 → 우 가로
    _LineDef(color: Color(0xFFCD7C2F), startStagger: 0.25, points: [
      [0.10, 0.75], [0.35, 0.78], [0.60, 0.80], [0.85, 0.82],
    ]), // 6호선 — 하단 가로
    _LineDef(color: Color(0xFF747F00), startStagger: 0.30, points: [
      [0.20, 0.10], [0.30, 0.32], [0.40, 0.55], [0.50, 0.78], [0.60, 0.95],
    ]), // 7호선 — 살짝 사선
    _LineDef(color: Color(0xFFE6186C), startStagger: 0.35, points: [
      [0.70, 0.10], [0.62, 0.35], [0.55, 0.60], [0.48, 0.85],
    ]), // 8호선 — 우상 → 좌하
    _LineDef(color: Color(0xFFBDB092), startStagger: 0.40, points: [
      [0.05, 0.30], [0.30, 0.25], [0.55, 0.22], [0.80, 0.18], [0.95, 0.15],
    ]), // 9호선 — 상단 가로
  ];

  // Phases (t 기준):
  //   0     ~ 0.05  : 페이드 인
  //   0.05  ~ 0.50  : 그리기 (스태거 + progressive)
  //   0.50  ~ 0.85  : hold — 전 라인 fully drawn (HomeView 로딩 대기)
  //   0.85  ~ 1.00  : 페이드 아웃
  static const _drawPhaseEnd = 0.50;
  static const _holdPhaseEnd = 0.85;
  static const _fadeInEnd = 0.05;

  @override
  void paint(Canvas canvas, Size size) {
    final globalAlpha = _alpha(t);
    if (globalAlpha <= 0) return;

    // 그리기 phase 내부의 진행도 (0~1).
    // hold/fadeout phase 동안에는 1.0 으로 고정 — 이미 다 그려진 상태.
    final drawProgress = t < _drawPhaseEnd ? (t / _drawPhaseEnd) : 1.0;

    for (final line in _lines) {
      // 각 라인은 stagger 부터 시작, 0.55 폭으로 drawProgress 진행.
      final localT =
          ((drawProgress - line.startStagger) / 0.55).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final path = _buildPath(line.points, size);
      // PathMetrics 로 progressive draw.
      final metrics = path.computeMetrics().first;
      final drawPath = metrics.extractPath(0, metrics.length * localT);

      // 글로우 — blur 대신 두 단계 stroke (iOS Impeller jank 회피).
      canvas.drawPath(
        drawPath,
        Paint()
          ..color = line.color.withValues(alpha: 0.22 * globalAlpha)
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      canvas.drawPath(
        drawPath,
        Paint()
          ..color = line.color.withValues(alpha: 0.40 * globalAlpha)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      // 코어
      canvas.drawPath(
        drawPath,
        Paint()
          ..color = line.color.withValues(alpha: 0.95 * globalAlpha)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  Path _buildPath(List<List<double>> points, Size size) {
    final path = Path();
    if (points.isEmpty) return path;
    final first = points.first;
    path.moveTo(first[0] * size.width, first[1] * size.height);
    for (int i = 1; i < points.length; i++) {
      // Catmull-Rom 같은 부드러운 곡선 효과 — 이전점/현재점 중간 control.
      final prev = points[i - 1];
      final curr = points[i];
      final ctrlX = (prev[0] + curr[0]) / 2 * size.width;
      final ctrlY = (prev[1] + curr[1]) / 2 * size.height;
      path.quadraticBezierTo(
        prev[0] * size.width,
        prev[1] * size.height,
        ctrlX,
        ctrlY,
      );
    }
    final last = points.last;
    path.lineTo(last[0] * size.width, last[1] * size.height);
    return path;
  }

  /// 글로벌 알파 — fade in / hold / fade out 3 단계.
  double _alpha(double t) {
    if (t <= 0 || t >= 1) return 0;
    if (t < _fadeInEnd) return t / _fadeInEnd;
    if (t > _holdPhaseEnd) return (1 - t) / (1 - _holdPhaseEnd);
    return 1.0;
  }

  @override
  bool shouldRepaint(covariant _SubwayDrawingPainter old) => old.t != t;
}

class _LineDef {
  final Color color;
  final double startStagger;
  final List<List<double>> points;
  const _LineDef({
    required this.color,
    required this.startStagger,
    required this.points,
  });
}

