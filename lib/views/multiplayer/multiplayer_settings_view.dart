import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import 'admin_monitor_view.dart';
import 'blocked_users_view.dart';
import '../../widgets/app_snackbar.dart';

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
    final l = AppL10n.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(title: l.mpSettingsTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 일시정지.
            _Section(label: l.mpSectionMyStatus, children: [
              AdaptiveSectionCard(children: [
                _SwitchRow(
                  icon: Icons.pause_circle_filled_rounded,
                  label: l.mpPause,
                  hint: l.mpPauseHint,
                  value: svc.seoulLivePaused,
                  onChanged: svc.setSeoulLivePaused,
                ),
              ]),
            ]),

            // 배터리 모드.
            _Section(label: l.mpSectionBattery, children: [
              AdaptiveSectionCard(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(l.mpBatteryHint,
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
            _Section(label: l.mpSectionNotifications, children: [
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
                        label: _notifLabel(context, k),
                        value: svc.notifPrefs[k] ?? true,
                        onChanged: (v) async {
                          try {
                            await svc.setNotifPref(k, v);
                          } catch (e) {
                            if (mounted) {
                              showAppSnackBar(AppL10n.of(context)
                                  .mpNotificationsFail(e.toString()));
                            }
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
                  l.mpNotificationsHint,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ),
            ]),

            // 튜토리얼.
            _Section(label: l.mpSectionTutorial, children: [
              AdaptiveSectionCard(children: [
                _ChevronRow(
                  icon: Icons.school_rounded,
                  label: l.mpReplayTutorial,
                  onTap: () async {
                    await MultiplayerService.resetTutorial();
                    if (!mounted) return;
                    showAppSnackBar(AppL10n.of(context).mpTutorialToast);
                  },
                ),
              ]),
            ]),

            // 차단 목록.
            _Section(label: l.mpSectionSafety, children: [
              AdaptiveSectionCard(children: [
                _ChevronRow(
                  icon: Icons.block_rounded,
                  label: l.mpBlockList,
                  hint: l.mpBlockListHint,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BlockedUsersView()),
                  ),
                ),
              ]),
            ]),

            // 동의 / 데이터.
            _Section(label: l.mpSectionConsent, children: [
              AdaptiveSectionCard(children: [
                _ChevronRow(
                  icon: Icons.privacy_tip_outlined,
                  label: l.mpRevokeConsent,
                  hint: l.mpRevokeConsentHint,
                  onTap: () => _confirmRevokeConsent(context),
                ),
                const _Divider(),
                _ChevronRow(
                  icon: Icons.download_outlined,
                  label: l.mpDownloadMyData,
                  hint: l.mpDownloadMyDataHint,
                  onTap: () {
                    showAppSnackBar(
                        AppL10n.of(context).mpDownloadMyDataToast);
                  },
                ),
              ]),
            ]),

            // 운영팀 전용 — admin email 한정.
            if (svc.isAdmin)
              _Section(label: l.mpSectionOps, children: [
                AdaptiveSectionCard(children: [
                  _ChevronRow(
                    icon: Icons.shield_moon_rounded,
                    label: l.mpOpsMonitor,
                    hint: l.mpOpsMonitorHint,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminMonitorView()),
                    ),
                  ),
                ]),
              ]),

            // 위험 영역.
            _Section(label: l.mpSectionDanger, children: [
              AdaptiveSectionCard(children: [
                _ChevronRow(
                  icon: Icons.delete_forever_outlined,
                  label: l.mpLeaveSeoulLive,
                  hint: l.mpLeaveSeoulLiveHint,
                  destructive: true,
                  onTap: () => _confirmDelete(context),
                ),
              ]),
            ]),

            const SizedBox(height: 16),
            Center(
              child: Text(
                l.mpFootnote,
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
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.mpRevokeDialogTitle,
      content: l.mpRevokeDialogBody,
      confirmText: l.mpRevokeDialogConfirm,
      isDestructive: true,
      onConfirm: () async {
        try {
          await MultiplayerService.instance.deleteMyData();
          if (!mounted) return;
          Navigator.of(context).popUntil((r) => r.isFirst);
          showAppSnackBar(AppL10n.of(context).mpRevokedToast);
        } catch (e) {
          if (!mounted) return;
          showAppSnackBar(AppL10n.of(context).mpNotificationsFail(e.toString()));
        }
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.mpLeaveDialogTitle,
      content: l.mpLeaveDialogBody,
      confirmText: l.mpLeaveConfirm,
      isDestructive: true,
      onConfirm: () async {
        try {
          await MultiplayerService.instance.deleteMyData();
          if (!mounted) return;
          Navigator.of(context).popUntil((r) => r.isFirst);
          showAppSnackBar(AppL10n.of(context).mpLeftToast);
        } catch (e) {
          if (!mounted) return;
          showAppSnackBar(AppL10n.of(context).mpNotificationsFail(e.toString()));
        }
      },
    );
  }

  String _notifLabel(BuildContext ctx, String k) {
    final l = AppL10n.of(ctx);
    return switch (k) {
      'friend_request' => l.mpNotifCatFriendRequest,
      'friend_accept' => l.mpNotifCatFriendAccept,
      'room_message' => l.mpNotifCatRoomMessage,
      'meetup' => l.mpNotifCatMeetup,
      'destination' => l.mpNotifCatDestination,
      'welcome' => l.mpNotifCatWelcome,
      _ => k,
    };
  }

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
