import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../services/place_search_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import 'chat_sheet.dart';
import 'peer_profile_card.dart';
import '../../widgets/app_snackbar.dart';

class RoomView extends StatefulWidget {
  const RoomView({super.key});

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    MultiplayerService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    MultiplayerService.instance.removeListener(_onChanged);
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await MultiplayerService.instance.createRoom();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = AppL10n.of(context).roomCodeRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await MultiplayerService.instance.joinRoomByCode(code);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _leave() {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.roomLeaveTitle,
      content: l.roomLeaveBody,
      confirmText: l.roomLeaveConfirm,
      isDestructive: true,
      onConfirm: () async {
        await MultiplayerService.instance.leaveCurrentRoom();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final room = MultiplayerService.instance.currentRoom;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(title: AppL10n.of(context).roomTitle),
      body: SafeArea(
        child: room == null ? _buildLobby() : _buildRoom(room),
      ),
    );
  }

  Widget _buildLobby() {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(l.roomDescription,
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(l.roomCapacityNote,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 24),

        AdaptiveGlassButton(
          label: _busy ? '...' : l.roomCreateButton,
          onPressed: _busy ? null : _create,
        ),

        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(l.roomCodeEntryTitle,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant)),
        ),
        AdaptiveTextField(
          controller: _codeCtrl,
          placeholder: 'ABCD23',
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        const SizedBox(height: 8),
        AdaptiveGlassButton(
          label: _busy ? '...' : l.roomJoinButton,
          onPressed: _busy ? null : _join,
        ),

        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_error!,
                style:
                    TextStyle(color: cs.onErrorContainer, fontSize: 13)),
          ),
        ],
      ],
    );
  }

  Widget _buildRoom(Room room) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final svc = MultiplayerService.instance;
    final members = svc.currentRoomMembers;
    final isOwner = svc.myId == room.ownerId;
    final remainingMin = room.expiresAt.difference(DateTime.now()).inMinutes;
    final expiringSoon = remainingMin <= 60 && remainingMin > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // G10: 만료 임박 경고.
        if (expiringSoon)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      color: cs.onErrorContainer, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.roomExpiresInMin(remainingMin),
                      style: TextStyle(
                          fontSize: 13, color: cs.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),

        AdaptiveSectionCard(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // G10: 룸 이름 (편집 가능, owner only).
                  Row(
                    children: [
                      Expanded(
                        child: Text(room.name ?? l.roomDefaultName,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface)),
                      ),
                      if (isOwner)
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          onPressed: () => _editRoomName(room),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(l.roomInviteCode,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(room.inviteCode,
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4)),
                      const Spacer(),
                      AdaptiveGlassIconButton(
                        icon: Icons.copy_rounded,
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: room.inviteCode));
                          showAppSnackBar(AppL10n.of(context).roomCodeCopied);
                        },
                      ),
                      const SizedBox(width: 6),
                      AdaptiveGlassIconButton(
                        icon: Icons.ios_share_rounded,
                        onPressed: () => _shareInviteLink(room),
                      ),
                      // G23: owner 만 코드 회전.
                      if (isOwner) ...[
                        const SizedBox(width: 6),
                        AdaptiveGlassIconButton(
                          icon: Icons.refresh_rounded,
                          onPressed: _rotateCode,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remainingMin >= 60
                        ? l.roomExpiresInHours(remainingMin ~/ 60)
                        : l.roomExpiresInMin(remainingMin),
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (room.hasDestination) ...[
          const SizedBox(height: 16),
          _DestinationBanner(room: room, isOwner: isOwner),
        ] else if (svc.activeProposal != null) ...[
          // 활성 투표 후보 — 멤버 전원에게 표시. 방장은 같이 취소 버튼.
          const SizedBox(height: 16),
          _ProposalBanner(
            proposal: svc.activeProposal!,
            isOwner: isOwner,
          ),
        ] else if (isOwner) ...[
          // 방장이고 목적지·후보 모두 없으면 주소 검색 카드 노출.
          const SizedBox(height: 16),
          _OwnerDestinationSetupCard(room: room),
        ],
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
              l.roomMembers(members.length, MultiplayerService.kRoomCapacity),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant)),
        ),
        AdaptiveSectionCard(
          children: [
            for (var i = 0; i < members.length; i++) ...[
              if (i > 0) const _MemberDivider(),
              Builder(builder: (_) {
                final uid = members[i];
                final p = svc.peerProfile(uid);
                final isMe = uid == svc.myId;
                final isMeeting = svc.activeMeetups.contains(uid);
                final loc = svc.peerLocations[uid];
                double? distM;
                if (room.hasDestination && loc != null && !loc.isOffline) {
                  distM = Geolocator.distanceBetween(
                    loc.lat, loc.lng,
                    room.destLat!, room.destLng!,
                  );
                }
                return _MemberRow(
                  profile: p,
                  fallbackId: uid,
                  isMe: isMe,
                  isMeeting: isMeeting,
                  distanceToDestM: distM,
                  showKick: isOwner && !isMe,
                  onKick: () => _confirmKick(uid, p?.nickname),
                  // #9 멤버 탭 → 프로필 카드 (거리/위치/액션).
                  onTap: isMe
                      ? null
                      : () => PeerProfileCard.show(context, uid),
                );
              }),
            ],
          ],
        ),

        const SizedBox(height: 20),
        AdaptiveGlassButton(
          label: svc.unreadCount(room.id) > 0
              ? l.roomChatOpenWithUnread(svc.unreadCount(room.id))
              : l.roomChatOpen,
          onPressed: () => ChatSheet.show(context),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: _leave,
            icon: const Icon(Icons.logout_rounded),
            label: Text(l.roomLeaveButton),
            style: TextButton.styleFrom(foregroundColor: cs.error),
          ),
        ),
      ],
    );
  }

  Future<void> _editRoomName(Room room) async {
    final ctrl = TextEditingController(text: room.name ?? '');
    String? newName;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        final l = AppL10n.of(context);
        final inset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, inset + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.roomEditNameTitle,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(l.roomEditNameBody,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),
              AdaptiveTextField(
                controller: ctrl,
                placeholder: l.roomEditNamePlaceholder,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              const SizedBox(height: 16),
              AdaptiveGlassButton(
                label: l.commonSave,
                onPressed: () {
                  newName = ctrl.text.trim();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
    if (newName == null || newName!.isEmpty) return;
    try {
      await MultiplayerService.instance.updateRoomName(newName!);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(AppL10n.of(context).roomGenericError(e.toString()));
    }
  }

  Future<void> _shareInviteLink(Room room) async {
    final l = AppL10n.of(context);
    final me = MultiplayerService.instance.myProfile?.nickname ?? l.dmDefaultPeer;
    final text = l.roomShareBody(me, room.inviteCode);
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: l.roomShareSubject,
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) showAppSnackBar(AppL10n.of(context).roomInviteTextCopied);
    }
  }

  Future<void> _rotateCode() async {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.roomRefreshCodeTitle,
      content: l.roomRefreshCodeBody,
      confirmText: l.roomRefreshCodeConfirm,
      onConfirm: () async {
        try {
          await MultiplayerService.instance.rotateInviteCode();
          if (!mounted) return;
          showAppSnackBar(AppL10n.of(context).roomCodeRefreshed);
        } catch (e) {
          if (!mounted) return;
          showAppSnackBar(AppL10n.of(context).roomGenericError(e.toString()));
        }
      },
    );
  }

  void _confirmKick(String userId, String? nickname) {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.roomKickTitle(nickname ?? l.roomKickFallbackName),
      content: l.roomKickBody,
      confirmText: l.roomKickConfirm,
      isDestructive: true,
      onConfirm: () async {
        try {
          await MultiplayerService.instance.kickMember(userId);
        } catch (e) {
          if (!mounted) return;
          showAppSnackBar(AppL10n.of(context).roomGenericError(e.toString()));
        }
      },
    );
  }
}

