import 'dart:ui';

import 'package:flutter/material.dart';

class RouteSearchOverlay extends StatefulWidget {
  const RouteSearchOverlay({
    super.key,
    required this.query,
    required this.onClose,
  });

  final String query;
  final VoidCallback onClose;

  @override
  State<RouteSearchOverlay> createState() => _RouteSearchOverlayState();
}

class _RouteSearchOverlayState extends State<RouteSearchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _showFullRoute = false;
  int _transportIndex = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _close() {
    _animController.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Stack(
          children: [
            // dim 배경
            GestureDetector(
              onTap: _close,
              child: Container(
                color: Colors.black
                    .withValues(alpha: 0.35 * _fadeAnim.value),
              ),
            ),
            // 드래그 가능한 시트 (슬라이드 + 페이드)
            SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.25,
              maxChildSize: 0.90,
              snap: true,
              snapSizes: const [0.45],
              builder: (context, scrollController) {
                return ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.85),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                          // 핸들
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 4),
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          _buildHeader(),
                          _buildTransportTabs(),
                          _buildTimeSummary(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: _buildTimelineBar(),
                          ),
                          _buildRouteSteps(),
                          const SizedBox(height: 32),
                        ],
                      ),
                      ),
                    ),
                  ),
                );
              },
            ),
            ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.50),
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '내 위치',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Color(0xFFFF453A), size: 12),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.query,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _close,
            icon: Icon(Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.60), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportTabs() {
    final tabs = [
      (Icons.directions_transit_rounded, '대중교통'),
      (Icons.directions_walk_rounded, '도보'),
      (Icons.directions_bike_rounded, '자전거'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _transportIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _transportIndex == i
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                    border: Border.all(
                      color: _transportIndex == i
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.white.withValues(alpha: 0.06),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabs[i].$1,
                        color: _transportIndex == i
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.40),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tabs[i].$2,
                        style: TextStyle(
                          color: _transportIndex == i
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.40),
                          fontSize: 12,
                          fontWeight: _transportIndex == i
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            '30',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '분',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '11:26 → 11:56',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '1,200원',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            Container(
              width: 24,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: 25,
              child: Container(color: const Color(0xFF0052A4)),
            ),
            const SizedBox(width: 2),
            Container(
              width: 32,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSteps() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _RouteStep(
            lineColor: Colors.white.withValues(alpha: 0.20),
            dotColor: Colors.white,
            title: '내 위치',
            subtitle: '도보 177m · 2분',
            icon: Icons.directions_walk_rounded,
          ),
          _RouteStep(
            lineColor: const Color(0xFF0052A4),
            dotColor: const Color(0xFF0052A4),
            title: '1호선 승차',
            subtitle: '용산역 → 23개 정류장 · 25분',
            icon: Icons.train_rounded,
            badge: '1호선',
            badgeColor: const Color(0xFF0052A4),
            expandable: true,
            showExpanded: _showFullRoute,
            onToggle: () => setState(() => _showFullRoute = !_showFullRoute),
          ),
          _RouteStep(
            lineColor: Colors.white.withValues(alpha: 0.20),
            dotColor: Colors.white,
            title: '하차 후 도보',
            subtitle: '237m · 3분',
            icon: Icons.directions_walk_rounded,
          ),
          _RouteStep(
            lineColor: null,
            dotColor: const Color(0xFFFF453A),
            title: widget.query,
            subtitle: '도착',
            icon: Icons.location_on_rounded,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _RouteStep extends StatelessWidget {
  const _RouteStep({
    required this.dotColor,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.lineColor,
    this.badge,
    this.badgeColor,
    this.expandable = false,
    this.showExpanded = false,
    this.onToggle,
    this.isLast = false,
  });

  final Color? lineColor;
  final Color dotColor;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  final bool expandable;
  final bool showExpanded;
  final VoidCallback? onToggle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor ?? Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon,
                          color: Colors.white.withValues(alpha: 0.60),
                          size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: badgeColor,
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                  if (expandable) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onToggle,
                      child: Text(
                        showExpanded ? '접기 ▲' : '정류장 보기 ▼',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (showExpanded) ...[
                      const SizedBox(height: 8),
                      ...List.generate(
                        5,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '  · 정류장 ${i + 1}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.30),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
