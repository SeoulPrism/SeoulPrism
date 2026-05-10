import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';
import 'friend_code_share.dart';
import 'friends_view.dart';
import 'group_editor_view.dart';
import 'login_required_gate.dart';
import 'multiplayer_settings_view.dart';
import 'profile_edit_sheet.dart';
import 'room_view.dart';

/// Seoul Live 진입점.
/// 만남 햅틱+스낵바 / 시스템 메시지 송신을 여기서 처리.
class MultiplayerHubView extends StatefulWidget {
  const MultiplayerHubView({super.key});

  @override
  State<MultiplayerHubView> createState() => _MultiplayerHubViewState();
}

class _MultiplayerHubViewState extends State<MultiplayerHubView> {
  @override
  void initState() {
    super.initState();
    MultiplayerService.instance.addListener(_onChanged);
    MultiplayerService.instance.addMeetupListener(_onMeetup);
  }

  @override
  void dispose() {
    MultiplayerService.instance.removeListener(_onChanged);
    MultiplayerService.instance.removeMeetupListener(_onMeetup);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onMeetup(String userId, bool started) {
    if (!started) return;
    final p = MultiplayerService.instance.peerProfile(userId);
    HapticFeedback.mediumImpact();
    showAppSnackBar('🎉  ${p?.nickname ?? '친구'}와 만났어요!');
    MultiplayerService.instance
        .sendMessage('${p?.nickname ?? '친구'}와 만났어요', kind: 'meetup');
  }

  @override
  Widget build(BuildContext context) {
    return LoginRequiredGate(builder: _buildHubScaffold);
  }

  Widget _buildHubScaffold(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasProfile = MultiplayerService.instance.myProfile != null;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(
        title: 'Seoul Live',
        actions: [
          if (hasProfile)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MultiplayerSettingsView()),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: hasProfile ? _buildHub() : _buildOnboardProfile(),
      ),
    );
  }

  Widget _buildOnboardProfile() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C5CFF), Color(0xFF5CC8FF)],
              ),
            ),
            child:
                const Icon(Icons.public_rounded, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('친구와 함께 서울을 탐험하기',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('닉네임과 핀을 만들어 시작하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 28),
          AdaptiveGlassButton(
            label: '프로필 만들기',
            onPressed: () async {
              final p = await MultiplayerProfileEditSheet.show(context);
              if (p != null && mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHub() {
    final svc = MultiplayerService.instance;
    final me = svc.myProfile!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // #11 일시정지 중 — 상단에 명확한 배지.
        if (svc.seoulLivePaused) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.pause_circle_filled_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seoul Live 일시정지 중 — 위치/알림 차단, 채팅은 가능',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onTertiaryContainer),
                  ),
                ),
                TextButton(
                  onPressed: () => svc.setSeoulLivePaused(false),
                  child: const Text('재개'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        AdaptiveSectionCard(
          children: [
            _ProfileSummary(
              onEdit: () async {
                await MultiplayerProfileEditSheet.show(context);
                if (mounted) setState(() {});
              },
              nickname: me.nickname,
              pinColor: me.pinColor,
              pinEmoji: me.pinEmoji,
              visibility: me.visibility,
            ),
          ],
        ),
        const SizedBox(height: 16),

        AdaptiveSectionCard(
          children: [
            _HubItem(
              icon: Icons.meeting_room_rounded,
              title: '친구방',
              subtitle: svc.currentRoom == null
                  ? '새 방을 만들거나 코드로 입장'
                  : '입장 중 · 코드 ${svc.currentRoom!.inviteCode}',
              badge: svc.totalUnread > 0 ? svc.totalUnread.toString() : null,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RoomView())),
            ),
            const _HubDivider(),
            _HubItem(
              icon: Icons.people_alt_rounded,
              title: '친구',
              subtitle:
                  '${svc.acceptedFriends.length}명 · 신청 ${svc.incomingRequests.length}건',
              badge: svc.incomingRequests.isNotEmpty
                  ? svc.incomingRequests.length.toString()
                  : null,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FriendsView())),
            ),
            const _HubDivider(),
            _HubItem(
              icon: Icons.qr_code_rounded,
              title: '친구 코드',
              subtitle: '내 코드 ${svc.myProfile?.friendCode ?? '--------'} 공유 / 입력',
              onTap: () => FriendCodeShareSheet.show(context),
            ),
            const _HubDivider(),
            _HubItem(
              icon: Icons.groups_rounded,
              title: '친구 그룹',
              subtitle: '${svc.friendGroups.length}개 그룹',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GroupEditorView())),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Profile summary row ──────────────────────────────────────

class _ProfileSummary extends StatelessWidget {
  final String nickname;
  final String pinColor;
  final String pinEmoji;
  final String visibility;
  final VoidCallback onEdit;
  const _ProfileSummary({
    required this.nickname,
    required this.pinColor,
    required this.pinEmoji,
    required this.visibility,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = int.parse(pinColor.substring(1), radix: 16);
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF000000 | v)),
              alignment: Alignment.center,
              child: Text(pinEmoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nickname,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(_visibilityLabel(visibility),
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _visibilityLabel(String v) => switch (v) {
        'ghost' => '비공개 — 송신/수신 모두 X',
        'friends' => '친구방 — 같은 방 멤버에게만',
        'public' => '전체 공개 — 모든 Seoul Live 사용자',
        _ => v,
      };
}

class _HubItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;
  const _HubItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: cs.secondaryContainer,
              ),
              child: Icon(icon, color: cs.onSecondaryContainer, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cs.onError)),
              ),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _HubDivider extends StatelessWidget {
  const _HubDivider();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
          height: 0.5, thickness: 0.5, color: cs.outlineVariant.withValues(alpha: 0.5)),
    );
  }
}
