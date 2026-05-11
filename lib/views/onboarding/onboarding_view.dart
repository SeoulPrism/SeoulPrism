import 'package:flutter/material.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_typography.dart';
import '../../widgets/adaptive/adaptive.dart';
import 'onboarding_page.dart';
import 'pages/living_city_page.dart';
import 'pages/permissions_page.dart';
import 'pages/optimization_page.dart';
import 'pages/pathfinding_page.dart';
import 'pages/ready_page.dart';
import 'pages/welcome_page.dart';
import 'widgets/aurora_overlay.dart';
import 'widgets/liquid_page_indicator.dart';
import 'widgets/onboarding_map_background.dart';
import 'widgets/subway_drawing_overlay.dart';

/// 컨셉 A — 드리프팅 글라스 풀스크린 페이저.
class OnboardingView extends StatefulWidget {
  final List<OnboardingPage> pages;
  final Widget background;

  /// finish 시퀀스 시작 시점 — 부모에서 HomeView 미리 mount 트리거.
  final VoidCallback onFinishStart;

  /// finish 시퀀스 완료 — 이제 OnboardingView 를 dismiss 해도 됨.
  final VoidCallback onFinishComplete;

  const OnboardingView({
    super.key,
    required this.pages,
    required this.background,
    required this.onFinishStart,
    required this.onFinishComplete,
  });

  /// 안 본 페이지가 있으면 OnboardingView 반환, 없으면 null.
  static OnboardingView? buildIfNeeded({
    Key? key,
    required Widget background,
    required VoidCallback onFinishStart,
    required VoidCallback onFinishComplete,
  }) {
    final all = <OnboardingPage>[
      const OnboardingPage(id: WelcomePage.id, body: WelcomePage()),
      const OnboardingPage(id: LivingCityPage.id, body: LivingCityPage()),
      const OnboardingPage(id: PathfindingPage.id, body: PathfindingPage()),
      const OnboardingPage(id: OptimizationPage.id, body: OptimizationPage()),
      // 5개 권한 (위치/알림/카메라/사진/마이크) 한 화면에 일괄 동의.
      const OnboardingPage(
          id: PermissionsPage.id, body: PermissionsPage()),
      const OnboardingPage(id: ReadyPage.id, body: ReadyPage()),
    ];
    final remainingIds =
        OnboardingService.instance.remainingPages(all.map((p) => p.id).toList());
    if (remainingIds.isEmpty) return null;
    final filtered =
        all.where((p) => remainingIds.contains(p.id)).toList(growable: false);
    return OnboardingView(
      key: key,
      pages: filtered,
      background: background,
      onFinishStart: onFinishStart,
      onFinishComplete: onFinishComplete,
    );
  }

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  final _controller = PageController();
  double _progress = 0;

  // ── Finish 시퀀스 상태 ──
  // 페이지 컨텐츠 (카드/CTA/인디케이터) 페이드 — 0~1
  late final AnimationController _contentFadeCtrl;
  // 오로라 + 어두운 오버레이 페이드 — 0~1
  late final AnimationController _backdropFadeCtrl;
  // 정중앙 로고 시퀀스 (등장 → 펄스 → 사라짐) — 0~1
  late final AnimationController _logoCtrl;
  // 지하철 라인 그려지는 오버레이 (지도 swap 시점 시각적 마스킹) — 0~1
  late final AnimationController _drawCtrl;
  // 전체 스캐폴드 페이드 (HomeView 가 뒤에서 보이도록) — 0~1
  late final AnimationController _scaffoldFadeCtrl;
  bool _finishing = false;

  late final VoidCallback _pageListener;

