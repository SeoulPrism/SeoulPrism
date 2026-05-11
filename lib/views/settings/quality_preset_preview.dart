import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../l10n/gen/app_localizations.dart';

/// 품질 프리셋 미리보기 — 실제 앱의 지하철 3D 시각화 (FillExtrusion 박스 +
/// 복선 트랙 + MiniTokyo3D 풍 캡슐 역) 을 축소판으로 재현.
/// preset: 'high' | 'medium' | 'low'
class QualityPresetPreview extends StatefulWidget {
  final String preset;
  const QualityPresetPreview({super.key, required this.preset});

  @override
  State<QualityPresetPreview> createState() => _QualityPresetPreviewState();
}

class _QualityPresetPreviewState extends State<QualityPresetPreview>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _intervalMs = 16;
  Duration _lastTickAt = Duration.zero;
  double _phase = 0;

  @override
  void initState() {
    super.initState();
    _applyPreset();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(covariant QualityPresetPreview old) {
    super.didUpdateWidget(old);
    if (old.preset != widget.preset) _applyPreset();
  }

  void _applyPreset() {
    _intervalMs = switch (widget.preset) {
      'high' => 16,   // 60 fps
      'medium' => 33, // 30 fps
      'low' => 100,   // 10 fps
      _ => 33,
    };
  }

  void _onTick(Duration elapsed) {
    if ((elapsed - _lastTickAt).inMilliseconds < _intervalMs) return;
    _lastTickAt = elapsed;
    if (!mounted) return;
    setState(() {
      // 진행 속도는 동일, 프레임 간격만 다르게 — 끊김 차이가 드러남
      _phase = (_phase + _intervalMs / 9000.0) % 1.0;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 부모 카드의 surfaceContainerLow 톤에 맞춰 베이스 색을 살짝 darken —
    // 어두운 야경 느낌은 살리되 카드와의 단절을 줄임.
    final base = Color.lerp(cs.surfaceContainerLow, Colors.black, 0.55)!;
    final top = Color.lerp(cs.surfaceContainerLow, Colors.black, 0.35)!;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, base],
              ),
            ),
          ),
          CustomPaint(
            painter: _SubwayPreviewPainter(
              phase: _phase,
              preset: widget.preset,
            ),
          ),
          // 하단 페이드 — 카드의 다음 섹션(세그먼트 컨트롤) 으로 자연스럽게 이어짐.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.surfaceContainerLow.withValues(alpha: 0),
                    cs.surfaceContainerLow.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          // 좌상단 데모 라벨 — 실 데이터 아니라는 명확한 표시.
          const Positioned(left: 12, top: 10, child: _DemoPill()),
        ],
      ),
    );
  }
}

class _DemoPill extends StatelessWidget {
  const _DemoPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB454), // 데모 = 호박색 (라이브 초록과 구분)
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            AppL10n.of(context).qualityPreviewDemoLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10.5,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 3D 투영 카메라 — 위에서 비스듬히 내려다보는 시점
// 월드 좌표: x = 좌우, y = 깊이(0=가까움, 클수록 멀어짐), z = 높이
// ─────────────────────────────────────────────────────────────────

class _Cam {
  final Size size;
  // 클수록 원근감 강함 (열차를 좀 더 시원하게 보고 싶어서 강하게)
  static const double persp = 0.0044;
  // 높이 한 단위가 화면 몇 픽셀에 해당하는지 (낮은 각도로 박스가 길어 보이도록)
  static const double zScale = 1.45;

  _Cam(this.size);

  Offset project(double x, double y, double z) {
    final scale = 1.0 / (1.0 + y * persp);
    final sx = size.width * 0.5 + x * scale;
    // 카메라 구도: 지평선을 화면 위쪽 1/4 지점으로 끌어올리고, 시야를 더 낮게.
    final sy =
        size.height * 0.24 + size.height * 0.72 * scale - z * zScale * scale;
    return Offset(sx, sy);
  }

  double depthScale(double y) => 1.0 / (1.0 + y * persp);
}

// ─────────────────────────────────────────────────────────────────

