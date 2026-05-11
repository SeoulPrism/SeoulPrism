import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AI Companion 페이지 데모.
/// 중앙 마이크 글로우 + 그 아래 음성 파형, 위쪽엔 mock 채팅 풍선 (Q + A) 슬라이드 인.
/// 마이크 탭 시 파형 진폭 증가 (실제 음성 X).
class AiVoiceWaveMock extends StatefulWidget {
  const AiVoiceWaveMock({super.key});

  @override
  State<AiVoiceWaveMock> createState() => _AiVoiceWaveMockState();
}

class _AiVoiceWaveMockState extends State<AiVoiceWaveMock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;
  double _amplitude = 0.55;

  static const _bubbles = <(String, bool)>[
    ('강남역 가는 법?', false), // user
    ('🗺 3호선 → 2호선, 18분 거리', true), // ai
  ];

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  void _onMicTap() {
    setState(() => _amplitude = 0.95);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _amplitude = 0.55);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 상단 채팅 풍선 2개.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ChatBubble(
                    text: _bubbles[0].$1,
                    fromAi: _bubbles[0].$2,
                    delay: 280,
                  ),
                  const SizedBox(height: 10),
                  _ChatBubble(
                    text: _bubbles[1].$1,
                    fromAi: _bubbles[1].$2,
                    delay: 720,
                  ),
                ],
              ),
            ),
            // 중앙 마이크 글로우.
            Positioned(
              bottom: 64,
              child: GestureDetector(
                onTap: _onMicTap,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.55),
                        blurRadius: 60,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.mic_rounded,
                      color: Colors.white, size: 56),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 1800.ms,
                      color: Colors.white.withValues(alpha: 0.4),
                      delay: 600.ms,
                    ),
              ),
            ),
            // 마이크 아래 파형.
            Positioned(
              bottom: 28,
              left: 24,
              right: 24,
              child: SizedBox(
                height: 28,
                child: AnimatedBuilder(
                  animation: _wave,
                  builder: (_, _) => CustomPaint(
                    painter: _WavePainter(
                      phase: _wave.value * 2 * math.pi,
                      amplitude: _amplitude,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: fromAi
            ? Colors.white.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: fromAi
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fromAi ? const Color(0xFF1E1E2E) : Colors.white,
          fontSize: 14,
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

class _WavePainter extends CustomPainter {
  final double phase;
  final double amplitude;
  _WavePainter({required this.phase, required this.amplitude});

  static const _barCount = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final gap = 4.0;
    final barW = (size.width - gap * (_barCount - 1)) / _barCount;
    for (var i = 0; i < _barCount; i++) {
      // 가운데가 큰 종 모양 + sin loop.
      final centerBias = 1.0 - (((_barCount - 1) / 2 - i).abs() / _barCount);
      final localAmp = amplitude *
          (0.4 + 0.6 * centerBias) *
          (0.5 + 0.5 * math.sin(phase + i * 0.7));
      final h = (size.height * localAmp).clamp(3.0, size.height);
      final x = i * (barW + gap);
      final y = (size.height - h) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, h),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.phase != phase || old.amplitude != amplitude;
}