  @override
  void initState() {
    super.initState();
    _pageListener = () {
      setState(() => _progress = _controller.page ?? 0);
    };
    _controller.addListener(_pageListener);
    _contentFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 0.0, // 컨텐츠(텍스트/CTA/인디케이터) 만 페이드인. 맵은 그대로 즉시 표시.
    );
    // 200ms 지연 후 페이드인 시작 — Mapbox GL 컨텍스트 초기화 첫 spike 가
    // 보통 100~200ms 안에 끝나서 그 이후로 미루면 페이드 frame skip 안 생김.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentFadeCtrl.forward();
    });
    _backdropFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      value: 1.0,
    );
    // 로고 + 그리기 모두 3000ms — 50% drawing → 35% hold (HomeView 로딩 시간) → 15% fadeout.
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _drawCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _scaffoldFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0, // 등장 페이드는 _contentFadeCtrl 가 담당 (맵은 즉시).
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_pageListener);
    _controller.dispose();
    _contentFadeCtrl.dispose();
    _backdropFadeCtrl.dispose();
    _logoCtrl.dispose();
    _drawCtrl.dispose();
    _scaffoldFadeCtrl.dispose();
    super.dispose();
  }

  bool get _isLast => _progress.round() == widget.pages.length - 1;

  bool get _isMapVisiblePage =>
      widget.pages[_progress.round().clamp(0, widget.pages.length - 1)].id ==
      'living_city_v1';

  Widget _buildBackdropOverlay() {
    if (_isMapVisiblePage) {
      return IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.25, 0.7, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.35),
            Colors.black.withValues(alpha: 0.55),
          ],
        ),
      ),
    );
  }

  /// 시작하기 / 건너뛰기 → finish 시퀀스 진입.
  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await OnboardingService.instance.markSeen(widget.pages.map((p) => p.id));

    // 1. 부모에 알림 — HomeView 가 뒤에서 마운트 시작.
    widget.onFinishStart();

    // 2. 백그라운드 맵 줌아웃 시작.
    OnboardingMapController.instance.zoomOutToCity();

    // 3. 페이지 컨텐츠 즉시 페이드 아웃 (320ms).
    _contentFadeCtrl.reverse();

    // 4. 약간의 딜레이 후 오로라/오버레이 페이드 (1100ms).
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _backdropFadeCtrl.reverse();

    // 5. 로고 + 지하철 라인 그려지기 동시 시작 (3000ms 총).
    //    timing:
    //      0    ~  150ms : 페이드 인
    //      150  ~ 1500ms : 그리기 (9 노선 stagger)
    //      1500 ~ 2550ms : hold — 전 라인 풀 그려진 채 + 로고 등장 → HomeView 가 뒤에서 로딩 완료
    //      2550 ~ 3000ms : 페이드 아웃
    _logoCtrl.forward();
    _drawCtrl.forward();

    // 6. 그리기 + 로고 fade out 거의 끝나갈 때 스캐폴드 페이드 시작 (HomeView 노출).
    await Future.delayed(const Duration(milliseconds: 2700));
    if (!mounted) return;
    _scaffoldFadeCtrl.reverse();

    // 7. 스캐폴드 fully transparent → dismiss.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    widget.onFinishComplete();
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // iOS 와 동일한 다크 글래스 룩으로 통일 — 배경 지도 위에 얹는 색이라
    // 플랫폼 별 분기 시 가독성/일관성 모두 떨어짐. Android 도 동일 톤 사용.
    const scaffoldBg = Color(0xFF0E1018);
    final skipColor = Colors.white.withValues(alpha: 0.7);
    const activeIndicator = Colors.white;
    const inactiveIndicator = Color(0x66FFFFFF);

    // PopScope: Android 시스템 뒤로가기로 튜토리얼 dismiss 방지.
    // 사용자는 "건너뛰기" 또는 "다음" 으로만 진행 가능 (App/Play Store 정책상 OK,
    // 명시적 escape hatch 가 있으므로).
    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: _scaffoldFadeCtrl,
        builder: (context, child) {
          return Opacity(
            opacity: _scaffoldFadeCtrl.value,
            // Material 로 감싸야 텍스트 default underline (노란 줄) 안 생김.
            child: Material(
              color: Color.fromRGBO(
                ((scaffoldBg.r) * 255).round(),
                ((scaffoldBg.g) * 255).round(),
                ((scaffoldBg.b) * 255).round(),
                _scaffoldFadeCtrl.value,
              ),
              child: child,
            ),
          );
        },
        child: Stack(
        fit: StackFit.expand,
        children: [
          widget.background,
          FadeTransition(
            opacity: _backdropFadeCtrl,
            child: const AuroraOverlay(),
          ),
          FadeTransition(
            opacity: _backdropFadeCtrl,
            child: _buildBackdropOverlay(),
          ),
          // 페이지 컨텐츠 — finish 시 페이드.
          FadeTransition(
            opacity: _contentFadeCtrl,
            child: IgnorePointer(
              ignoring: _finishing,
              child: PageView(
                controller: _controller,
                // swipe 전면 비활성화 — 사용자는 "다음" 버튼으로만 진행.
                // forward-only physics 는 빠른 swipe 에서 살짝 새는 느낌이 있어
                // 아예 모든 swipe 차단이 가장 깔끔. forward swipe 도 같이 비활성됨.
                physics: const NeverScrollableScrollPhysics(),
                children: widget.pages.map((p) => p.body).toList(),
              ),
            ),
          ),
          // 상단 건너뛰기 (finish 중 페이드).
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: FadeTransition(
              opacity: _contentFadeCtrl,
              child: IgnorePointer(
                ignoring: _finishing,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    AppL10n.of(context).whatsNewSkip,
                    style: AppTypography.bodySm.copyWith(color: skipColor),
                  ),
                ),
              ),
            ),
          ),
          // 하단 인디케이터 + CTA (finish 중 페이드).
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: FadeTransition(
              opacity: _contentFadeCtrl,
              child: IgnorePointer(
                ignoring: _finishing,
                child: Column(
                  children: [
                    LiquidPageIndicator(
                      count: widget.pages.length,
                      progress: _progress,
                      activeColor: activeIndicator,
                      inactiveColor: inactiveIndicator,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: AdaptiveGlassButton(
                          label: _isLast
                              ? AppL10n.of(context).whatsNewStart
                              : AppL10n.of(context).whatsNewNext,
                          onPressed: _next,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 지하철 라인 그려지는 오버레이 — 지도 swap 시각적 마스킹.
          if (_finishing) SubwayDrawingOverlay(progress: _drawCtrl),
          // Finish 로고 — 시퀀스 진행 시 정중앙 등장 → 펄스 → 사라짐.
          if (_finishing)
            Center(
              child: _FinaleLogo(controller: _logoCtrl),
            ),
        ],
      ),
      ),
    );
  }
}


/// 종료 시퀀스 정중앙 로고.
/// _logoCtrl 0..1 단계: 등장(0~0.32) → 유지(0.32~0.7) → 페이드(0.7~1.0).
class _FinaleLogo extends StatelessWidget {
  final AnimationController controller;
  const _FinaleLogo({required this.controller});

  @override
  Widget build(BuildContext context) {
    // 0~20% (~600ms): 등장 (scale 0.6 → 1.05)
    // 20~85% (~1950ms): hold (HomeView 로딩 시간 동안 시각적 anchor)
    // 85~100% (~450ms): 페이드 아웃 (살짝 더 커지며 사라짐)
    final scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.05), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.18), weight: 15),
    ]).animate(controller);

    final opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(controller);

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Opacity(
        opacity: opacity.value,
        child: Transform.scale(
          scale: scale.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBC82F3).withValues(alpha: 0.55),
                  blurRadius: 60,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: const Color(0xFF8FE3FF).withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'images/app-icon-ios.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
