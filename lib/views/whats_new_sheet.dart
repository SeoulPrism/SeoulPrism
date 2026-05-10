import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/onboarding_service.dart';
import '../widgets/adaptive/adaptive.dart';

/// 앱 short version. pubspec 의 version 과 일치 유지.
const String kAppVersion = '1.0.5';

/// What's New — 신버전 첫 진입 시 풀스크린 튜토리얼식 페이지.
/// PageView 로 좌우 swipe + 마지막 "시작하기".
class WhatsNewView extends StatefulWidget {
  const WhatsNewView({super.key});

  /// 마지막 본 버전이 [kAppVersion] 과 다르면 fullscreen route 로 띄움.
  /// [forceShow] true 면 무조건.
  static Future<void> maybeShow(
    BuildContext context, {
    bool forceShow = false,
  }) async {
    final svc = OnboardingService.instance;
    if (!forceShow && svc.lastSeenWhatsNewVersion == kAppVersion) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => const WhatsNewView(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    await svc.markWhatsNewSeen(kAppVersion);
  }

  @override
  State<WhatsNewView> createState() => _WhatsNewViewState();
}

class _WhatsNewViewState extends State<WhatsNewView> {
  final _pageCtrl = PageController();
  int _index = 0;

  static const _pages = <_WnPage>[
    _WnPage(
      emoji: '🎉',
      title: 'v$kAppVersion — 다시 만나서 반가워요',
      body:
          'Seoul Live 가 한 단계 더 풍성해졌어요.\n'
          '친구와 만나고, 같이 가고, 추억으로 남기는\n'
          '13개의 새 기능을 만나보세요.',
      gradient: [Color(0xFF7C5CFF), Color(0xFF5CC8FF)],
    ),
    _WnPage(
      emoji: '🎯',
      title: '같이 가기',
      body: '친구방에서 공통 목적지를 정하면\n'
          '멤버별 거리가 실시간으로 보여요.\n'
          '맵에는 주황 핀이 자동으로.',
      gradient: [Color(0xFFFF7A00), Color(0xFFFFC371)],
    ),
    _WnPage(
      emoji: '💬',
      title: '1:1 DM + 음성/사진',
      body: '친구방 없이 친구와 바로 대화.\n'
          '🎙 마이크 길게 눌러 음성, 📷 갤러리에서 사진,\n'
          '📍 위치까지 한 채팅에서.',
      gradient: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
    ),
    _WnPage(
      emoji: '🎵',
      title: 'Spotify 공유',
      body: '내가 듣는 곡을 친구에게.\n'
          '채팅에 🎵 누르면 지금 재생 중인\n'
          'Spotify 트랙이 카드로 공유돼요.',
      gradient: [Color(0xFF1DB954), Color(0xFF1ED760)],
    ),
    _WnPage(
      emoji: '🤝',
      title: '친구 늘리기',
      body: '친구 화면에 "친구의 친구" 추천,\n'
          'QR 코드로 즉시 추가,\n'
          '방 초대 링크로 한 번에 입장.',
      gradient: [Color(0xFFEC4899), Color(0xFFF472B6)],
    ),
    _WnPage(
      emoji: '🏆',
      title: '활동이 점수가 돼요',
      body: '친구 추가, 만남, 연속 출석으로 점수와 뱃지.\n'
          '친구끼리 랭킹으로 비교하고,\n'
          '주간 활동 차트로 돌아보세요.',
      gradient: [Color(0xFFA855F7), Color(0xFFD946EF)],
    ),
    _WnPage(
      emoji: '🛡',
      title: '내 마음대로',
      body: '알림은 종류별로 켜고 끄고,\n'
          '내 위치는 특정 그룹에게만.\n'
          '안전과 프라이버시는 본인이.',
      gradient: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index >= _pages.length - 1) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1018),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) => _PageContent(
                // 같은 페이지로 돌아와도 애니메이션 재생되도록 currentIndex 포함.
                key: ValueKey('wn_$i${_index == i ? '_active' : ''}'),
                page: _pages[i],
                isActive: i == _index,
              ),
            ),
            // skip 우측 상단.
            Positioned(
              top: 8,
              right: 8,
              child: TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.6),
                ),
                child: Text(isLast ? '닫기' : '건너뛰기',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            // 페이지 indicator + 다음 버튼.
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final on = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: on ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: on
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: AdaptiveGlassButton(
                      label: isLast ? '시작하기' : '다음',
                      onPressed: _next,
                    ),
                  )
                      .animate(key: ValueKey('btn_$_index'))
                      .slideY(
                        begin: 0.6,
                        end: 0,
                        duration: 420.ms,
                        curve: Curves.easeOutCubic,
                        delay: 460.ms,
                      )
                      .fadeIn(duration: 320.ms, delay: 460.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _WnPage page;
  final bool isActive;
  const _PageContent({super.key, required this.page, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 배경 — 그라데이션 + 은은한 펄스 (loop).
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: page.gradient
                    .map((c) => c.withValues(alpha: 0.22))
                    .toList(),
              ),
            ),
          ),
        ),
        // 좌상 / 우하 발광 blob — 천천히 이동.
        _BackgroundBlob(
          color: page.gradient.first,
          alignment: const Alignment(-0.7, -0.6),
        ),
        _BackgroundBlob(
          color: page.gradient.last,
          alignment: const Alignment(0.8, 0.7),
        ),
        // 본문.
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 큰 emoji 원형 글로우.
              Center(
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: page.gradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: page.gradient.first.withValues(alpha: 0.55),
                        blurRadius: 60,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(page.emoji,
                      style: const TextStyle(fontSize: 72)),
                )
                    .animate(target: isActive ? 1 : 0)
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 520.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 320.ms)
                    .then()
                    .shimmer(
                      duration: 1200.ms,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
              ),
              const SizedBox(height: 48),
              Text(page.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                      ))
                  .animate(target: isActive ? 1 : 0)
                  .slideY(
                    begin: 0.4,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                    delay: 180.ms,
                  )
                  .fadeIn(duration: 400.ms, delay: 180.ms),
              const SizedBox(height: 16),
              Text(page.body,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: Colors.white.withValues(alpha: 0.85),
                      ))
                  .animate(target: isActive ? 1 : 0)
                  .slideY(
                    begin: 0.5,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                    delay: 320.ms,
                  )
                  .fadeIn(duration: 400.ms, delay: 320.ms),
            ],
          ),
        ),
      ],
    );
  }
}

/// 배경 발광 blob — slow-pulse 로 화면에 생동감.
class _BackgroundBlob extends StatelessWidget {
  final Color color;
  final Alignment alignment;
  const _BackgroundBlob({required this.color, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.35),
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

class _WnPage {
  final String emoji;
  final String title;
  final String body;
  final List<Color> gradient;
  const _WnPage({
    required this.emoji,
    required this.title,
    required this.body,
    required this.gradient,
  });
}
