import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/gen/app_localizations.dart';
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
                        AppL10n.of(context).seoulLiveStartTitle,
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
                        AppL10n.of(context).seoulLiveStartBody,
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

  // 한국어 라벨은 const 이 아니라 ARB lookup 이 필요해 build-time 에 생성.
  // 아이콘 / isPermission 만 const 유지.
  static const _stepCount = 5;
  static const _stepIcons = <IconData>[
    Icons.location_on_rounded,
    Icons.meeting_room_rounded,
    Icons.celebration_rounded,
    Icons.shield_rounded,
    Icons.notifications_active_rounded,
  ];
  static const _stepPermission = <bool>[false, false, false, false, true];

  List<_CoachStep> _stepsFor(BuildContext ctx) {
    final l = AppL10n.of(ctx);
    final titles = [
      l.seoulLiveStep2Title,
      l.seoulLiveStep3Title,
      l.seoulLiveStep4Title,
      l.seoulLiveStep5Title,
      l.seoulLivePermTitle,
    ];
    final bodies = [
      l.seoulLiveStep2Body,
      l.seoulLiveStep3Body,
      l.seoulLiveStep4Body,
      l.seoulLiveStep5Body,
      l.seoulLivePermBody,
    ];
    return [
      for (var i = 0; i < _stepCount; i++)
        _CoachStep(
          icon: _stepIcons[i],
          title: titles[i],
          body: bodies[i],
          isPermission: _stepPermission[i],
        ),
    ];
  }

  bool _requestingPermission = false;
  bool? _permissionResult;

  Future<void> _next() async {
    final s = _stepsFor(context)[_step];
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
    if (_step >= _stepCount - 1) {
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = _stepsFor(context);
    final s = steps[_step];

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
                    children: List.generate(_stepCount, (i) {
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
                    child: Text(AppL10n.of(context).commonSkip),
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
                        ? AppL10n.of(context).seoulLivePermAllowed
                        : AppL10n.of(context).seoulLivePermDenied,
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
                    _resolveButtonLabel(context, s),
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

  String _resolveButtonLabel(BuildContext ctx, _CoachStep s) {
    final l = AppL10n.of(ctx);
    if (s.isPermission) {
      if (_requestingPermission) return l.seoulLivePermRequesting;
      if (_permissionResult == null) return l.seoulLivePermAllow;
      return l.commonStart;
    }
    return _step >= _stepCount - 1 ? l.commonStart : l.commonNext;
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