class _SubwayPreviewPainter extends CustomPainter {
  final double phase;
  final String preset;
  _SubwayPreviewPainter({required this.phase, required this.preset});

  // 1호선 색 (실제 SubwayColors)
  static const _line1 = Color(0xFF0052A4);

  // 1호선 한 노선만 — 부드러운 S 곡선
  static final _LineDef _line = _LineDef(_line1, const [
    Offset(-280, 360),
    Offset(-70, 260),
    Offset(60, 140),
    Offset(290, 40),
  ]);

  static const _trackOffset = 6.5; // 복선 간격 (월드 단위)

  @override
  void paint(Canvas canvas, Size size) {
    final cam = _Cam(size);

    final showGlow = preset == 'high';
    final showStations = preset != 'low';

    _drawGroundGrid(canvas, cam);

    // 1. 복선 트랙
    _drawDoubleTrack(canvas, cam, _line, showGlow);

    // 2. 역 (MiniTokyo3D 캡슐)
    if (showStations) {
      _drawStations(canvas, cam, _line);
    }

    // 3. 열차 한 대 — 3D 박스 (FillExtrusion 풍, 진행 방향과 정렬)
    _drawTrainBox(canvas, cam, _TrainOrder(_line, phase, true), showGlow);
  }

  // ── 바닥 그리드 (희미하게 깊이감을 줌) ──
  void _drawGroundGrid(Canvas canvas, _Cam cam) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.6;
    for (int i = -3; i <= 3; i++) {
      final x = i * 80.0;
      canvas.drawLine(
        cam.project(x, 0, 0),
        cam.project(x, 400, 0),
        paint,
      );
    }
    for (int j = 0; j <= 5; j++) {
      final y = j * 80.0;
      canvas.drawLine(
        cam.project(-280, y, 0),
        cam.project(280, y, 0),
        paint,
      );
    }
  }

  // ── 복선 트랙 (좌/우 평행 라인) ──
  void _drawDoubleTrack(Canvas canvas, _Cam cam, _LineDef line, bool glow) {
    const samples = 28;
    final left = <Offset>[];
    final right = <Offset>[];
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final p = _bezierAt(line.controls, t);
      final tangent = _bezierTangent(line.controls, t);
      // 수직 단위 벡터
      final len = math.sqrt(tangent.dx * tangent.dx + tangent.dy * tangent.dy);
      final nx = -tangent.dy / len;
      final ny = tangent.dx / len;
      left.add(cam.project(p.dx + nx * _trackOffset, p.dy + ny * _trackOffset, 0));
      right.add(cam.project(p.dx - nx * _trackOffset, p.dy - ny * _trackOffset, 0));
    }

    Path build(List<Offset> pts) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      return path;
    }

    final pL = build(left);
    final pR = build(right);

    if (glow) {
      final glowPaint = Paint()
        ..color = line.color.withValues(alpha: 0.35)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(pL, glowPaint);
      canvas.drawPath(pR, glowPaint);
    }

    final trackPaint = Paint()
      ..color = line.color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(pL, trackPaint);
    canvas.drawPath(pR, trackPaint);
  }

  // ── 역 (MiniTokyo3D 캡슐 + 노선색 도트) ──
  void _drawStations(Canvas canvas, _Cam cam, _LineDef line) {
    const stops = [0.18, 0.42, 0.66, 0.88];
    for (final t in stops) {
      final p = _bezierAt(line.controls, t);
      final tangent = _bezierTangent(line.controls, t);
      final len = math.sqrt(tangent.dx * tangent.dx + tangent.dy * tangent.dy);
      final nx = -tangent.dy / len;
      final ny = tangent.dx / len;

      // 단일 노선이라 단일 도트 캡슐 (실제 앱: 환승역만 멀티 도트)
      final start = cam.project(p.dx + nx * -4.5, p.dy + ny * -4.5, 0.6);
      final end = cam.project(p.dx + nx * 4.5, p.dy + ny * 4.5, 0.6);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.95)
          ..strokeWidth = 7.0
          ..strokeCap = StrokeCap.round,
      );
      final dotPos = cam.project(p.dx, p.dy, 0.7);
      canvas.drawCircle(dotPos, 2.6, Paint()..color = line.color);
    }
  }

  // ── 3D 추출 박스 (FillExtrusion 풍) ──
  void _drawTrainBox(
    Canvas canvas,
    _Cam cam,
    _TrainOrder order,
    bool glow,
  ) {
    final center = _bezierAt(order.line.controls, order.t);
    final tangent = _bezierTangent(order.line.controls, order.t);
    // bearing: 진행 방향의 각도 (atan2(dy, dx)) — 박스의 로컬 +x 가 이 방향을 향함
    final bearing = math.atan2(tangent.dy, tangent.dx);

    // 복선 오프셋 (방향에 따라 좌/우)
    final lenT = math.sqrt(tangent.dx * tangent.dx + tangent.dy * tangent.dy);
    final nx = -tangent.dy / lenT;
    final ny = tangent.dx / lenT;
    final sign = order.forward ? 1.0 : -1.0;
    final cx = center.dx + nx * _trackOffset * sign;
    final cy = center.dy + ny * _trackOffset * sign;

    // 박스 크기 (실제 앱: 45m × 20m × 20m) — 로컬 x 가 길이축
    const halfL = 22.0;
    const halfW = 8.0;
    const height = 22.0;

    final cosB = math.cos(bearing);
    final sinB = math.sin(bearing);

    // 표준 2D 회전: 로컬 +x 가 (cosB, sinB) = tangent 방향을 향함
    List<double> rotate(double lx, double ly) => [
          cx + lx * cosB - ly * sinB,
          cy + lx * sinB + ly * cosB,
        ];

    // 4 모서리: 뒤좌 / 뒤우 / 앞우 / 앞좌 (로컬 x = 길이, y = 폭)
    final c = [
      rotate(-halfL, -halfW), // rear-left
      rotate(-halfL, halfW),  // rear-right
      rotate(halfL, halfW),   // front-right
      rotate(halfL, -halfW),  // front-left
    ];

    final base = [for (final p in c) cam.project(p[0], p[1], 0)];
    final top = [for (final p in c) cam.project(p[0], p[1], height)];

    // 측면 4개 — 깊이순 (먼 것부터)
    final sideIdx = [0, 1, 2, 3];
    sideIdx.sort((a, b) {
      final aMid = (c[a][1] + c[(a + 1) % 4][1]) / 2;
      final bMid = (c[b][1] + c[(b + 1) % 4][1]) / 2;
      return bMid.compareTo(aMid);
    });

    final dark = Color.fromARGB(
      255,
      (order.line.color.r * 255 * 0.55).round().clamp(0, 255),
      (order.line.color.g * 255 * 0.55).round().clamp(0, 255),
      (order.line.color.b * 255 * 0.55).round().clamp(0, 255),
    );
    final mid = Color.fromARGB(
      255,
      (order.line.color.r * 255 * 0.78).round().clamp(0, 255),
      (order.line.color.g * 255 * 0.78).round().clamp(0, 255),
      (order.line.color.b * 255 * 0.78).round().clamp(0, 255),
    );

    for (int i = 0; i < 4; i++) {
      final fi = sideIdx[i];
      final p = Path()
        ..moveTo(base[fi].dx, base[fi].dy)
        ..lineTo(base[(fi + 1) % 4].dx, base[(fi + 1) % 4].dy)
        ..lineTo(top[(fi + 1) % 4].dx, top[(fi + 1) % 4].dy)
        ..lineTo(top[fi].dx, top[fi].dy)
        ..close();
      canvas.drawPath(p, Paint()..color = i < 2 ? dark : mid);
      canvas.drawPath(
        p,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6,
      );
    }

    // 윗면 (line color, 발광)
    final topPath = Path()
      ..moveTo(top[0].dx, top[0].dy)
      ..lineTo(top[1].dx, top[1].dy)
      ..lineTo(top[2].dx, top[2].dy)
      ..lineTo(top[3].dx, top[3].dy)
      ..close();

    if (glow) {
      canvas.drawPath(
        topPath,
        Paint()
          ..color = order.line.color.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    canvas.drawPath(topPath, Paint()..color = order.line.color);
    canvas.drawPath(
      topPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    // 진행 방향 표시: 앞쪽 헤드라이트 (흰색) + 뒤쪽 테일라이트 (빨강)
    final headL = rotate(halfL - 2, -halfW * 0.55);
    final headR = rotate(halfL - 2, halfW * 0.55);
    final tailL = rotate(-halfL + 2, -halfW * 0.55);
    final tailR = rotate(-halfL + 2, halfW * 0.55);
    final scaleAt = cam.depthScale(cy);
    final lightR = 1.4 + 1.4 * scaleAt;

    final headLPos = cam.project(headL[0], headL[1], height);
    final headRPos = cam.project(headR[0], headR[1], height);
    final tailLPos = cam.project(tailL[0], tailL[1], height);
    final tailRPos = cam.project(tailR[0], tailR[1], height);

    if (glow) {
      final headGlow = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(headLPos, lightR + 2, headGlow);
      canvas.drawCircle(headRPos, lightR + 2, headGlow);
      final tailGlow = Paint()
        ..color = const Color(0xFFFF3B30).withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(tailLPos, lightR + 1.5, tailGlow);
      canvas.drawCircle(tailRPos, lightR + 1.5, tailGlow);
    }
    final headPaint = Paint()..color = const Color(0xFFFFF6D5);
    canvas.drawCircle(headLPos, lightR, headPaint);
    canvas.drawCircle(headRPos, lightR, headPaint);
    final tailPaint = Paint()..color = const Color(0xFFFF3B30);
    canvas.drawCircle(tailLPos, lightR * 0.85, tailPaint);
    canvas.drawCircle(tailRPos, lightR * 0.85, tailPaint);
  }

  // ── 베지어 헬퍼 ──
  Offset _bezierAt(List<Offset> p, double t) {
    final u = 1 - t;
    final x = u * u * u * p[0].dx +
        3 * u * u * t * p[1].dx +
        3 * u * t * t * p[2].dx +
        t * t * t * p[3].dx;
    final y = u * u * u * p[0].dy +
        3 * u * u * t * p[1].dy +
        3 * u * t * t * p[2].dy +
        t * t * t * p[3].dy;
    return Offset(x, y);
  }

  Offset _bezierTangent(List<Offset> p, double t) {
    final u = 1 - t;
    final x = 3 * u * u * (p[1].dx - p[0].dx) +
        6 * u * t * (p[2].dx - p[1].dx) +
        3 * t * t * (p[3].dx - p[2].dx);
    final y = 3 * u * u * (p[1].dy - p[0].dy) +
        6 * u * t * (p[2].dy - p[1].dy) +
        3 * t * t * (p[3].dy - p[2].dy);
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(_SubwayPreviewPainter old) =>
      old.phase != phase || old.preset != preset;
}

class _LineDef {
  final Color color;
  final List<Offset> controls; // 4 Bezier control points (world XY)
  const _LineDef(this.color, this.controls);
}

class _TrainOrder {
  final _LineDef line;
  final double t;
  final bool forward; // 좌/우 트랙
  const _TrainOrder(this.line, this.t, this.forward);
}

// ─────────────────────────────────────────────────────────────────
// 인라인 세그먼트 컨트롤 — preview 바로 아래에 붙어서 한 카드처럼 보임
// ─────────────────────────────────────────────────────────────────

class QualityPresetSegmented extends StatelessWidget {
  final String selected; // 'high' | 'medium' | 'low'
  final ValueChanged<String> onChanged;
  const QualityPresetSegmented({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final items = [
      ('high', l.qualityPresetHigh, l.qualityPresetHighDetail),
      ('medium', l.qualityPresetMedium, l.qualityPresetMediumDetail),
      ('low', l.qualityPresetLow, l.qualityPresetLowDetail),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Expanded(
                  child: _SegmentButton(
                    label: items[i].$2,
                    selected: selected == items[i].$1,
                    onTap: () => onChanged(items[i].$1),
                  ),
                ),
                if (i < items.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            items.firstWhere((e) => e.$1 == selected, orElse: () => items[0]).$3,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              letterSpacing: 0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withValues(alpha: 0.16) : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.55)
                  : cs.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? cs.primary : cs.onSurface,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