class _MemberRow extends StatelessWidget {
  final MultiplayerProfile? profile;
  final String fallbackId;
  final bool isMe;
  final bool isMeeting;
  final bool showKick;
  final VoidCallback? onKick;
  final VoidCallback? onTap;
  /// 방 목적지까지 직선거리 (m). null = 표시 안 함.
  final double? distanceToDestM;

  const _MemberRow({
    required this.profile,
    required this.fallbackId,
    required this.isMe,
    required this.isMeeting,
    this.showKick = false,
    this.onKick,
    this.onTap,
    this.distanceToDestM,
  });

  String _fmtDist(double m) {
    if (m < 1000) return '${m.round()}m';
    return '${(m / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final name = profile?.nickname ?? fallbackId.substring(0, 8);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
        children: [
          if (profile != null)
            _AvatarChip(profile: profile!)
          else
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.surfaceContainerHighest,
              child: Icon(Icons.person, size: 16, color: cs.onSurfaceVariant),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(isMe ? l.roomNameMe(name) : name,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ),
          if (distanceToDestM != null) ...[
            Icon(Icons.flag_rounded, size: 14, color: cs.primary),
            const SizedBox(width: 2),
            Text(_fmtDist(distanceToDestM!),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.primary)),
            const SizedBox(width: 8),
          ],
          if (isMeeting)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(l.roomMeetupBadge,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer)),
            ),
          if (showKick) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.person_remove_rounded,
                  size: 18, color: cs.error),
              onPressed: onKick,
              tooltip: l.roomKickTooltip,
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final MultiplayerProfile profile;
  const _AvatarChip({required this.profile});
  @override
  Widget build(BuildContext context) {
    final v = int.parse(profile.pinColor.substring(1), radix: 16);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Color(0xFF000000 | v)),
      alignment: Alignment.center,
      child: Text(profile.pinEmoji, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _MemberDivider extends StatelessWidget {
  const _MemberDivider();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 58),
      child: Divider(
          height: 0.5, thickness: 0.5, color: cs.outlineVariant.withValues(alpha: 0.5)),
    );
  }
}

