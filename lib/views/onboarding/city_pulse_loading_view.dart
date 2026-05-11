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

  // ShaderMask 가 활성화될 시점 — reveal 시작 후에만 켜서 shader 재생성 비용을
  // 첫 2.2s 동안 회피한다 (이 동안 뒤에서 Mapbox 가 mount 중이라 UI thread 가
  // 가장 바쁨).
  bool _revealStarted = false;

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
    setState(() => _revealStarted = true);
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
    // 부모는 정적 — setState 폭격 없음. 컨트롤러 .value 가 바뀌는 영역은 각자
    // AnimatedBuilder 로 좁혀서 다시 그린다. 그래서 build() 자체는 진입 시
    // 한 번만 실행됨.
    //
    // Material(transparency) — Text 위젯 노란 underline 디버그 표시 방지.
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _scaffoldFadeCtrl,
        builder: (context, child) => Opacity(
          opacity: _scaffoldFadeCtrl.value,
          child: child,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 도시 모델 레이어 — 진입 첫 ~2.2s 는 ShaderMask 없이 (shader
            // 재생성 비용 회피). reveal 시작되면 ShaderMask 켜서 radial reveal.
            _revealStarted ? _buildCityLayerMasked() : _buildCityLayer(),

            // 브랜드 텍스트 — reveal 시작 후 페이드 아웃.
            _buildBrandText(),
          ],
        ),
      ),
    );
  }

  /// 도시 모델 (ShaderMask 없음) — 첫 2.2s 동안 사용.
  Widget _buildCityLayer() {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF18203A), Color(0xFF080A12)],
              ),
            ),
          ),
          // 페인터만 컨트롤러 tick 으로 다시 그림. 부모는 리빌드 안 함.
          AnimatedBuilder(
            animation: _buildCtrl,
            builder: (_, __) => CustomPaint(
              // willChange: true 라 Flutter raster cache 는 어차피 안 함 →
              // isComplex 와 동시 사용은 모순. progress 가 매 프레임 변하니
              // cache 를 노리지 말고 willChange 만 두는 게 맞다.
              willChange: true,
              painter: _IsoCityPainter(progress: _buildCtrl.value),
            ),
          ),
        ],
      ),
    );
  }

  /// 도시 모델 + ShaderMask reveal — reveal 시작 후 사용.
  Widget _buildCityLayerMasked() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _revealCtrl,
        builder: (context, child) {
          return ShaderMask(
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
            child: child,
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0xFF18203A), Color(0xFF080A12)],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _buildCtrl,
              builder: (_, __) => CustomPaint(
                isComplex: true,
                willChange: true,
                painter: _IsoCityPainter(progress: _buildCtrl.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandText() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 56),
          child: AnimatedBuilder(
            animation: _revealCtrl,
            builder: (_, child) => Opacity(
              opacity: (1.0 - _revealCtrl.value).clamp(0.0, 1.0),
              child: child,
            ),
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
                        color: const Color(0xFF8FE3FF).withValues(alpha: 0.55),
                        blurRadius: 22,
                      ),
                      Shadow(
                        color: const Color(0xFFBC82F3).withValues(alpha: 0.35),
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
                  'v1.0.5',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
    // 8 → 13 × 2 = 26 line draws (전 50 → 26, 약 절반). 시각 차이 미미.
    const gridSize = 8;
    const step = 1.5;
    final bound = gridSize * step;
    for (int i = -gridSize; i <= gridSize; i++) {
      final v = i * step;
      // x 라인 (z 변화)
      canvas.drawLine(project(v, 0, -bound), project(v, 0, bound), paint);
      // z 라인 (x 변화)
      canvas.drawLine(project(-bound, 0, v), project(bound, 0, v), paint);
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
    // 글로우 — MaskFilter.blur 는 iOS Impeller 에서 첫 paint 시 Metal shader
    // compile 로 jank → 두 단계 stroke 로 같은 글로우 효과를 blur 없이 낸다.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4A90E2).withValues(alpha: 0.18)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4A90E2).withValues(alpha: 0.30)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
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

    // (모서리 stroke 제거 — 23 빌딩 × 2 stroke pass = 46 draw call 절감.
    // 시각 차이 미미하고, 윗면/우측 면의 _shade 차이로 모서리 라인 자체가
    // 자연스럽게 보인다.)

    // 랜드마크 — 꼭대기 글로우. blur 대신 동심원 alpha 계단으로 글로우 표현
    // (iOS Impeller jank 회피).
    if (b.isLandmark) {
      final topCenter = project(b.wx, height, b.wz);
      canvas.drawCircle(
        topCenter, 18,
        Paint()..color = b.color.withValues(alpha: 0.10),
      );
      canvas.drawCircle(
        topCenter, 12,
        Paint()..color = b.color.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        topCenter, 7,
        Paint()..color = b.color.withValues(alpha: 0.55),
      );
      canvas.drawCircle(
        topCenter, 4,
        Paint()..color = b.color,
      );
      canvas.drawCircle(
        topCenter, 2,
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
