import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 앱 시작 로딩 — "3D 도시 모델링이 구축되고 → 실제 지도로 reveal".
///
/// Phase 1 (0~2.5s): 어두운 화면에 격자 ground plane 이 깔리고, 한강이 그려지고,
///   isometric cuboid 빌딩들이 한 채씩 솟아올라 광화문 일대 도시 형상이 구축됨.
///   N서울타워(중앙, 골드), 롯데타워(우, 청), 63빌딩(좌, 라이트블루) 랜드마크 글로우.
/// Phase 2 (2.2~3.0s): 중앙부터 radial reveal 마스크가 확장 — ShaderMask + dstOut 으로
///   다크/빌딩 레이어를 "관통" 해 뒤에서 mount 중인 진짜 Mapbox 지도가 드러남.
/// Phase 3 (2.9~3.5s): 잔여 페이드 + 텍스트 페이드 → onComplete.
class CityPulseLoadingView extends StatefulWidget {
  final VoidCallback onComplete;
  const CityPulseLoadingView({super.key, required this.onComplete});

  @override
  State<CityPulseLoadingView> createState() => _CityPulseLoadingViewState();
}

class _CityPulseLoadingViewState extends State<CityPulseLoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _buildCtrl; // 도시 구축 진행
  late final AnimationController _revealCtrl; // 진짜 지도 reveal
  late final AnimationController _scaffoldFadeCtrl; // 최종 페이드

  @override
  void initState() {
    super.initState();
    _buildCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaffoldFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );
    _runSequence();
  }

  Future<void> _runSequence() async {
    // 도시 구축이 거의 끝나갈 때 (2.2s) reveal 시작 — 살짝 overlap 으로 자연스러움.
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    _revealCtrl.forward();
    // 텍스트는 reveal 중간쯤에 페이드 시작.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _scaffoldFadeCtrl.reverse();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _buildCtrl.dispose();
    _revealCtrl.dispose();
    _scaffoldFadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([_buildCtrl, _revealCtrl, _scaffoldFadeCtrl]),
      builder: (_, __) {
        // Material(transparency) — Text 위젯 노란 underline 디버그 표시 방지.
        return Material(
          type: MaterialType.transparency,
          child: Opacity(
            opacity: _scaffoldFadeCtrl.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ShaderMask + dstOut: 다크 + 도시 모델 레이어에 radial 구멍을 뚫음.
                // 구멍 안쪽으로 뒤의 진짜 Mapbox 지도가 드러남.
                ShaderMask(
                  blendMode: BlendMode.dstOut,
                  shaderCallback: (rect) {
                    final p = _revealCtrl.value;
                    return RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: const [
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [
                        0.0,
                        (p * 0.95).clamp(0.0, 0.95),
                        ((p * 0.95) + 0.10).clamp(0.0, 1.0),
                      ],
                    ).createShader(rect);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 어두운 베이스 (네이비 → 검정 그라데이션).
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.2,
                            colors: [
                              Color(0xFF18203A),
                              Color(0xFF080A12),
                            ],
                          ),
                        ),
                      ),
                      // isometric 도시 모델링 — 빌딩 솟아오름 + 한강 + 격자.
                      CustomPaint(
                        painter: _IsoCityPainter(progress: _buildCtrl.value),
                      ),
                    ],
                  ),
                ),

                // 브랜드 텍스트 — reveal 시작 직전에 페이드 아웃 시작.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 56),
                      child: Opacity(
                        opacity: (1.0 - _revealCtrl.value).clamp(0.0, 1.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Seoul Vista',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF8FE3FF)
                                        .withValues(alpha: 0.55),
                                    blurRadius: 22,
                                  ),
                                  Shadow(
                                    color: const Color(0xFFBC82F3)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 500.ms, delay: 200.ms)
                                .slideY(
                                  begin: 0.3,
                                  end: 0,
                                  duration: 500.ms,
                                  delay: 200.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 4),
                            Text(
                              'v1.0.4',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 500.ms, delay: 350.ms),
                            const SizedBox(height: 10),
                            Text(
                              '도시를 구축하고 있어요',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13,
                                letterSpacing: 0.6,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 500.ms, delay: 500.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Isometric city painter
// ─────────────────────────────────────────────────────────────────

/// 빌딩 정의 (월드 좌표).
///   worldX: 동(+) ~ 서(-)
///   worldZ: 남(+) ~ 북(-)
///   targetHeight: 솟아오를 최종 높이 (월드 y)
///   width/depth: footprint
///   color: 색상 (랜드마크는 강조 색)
///   isLandmark: 글로우 효과
///   riseDelay: 0~1, 글로벌 progress 안에서 솟기 시작 시점
class _Building {
  final double wx;
  final double wz;
  final double targetHeight;
  final double width;
  final double depth;
  final Color color;
  final bool isLandmark;
  final double riseDelay;
  const _Building({
    required this.wx,
    required this.wz,
    required this.targetHeight,
    required this.width,
    required this.depth,
    required this.color,
    required this.riseDelay,
    this.isLandmark = false,
  });
}

class _IsoCityPainter extends CustomPainter {
  final double progress; // 0~1, 도시 구축 진행
  _IsoCityPainter({required this.progress});

  // 30° isometric — cos = √3/2 ≈ 0.866, sin = 0.5.
  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;

  // 빌딩 라인업 — 광화문 일대 + 한강 양안 클러스터.
  // 좌표는 -8~8 정도 범위, 높이는 1.5~10.
  static const List<_Building> _buildings = [
    // ── N서울타워 (중앙, 가장 높은 골드 랜드마크) ──
    _Building(
      wx: -0.5, wz: -2.5, targetHeight: 9, width: 0.9, depth: 0.9,
      color: Color(0xFFFFD700), isLandmark: true, riseDelay: 0.5,
    ),
    // ── 롯데타워 (동남, 가장 높은 청색 랜드마크) ──
    _Building(
      wx: 5.0, wz: 3.0, targetHeight: 11, width: 1.0, depth: 1.0,
      color: Color(0xFF8FE3FF), isLandmark: true, riseDelay: 0.6,
    ),
    // ── 63빌딩 (서쪽 강남, 라이트블루) ──
    _Building(
      wx: -5.0, wz: 1.5, targetHeight: 6.5, width: 0.8, depth: 0.8,
      color: Color(0xFFCFE9FF), isLandmark: true, riseDelay: 0.4,
    ),
    // ── 광화문/시청 클러스터 (중앙 북쪽) ──
    _Building(wx: 0.0, wz: -1.0, targetHeight: 3, width: 1, depth: 1,
        color: Color(0xFF2C3654), riseDelay: 0.05),
    _Building(wx: 1.5, wz: -0.5, targetHeight: 4, width: 1, depth: 1,
        color: Color(0xFF2C3654), riseDelay: 0.10),
    _Building(wx: -1.5, wz: -0.5, targetHeight: 3.5, width: 1, depth: 1,
        color: Color(0xFF2C3654), riseDelay: 0.08),
    _Building(wx: 0.8, wz: -2.0, targetHeight: 4.5, width: 1.2, depth: 1.0,
        color: Color(0xFF2C3654), riseDelay: 0.15),
    _Building(wx: -2.5, wz: -1.8, targetHeight: 2.5, width: 1, depth: 1,
        color: Color(0xFF2C3654), riseDelay: 0.12),
    _Building(wx: 2.8, wz: -1.5, targetHeight: 3.2, width: 1, depth: 1,
        color: Color(0xFF2C3654), riseDelay: 0.18),
    _Building(wx: -3.5, wz: -2.5, targetHeight: 2, width: 1, depth: 1,
        color: Color(0xFF2C3654), riseDelay: 0.20),
    // ── 강남 클러스터 (남동) ──
    _Building(wx: 3.5, wz: 2.5, targetHeight: 5, width: 1.1, depth: 1.1,
        color: Color(0xFF2C3654), riseDelay: 0.25),
    _Building(wx: 4.5, wz: 1.5, targetHeight: 6, width: 1.0, depth: 1.0,
        color: Color(0xFF2C3654), riseDelay: 0.30),
    _Building(wx: 6.0, wz: 4.0, targetHeight: 4, width: 1, depth: 1,
        color: Color(0xFF2C3654), riseDelay: 0.35),
    _Building(wx: 3.0, wz: 4.5, targetHeight: 5.5, width: 1.2, depth: 1.2,
        color: Color(0xFF2C3654), riseDelay: 0.32),
    // ── 영등포/마포 (서남) ──
    _Building(wx: -4.0, wz: 2.5, targetHeight: 3.5, width: 1, depth: 1,
        color: Color(0xFF2C3654), riseDelay: 0.22),
    _Building(wx: -3.0, wz: 3.5, targetHeight: 5, width: 1, depth: 1,
        color: Color(0xFF2C3654), riseDelay: 0.28),
    _Building(wx: -6.0, wz: 3.0, targetHeight: 3, width: 1, depth: 1,
        color: Color(0xFF2C3654), riseDelay: 0.18),
    // ── 외곽 채움 ──
    _Building(wx: 7.0, wz: -1.0, targetHeight: 2.5, width: 0.9, depth: 0.9,
        color: Color(0xFF2C3654), riseDelay: 0.35),
    _Building(wx: -7.0, wz: -1.0, targetHeight: 2.5, width: 0.9, depth: 0.9,
        color: Color(0xFF2C3654), riseDelay: 0.30),
    _Building(wx: 5.5, wz: -3.0, targetHeight: 3, width: 0.9, depth: 0.9,
        color: Color(0xFF2C3654), riseDelay: 0.40),
    _Building(wx: -5.5, wz: -3.5, targetHeight: 2.5, width: 0.9, depth: 0.9,
        color: Color(0xFF2C3654), riseDelay: 0.42),
    _Building(wx: 0.0, wz: 5.5, targetHeight: 2, width: 0.9, depth: 0.9,
        color: Color(0xFF2C3654), riseDelay: 0.38),
    _Building(wx: -1.5, wz: -4.5, targetHeight: 2, width: 0.9, depth: 0.9,
        color: Color(0xFF2C3654), riseDelay: 0.40),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // 살짝 위쪽으로 뷰포인트 이동 — 위 1/3 지점에 카메라 둠.
    final cy = size.height * 0.50;
    // 화면에 적당히 들어오도록 스케일.
    final scale = size.shortestSide / 18;

    Offset project(double wx, double wy, double wz) {
      return Offset(
        cx + (wx - wz) * _cos30 * scale,
        cy + (wx + wz) * _sin30 * scale - wy * scale,
      );
    }

    _drawGround(canvas, project, scale);
    _drawHanRiver(canvas, project, scale);

    // 빌딩 — depth 정렬 (먼 것 = wx+wz 큰 것 부터 = 화면상 위쪽).
    final sorted = [..._buildings]
      ..sort((a, b) => (b.wx + b.wz).compareTo(a.wx + a.wz));
    for (final b in sorted) {
      // 각 빌딩의 로컬 진행도.
      final localT = ((progress - b.riseDelay) / 0.5).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final easedT = 1 - math.pow(1 - localT, 3).toDouble();
      final h = b.targetHeight * easedT;
      if (h < 0.05) continue;
      _drawCuboid(canvas, project, b, h);
    }
  }

  // ── 격자 ground plane ──
  void _drawGround(
    Canvas canvas,
    Offset Function(double, double, double) project,
    double scale,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF2A3550).withValues(alpha: 0.35)
      ..strokeWidth = 0.6;
    const gridSize = 12;
    const step = 1.0;
    for (int i = -gridSize; i <= gridSize; i++) {
      // x 라인 (z 변화)
      final p1 = project(i * step, 0, -gridSize * step);
      final p2 = project(i * step, 0, gridSize * step);
      canvas.drawLine(p1, p2, paint);
      // z 라인 (x 변화)
      final p3 = project(-gridSize * step, 0, i * step);
      final p4 = project(gridSize * step, 0, i * step);
      canvas.drawLine(p3, p4, paint);
    }
  }

  // ── 한강 — 가로 곡선 (지면 위) ──
  void _drawHanRiver(
    Canvas canvas,
    Offset Function(double, double, double) project,
    double scale,
  ) {
    // 한강은 z ≈ 1.5 부근 (남쪽) 동서로 흐름.
    final pts = <Offset>[];
    for (double wx = -10; wx <= 10; wx += 0.5) {
      // 살짝 곡선 — sin 으로 wave.
      final wz = 1.5 + math.sin(wx * 0.3) * 0.4;
      pts.add(project(wx, 0, wz));
    }
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    // 글로우.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4A90E2).withValues(alpha: 0.30)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // 코어.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF6BA8E5).withValues(alpha: 0.85)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  // ── cuboid 한 채 그리기 (3 면: 우측, 정면, 윗면) ──
  void _drawCuboid(
    Canvas canvas,
    Offset Function(double, double, double) project,
    _Building b,
    double height,
  ) {
    final hw = b.width / 2;
    final hd = b.depth / 2;

    // 7 visible 모서리 (back-bottom 모서리 p000 은 항상 가려짐).
    final p100 = project(b.wx + hw, 0, b.wz - hd);
    final p001 = project(b.wx - hw, 0, b.wz + hd);
    final p101 = project(b.wx + hw, 0, b.wz + hd);
    final p010 = project(b.wx - hw, height, b.wz - hd);
    final p110 = project(b.wx + hw, height, b.wz - hd);
    final p011 = project(b.wx - hw, height, b.wz + hd);
    final p111 = project(b.wx + hw, height, b.wz + hd);

    // 면 색 — 윗면 brightest, 우측 mid, 정면(앞) darkest.
    final topColor = _shade(b.color, 1.0);
    final rightColor = _shade(b.color, 0.65);
    final frontColor = _shade(b.color, 0.45);

    // 정면 (남쪽 face — z+ 방향).
    final front = Path()
      ..moveTo(p001.dx, p001.dy)
      ..lineTo(p101.dx, p101.dy)
      ..lineTo(p111.dx, p111.dy)
      ..lineTo(p011.dx, p011.dy)
      ..close();
    canvas.drawPath(front, Paint()..color = frontColor);

    // 우측 (동쪽 face — x+ 방향).
    final right = Path()
      ..moveTo(p100.dx, p100.dy)
      ..lineTo(p101.dx, p101.dy)
      ..lineTo(p111.dx, p111.dy)
      ..lineTo(p110.dx, p110.dy)
      ..close();
    canvas.drawPath(right, Paint()..color = rightColor);

    // 윗면.
    final top = Path()
      ..moveTo(p010.dx, p010.dy)
      ..lineTo(p110.dx, p110.dy)
      ..lineTo(p111.dx, p111.dy)
      ..lineTo(p011.dx, p011.dy)
      ..close();
    canvas.drawPath(top, Paint()..color = topColor);

    // 모서리 라인 — 살짝 더 밝게.
    final edgePaint = Paint()
      ..color = _shade(b.color, 1.3).withValues(alpha: 0.4)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    canvas.drawPath(top, edgePaint);
    canvas.drawPath(right, edgePaint);

    // 랜드마크 — 꼭대기 글로우.
    if (b.isLandmark) {
      final topCenter = project(b.wx, height, b.wz);
      canvas.drawCircle(
        topCenter,
        14,
        Paint()
          ..color = b.color.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(
        topCenter,
        4,
        Paint()..color = b.color,
      );
      canvas.drawCircle(
        topCenter,
        2,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
    }
  }

  /// 색 brightness 조절 — alpha 유지.
  Color _shade(Color base, double brightness) {
    return Color.fromRGBO(
      ((base.r * 255) * brightness).round().clamp(0, 255),
      ((base.g * 255) * brightness).round().clamp(0, 255),
      ((base.b * 255) * brightness).round().clamp(0, 255),
      base.a,
    );
  }

  @override
  bool shouldRepaint(covariant _IsoCityPainter old) =>
      old.progress != progress;
}
