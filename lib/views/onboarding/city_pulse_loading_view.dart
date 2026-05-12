import 'dart:math' as math;
import 'dart:ui' as ui;
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

/// 빌딩 종류 — 랜드마크는 특수 렌더링 (N타워 = 기둥+돔, 롯데 = 테이퍼, 63 = 골드).
enum _BuildingKind { normal, nSeoulTower, lotteTower, building63 }

/// 빌딩 정의 (월드 좌표).
class _Building {
  final double wx;
  final double wz;
  final double targetHeight;
  final double width;
  final double depth;
  final Color color;
  final _BuildingKind kind;
  final double riseDelay; // 0~1, 글로벌 progress 안에서 솟기 시작 시점
  const _Building({
    required this.wx,
    required this.wz,
    required this.targetHeight,
    required this.width,
    required this.depth,
    required this.color,
    required this.riseDelay,
    this.kind = _BuildingKind.normal,
  });
}

class _IsoCityPainter extends CustomPainter {
  final double progress; // 0~1, 도시 구축 진행
  _IsoCityPainter({required this.progress});

  // 30° isometric — cos = √3/2 ≈ 0.866, sin = 0.5.
  static const double _cos30 = 0.866;
  static const double _sin30 = 0.5;

  // 5개 빌딩, 모두 같은 깊이 라인 (wx+wz=0) — 화면상 일렬로 배치 → occlusion 없음.
  // 중앙 N서울타워가 hero, 양옆으로 대칭. 중앙→바깥 순서로 1개씩 솟음.
  static const Color _bldg = Color(0xFF3F4D7A);
  static const List<_Building> _buildings = [
    // 중앙 (hero, 첫 번째로 솟음).
    _Building(
      wx: 0, wz: 0, targetHeight: 7.5, width: 0.35, depth: 0.35,
      color: Color(0xFFFFD27A),
      kind: _BuildingKind.nSeoulTower,
      riseDelay: 0.00,
    ),
    // 좌1 — 광화문 / 우1 — 동대문. 중심에서 2.3 unit 떨어짐.
    _Building(wx: -2.3, wz: 2.3, targetHeight: 4.5, width: 1.1, depth: 1.0,
        color: _bldg, riseDelay: 0.18),
    _Building(wx:  2.3, wz: -2.3, targetHeight: 4.5, width: 1.0, depth: 1.1,
        color: _bldg, riseDelay: 0.18),
    // 좌2 — 63빌딩 (골드 슬랩) / 우2 — 롯데타워 (tapered). 중심 4.6 unit.
    _Building(
      wx: -4.6, wz: 4.6, targetHeight: 7.0, width: 0.55, depth: 0.9,
      color: Color(0xFFE8C775),
      kind: _BuildingKind.building63,
      riseDelay: 0.36,
    ),
    _Building(
      wx: 4.6, wz: -4.6, targetHeight: 11, width: 0.9, depth: 0.9,
      color: Color(0xFFA8DCF7),
      kind: _BuildingKind.lotteTower,
      riseDelay: 0.36,
    ),
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

    // 5개 빌딩 모두 wx+wz=0 (같은 깊이) 라 occlusion 무관, 그래도 wx 기준 정렬
    // (back-to-front = 작은 wx 가 화면 좌측 = 좌→우 paint).
    final sorted = [..._buildings]..sort((a, b) => a.wx.compareTo(b.wx));

    for (final b in sorted) {
      // 명시 riseDelay 후 0.40 progress 동안 솟아오름.
      final localT = ((progress - b.riseDelay) / 0.40).clamp(0.0, 1.0);
      if (localT <= 0) continue; // 아직 안 솟은 빌딩은 footprint 도 안 그림.
      final easedT = 1 - math.pow(1 - localT, 3).toDouble();
      final h = b.targetHeight * easedT;
      if (h < 0.08) {
        _drawFootprint(canvas, project, b, 1.0);
      } else {
        _drawGroundShadow(canvas, project, b, h);
        _drawCuboid(canvas, project, b, h);
      }
    }
  }

