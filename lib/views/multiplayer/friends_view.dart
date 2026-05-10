import 'package:flutter/material.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';
import 'friend_code_share.dart';
import 'friend_groups_view.dart';
import 'report_sheet.dart';

class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  final _searchCtrl = TextEditingController();
  List<MultiplayerProfile> _searchResults = [];
  bool _searching = false;
  bool _searchedOnce = false;
  String _lastQuery = '';
  /// 신청 보낸 user_id — 검색 결과에 즉시 반영 ("신청됨" 상태).
  final Set<String> _justRequestedIds = {};

  @override
  void initState() {
    super.initState();
    MultiplayerService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    MultiplayerService.instance.removeListener(_onChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// userId → cooldown 만료 시각 (없으면 null).
  final Map<String, DateTime?> _cooldowns = {};

  Future<void> _runSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchedOnce = false;
        _lastQuery = '';
      });
      return;
    }
    setState(() {
      _searching = true;
      _lastQuery = query;
    });
    final res = await MultiplayerService.instance.searchByNickname(query);
    if (!mounted) return;
    // 각 결과의 cooldown 일괄 조회 (병렬).
    final cooldownEntries = await Future.wait(res.map((p) async {
      final t = await MultiplayerService.instance
          .friendRequestCooldownUntil(p.userId);
      return MapEntry(p.userId, t);
    }));
    if (!mounted) return;
    setState(() {
      _searchResults = res;
      _cooldowns
        ..clear()
        ..addEntries(cooldownEntries);
      _searching = false;
      _searchedOnce = true;
    });
  }

  /// 검색 결과의 사용자가 현재 어떤 친구 상태인지 판단.
  _FriendState _stateFor(String userId) {
    final svc = MultiplayerService.instance;
    final me = svc.myId ?? '';
    final f = svc.friendships
        .where((x) =>
            (x.userA == me && x.userB == userId) ||
            (x.userB == me && x.userA == userId))
        .firstOrNull;
    if (f == null) {
      if (_justRequestedIds.contains(userId)) return _FriendState.requested;
      return _FriendState.none;
    }
    if (f.status == 'accepted') return _FriendState.friend;
    if (f.isIncoming(me)) return _FriendState.incoming;
    return _FriendState.requested; // pending, 내가 보낸 것.
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = MultiplayerService.instance;
    final incoming = svc.incomingRequests;
    final accepted = svc.acceptedFriends;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(
        title: '친구',
        actions: [
          IconButton(
            icon: const Icon(Icons.group_outlined),
            tooltip: '친구 그룹',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FriendGroupsView()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: '친구 코드',
            onPressed: () => FriendCodeShareSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SectionLabel(text: '닉네임으로 친구 추가'),
            AdaptiveTextField(
              controller: _searchCtrl,
              placeholder: '닉네임 입력 후 검색',
              onSubmitted: _runSearch,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            const SizedBox(height: 8),
            AdaptiveGlassButton(
              label: _searching ? '검색 중...' : '검색',
              onPressed: _searching ? null : () => _runSearch(_searchCtrl.text),
            ),
            // 검색 결과 / 빈 상태.
            if (_searching) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ] else if (_searchedOnce && _searchResults.isEmpty) ...[
              const SizedBox(height: 24),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 36, color: cs.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text('"$_lastQuery" 와(과) 일치하는 사용자가 없어요',
                          style:
                              TextStyle(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('닉네임은 정확히 일치해야 해요. 친구코드(8자리)도 시도해보세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ] else if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              AdaptiveSectionCard(
                children: [
                  for (var i = 0; i < _searchResults.length; i++) ...[
                    if (i > 0) const _RowDivider(),
                    _PeerRow(
                      profile: _searchResults[i],
                      trailing: _buildSearchTrailing(_searchResults[i]),
                    ),
                  ],
                ],
              ),
            ],

            if (incoming.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionLabel(text: '받은 친구 신청 (${incoming.length})'),
              AdaptiveSectionCard(
                children: [
                  for (var i = 0; i < incoming.length; i++) ...[
                    if (i > 0) const _RowDivider(),
                    Builder(builder: (_) {
                      final f = incoming[i];
                      final other = f.otherSide(svc.myId ?? '');
                      final p = svc.peerProfile(other);
                      return _PeerRow(
                        profile: p,
                        fallbackId: other,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => svc.acceptFriendRequest(f),
                              child: const Text('수락'),
                            ),
                            TextButton(
                              onPressed: () => svc.removeFriend(other),
                              style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.error),
                              child: const Text('거절'),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 24),
            _SectionLabel(text: '내 친구 (${accepted.length})'),
            if (accepted.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('아직 친구가 없어요. 닉네임으로 추가해보세요.',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ),
              )
            else
              AdaptiveSectionCard(
                children: [
                  for (var i = 0; i < accepted.length; i++) ...[
                    if (i > 0) const _RowDivider(),
                    Builder(builder: (_) {
                      final f = accepted[i];
                      final other = f.otherSide(svc.myId ?? '');
                      final p = svc.peerProfile(other);
                      return _PeerRow(
                        profile: p,
                        fallbackId: other,
                        trailing: IconButton(
                          icon: const Icon(Icons.more_horiz_rounded),
                          onPressed: () => _showFriendMenu(other, p),
                        ),
                      );
                    }),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTrailing(MultiplayerProfile p) {
    final cs = Theme.of(context).colorScheme;
    final state = _stateFor(p.userId);
    // #19 cooldown 이 있고 친구 아님 — "N일 후 재신청" 표시 (신청 버튼 비활성).
    final cooldown = _cooldowns[p.userId];
    if (state == _FriendState.none && cooldown != null) {
      final hoursLeft = cooldown.difference(DateTime.now()).inHours;
      final daysLeft = (hoursLeft / 24).ceil();
      return Tooltip(
        message: '거절당한 신청은 7일 후 다시 보낼 수 있어요',
        child: Text(
          daysLeft >= 1 ? '$daysLeft일 후 재신청' : '$hoursLeft시간 후',
          style: TextStyle(
              fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        ),
      );
    }
    return switch (state) {
      _FriendState.friend => Text('친구',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.primary)),
      _FriendState.requested => Text('신청됨',
          style: TextStyle(
              fontSize: 12, color: cs.onSurfaceVariant)),
      _FriendState.incoming => TextButton(
          onPressed: () {
            final svc = MultiplayerService.instance;
            final f = svc.friendships.firstWhere(
              (x) => x.otherSide(svc.myId ?? '') == p.userId,
            );
            svc.acceptFriendRequest(f);
          },
          child: const Text('수락'),
        ),
      _FriendState.none => TextButton(
          onPressed: () => _sendRequest(p),
          child: const Text('신청'),
        ),
    };
  }

  Future<void> _sendRequest(MultiplayerProfile p) async {
    setState(() => _justRequestedIds.add(p.userId));
    try {
      await MultiplayerService.instance.sendFriendRequest(p.userId);
      showAppSnackBar(
          '${p.nickname} 님에게 친구 신청 — 수락하면 푸시 알림이 와요',
          duration: const Duration(seconds: 4));
    } catch (e) {
      if (mounted) setState(() => _justRequestedIds.remove(p.userId));
      showAppSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showFriendMenu(String userId, MultiplayerProfile? p) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: const Text('친구 해제'),
              onTap: () async {
                Navigator.pop(context);
                await MultiplayerService.instance.removeFriend(userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('신고',
                  style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                ReportSheet.showForUser(context, userId,
                    nickname: p?.nickname);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Colors.red),
              title: const Text('차단', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                showAdaptiveConfirmDialog(
                  context: context,
                  title: '${p?.nickname ?? '이 사용자'} 차단',
                  content: '차단하면 같은 방 입장이 불가능하고 메시지도 보이지 않습니다.',
                  confirmText: '차단',
                  isDestructive: true,
                  onConfirm: () =>
                      MultiplayerService.instance.blockUser(userId),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _FriendState { none, requested, incoming, friend }

// ─── Reusable rows ────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant)),
    );
  }
}

class _PeerRow extends StatelessWidget {
  final MultiplayerProfile? profile;
  final String? fallbackId;
  final Widget trailing;
  const _PeerRow({this.profile, this.fallbackId, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = profile?.nickname ?? (fallbackId?.substring(0, 8) ?? '알 수 없음');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          _Avatar(profile: profile),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final MultiplayerProfile? profile;
  const _Avatar({this.profile});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (profile == null) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: cs.surfaceContainerHighest,
        child: Icon(Icons.person, size: 18, color: cs.onSurfaceVariant),
      );
    }
    final v = int.parse(profile!.pinColor.substring(1), radix: 16);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Color(0xFF000000 | v)),
      alignment: Alignment.center,
      child: Text(profile!.pinEmoji, style: const TextStyle(fontSize: 18)),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Divider(
          height: 0.5, thickness: 0.5, color: cs.outlineVariant.withValues(alpha: 0.5)),
    );
  }
}
