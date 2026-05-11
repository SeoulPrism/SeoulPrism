import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_typography.dart';
import '../widgets/ai_voice_wave_mock.dart';

/// 페이지 6 — AI Companion (음성 AI).
/// 풀스크린 보라/시안 그라데이션 위에 마이크 글로우 + 파형 + mock 채팅 풍선.
/// 배경맵을 가리도록 페이지 root 가 opaque 그라데이션을 그림.
class AiCompanionPage extends StatelessWidget {
  static const id = 'ai_companion_v1';
  const AiCompanionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);

    return Stack(
      children: [
        // 풀스크린 보라/시안 그라데이션 — 배경맵을 가림.
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1240), Color(0xFF3A1A5C), Color(0xFF6B1F62)],
              ),
            ),
          ),
        ),
        // Blob pulse (좌상/우하).
        const _BackgroundBlob(
          color: Color(0xFF8B5CF6),
          alignment: Alignment(-0.7, -0.5),
        ),
        const _BackgroundBlob(
          color: Color(0xFFEC4899),
          alignment: Alignment(0.8, 0.6),
        ),
        // 컨텐츠.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 120),
            child: Column(
              children: [
                // 데모: 채팅 + 마이크 + 파형 — 상단 영역 fill.
                const Expanded(child: AiVoiceWaveMock()),
                const SizedBox(height: 16),
                // 텍스트.
                Text(
                  l.aiVoiceTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.displayLg.copyWith(
                    color: Colors.white,
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
                      delay: 160.ms,
                    )
                    .fadeIn(duration: 400.ms, delay: 160.ms),
                const SizedBox(height: 10),
                Text(
                  l.aiVoiceBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
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
                      delay: 320.ms,
                    )
                    .fadeIn(duration: 400.ms, delay: 320.ms),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📅 ', style: TextStyle(fontSize: 16)),
                    Flexible(
                      child: Text(
                        l.aiDayPlanHint,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .slideX(
                      begin: 0.2,
                      end: 0,
                      duration: 420.ms,
                      curve: Curves.easeOutCubic,
                      delay: 480.ms,
                    )
                    .fadeIn(duration: 320.ms, delay: 480.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackgroundBlob extends StatelessWidget {
  final Color color;
  final Alignment alignment;
  const _BackgroundBlob({required this.color, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 320,
        height: 320,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.45),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1.15, 1.15),
            duration: 4500.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