  /// 빌딩 바닥 그림자 (ambient occlusion) — footprint 보다 살짝 크고 어두운 폴리곤.
  /// 빌딩을 지면에 anchor 시킴.
  void _drawGroundShadow(
    Canvas canvas,
    Offset Function(double, double, double) project,
    _Building b,
    double height,
  ) {
    final expand = 0.18; // footprint 보다 0.18 unit 넓게 펴진 그림자.
    final hw = b.width / 2 + expand;
    final hd = b.depth / 2 + expand;
    final p00 = project(b.wx - hw, 0, b.wz - hd);
    final p10 = project(b.wx + hw, 0, b.wz - hd);
    final p11 = project(b.wx + hw, 0, b.wz + hd);
    final p01 = project(b.wx - hw, 0, b.wz + hd);
    final path = Path()
      ..moveTo(p00.dx, p00.dy)
      ..lineTo(p10.dx, p10.dy)
      ..lineTo(p11.dx, p11.dy)
      ..lineTo(p01.dx, p01.dy)
      ..close();
    final alpha = (height / 6.0).clamp(0.15, 0.55);
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: alpha),
    );
  }

  /// 평면 footprint — 빌딩 색의 평평한 폴리곤. alpha 로 fade-in 제어.
  void _drawFootprint(
    Canvas canvas,
    Offset Function(double, double, double) project,
    _Building b,
    double alpha,
  ) {
    if (alpha <= 0) return;
    final hw = b.width / 2;
    final hd = b.depth / 2;
    final p00 = project(b.wx - hw, 0, b.wz - hd);
    final p10 = project(b.wx + hw, 0, b.wz - hd);
    final p11 = project(b.wx + hw, 0, b.wz + hd);
    final p01 = project(b.wx - hw, 0, b.wz + hd);
    final path = Path()
      ..moveTo(p00.dx, p00.dy)
      ..lineTo(p10.dx, p10.dy)
      ..lineTo(p11.dx, p11.dy)
      ..lineTo(p01.dx, p01.dy)
      ..close();
    final fillColor = _shade(b.color, 0.75);
    canvas.drawPath(
      path,
      Paint()..color = fillColor.withValues(alpha: fillColor.a * alpha),
    );
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

  // ── cuboid 한 채 그리기 — landmark 별 분기 ──
  void _drawCuboid(
    Canvas canvas,
    Offset Function(double, double, double) project,
    _Building b,
    double height,
  ) {
    switch (b.kind) {
      case _BuildingKind.nSeoulTower:
        _drawNSeoulTower(canvas, project, b, height);
        return;
      case _BuildingKind.lotteTower:
        _drawLotteTower(canvas, project, b, height);
        return;
      case _BuildingKind.building63:
      case _BuildingKind.normal:
        _drawNormalCuboid(canvas, project, b, height);
        return;
    }
  }

  /// 일반 cuboid — 3면 + 강한 face contrast + window grid + 랜덤 lit window +
  /// 모든 visible edge highlight + 모서리 vertical rim light.
  void _drawNormalCuboid(
    Canvas canvas,
    Offset Function(double, double, double) project,
    _Building b,
    double height,
  ) {
    final hw = b.width / 2;
    final hd = b.depth / 2;

    final p100 = project(b.wx + hw, 0, b.wz - hd);
    final p001 = project(b.wx - hw, 0, b.wz + hd);
    final p101 = project(b.wx + hw, 0, b.wz + hd);
    final p010 = project(b.wx - hw, height, b.wz - hd);
    final p110 = project(b.wx + hw, height, b.wz - hd);
    final p011 = project(b.wx - hw, height, b.wz + hd);
    final p111 = project(b.wx + hw, height, b.wz + hd);

    // 강한 face contrast — 윗면 매우 밝게, 정면 매우 어둡게.
    final topColor = _shade(b.color, 1.20);
    final rightColor = _shade(b.color, 0.82);
    final frontColor = _shade(b.color, 0.42);

    // 정면 — 위 → 아래 vertical gradient.
    final frontPath = Path()
      ..moveTo(p001.dx, p001.dy)
      ..lineTo(p101.dx, p101.dy)
      ..lineTo(p111.dx, p111.dy)
      ..lineTo(p011.dx, p011.dy)
      ..close();
    canvas.drawPath(
      frontPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset((p011.dx + p111.dx) / 2, (p011.dy + p111.dy) / 2),
          Offset((p001.dx + p101.dx) / 2, (p001.dy + p101.dy) / 2),
          [frontColor, _shade(frontColor, 0.65)],
        ),
    );

    // 우측 — 같은 패턴.
    final rightPath = Path()
      ..moveTo(p100.dx, p100.dy)
      ..lineTo(p101.dx, p101.dy)
      ..lineTo(p111.dx, p111.dy)
      ..lineTo(p110.dx, p110.dy)
      ..close();
    canvas.drawPath(
      rightPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset((p110.dx + p111.dx) / 2, (p110.dy + p111.dy) / 2),
          Offset((p100.dx + p101.dx) / 2, (p100.dy + p101.dy) / 2),
          [rightColor, _shade(rightColor, 0.65)],
        ),
    );

    // 윗면.
    final topPath = Path()
      ..moveTo(p010.dx, p010.dy)
      ..lineTo(p110.dx, p110.dy)
      ..lineTo(p111.dx, p111.dy)
      ..lineTo(p011.dx, p011.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = topColor);

    // Window grid + lit windows — face 1.5 unit 이상에서만.
    if (height > 1.5) {
      // 정면 (남쪽 face): bl=p001, br=p101, tr=p111, tl=p011
      _drawWindowGrid(canvas, p001, p101, p111, p011, height, b.width,
          frontColor, _seedFor(b, 0));
      // 우측 (동쪽 face): bl=p100, br=p101, tr=p111, tl=p110
      _drawWindowGrid(canvas, p100, p101, p111, p110, height, b.depth,
          rightColor, _seedFor(b, 1));
    }

    // Top edge highlight — 윗면 가장자리 + 수직 모서리 rim light (3 visible).
    final topEdge = Paint()
      ..color = _shade(b.color, 1.45).withValues(alpha: 0.95)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(p010, p110, topEdge);
    canvas.drawLine(p110, p111, topEdge);
    canvas.drawLine(p111, p011, topEdge);

    // 수직 rim — front-right 모서리만 highlight (가장 light-facing).
    final rim = Paint()
      ..color = _shade(b.color, 1.25).withValues(alpha: 0.7)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p101, p111, rim);
  }

  /// 빌딩 위치 기반 deterministic seed — lit window 패턴 고정 (매 프레임 동일).
  int _seedFor(_Building b, int faceIdx) =>
      (b.wx * 137 + b.wz * 53 + faceIdx * 19).toInt() + 1000;

  /// Window grid — face 위에 수직 + 수평 라인 그리고, 일부 셀에 lit dot.
  /// faceWidth 는 월드 단위 가로 길이 (정면 = b.width, 우측 = b.depth).
  void _drawWindowGrid(
    Canvas canvas,
    Offset a, Offset b, Offset c, Offset d,
    double height,
    double faceWidth,
    Color faceColor,
    int seed,
  ) {
    // 0.45 unit 당 1 floor, 0.4 unit 당 1 column.
    final floorCount = (height / 0.45).clamp(2, 14).toInt();
    final colCount = (faceWidth / 0.32).clamp(2, 6).toInt();

    final linePaint = Paint()
      ..color = _shade(faceColor, 0.55).withValues(alpha: 0.65)
      ..strokeWidth = 0.45
      ..strokeCap = StrokeCap.round;

    // 수평 floor 라인.
    for (int j = 1; j <= floorCount; j++) {
      final t = j / (floorCount + 1);
      final pLeft = Offset.lerp(a, d, t)!;
      final pRight = Offset.lerp(b, c, t)!;
      canvas.drawLine(pLeft, pRight, linePaint);
    }
    // 수직 column 라인.
    for (int i = 1; i <= colCount; i++) {
      final t = i / (colCount + 1);
      final pBot = Offset.lerp(a, b, t)!;
      final pTop = Offset.lerp(d, c, t)!;
      canvas.drawLine(pBot, pTop, linePaint);
    }

    // Lit windows — 일부 셀에 작은 warm 빛. deterministic seed 로 stable.
    final rng = math.Random(seed);
    final litPaint = Paint()..color = const Color(0xFFFFD080);
    final litGlow = Paint()
      ..color = const Color(0xFFFFD080).withValues(alpha: 0.25);
    for (int j = 0; j < floorCount; j++) {
      for (int i = 0; i < colCount; i++) {
        if (rng.nextDouble() < 0.18) {
          // 셀 중심 위치 — 양방향 bilinear interp.
          final u = (i + 0.5) / colCount;
          final v = (j + 0.5) / floorCount;
          // 위쪽(v=1) ↔ 아래쪽(v=0) lerp on horizontal.
          final bottomEdgePt = Offset.lerp(a, b, u)!;
          final topEdgePt = Offset.lerp(d, c, u)!;
          final cell = Offset.lerp(bottomEdgePt, topEdgePt, v)!;
          // 글로우 + 코어.
          canvas.drawCircle(cell, 1.6, litGlow);
          canvas.drawCircle(cell, 0.9, litPaint);
        }
      }
    }
  }

  /// N서울타워: 가는 기둥 (0~75%) + 관측대 dome (75~87%) + 안테나 (87~100%).
  /// height 가 자라면서 부위가 순차적으로 나타남. targetHeight 절대 초과 안 함.
  void _drawNSeoulTower(
    Canvas canvas,
    Offset Function(double, double, double) project,
    _Building b,
    double height,
  ) {
    final th = b.targetHeight;
    // 1) 기둥 — y 0 ~ 0.75*th. 처음에는 height 만큼만 자람.
    final pillarTop = math.min(height, th * 0.75);
    if (pillarTop > 0.02) {
      _drawCuboidAt(canvas, project, b, 0, pillarTop);
    }

    // 2) Dome — y 0.75*th ~ 0.87*th. 기둥 다 자란 뒤 등장.
    if (height > th * 0.75) {
      final domeBase = th * 0.75;
      final domeTop = math.min(height, th * 0.87);
      final domeH = domeTop - domeBase;
      final domeBldg = _Building(
        wx: b.wx, wz: b.wz,
        targetHeight: domeH,
        width: b.width * 2.6, depth: b.depth * 2.6,
        color: _shade(b.color, 0.95),
        riseDelay: 0,
      );
      _drawCuboidAt(canvas, project, domeBldg, domeBase, domeH);
    }

    // 3) 안테나 — y 0.87*th ~ th. dome 다 자란 뒤 등장.
    if (height > th * 0.87) {
      final antBase = th * 0.87;
      final antTop = math.min(height, th);
      final base = project(b.wx, antBase, b.wz);
      final top = project(b.wx, antTop, b.wz);
      canvas.drawLine(
        base, top,
        Paint()
          ..color = b.color
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
      // 끝 광점 — 안테나 다 자란 후에만.
      if (antTop >= th * 0.99) {
        canvas.drawCircle(top, 2.5, Paint()..color = b.color);
        canvas.drawCircle(
          top, 1.2,
          Paint()..color = Colors.white.withValues(alpha: 0.95),
        );
      }
    }
  }

  /// 롯데타워: 위로 갈수록 좁아지는 tapered 4-stage tower.
  void _drawLotteTower(
    Canvas canvas,
    Offset Function(double, double, double) project,
    _Building b,
    double height,
  ) {
    // 4단으로 쪼개서 각 단마다 width 가 작아짐.
    const stages = 4;
    for (int i = 0; i < stages; i++) {
      final stageBaseT = i / stages;
      final stageTopT = (i + 1) / stages;
      if (height * stageBaseT > height) break;
      final stageBaseY = b.targetHeight * stageBaseT;
      if (height < stageBaseY) break;
      final stageH = math.min(
        height - stageBaseY,
        b.targetHeight * (stageTopT - stageBaseT),
      );
      // width: 1.0 → 0.55 점진적 감소.
      final widthFactor = 1.0 - stageBaseT * 0.45;
      final stageBldg = _Building(
        wx: b.wx, wz: b.wz,
        targetHeight: stageH,
        width: b.width * widthFactor,
        depth: b.depth * widthFactor,
        color: b.color,
        riseDelay: 0,
      );
      _drawCuboidAt(canvas, project, stageBldg, stageBaseY, stageH);
    }
    // 꼭대기 점 highlight.
    if (height >= b.targetHeight * 0.95) {
      final top = project(b.wx, height, b.wz);
      canvas.drawCircle(
        top, 2.5,
        Paint()..color = b.color,
      );
    }
  }

  /// cuboid 를 임의의 y offset 부터 그림 — _drawNormalCuboid 와 동일한 품질
  /// (gradient + window grid + edge highlight + rim light) but base y 가 자유.
  void _drawCuboidAt(
    Canvas canvas,
    Offset Function(double, double, double) project,
    _Building b,
    double baseY,
    double height,
  ) {
    if (height < 0.02) return;
    final hw = b.width / 2;
    final hd = b.depth / 2;
    final topY = baseY + height;

    final p100 = project(b.wx + hw, baseY, b.wz - hd);
    final p001 = project(b.wx - hw, baseY, b.wz + hd);
    final p101 = project(b.wx + hw, baseY, b.wz + hd);
    final p010 = project(b.wx - hw, topY, b.wz - hd);
    final p110 = project(b.wx + hw, topY, b.wz - hd);
    final p011 = project(b.wx - hw, topY, b.wz + hd);
    final p111 = project(b.wx + hw, topY, b.wz + hd);

    final topColor = _shade(b.color, 1.20);
    final rightColor = _shade(b.color, 0.82);
    final frontColor = _shade(b.color, 0.42);

    final frontPath = Path()
      ..moveTo(p001.dx, p001.dy)
      ..lineTo(p101.dx, p101.dy)
      ..lineTo(p111.dx, p111.dy)
      ..lineTo(p011.dx, p011.dy)
      ..close();
    canvas.drawPath(
      frontPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset((p011.dx + p111.dx) / 2, (p011.dy + p111.dy) / 2),
          Offset((p001.dx + p101.dx) / 2, (p001.dy + p101.dy) / 2),
          [frontColor, _shade(frontColor, 0.65)],
        ),
    );

    final rightPath = Path()
      ..moveTo(p100.dx, p100.dy)
      ..lineTo(p101.dx, p101.dy)
      ..lineTo(p111.dx, p111.dy)
      ..lineTo(p110.dx, p110.dy)
      ..close();
    canvas.drawPath(
      rightPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset((p110.dx + p111.dx) / 2, (p110.dy + p111.dy) / 2),
          Offset((p100.dx + p101.dx) / 2, (p100.dy + p101.dy) / 2),
          [rightColor, _shade(rightColor, 0.65)],
        ),
    );

    final topPath = Path()
      ..moveTo(p010.dx, p010.dy)
      ..lineTo(p110.dx, p110.dy)
      ..lineTo(p111.dx, p111.dy)
      ..lineTo(p011.dx, p011.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = topColor);

    // Window grid — face width 0.5+ 이고 height 1.0+ 일 때만.
    if (height > 1.0 && b.width > 0.5 && b.depth > 0.5) {
      _drawWindowGrid(canvas, p001, p101, p111, p011, height, b.width,
          frontColor, _seedFor(b, baseY.round() * 7));
      _drawWindowGrid(canvas, p100, p101, p111, p110, height, b.depth,
          rightColor, _seedFor(b, baseY.round() * 7 + 1));
    }

    // Top edge + 수직 rim.
    final topEdge = Paint()
      ..color = _shade(b.color, 1.45).withValues(alpha: 0.95)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(p010, p110, topEdge);
    canvas.drawLine(p110, p111, topEdge);
    canvas.drawLine(p111, p011, topEdge);

    final rim = Paint()
      ..color = _shade(b.color, 1.25).withValues(alpha: 0.7)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p101, p111, rim);
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
