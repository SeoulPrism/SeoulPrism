import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
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
      setState(() => _error = '6자리 코드를 입력해주세요.');
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
    showAdaptiveConfirmDialog(
      context: context,
      title: '방 나가기',
      content: '나가면 위치 공유와 채팅이 종료됩니다.',
      confirmText: '나가기',
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
      appBar: const AdaptiveAppBar(title: '친구방'),
      body: SafeArea(
        child: room == null ? _buildLobby() : _buildRoom(room),
      ),
    );
  }

  Widget _buildLobby() {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('실시간으로 친구와 위치/채팅을 공유합니다.',
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text('방은 24시간 후 자동 만료, 정원 8명입니다.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 24),

        AdaptiveGlassButton(
          label: _busy ? '...' : '새 방 만들기',
          onPressed: _busy ? null : _create,
        ),

        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('초대 코드로 입장 (6자리)',
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
          label: _busy ? '...' : '입장',
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
                      '$remainingMin분 후 방이 만료돼요',
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
                        child: Text(room.name ?? '이름 없는 친구방',
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
                  Text('초대 코드',
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
                          showAppSnackBar('코드 복사됨');
                        },
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
                        ? '${remainingMin ~/ 60}시간 후 만료'
                        : '$remainingMin분 후 만료',
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
          _DestinationBanner(room: room),
        ],
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
              '멤버 (${members.length}/${MultiplayerService.kRoomCapacity})',
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
                return _MemberRow(
                  profile: p,
                  fallbackId: uid,
                  isMe: isMe,
                  isMeeting: isMeeting,
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
              ? '채팅 열기 (${svc.unreadCount(room.id)})'
              : '채팅 열기',
          onPressed: () => ChatSheet.show(context),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: _leave,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('방 나가기'),
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
        final inset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, inset + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('방 이름',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              AdaptiveTextField(
                controller: ctrl,
                placeholder: '예: 광화문 모임',
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              const SizedBox(height: 16),
              AdaptiveGlassButton(
                label: '저장',
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
      showAppSnackBar('실패: $e');
    }
  }

  Future<void> _rotateCode() async {
    showAdaptiveConfirmDialog(
      context: context,
      title: '초대 코드 갱신',
      content: '기존 코드는 즉시 무효화됩니다. 계속할까요?',
      confirmText: '갱신',
      onConfirm: () async {
        try {
          await MultiplayerService.instance.rotateInviteCode();
          if (!mounted) return;
          showAppSnackBar('새 코드로 갱신됐어요');
        } catch (e) {
          if (!mounted) return;
          showAppSnackBar('실패: $e');
        }
      },
    );
  }

  void _confirmKick(String userId, String? nickname) {
    showAdaptiveConfirmDialog(
      context: context,
      title: '${nickname ?? '멤버'} 강퇴',
      content: '강퇴하면 즉시 방에서 내보내져요.',
      confirmText: '강퇴',
      isDestructive: true,
      onConfirm: () async {
        try {
          await MultiplayerService.instance.kickMember(userId);
        } catch (e) {
          if (!mounted) return;
          showAppSnackBar('실패: $e');
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

  const _MemberRow({
    required this.profile,
    required this.fallbackId,
    required this.isMe,
    required this.isMeeting,
    this.showKick = false,
    this.onKick,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            child: Text('$name${isMe ? ' (나)' : ''}',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ),
          if (isMeeting)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('만남',
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
              tooltip: '강퇴',
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

/// 방 공통 목적지 배너 — 누구든 해제 가능 (프로토타입; 추후 권한 체크 가능).
class _DestinationBanner extends StatelessWidget {
  final Room room;
  const _DestinationBanner({required this.room});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = MultiplayerService.instance;
    final setBy = room.destSetBy != null
        ? svc.peerProfile(room.destSetBy!)?.nickname ?? '누군가'
        : '누군가';
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
                Text('🎯 같이 가기 — ${room.destName ?? '목적지'}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('$setBy 님이 설정',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined, size: 20),
            tooltip: '지도에서 보기',
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
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: '목적지 해제',
            onPressed: () async {
              try {
                await svc.clearRoomDestination();
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }
}
