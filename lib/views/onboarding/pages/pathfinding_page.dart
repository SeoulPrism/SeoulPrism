import 'dart:io';
import 'package:flutter/material.dart';
import '../../../theme/app_typography.dart';
import '../widgets/page_card.dart';

class PathfindingPage extends StatelessWidget {
  static const id = 'pathfinding_v1';
  const PathfindingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;
    final titleColor = isIos ? Colors.white : cs.onSurface;
    final bodyColor = isIos ? Colors.white.withValues(alpha: 0.78) : cs.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: PageCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '어디든, 지금 바로',
                style: AppTypography.displayLg.copyWith(
                  color: titleColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '지하철·버스·도보를 합친 통합 길찾기.\n사진을 보여주거나 음성으로 물어봐도 OK.',
                style: AppTypography.bodyMd.copyWith(
                  color: bodyColor,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              _Bullet(icon: Icons.alt_route, text: '최소시간 / 최단거리 / 최소환승 비교'),
              const SizedBox(height: 12),
              _Bullet(icon: Icons.mic, text: 'Gemini AI 음성 비서'),
              const SizedBox(height: 12),
              _Bullet(icon: Icons.camera_alt, text: '사진 한 장으로 장소 분석'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;
    final iconBg = isIos
        ? Colors.white.withValues(alpha: 0.12)
        : cs.secondaryContainer;
    final iconFg = isIos ? Colors.white : cs.onSecondaryContainer;
    final textColor = isIos ? Colors.white.withValues(alpha: 0.85) : cs.onSurface;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconFg),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySm.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }
}