/// 방 공통 목적지 배너 — 방장만 해제 가능. 비-방장에겐 close 버튼 숨김.
class _DestinationBanner extends StatelessWidget {
  final Room room;
  final bool isOwner;
  const _DestinationBanner({required this.room, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final svc = MultiplayerService.instance;
    final setBy = room.destSetBy != null
        ? svc.peerProfile(room.destSetBy!)?.nickname ?? l.roomUnknownUser
        : l.roomUnknownUser;
    return AdaptiveSurfaceCard(
      borderRadius: 14,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.flag_rounded, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.roomDestTitle(room.destName ?? l.roomDestDefault),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(l.roomDestSetBy(setBy),
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined, size: 20),
            tooltip: l.roomDestViewMap,
            onPressed: () {
              if (room.destLat == null || room.destLng == null) return;
              svc.requestMapJump(
                lat: room.destLat!,
                lng: room.destLng!,
                name: room.destName,
              );
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: l.roomDestClear,
              onPressed: () async {
                try {
                  await svc.clearRoomDestination();
                } catch (e) {
                  if (context.mounted) {
                    showAppSnackBar(
                        AppL10n.of(context).chatActionFailed(e.toString()));
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}

/// 방장 전용 — 목적지 없을 때 보이는 주소 검색 카드. 결과 카드마다 두 버튼:
/// [바로 확정] — set_room_destination 즉시 호출. [투표로 정하기] — proposal 생성.
class _OwnerDestinationSetupCard extends StatefulWidget {
  final Room room;
  const _OwnerDestinationSetupCard({required this.room});

  @override
  State<_OwnerDestinationSetupCard> createState() =>
      _OwnerDestinationSetupCardState();
}

class _OwnerDestinationSetupCardState
    extends State<_OwnerDestinationSetupCard> {
  final _ctrl = TextEditingController();
  bool _searching = false;
  List<PlaceSearchResult> _results = const [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _ctrl.text.trim();
    if (q.length < 2) return;
    setState(() => _searching = true);
    try {
      final res = await PlaceSearchService.instance.search(q);
      if (!mounted) return;
      setState(() => _results = res.take(5).toList());
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).chatActionFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _setNow(PlaceSearchResult r) async {
    try {
      await MultiplayerService.instance.setRoomDestination(
        name: r.name, lat: r.lat, lng: r.lng,
      );
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).chatRoomDestSet);
        setState(() {
          _ctrl.clear();
          _results = const [];
        });
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).chatActionFailed(e.toString()));
      }
    }
  }

  Future<void> _propose(PlaceSearchResult r) async {
    try {
      await MultiplayerService.instance.proposeRoomDestination(
        name: r.name, lat: r.lat, lng: r.lng, address: r.address,
      );
      if (mounted) {
        setState(() {
          _ctrl.clear();
          _results = const [];
        });
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).chatActionFailed(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final cs = Theme.of(context).colorScheme;
    return AdaptiveSurfaceCard(
      borderRadius: 14,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AdaptiveTextField(
                  controller: _ctrl,
                  placeholder: l.roomDestSearchHint,
                  onSubmitted: (_) => _runSearch(),
                ),
              ),
              const SizedBox(width: 8),
              AdaptiveGlassIconButton(
                icon: Icons.search_rounded,
                onPressed: _searching ? null : _runSearch,
              ),
            ],
          ),
          if (_searching) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l.roomDestSearchSearching,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ] else if (_results.isEmpty && _ctrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l.roomDestSearchEmpty,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ] else if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final r in _results) _ResultRow(
              result: r,
              onSetNow: () => _setNow(r),
              onPropose: () => _propose(r),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final PlaceSearchResult result;
  final VoidCallback onSetNow;
  final VoidCallback onPropose;
  const _ResultRow({
    required this.result,
    required this.onSetNow,
    required this.onPropose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          if (result.address.isNotEmpty)
            Text(
              result.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onSetNow,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    l.roomDestSetNow,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPropose,
                  icon: const Icon(Icons.how_to_vote_rounded, size: 16),
                  label: Text(
                    l.roomDestProposeVote,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 활성 후보 + 투표 현황. 멤버는 yes/no, 방장은 추가로 취소 가능.
class _ProposalBanner extends StatelessWidget {
  final DestinationProposal proposal;
  final bool isOwner;
  const _ProposalBanner({required this.proposal, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final svc = MultiplayerService.instance;
    final proposerName = svc.peerProfile(proposal.proposerId)?.nickname ??
        l.roomUnknownUser;
    final votes = svc.votesFor(proposal.id);
    final myVote = svc.myId != null ? votes[svc.myId!] : null;
    final yes = votes.values.where((v) => v).length;
    final no = votes.values.where((v) => !v).length;

    return AdaptiveSurfaceCard(
      borderRadius: 14,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.how_to_vote_rounded,
                    color: cs.tertiary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proposal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    if ((proposal.address ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(proposal.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant)),
                      ),
                    const SizedBox(height: 2),
                    Text(l.roomDestProposalBy(proposerName),
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: l.roomDestProposalCancel,
                  onPressed: () async {
                    try {
                      await svc.cancelRoomDestinationProposal(proposal.id);
                    } catch (e) {
                      if (context.mounted) {
                        showAppSnackBar(AppL10n.of(context)
                            .chatActionFailed(e.toString()));
                      }
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VoteButton(
                  label: l.roomDestVoteYes,
                  icon: Icons.thumb_up_rounded,
                  active: myVote == true,
                  onTap: () async {
                    try {
                      await svc.voteRoomDestination(proposal.id, true);
                    } catch (e) {
                      if (context.mounted) {
                        showAppSnackBar(AppL10n.of(context)
                            .chatActionFailed(e.toString()));
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _VoteButton(
                  label: l.roomDestVoteNo,
                  icon: Icons.thumb_down_rounded,
                  active: myVote == false,
                  onTap: () async {
                    try {
                      await svc.voteRoomDestination(proposal.id, false);
                    } catch (e) {
                      if (context.mounted) {
                        showAppSnackBar(AppL10n.of(context)
                            .chatActionFailed(e.toString()));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.roomDestProposalVoting,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              Text(l.roomDestProposalCounts(yes, no),
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

/// yes/no 투표 버튼 — active 일 땐 tonal, 아니면 outlined.
class _VoteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _VoteButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (active) {
      return FilledButton.tonalIcon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
