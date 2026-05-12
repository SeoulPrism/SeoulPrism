import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_typography.dart';
import '../widgets/onboarding_ai_glow_demo.dart';

/// 페이지 6 — AI Companion (음성 AI).
/// ai_view.dart 의 무드 Glow UI 와 동일한 풀스크린 ring + sweep gradient 데모를
/// 배경맵 위에 직접 얹는다 (별도 opaque 베이스 안 깔아서 지도가 그대로 비치게).
/// 상단엔 mock 채팅 풍선 2개 (Q + A) 로 음성 어시스턴트의 결과 예시를 보여줌.
/// 무드 팔레트는 Pathfinding 페이지에서 사용자가 고른 스타일 (없으면 기본).
class AiCompanionPage extends StatelessWidget {
  static const id = 'ai_companion_v1';
  const AiCompanionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);

    return Stack(
      children: [
        // 무드 Glow ring — 풀스크린. 배경맵이 비치도록 검은 베이스는 안 깐다.
        const Positioned.fill(child: OnboardingAiGlowDemo()),
        // 상단 mock 채팅 시퀀스 — 음성 어시스턴트가 다룰 수 있는 3가지 인터랙션
        // (장소 검색, 일정 생성, 자연어 follow-up). ring 안쪽 상단에 떠 있게.
        Positioned(
          top: 84,
          left: 24,
          right: 24,
          child: Column(
            children: const [
              _ChatBubble(text: '서울역이 어디야?', fromAi: false, delay: 360),
              SizedBox(height: 6),
              _ChatBubble(text: '🗺 여기예요 (지도에 핀)', fromAi: true, delay: 760),
              SizedBox(height: 10),
              _ChatBubble(
                  text: '영등포구 근처 여행 계획 짜줘',
                  fromAi: false,
                  delay: 1240),
              SizedBox(height: 6),
              _ChatBubble(
                  text: '📋 여의도공원 · IFC몰 · 노들섬 · 선유도...',
                  fromAi: true,
                  delay: 1700),
              SizedBox(height: 10),
              _ChatBubble(
                  text: '여기서 몇 개 빼고 이대로 해줘',
                  fromAi: false,
                  delay: 2200),
              SizedBox(height: 6),
              _ChatBubble(
                  text: '✅ 4곳 · 약 5시간 확정',
                  fromAi: true,
                  delay: 2620),
            ],
          ),
        ),
        // 텍스트 — ring 안쪽 하단.
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 0, 36, 140),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      delay: 380.ms,
                    )
                    .fadeIn(duration: 400.ms, delay: 380.ms),
                const SizedBox(height: 10),
                Text(
                  l.aiVoiceBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
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
                      delay: 520.ms,
                    )
                    .fadeIn(duration: 400.ms, delay: 520.ms),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📅 ', style: TextStyle(fontSize: 16)),
                    Flexible(
                      child: Text(
                        l.aiDayPlanHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
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
                      delay: 680.ms,
                    )
                    .fadeIn(duration: 320.ms, delay: 680.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// mock 채팅 풍선. fromAi=true 면 좌측 정렬 + 흰 배경, false 면 우측 정렬 + 반투명 흰 테두리.
class _ChatBubble extends StatelessWidget {
  final String text;
  final bool fromAi;
  final int delay;
  const _ChatBubble({
    required this.text,
    required this.fromAi,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fromAi
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: fromAi
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fromAi ? const Color(0xFF1E1E2E) : Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return Row(
      mainAxisAlignment:
          fromAi ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        Flexible(
          child: bubble
              .animate()
              .slideY(
                begin: -0.4,
                end: 0,
                duration: 480.ms,
                curve: Curves.easeOutCubic,
                delay: Duration(milliseconds: delay),
              )
              .fadeIn(
                duration: 360.ms,
                delay: Duration(milliseconds: delay),
              ),
        ),
      ],
    );
  }
}
