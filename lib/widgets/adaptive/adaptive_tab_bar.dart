import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';

/// 탭바 아이템 정의
class AdaptiveTabItem {
  final String label;
  final IconData icon;

  const AdaptiveTabItem({required this.label, required this.icon});
}

/// iOS: CNTabBar (리퀴드 글라스)
/// Android: M3 커스텀 플로팅 캡슐 네비게이션
class AdaptiveTabBar extends StatelessWidget {
  final List<AdaptiveTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AdaptiveTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CNTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items
            .map((item) => CNTabBarItem(
                  label: item.label,
                  customIcon: item.icon,
                ))
            .toList(),
      );
    }

    return _M3CapsuleNavBar(
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}

/// Material 3 — 플로팅 캡슐 네비게이션 바
/// 선택된 탭 뒤로 슬라이딩 인디케이터 애니메이션
class _M3CapsuleNavBar extends StatefulWidget {
  final List<AdaptiveTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _M3CapsuleNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_M3CapsuleNavBar> createState() => _M3CapsuleNavBarState();
}

class _M3CapsuleNavBarState extends State<_M3CapsuleNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant _M3CapsuleNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _prevIndex = old.currentIndex;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final itemCount = widget.items.length;

    // 좌우 12px 안전 마진 확보 후 사용 가능한 폭 안에서 itemWidth 자동 계산.
    // 큰 화면(태블릿)에서는 88dp 상한, 작은 화면(폴드 내부 등) 에서는 자동 축소.
    // heightFactor: 1.0 — 가로는 부모 폭 채우되 세로는 child 높이로 축소.
    // Scaffold.bottomNavigationBar 슬롯은 loose height 를 줘서, 단순 Center 를
    // 쓰면 화면 절반 높이로 부풀고 그 안에서 다시 중앙 정렬되어 탭바가 정중앙에 떠버림.
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding + 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(builder: (context, constraints) {
            const maxItemWidth = 88.0;
            final available = constraints.maxWidth;
            final itemWidth = (available / itemCount).clamp(56.0, maxItemWidth);
            final barWidth = itemWidth * itemCount;
            return Material(
              elevation: 6,
              shadowColor: cs.shadow.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(28),
              color: cs.surfaceContainer,
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: barWidth,
                height: 56,
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _slideAnim,
                      builder: (context, _) {
                        final from = _prevIndex * itemWidth;
                        final to = widget.currentIndex * itemWidth;
                        final current =
                            from + (to - from) * _slideAnim.value;

                        return Positioned(
                          left: current + 4,
                          top: 4,
                          child: Container(
                            width: itemWidth - 8,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: cs.primaryContainer,
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(itemCount, (i) {
                        final item = widget.items[i];
                        final selected = i == widget.currentIndex;
                        return GestureDetector(
                          onTap: () => widget.onTap(i),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: itemWidth,
                            height: 56,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 20,
                                  color: selected
                                      ? cs.onPrimaryContainer
                                      : cs.onSurfaceVariant,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? cs.onPrimaryContainer
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
