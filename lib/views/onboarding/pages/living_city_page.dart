import 'dart:io';
import 'package:flutter/material.dart';
import '../../../theme/app_typography.dart';
import '../widgets/page_card.dart';

class LivingCityPage extends StatelessWidget {
  static const id = 'living_city_v1';
  const LivingCityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iosTitle = Colors.white;
    final iosBody = Colors.white.withValues(alpha: 0.78);
    final mdTitle = cs.onSurface;
    final mdBody = cs.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: PageCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '서울이 살아 움직여요',
                style: AppTypography.displayLg.copyWith(
                  color: Platform.isIOS ? iosTitle : mdTitle,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '지하철·버스·한강버스·항공기를\n실시간으로 한 화면에서 추적하세요.',
                style: AppTypography.bodyMd.copyWith(
                  color: Platform.isIOS ? iosBody : mdBody,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              _IconRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.directions_subway, const Color(0xFF00B0FF), '지하철'),
      (Icons.directions_bus, const Color(0xFF00E676), '버스'),
      (Icons.directions_boat, const Color(0xFF00ACC1), '한강버스'),
      (Icons.flight, const Color(0xFFFFC400), '항공기'),
    ];
    final labelColor = Platform.isIOS
        ? Colors.white.withValues(alpha: 0.7)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((it) {
        final (icon, color, label) = it;
        return Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: labelColor),
            ),
          ],
        );
      }).toList(),
    );
  }
}
