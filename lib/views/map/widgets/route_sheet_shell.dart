import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/platform_scroll.dart';

/// 길찾기 결과 시트의 외곽 컨테이너.
/// - 핸들 드래그로 높이 변경 (callback 으로 fraction 전달).
/// - 헤더 (constrained scroll) + 타임라인 (Expanded scroll) 두 영역.
class RouteSheetShell extends StatelessWidget {
  final bool isDark;
  final List<Widget> timelineItems;
  final List<Widget> headerChildren;
  final double sheetFraction; // 0.0 ~ 0.85
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
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final minSheetHeight = min(
      screenHeight * 0.85,
      max(220.0, bottomPadding + 190.0),
    );
    final minSheetFraction = minSheetHeight / screenHeight;
    final sheetHeight =
        screenHeight * sheetFraction.clamp(minSheetFraction, 0.85);
    final headerMaxHeight = max(
      96.0,
      min(sheetHeight - 72.0, screenHeight * 0.50),
    );
    final handle = headerChildren.isNotEmpty
        ? headerChildren.first
        : const SizedBox(height: 16);
    final headerBody = headerChildren.length > 1
        ? headerChildren.sublist(1)
        : const <Widget>[];

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
            child: Column(
              children: [
                GestureDetector(
                  onVerticalDragUpdate: (d) {
                    final next = (sheetFraction - d.delta.dy / screenHeight)
                        .clamp(minSheetFraction, 0.85);
                    onFractionChange(next);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(width: double.infinity, child: handle),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: headerMaxHeight),
                  child: SingleChildScrollView(
                    physics: platformScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: headerBody,
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
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      20,
                      MediaQuery.of(context).padding.bottom + 20,
                    ),
                    physics: platformScrollPhysics(),
                    children: timelineItems,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
