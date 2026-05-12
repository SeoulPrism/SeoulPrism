import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_typography.dart';
import '../widgets/demo_friend_dots.dart';
import '../widgets/onboarding_map_background.dart';

/// 페이지 5 — Seoul Live (멀티플레이어).
/// 친구방 공통 목적지를 메인으로, DM·음악·QR·점수를 보조 라인 4개로 흡수.
/// 진입 시 백그라운드 맵을 명동/홍대 부근으로 이동시키고, 그 위에 친구 dot 데모를 띄움.
class SeoulLivePage extends StatefulWidget {
  static const id = 'seoul_live_v1';
  const SeoulLivePage({super.key});

  @override
  State<SeoulLivePage> createState() => _SeoulLivePageState();
}

class _SeoulLivePageState extends State<SeoulLivePage> {
  @override
  void initState() {
    super.initState();
    // 페이지 진입 — 맵을 Seoul Live 씬으로.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingMapController.instance.flyToLiveMeet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final isIos = Platform.isIOS;
    final titleColor = isIos ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final bodyColor = isIos
        ? Colors.white.withValues(alpha: 0.78)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final hintColor = isIos
        ? Colors.white.withValues(alpha: 0.72)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Stack(
      children: [
        // 친구 dot 데모 — 상단 절반.
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 64, 8, 0),
            child: FractionallySizedBox(
              alignment: Alignment.topCenter,
              heightFactor: 0.52,
              child: const DemoFriendDots(),
            ),
          ),
        ),
        // 텍스트 컨텐츠 — 하단.
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seoul Live 활성화 후 사용 가능 — 보라 배지.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C5CFF).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF7C5CFF).withValues(alpha: 0.55),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          size: 12, color: Color(0xFFB6A8FF)),
                      const SizedBox(width: 5),
                      Text(
                        l.liveActivationHint,
                        style: const TextStyle(
                          color: Color(0xFFE0D6FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .slideX(
                      begin: -0.2,
                      end: 0,
                      duration: 420.ms,
                      curve: Curves.easeOutCubic,
                      delay: 60.ms,
                    )
                    .fadeIn(duration: 320.ms, delay: 60.ms),
                const SizedBox(height: 8),
                Text(
                  l.liveMeetTitle,
                  style: AppTypography.displayLg.copyWith(
                    color: titleColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                )
                    .animate()
                    .slideY(
                      begin: 0.4,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                      delay: 120.ms,
                    )
                    .fadeIn(duration: 400.ms, delay: 120.ms),
                const SizedBox(height: 8),
                Text(
                  l.liveMeetBody,
                  style: AppTypography.bodyMd.copyWith(
                    color: bodyColor,
                    height: 1.45,
                    fontSize: 13,
                  ),
                )
                    .animate()
                    .slideY(
                      begin: 0.5,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                      delay: 260.ms,
                    )
                    .fadeIn(duration: 400.ms, delay: 260.ms),
                const SizedBox(height: 16),
                _HintRow(emoji: '💬', text: l.liveDmHint, color: hintColor, delay: 380),
                _HintRow(emoji: '🎵', text: l.liveMusicHint, color: hintColor, delay: 460),
                _HintRow(emoji: '🔗', text: l.liveAddFriendHint, color: hintColor, delay: 540),
                _HintRow(emoji: '🏆', text: l.livePointsHint, color: hintColor, delay: 620),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HintRow extends StatelessWidget {
  final String emoji;
  final String text;
  final Color color;
  final int delay;
  const _HintRow({
    required this.emoji,
    required this.text,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideX(
          begin: 0.2,
          end: 0,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
          delay: Duration(milliseconds: delay),
        )
        .fadeIn(duration: 320.ms, delay: Duration(milliseconds: delay));
  }
}
