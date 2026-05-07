import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_typography.dart';
import '../../widgets/adaptive/adaptive.dart';
import 'onboarding_page.dart';
import 'pages/living_city_page.dart';
import 'pages/optimization_page.dart';
import 'pages/pathfinding_page.dart';
import 'pages/ready_page.dart';
import 'pages/welcome_page.dart';
import 'widgets/liquid_page_indicator.dart';

/// 컨셉 A — 드리프팅 글라스 풀스크린 페이저.
/// iOS: 어두운 배경 + 리퀴드 글라스 카드 (사용자가 좋아하는 느낌)
/// Android: Material 3 surface 배경 + tonal 카드
class OnboardingView extends StatefulWidget {
  final List<OnboardingPage> pages;
  final Widget background;
  final VoidCallback onComplete;

  const OnboardingView({
    super.key,
    required this.pages,
    required this.background,
    required this.onComplete,
  });

  /// 안 본 페이지가 있으면 OnboardingView 반환, 없으면 null.
  static OnboardingView? buildIfNeeded({
    required Widget background,
    required VoidCallback onComplete,
  }) {
    final all = <OnboardingPage>[
      const OnboardingPage(id: WelcomePage.id, body: WelcomePage()),
      const OnboardingPage(id: LivingCityPage.id, body: LivingCityPage()),
      const OnboardingPage(id: PathfindingPage.id, body: PathfindingPage()),
      const OnboardingPage(id: OptimizationPage.id, body: OptimizationPage()),
      const OnboardingPage(id: ReadyPage.id, body: ReadyPage()),
    ];
    final remainingIds =
        OnboardingService.instance.remainingPages(all.map((p) => p.id).toList());
    if (remainingIds.isEmpty) return null;
    final filtered =
        all.where((p) => remainingIds.contains(p.id)).toList(growable: false);
    return OnboardingView(
      pages: filtered,
      background: background,
      onComplete: onComplete,
    );
  }

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _controller = PageController();
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _progress = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _progress.round() == widget.pages.length - 1;

  Future<void> _finish() async {
    await OnboardingService.instance.markSeen(widget.pages.map((p) => p.id));
    widget.onComplete();
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
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;

    final scaffoldBg = isIos ? const Color(0xFF0E1018) : cs.surface;
    final skipColor = isIos
        ? Colors.white.withValues(alpha: 0.7)
        : cs.onSurfaceVariant;
    final activeIndicator = isIos ? Colors.white : cs.primary;
    final inactiveIndicator =
        isIos ? const Color(0x66FFFFFF) : cs.outlineVariant;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 — iOS 는 지도/그라데이션, Android 는 surface 그대로
          if (isIos) widget.background,
          // iOS 한정 어두운 오버레이 (글라스 카드 가독성).
          if (isIos)
            Container(
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
            ),
          // 페이저
          PageView(
            controller: _controller,
            physics: const PageScrollPhysics(),
            children: widget.pages.map((p) => p.body).toList(),
          ),
          // 상단: 건너뛰기
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: TextButton(
              onPressed: _finish,
              child: Text(
                '건너뛰기',
                style: AppTypography.bodySm.copyWith(color: skipColor),
              ),
            ),
          ),
          // 하단: 인디케이터 + CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 24,
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
                      label: _isLast ? '시작하기' : '다음',
                      onPressed: _next,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
