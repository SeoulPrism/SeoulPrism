import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';
import 'dm_thread_view.dart';
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
    final l = AppL10n.of(context);
    final svc = MultiplayerService.instance;
    final incoming = svc.incomingRequests;
    final accepted = svc.acceptedFriends;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(
        title: l.hubFriendsTitle,
        actions: [
          AdaptiveAppBarAction(
            icon: Icons.group_outlined,
            tooltip: l.friendsGroupTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FriendGroupsView()),
            ),
          ),
          AdaptiveAppBarAction(
            icon: Icons.qr_code_rounded,
            tooltip: l.friendsCodeTooltip,
            onPressed: () => FriendCodeShareSheet.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SectionLabel(text: l.friendsAddByNickname),
            AdaptiveTextField(
              controller: _searchCtrl,
              placeholder: l.friendsSearchPlaceholder,
              onSubmitted: _runSearch,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            const SizedBox(height: 8),
            AdaptiveGlassButton(
              label: _searching ? l.friendsSearching : l.friendsSearch,
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
                      Text(l.friendsNotFound(_lastQuery),
                          style:
                              TextStyle(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(l.friendsSearchHint,
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
              _SectionLabel(text: l.friendsReceivedRequests(incoming.length)),
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
                              child: Text(l.friendsAccept),
                            ),
                            TextButton(
                              onPressed: () => svc.removeFriend(other),
                              style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.error),
                              child: Text(l.friendsReject),
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
            _SuggestedFriendsSection(),
            _SectionLabel(text: l.friendsMyFriends(accepted.length)),
            if (accepted.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(l.friendsEmpty,
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 20),
                              tooltip: 'DM',
                              onPressed: () => _openDm(other),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_horiz_rounded),
                              onPressed: () => _showFriendMenu(other, p),
                            ),
                          ],
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
    final l = AppL10n.of(context);
    final state = _stateFor(p.userId);
    // #19 cooldown 이 있고 친구 아님 — "N일 후 재신청" 표시 (신청 버튼 비활성).
    final cooldown = _cooldowns[p.userId];
    if (state == _FriendState.none && cooldown != null) {
      final hoursLeft = cooldown.difference(DateTime.now()).inHours;
      final daysLeft = (hoursLeft / 24).ceil();
      return Tooltip(
        message: l.friendsCooldownTooltip,
        child: Text(
          daysLeft >= 1
              ? l.friendsCooldownDays(daysLeft)
              : l.friendsCooldownHours(hoursLeft),
          style: TextStyle(
              fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        ),
      );
    }
    return switch (state) {
      _FriendState.friend => Text(l.friendsBadgeFriend,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.primary)),
      _FriendState.requested => Text(l.friendsBadgeRequested,
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
          child: Text(l.friendsAccept),
        ),
      _FriendState.none => TextButton(
          onPressed: () => _sendRequest(p),
          child: Text(l.friendsApply),
        ),
    };
  }

  Future<void> _sendRequest(MultiplayerProfile p) async {
    setState(() => _justRequestedIds.add(p.userId));
    try {
      await MultiplayerService.instance.sendFriendRequest(p.userId);
      if (mounted) {
        showAppSnackBar(
            AppL10n.of(context).friendsSendingRequestHint(p.nickname),
            duration: const Duration(seconds: 4));
      }
    } catch (e) {
      if (mounted) setState(() => _justRequestedIds.remove(p.userId));
      showAppSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openDm(String otherUserId) async {
    try {
      final tid =
          await MultiplayerService.instance.ensureDmThread(otherUserId);
      if (tid == null || !mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DmThreadView(threadId: tid, otherUserId: otherUserId),
      ));
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).friendsDmStartFailed(e.toString()));
      }
    }
  }

  void _showFriendMenu(String userId, MultiplayerProfile? p) {
    final l = AppL10n.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: Text(l.friendsUnfriend),
              onTap: () async {
                Navigator.pop(context);
                await MultiplayerService.instance.removeFriend(userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: Text(l.friendsReport,
                  style: const TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                ReportSheet.showForUser(context, userId,
                    nickname: p?.nickname);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Colors.red),
              title: Text(l.friendsBlock,
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                showAdaptiveConfirmDialog(
                  context: context,
                  title: p?.nickname != null
                      ? l.friendsBlockDialogTitle(p!.nickname)
                      : l.friendsBlockDialogTitleFallback,
                  content: l.friendsBlockDialogBody,
                  confirmText: l.friendsBlockConfirm,
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
    final name = profile?.nickname ??
        (fallbackId?.substring(0, 8) ?? AppL10n.of(context).friendsUnknown);
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

/// 친구 추천 — 친구의 친구 mutual count 순. 처음엔 lazy load.
class _SuggestedFriendsSection extends StatefulWidget {
  @override
  State<_SuggestedFriendsSection> createState() =>
      _SuggestedFriendsSectionState();
}

class _SuggestedFriendsSectionState extends State<_SuggestedFriendsSection> {
  List<({MultiplayerProfile profile, int mutualCount})>? _items;
  bool _loading = false;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res =
        await MultiplayerService.instance.loadSuggestedFriends(limit: 8);
    if (!mounted) return;
    setState(() {
      _items = res;
      _loading = false;
    });
  }

  Future<void> _add(MultiplayerProfile p) async {
    setState(() => _busy.add(p.userId));
    try {
      await MultiplayerService.instance.sendFriendRequest(p.userId);
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).friendsRequestSent(p.nickname));
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).friendsFailure(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(p.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = _items;
    if (items == null && _loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
      );
    }
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(text: AppL10n.of(context).friendsSuggestionsTitle),
        AdaptiveSectionCard(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const _RowDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(int.parse(
                            'FF${items[i].profile.pinColor.substring(1)}',
                            radix: 16)),
                      ),
                      alignment: Alignment.center,
                      child: Text(items[i].profile.pinEmoji,
                          style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].profile.nickname,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(AppL10n.of(context).friendsMutualCount(items[i].mutualCount),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    _busy.contains(items[i].profile.userId)
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : TextButton.icon(
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: Text(AppL10n.of(context).friendsAddShort),
                            onPressed: () => _add(items[i].profile),
                          ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
