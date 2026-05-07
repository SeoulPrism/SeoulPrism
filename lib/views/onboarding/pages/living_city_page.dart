import 'dart:io';
import 'package:flutter/material.dart';
import '../../../theme/app_typography.dart';
import '../widgets/onboarding_map_background.dart';

enum _Vehicle { subway, bus, riverBus, flight }

class LivingCityPage extends StatefulWidget {
  static const id = 'living_city_v1';
  const LivingCityPage({super.key});

  @override
  State<LivingCityPage> createState() => _LivingCityPageState();
}

class _LivingCityPageState extends State<LivingCityPage> {
  _Vehicle? _active;

  static const _items = [
    (_Vehicle.subway, Icons.directions_subway, Color(0xFF00B0FF), '지하철'),
    (_Vehicle.bus, Icons.directions_bus, Color(0xFF00E676), '버스'),
    (_Vehicle.riverBus, Icons.directions_boat, Color(0xFF00ACC1), '한강버스'),
    (_Vehicle.flight, Icons.flight, Color(0xFFFFC400), '항공기'),
  ];

  void _select(_Vehicle v) {
    setState(() => _active = v);
    final ctrl = OnboardingMapController.instance;
    switch (v) {
      case _Vehicle.subway:
        ctrl.flyToSubway();
      case _Vehicle.bus:
        ctrl.flyToBus();
      case _Vehicle.riverBus:
        ctrl.flyToRiverBus();
      case _Vehicle.flight:
        ctrl.flyToFlight();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;
    final titleColor = isIos ? Colors.white : cs.onSurface;
    final bodyColor =
        isIos ? Colors.white.withValues(alpha: 0.78) : cs.onSurfaceVariant;

    final padding = MediaQuery.of(context).padding;

    // 카드 없이 — 제목/부제목은 상단, 아이콘 row 는 하단. 가운데는 지도가 그대로 보임.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        padding.top + 64,
        24,
        padding.bottom + 180,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '서울이 살아 움직여요',
            style: AppTypography.displayLg.copyWith(
              color: titleColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '아이콘을 누르면 카메라가 그 장면으로 날아가요.',
            style: AppTypography.bodySm.copyWith(
              color: bodyColor,
              height: 1.4,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _items.map((it) {
              final (vehicle, icon, color, label) = it;
              return _IconButton(
                icon: icon,
                color: color,
                label: label,
                selected: _active == vehicle,
                onTap: () => _select(vehicle),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _IconButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = Platform.isIOS;
    final labelColor = isIos
        ? Colors.white.withValues(alpha: selected ? 1.0 : 0.7)
        : (selected
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onSurfaceVariant);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: selected ? 0.32 : 0.18),
              border: Border.all(
                color: color.withValues(alpha: selected ? 0.95 : 0.45),
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: labelColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
