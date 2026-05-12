import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/platform_scroll.dart';

/// 길찾기 결과 시트의 외곽 컨테이너.
/// - 핸들/헤더 어디든 vertical drag → sheet 확장/축소.
/// - 타임라인은 항상 자체 스크롤 가능 (max 까지 끌어올리지 않아도).
/// - dragEnd velocity 기반 모멘텀 + snap (min/mid/max) → 부드러운 느낌.
class RouteSheetShell extends StatefulWidget {
  final bool isDark;
  final List<Widget> timelineItems;
  final List<Widget> headerChildren;
  final double sheetFraction; // 0.0 ~ 0.95
  final void Function(double newFraction) onFractionChange;

  const RouteSheetShell({
    super.key,
    required this.isDark,
    required this.timelineItems,
    required this.headerChildren,
    required this.sheetFraction,
    required this.onFractionChange,
  });

  @override
  State<RouteSheetShell> createState() => _RouteSheetShellState();
}

class _RouteSheetShellState extends State<RouteSheetShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _snapCtrl;
  Animation<double>? _snapAnim;

  static const _maxFraction = 0.95;
  static const _midFraction = 0.55;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _snapCtrl.stop();
    final from = widget.sheetFraction;
    _snapAnim =
        Tween(begin: from, end: target).animate(CurvedAnimation(
      parent: _snapCtrl,
      curve: Curves.easeOutCubic,
    ));
    void tick() {
      widget.onFractionChange(_snapAnim!.value);
    }
    _snapAnim!.addListener(tick);
    _snapCtrl.forward(from: 0).whenCompleteOrCancel(() {
      _snapAnim?.removeListener(tick);
    });
  }

  void _onDragUpdate(DragUpdateDetails d, double screenHeight, double minF) {
    // 직접 추적 — 손가락 따라감.
    _snapCtrl.stop();
    final next = (widget.sheetFraction - d.delta.dy / screenHeight)
        .clamp(minF, _maxFraction);
    widget.onFractionChange(next);
  }

  void _onDragEnd(DragEndDetails d, double screenHeight, double minF) {
    // velocity (px/s) → fraction/s 로 환산해 짧은 flick 도 살짝 더 미끄러짐.
    final velocityFrac = -d.primaryVelocity! / screenHeight;
    // 100ms 동안 미끄러진 위치를 추정해 그 위치 기준으로 가까운 snap 선택.
    final projected =
        (widget.sheetFraction + velocityFrac * 0.1).clamp(minF, _maxFraction);

    final candidates = [minF, _midFraction.clamp(minF, _maxFraction), _maxFraction];
    candidates.sort();
    double best = candidates.first;
    double bestDist = (projected - best).abs();
    for (final c in candidates.skip(1)) {
      final dst = (projected - c).abs();
      if (dst < bestDist) {
        bestDist = dst;
        best = c;
      }
    }
    _animateTo(best);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final minSheetHeight = min(
      screenHeight * 0.95,
      max(220.0, bottomPadding + 190.0),
    );
    final minSheetFraction = minSheetHeight / screenHeight;
    final sheetHeight =
        screenHeight * widget.sheetFraction.clamp(minSheetFraction, _maxFraction);
    final handle = widget.headerChildren.isNotEmpty
        ? widget.headerChildren.first
        : const SizedBox(height: 16);
    final headerBody = widget.headerChildren.length > 1
        ? widget.headerChildren.sublist(1)
        : const <Widget>[];
    final isDark = widget.isDark;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: sheetHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.50),
                        Colors.black.withValues(alpha: 0.70),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.80),
                        Colors.white.withValues(alpha: 0.95),
                      ],
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white24
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            // LayoutBuilder 로 실제 가용 높이 측정 → 헤더 maxHeight 결정.
            // 헤더가 unflexed 라 시트 높이를 넘으면 Expanded(timeline) 가 음수
            // 공간으로 가서 overflow 40px 같은 RenderFlex 경고 발생.
            // → ConstrainedBox 로 헤더 캡 + 그 안에서 NeverScroll 로 클립.
            child: LayoutBuilder(builder: (ctx, constraints) {
              final available = constraints.maxHeight;
              // 헤더 최대 = (시트 높이의 70%) 이지만 최소 timeline 80 은 보장.
              final headerMax = (available * 0.7)
                  .clamp(80.0, max(80.0, available - 80.0))
                  .toDouble();
              return Column(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: headerMax),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (d) =>
                          _onDragUpdate(d, screenHeight, minSheetFraction),
                      onVerticalDragEnd: (d) =>
                          _onDragEnd(d, screenHeight, minSheetFraction),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: double.infinity, child: handle),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: headerBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Divider(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.06),
                    height: 1,
                  ),
                  // 타임라인 (자세한 경로) — 항상 자체 스크롤 가능.
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        10,
                        20,
                        MediaQuery.of(context).padding.bottom + 20,
                      ),
                      physics: platformScrollPhysics(),
                      children: widget.timelineItems,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
