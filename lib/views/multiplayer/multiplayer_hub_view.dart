import 'package:flutter/material.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import 'activity_dashboard_view.dart';
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
        if (svc.myScore != null) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ActivityDashboardView())),
            child: _ScoreCard(score: svc.myScore!),
          ),
        ],
        if (svc.meetupHistory.isNotEmpty) ...[
          const SizedBox(height: 16),
          _MeetupHistorySection(history: svc.meetupHistory),
        ],
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

class _ScoreCard extends StatelessWidget {
  final UserScore score;
  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AdaptiveSectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 6),
              const Text('내 활동',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${score.totalPoints}p',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: cs.primary)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: '만남', value: score.meetupCount.toString()),
              _Stat(label: '친구', value: score.friendCount.toString()),
              _Stat(
                  label: '연속',
                  value: '${score.currentStreakDays}일',
                  hint: score.longestStreakDays > score.currentStreakDays
                      ? '최고 ${score.longestStreakDays}'
                      : null),
            ],
          ),
        ),
        if (score.badges.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: score.badges
                  .map((c) {
                    final m = BadgeMeta.lookup(c);
                    if (m == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(m.emoji,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(m.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onPrimaryContainer)),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text('첫 친구나 첫 만남으로 뱃지를 모아보세요',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  const _Stat({required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        if (hint != null)
          Text(hint!,
              style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _MeetupHistorySection extends StatelessWidget {
  final List<({String userId, DateTime at})> history;
  const _MeetupHistorySection({required this.history});

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return '방금';
    if (d.inMinutes < 60) return '${d.inMinutes}분 전';
    if (d.inHours < 24) return '${d.inHours}시간 전';
    return '${d.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = MultiplayerService.instance;
    final shown = history.take(5).toList();
    return AdaptiveSectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Row(
            children: [
              const Text('🎉 최근 만남',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${history.length}회',
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        for (final m in shown)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Text(svc.peerProfile(m.userId)?.pinEmoji ?? '📍',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    svc.peerProfile(m.userId)?.nickname ??
                        m.userId.substring(0, 6),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(_ago(m.at),
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
