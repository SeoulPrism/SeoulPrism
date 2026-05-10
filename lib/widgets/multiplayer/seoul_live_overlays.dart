import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/multiplayer_service.dart';
import '../../services/notification_service.dart';

/// Seoul Live 모드 진입 시 1회 한정으로 재생되는 인트로 시퀀스:
///   1) 화면 중앙 지구본 등장 → 회전 → 탭바 위치로 이동 (탭바가 '세계' 로 바뀐 걸 시각화)
///   2) 코치마크 3장 (지구본 마커 / 친구방 / 만남 알림)
///
/// SharedPrefs 키 `seoul_live_tutorial_seen_v1` 로 중복 노출 방지.
class SeoulLiveOverlays {
  /// 메인 지도가 mount 된 직후 호출. tutorial 본 적 없으면 시퀀스 시작.
  static Future<void> maybeRunIntro(BuildContext context) async {
    if (await MultiplayerService.hasSeenTutorial()) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => const _CelebrationOverlay(),
      ),
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => const _TutorialCoachmarks(),
      ),
    );
    await MultiplayerService.markTutorialSeen();
  }
}

// ─────────────────────────────────────────────────────────────────
// 1. Celebration — 지구본 등장 + 회전 + 탭바로 swoop
// ─────────────────────────────────────────────────────────────────

class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay();

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _swoopCtrl;
  late final AnimationController _scrimCtrl;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _scrimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _swoopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    Future.delayed(const Duration(milliseconds: 1700), () async {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _swoopCtrl.forward();
      _scrimCtrl.reverse();
      await Future.delayed(const Duration(milliseconds: 720));
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _swoopCtrl.dispose();
    _scrimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 탭바 가운데 (지도 탭) 대략 위치 — 화면 너비/2, 화면 높이 - bottom inset - tabbar~80px
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final endX = size.width / 2;
    final endY = size.height - bottomInset - 56;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scrimCtrl, _enterCtrl, _swoopCtrl]),
        builder: (_, _) {
          // Scrim: 0→1 진입, 1→0 퇴장.
          final scrim = _scrimCtrl.value;
          // Center→tab swoop.
          final t = Curves.easeInOutCubic.transform(_swoopCtrl.value);
          final cx = size.width / 2 + (endX - size.width / 2) * t;
          final cy = size.height / 2 + (endY - size.height / 2) * t;
          // Globe scale: 0→1.05 (등장 ease-out), 1.05→0.4 (탭바 흡수).
          final enter =
              Curves.easeOutBack.transform(_enterCtrl.value.clamp(0.0, 1.0));
          final scale = enter * 1.05 - t * 0.65;
          // 회전: 진입 + swoop 모두에서 계속 도는 중.
          final rot = _enterCtrl.value * 1.2 + _swoopCtrl.value * 0.6;
          return Stack(
            children: [
              // 다크 스크림.
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.65 * scrim),
                ),
              ),
              // 캡션.
              Positioned(
                top: size.height * 0.32,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: (scrim * (1 - _swoopCtrl.value)).clamp(0.0, 1.0),
                  child: Column(
                    children: [
                      Text(
                        'Seoul Live 시작',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF7C5CFF)
                                  .withValues(alpha: 0.6),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '지도가 세계로 확장됐어요',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 지구본.
              Positioned(
                left: cx - 60,
                top: cy - 60,
                child: Transform.rotate(
                  angle: rot,
                  child: Transform.scale(
                    scale: scale.clamp(0.0, 1.5),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7C5CFF), Color(0xFF5CC8FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C5CFF)
                                .withValues(alpha: 0.6),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.public_rounded,
                          size: 64, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 2. Tutorial coachmarks
// ─────────────────────────────────────────────────────────────────

class _TutorialCoachmarks extends StatefulWidget {
  const _TutorialCoachmarks();

  @override
  State<_TutorialCoachmarks> createState() => _TutorialCoachmarksState();
}

class _TutorialCoachmarksState extends State<_TutorialCoachmarks> {
  int _step = 0;

  static const _steps = <_CoachStep>[
    _CoachStep(
      icon: Icons.location_on_rounded,
      title: '친구의 핀이 지도에 떠요',
      body: '같은 친구방의 멤버가 핀(닉네임 + 이모지) 으로 실시간 표시돼요. '
          '친구가 움직이면 핀도 같이 움직여요.',
    ),
    _CoachStep(
      icon: Icons.meeting_room_rounded,
      title: '친구방 코드로 모이기',
      body: '프로필 → Seoul Live → 친구방에서 새 방을 만들거나 '
          '6자리 초대 코드로 입장하세요. 정원은 8명이에요.',
    ),
    _CoachStep(
      icon: Icons.celebration_rounded,
      title: '50m 이내면 만남 알림',
      body: '친구와 가까워지면 햅틱과 알림이 울려요. 채팅에도 자동으로 기록돼요.',
    ),
    _CoachStep(
      icon: Icons.shield_rounded,
      title: '언제든 비공개 모드',
      body: '상단의 "위치 공유 중" 배지를 탭하면 즉시 ghost 모드로 전환돼요. '
          '친구방을 나가면 자동으로 송신이 멈춰요.',
    ),
    _CoachStep(
      icon: Icons.notifications_active_rounded,
      title: '알림 받기',
      body: '친구 신청 / 새 메시지 / 만남이 발생하면 푸시 알림으로 알려드려요. '
          '아래 "허용" 버튼을 눌러 알림을 받아주세요.',
      isPermission: true,
    ),
  ];

  bool _requestingPermission = false;
  bool? _permissionResult;

  Future<void> _next() async {
    final s = _steps[_step];
    if (s.isPermission && _permissionResult == null) {
      // 알림 권한 요청.
      setState(() => _requestingPermission = true);
      final granted =
          await NotificationService.instance.requestPermissionAndRegister();
      if (!mounted) return;
      setState(() {
        _requestingPermission = false;
        _permissionResult = granted;
      });
      // 권한 요청 후에도 사용자가 다시 "다음" 누르도록 유지.
      return;
    }
    if (_step >= _steps.length - 1) {
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = _steps[_step];

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              // 상단: 진행 dots + 닫기.
              Row(
                children: [
                  Row(
                    children: List.generate(_steps.length, (i) {
                      final on = i <= _step;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: on ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: on
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('건너뛰기'),
                  ),
                ],
              ),
              const Spacer(),
              // 카드.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position:
                        Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                            .animate(a),
                    child: c,
                  ),
                ),
                child: Container(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF7C5CFF), Color(0xFF5CC8FF)],
                          ),
                        ),
                        child:
                            Icon(s.icon, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.body,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (s.isPermission && _permissionResult != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _permissionResult!
                        ? '✓ 알림 권한 허용됨'
                        : '거부됨 — 설정에서 직접 허용할 수 있어요',
                    style: TextStyle(
                      color: _permissionResult!
                          ? const Color(0xFF34C759)
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _requestingPermission ? null : _next,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _resolveButtonLabel(s),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveButtonLabel(_CoachStep s) {
    if (s.isPermission) {
      if (_requestingPermission) return '요청 중...';
      if (_permissionResult == null) return '알림 허용';
      return '시작하기';
    }
    return _step >= _steps.length - 1 ? '시작하기' : '다음';
  }
}

class _CoachStep {
  final IconData icon;
  final String title;
  final String body;
  final bool isPermission;
  const _CoachStep({
    required this.icon,
    required this.title,
    required this.body,
    this.isPermission = false,
  });
}
