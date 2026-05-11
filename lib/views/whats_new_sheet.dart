import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/gen/app_localizations.dart';
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

  // 페이지 정의는 BuildContext 가 있어야 현지화된 타이틀/본문을 빌드할 수 있어
  // const → instance method 로 전환. 그라데이션/이모지는 고정.
  static const _pageGradients = <List<Color>>[
    [Color(0xFF7C5CFF), Color(0xFF5CC8FF)], // 1 환영
    [Color(0xFFBC82F3), Color(0xFFFF6B9D)], // 2 무드
    [Color(0xFFFF7A00), Color(0xFFFFC371)], // 3 같이가기
    [Color(0xFF06B6D4), Color(0xFF22D3EE)], // 4 DM
    [Color(0xFF1DB954), Color(0xFF1ED760)], // 5 Spotify
    [Color(0xFFEC4899), Color(0xFFF472B6)], // 6 친구 늘리기
    [Color(0xFFA855F7), Color(0xFFD946EF)], // 7 점수
    [Color(0xFF10B981), Color(0xFF34D399)], // 8 프라이버시
    [Color(0xFF3B82F6), Color(0xFF06B6D4)], // 9 길찾기
    [Color(0xFFF59E0B), Color(0xFFFB923C)], // 10 하루 플랜
    [Color(0xFF14B8A6), Color(0xFF60A5FA)], // 11 다국어
    [Color(0xFF8B5CF6), Color(0xFFEC4899)], // 12 AI 음성
  ];
  static const _pageEmojis = <String>[
    '🎉', '✨', '🎯', '💬', '🎵', '🤝', '🏆', '🛡',
    '🗺', '📅', '🌐', '🎙',
  ];
  static const _pageCount = 12;

  List<_WnPage> _pagesFor(BuildContext ctx) {
    final l = AppL10n.of(ctx);
    final titles = <String>[
      l.whatsNewPage1Title(kAppVersion),
      l.whatsNewPage2Title,
      l.whatsNewPage3Title,
      l.whatsNewPage4Title,
      l.whatsNewPage5Title,
      l.whatsNewPage6Title,
      l.whatsNewPage7Title,
      l.whatsNewPage8Title,
      l.whatsNewPage9Title,
      l.whatsNewPage10Title,
      l.whatsNewPage11Title,
      l.whatsNewPage12Title,
    ];
    final bodies = <String>[
      l.whatsNewPage1Body,
      l.whatsNewPage2Body,
      l.whatsNewPage3Body,
      l.whatsNewPage4Body,
      l.whatsNewPage5Body,
      l.whatsNewPage6Body,
      l.whatsNewPage7Body,
      l.whatsNewPage8Body,
      l.whatsNewPage9Body,
      l.whatsNewPage10Body,
      l.whatsNewPage11Body,
      l.whatsNewPage12Body,
    ];
    return [
      for (int i = 0; i < _pageCount; i++)
        _WnPage(
          emoji: _pageEmojis[i],
          title: titles[i],
          body: bodies[i],
          gradient: _pageGradients[i],
        ),
    ];
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index >= _pageCount - 1) {
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
    final pages = _pagesFor(context);
    final isLast = _index == pages.length - 1;
    final l = AppL10n.of(context);
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      // 노치 / 홈인디케이터 영역까지 그라데이션이 채워지도록 SafeArea 제거.
      backgroundColor: const Color(0xFF0E1018),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 페이지가 화면 전체 (노치/홈 영역 포함) 채우도록.
          Positioned.fill(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: pages.length,
              itemBuilder: (_, i) => _PageContent(
                // 같은 페이지로 돌아와도 애니메이션 재생되도록 currentIndex 포함.
                key: ValueKey('wn_$i${_index == i ? '_active' : ''}'),
                page: pages[i],
                isActive: i == _index,
                topPadding: topPad,
                bottomPadding: bottomPad,
              ),
            ),
          ),
          // skip 우측 상단 (status bar 아래로).
          Positioned(
            top: topPad + 4,
            right: 8,
            child: TextButton(
              onPressed: _skip,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.7),
              ),
              child: Text(isLast ? l.whatsNewClose : l.whatsNewSkip,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          // 페이지 indicator + 다음 버튼.
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomPad + 24,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) {
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
                      label: isLast ? l.whatsNewStart : l.whatsNewNext,
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
    );
  }
}

class _PageContent extends StatelessWidget {
  final _WnPage page;
  final bool isActive;
  final double topPadding;
  final double bottomPadding;
  const _PageContent({
    super.key,
    required this.page,
    required this.isActive,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

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
        // 본문 — safe inset 만큼 padding 추가.
        Padding(
          padding: EdgeInsets.fromLTRB(32, 80 + topPadding, 32, 200 + bottomPadding),
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
