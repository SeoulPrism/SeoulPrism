import 'package:flutter/material.dart';
import 'widgets/aurora_overlay.dart';
import 'widgets/subway_drawing_overlay.dart';

/// 앱 실행 시 (튜토리얼 통과 사용자) 보여주는 로딩 화면.
/// 튜토리얼 종료 시퀀스와 동일한 비주얼 (오로라 + 지하철 그려짐 + 로고) — 일관된 브랜드 경험.
/// 동안 HomeView 가 뒤에서 mount 되어 로딩하므로, 시퀀스 끝나면 즉시 HomeView 노출.
class LaunchLoadingView extends StatefulWidget {
  final VoidCallback onComplete;
  const LaunchLoadingView({super.key, required this.onComplete});

  @override
  State<LaunchLoadingView> createState() => _LaunchLoadingViewState();
}

class _LaunchLoadingViewState extends State<LaunchLoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _drawCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _scaffoldFadeCtrl;

  @override
  void initState() {
    super.initState();
    _drawCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _scaffoldFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );
    _runSequence();
  }

  Future<void> _runSequence() async {
    // 모든 애니메이션 동시 시작.
    _drawCtrl.forward();
    _logoCtrl.forward();
    // 시퀀스 거의 끝나갈 때 스캐폴드 페이드.
    await Future.delayed(const Duration(milliseconds: 2700));
    if (!mounted) return;
    _scaffoldFadeCtrl.reverse();
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _drawCtrl.dispose();
    _logoCtrl.dispose();
    _scaffoldFadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaffoldFadeCtrl,
      builder: (_, child) => Opacity(
        opacity: _scaffoldFadeCtrl.value,
        child: Material(
          // 어두운 backdrop — 튜토리얼 finish 와 동일 톤.
          color: Color.fromRGBO(14, 16, 24, _scaffoldFadeCtrl.value),
          child: child,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AuroraOverlay(),
          // 약간 어둡게 — 라인/로고 가독성.
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
          SubwayDrawingOverlay(progress: _drawCtrl),
          Center(child: _LaunchLogo(controller: _logoCtrl)),
        ],
      ),
    );
  }
}

class _LaunchLogo extends StatelessWidget {
  final AnimationController controller;
  const _LaunchLogo({required this.controller});

  @override
  Widget build(BuildContext context) {
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
