import 'package:flutter/material.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import 'admin_monitor_view.dart';
import 'blocked_users_view.dart';
import '../../widgets/app_snackbar.dart';
import '../whats_new_sheet.dart';

/// Seoul Live 설정/탈퇴/배터리/튜토리얼/동의관리.
class MultiplayerSettingsView extends StatefulWidget {
  const MultiplayerSettingsView({super.key});

  @override
  State<MultiplayerSettingsView> createState() =>
      _MultiplayerSettingsViewState();
}

class _MultiplayerSettingsViewState extends State<MultiplayerSettingsView> {
  @override
  void initState() {
    super.initState();
    MultiplayerService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    MultiplayerService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = MultiplayerService.instance;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AdaptiveAppBar(title: 'Seoul Live 설정'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 일시정지.
            _Section(label: '내 상태', children: [
              AdaptiveSectionCard(children: [
                _SwitchRow(
                  icon: Icons.pause_circle_filled_rounded,
                  label: 'Seoul Live 일시정지',
                  hint: '✓ 채팅 / 친구방 입장 / 친구 신청 — 가능\n'
                      '✗ 위치 송신 / 만남 알림 / 핀 표시 — 차단\n'
                      '데이터는 그대로 유지',
                  value: svc.seoulLivePaused,
                  onChanged: svc.setSeoulLivePaused,
                ),
              ]),
            ]),

            // 배터리 모드.
            _Section(label: '배터리 모드', children: [
              AdaptiveSectionCard(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text('위치 송신 주기 — 정확할수록 배터리 소모',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: AdaptiveSegmented<BatteryMode>(
                    selected: svc.batteryMode,
                    onSelected: (m) => svc.setBatteryMode(m),
                    segments: BatteryMode.values
                        .map((m) => AdaptiveSegment(
                              value: m,
                              label: '${m.label} (${m.intervalSec}s)',
                            ))
                        .toList(),
                  ),
                ),
              ]),
            ]),

            // 알림 종류별 toggle (B12).
            _Section(label: '알림', children: [
              AdaptiveSectionCard(
                children: [
                  for (var i = 0;
                      i < MultiplayerService.notifPrefKinds.length;
                      i++) ...[
                    if (i > 0) const _Divider(),
                    Builder(builder: (_) {
                      final k = MultiplayerService.notifPrefKinds[i];
                      return _SwitchRow(
                        icon: _notifIcon(k),
                        label: _notifLabel(k),
                        value: svc.notifPrefs[k] ?? true,
                        onChanged: (v) async {
                          try {
                            await svc.setNotifPref(k, v);
                          } catch (e) {
                            if (mounted) showAppSnackBar('실패: $e');
                          }
                        },
                      );
                    }),
                  ],
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Text(
                  '시스템 알림 권한과 별개 — 여기서 끄면 푸시는 보내지지만 무음 처리.',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ),
            ]),

            // 튜토리얼.
            _Section(label: '튜토리얼', children: [
              AdaptiveSectionCard(children: [
                _ChevronRow(
                  icon: Icons.school_rounded,
                  label: 'Seoul Live 튜토리얼 다시 보기',
                  onTap: () async {
                    await MultiplayerService.resetTutorial();
                    if (!mounted) return;
                    showAppSnackBar('다음 진입 시 튜토리얼이 다시 나와요');
                  },
                ),
                const _Divider(),
                _ChevronRow(
                  icon: Icons.new_releases_outlined,
                  label: '새 기능 다시 보기',
                  hint: 'v$kAppVersion 업데이트 내역',
                  onTap: () => WhatsNewView.maybeShow(context, forceShow: true),
                ),
              ]),
            ]),

            // 차단 목록.
            _Section(label: '안전', children: [
              AdaptiveSectionCard(children: [
                _ChevronRow(
                  icon: Icons.block_rounded,
                  label: '차단 목록',
                  hint: '차단한 사용자 보기 / 해제',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BlockedUsersView()),
                  ),
                ),
              ]),
            ]),

            // 동의 / 데이터.
            _Section(label: '동의 및 데이터', children: [
              AdaptiveSectionCard(children: [
                _ChevronRow(
                  icon: Icons.privacy_tip_outlined,
                  label: '위치정보 동의 철회',
                  hint: '동의를 철회하면 멀티플레이가 비활성화되고 모든 데이터가 삭제돼요',
                  onTap: () => _confirmRevokeConsent(context),
                ),
                const _Divider(),
                _ChevronRow(
                  icon: Icons.download_outlined,
                  label: '내 데이터 다운로드',
                  hint: 'PIPA 데이터 이동권 — 이메일로 요청',
                  onTap: () {
                    showAppSnackBar('rush94434@gmail.com 으로 요청해주세요 (10일 이내 처리)');
                  },
                ),
              ]),
            ]),

            // 운영팀 전용 — admin email 한정.
            if (svc.isAdmin)
              _Section(label: '운영팀', children: [
                AdaptiveSectionCard(children: [
                  _ChevronRow(
                    icon: Icons.shield_moon_rounded,
                    label: '운영 모니터',
                    hint: '일일 지표 · 어뷰즈 신호 · 신고 처리',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminMonitorView()),
                    ),
                  ),
                ]),
              ]),

            // 위험 영역.
            _Section(label: '위험 영역', children: [
              AdaptiveSectionCard(children: [
                _ChevronRow(
                  icon: Icons.delete_forever_outlined,
                  label: 'Seoul Live 탈퇴',
                  hint: '프로필·친구·방·채팅 등 멀티플레이 데이터 일괄 삭제',
                  destructive: true,
                  onTap: () => _confirmDelete(context),
                ),
              ]),
            ]),

            const SizedBox(height: 16),
            Center(
              child: Text(
                '※ Seoul Vista 본 계정은 유지돼요. 멀티플레이 관련 데이터만 삭제됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRevokeConsent(BuildContext context) {
    showAdaptiveConfirmDialog(
      context: context,
      title: '동의 철회',
      content:
          '위치정보 처리 동의를 철회하면 멀티플레이가 비활성화되고\n프로필·친구·방·채팅 데이터가 모두 삭제됩니다.\n계속할까요?',
      confirmText: '철회',
      isDestructive: true,
      onConfirm: () async {
        try {
          await MultiplayerService.instance.deleteMyData();
          if (!mounted) return;
          Navigator.of(context).popUntil((r) => r.isFirst);
          showAppSnackBar('동의를 철회하고 데이터를 삭제했어요');
        } catch (e) {
          if (!mounted) return;
          showAppSnackBar('실패: $e');
        }
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showAdaptiveConfirmDialog(
      context: context,
      title: 'Seoul Live 탈퇴',
      content: '모든 멀티플레이 데이터가 영구 삭제됩니다.\n다시 가입할 수 있지만 친구·방·채팅 기록은 복구되지 않아요.',
      confirmText: '탈퇴',
      isDestructive: true,
      onConfirm: () async {
        try {
          await MultiplayerService.instance.deleteMyData();
          if (!mounted) return;
          Navigator.of(context).popUntil((r) => r.isFirst);
          showAppSnackBar('Seoul Live 에서 탈퇴했어요');
        } catch (e) {
          if (!mounted) return;
          showAppSnackBar('실패: $e');
        }
      },
    );
  }

  String _notifLabel(String k) => switch (k) {
        'friend_request' => '친구 신청',
        'friend_accept' => '친구 수락',
        'room_message' => '채팅 메시지',
        'meetup' => '만남 감지',
        'destination' => '목적지 변경',
        'welcome' => '환영',
        _ => k,
      };

  IconData _notifIcon(String k) => switch (k) {
        'friend_request' => Icons.person_add_alt_1_rounded,
        'friend_accept' => Icons.handshake_outlined,
        'room_message' => Icons.chat_bubble_outline_rounded,
        'meetup' => Icons.celebration_outlined,
        'destination' => Icons.flag_outlined,
        'welcome' => Icons.waving_hand_outlined,
        _ => Icons.notifications_outlined,
      };
}

// ─── Reusable rows ────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _Section({required this.label, required this.children});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant)),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ChevronRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final bool destructive;
  final VoidCallback onTap;
  const _ChevronRow({
    required this.icon,
    required this.label,
    this.hint,
    this.destructive = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = destructive ? cs.error : cs.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color)),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(hint!,
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.icon,
    required this.label,
    this.hint,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurface),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(hint!,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Divider(
          height: 0.5,
          thickness: 0.5,
          color: cs.outlineVariant.withValues(alpha: 0.5)),
    );
  }
}
