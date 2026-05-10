import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';
import 'peer_profile_card.dart';
import 'report_sheet.dart';

class ChatSheet extends StatefulWidget {
  const ChatSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => const ChatSheet(),
      ),
    );
  }

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  static const _quickEmojis = ['👋', '😂', '🔥', '👍', '❤️', '🥲', '🎉', '📍'];

  @override
  void initState() {
    super.initState();
    MultiplayerService.instance.addListener(_onChanged);
    // G13: 채팅 열림 → 미확인 0.
    MultiplayerService.instance.markCurrentRoomRead();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    MultiplayerService.instance.removeListener(_onChanged);
    _scroll.removeListener(_onScroll);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    // 새 realtime 메시지가 도착해도 사용자가 위에서 옛 메시지 보고 있으면
    // 강제로 바닥으로 끌어내리지 않음.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final pos = _scroll.position;
      if (pos.pixels >= pos.maxScrollExtent - 80) {
        _scroll.jumpTo(pos.maxScrollExtent);
      }
    });
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels < 60) {
      _maybeLoadMore();
    }
  }

  Future<void> _maybeLoadMore() async {
    final svc = MultiplayerService.instance;
    if (!svc.hasMoreMessages || svc.loadingMoreMessages) return;
    final oldMax = _scroll.position.maxScrollExtent;
    final oldPx = _scroll.position.pixels;
    await svc.loadMoreMessages();
    // 옛 메시지가 위쪽에 prepend 됐으니 사용자가 보던 위치를 유지.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final delta = _scroll.position.maxScrollExtent - oldMax;
      if (delta > 0) _scroll.jumpTo(oldPx + delta);
    });
  }

  Future<void> _send({String? body, String kind = 'text'}) async {
    final text = body ?? _ctrl.text;
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    await MultiplayerService.instance.sendMessage(text, kind: kind);
  }

  Widget _placeAction(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: cs.onSurface),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalDirections(
      String name, double lat, double lng) async {
    // iOS: Apple Maps 우선, 없으면 Google Maps
    // Android: Google Maps geo intent
    final encoded = Uri.encodeComponent(name);
    final urls = <Uri>[
      // iOS Apple Maps
      Uri.parse('http://maps.apple.com/?daddr=$lat,$lng&q=$encoded'),
      // Google Maps universal
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$encoded'),
    ];
    for (final u in urls) {
      try {
        if (await canLaunchUrl(u)) {
          await launchUrl(u, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
    if (mounted) showAppSnackBar('지도 앱을 열 수 없어요');
  }

  Future<void> _shareMyLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await MultiplayerService.instance.sharePlaceToRoom(
        name: '내 위치',
        lat: pos.latitude,
        lng: pos.longitude,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar('위치를 가져올 수 없어요');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = MultiplayerService.instance;
    final messages = svc.messages;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${svc.currentRoom?.name ?? '친구방'} 채팅',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const Spacer(),
                Text('${svc.currentRoomMembers.length}명',
                    style:
                        TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(
                height: 0.5,
                thickness: 0.5,
                color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text('첫 메시지를 보내보세요',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    // index 0 = 더 불러오기 인디케이터, 그 외는 메시지.
                    itemCount: messages.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) return _loadMoreHeader(svc);
                      return _bubble(messages[i - 1]);
                    },
                  ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickEmojis.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final e = _quickEmojis[i];
                return GestureDetector(
                  onTap: () => _send(body: e, kind: 'emoji'),
                  child: Container(
                    width: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                AdaptiveGlassIconButton(
                  icon: Icons.place_outlined,
                  onPressed: _shareMyLocation,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AdaptiveTextField(
                    controller: _ctrl,
                    placeholder: '메시지 입력',
                    onSubmitted: (_) => _send(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                AdaptiveGlassIconButton(
                  icon: Icons.send_rounded,
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeCard(RoomMessage m, MultiplayerProfile? p, bool isMe) {
    final cs = Theme.of(context).colorScheme;
    final parts = m.body.split('|');
    if (parts.length < 3) {
      // 형식 깨진 메시지 — 그냥 텍스트로 fallback.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(m.body,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
      );
    }
    final name = parts[0];
    final lat = double.tryParse(parts[1]);
    final lng = double.tryParse(parts[2]);
    if (lat == null || lng == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[_miniAvatar(p), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxWidth: 260),
              decoration: BoxDecoration(
                color: isMe ? cs.primaryContainer : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                    width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.place_rounded,
                            color: cs.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isMe
                                    ? cs.onPrimaryContainer
                                    : cs.onSurface)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _placeAction(
                          icon: Icons.map_outlined,
                          label: '지도',
                          onTap: () {
                            MultiplayerService.instance.requestMapJump(
                                lat: lat, lng: lng, name: name);
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _placeAction(
                          icon: Icons.directions_outlined,
                          label: '길찾기',
                          onTap: () => _openExternalDirections(name, lat, lng),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadMoreHeader(MultiplayerService svc) {
    final cs = Theme.of(context).colorScheme;
    if (svc.loadingMoreMessages) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!svc.hasMoreMessages) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text('대화 시작',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  Widget _bubble(RoomMessage m) {
    final cs = Theme.of(context).colorScheme;
    final svc = MultiplayerService.instance;
    final isMe = m.userId == svc.myId;
    final p = svc.peerProfile(m.userId);
    final isMeetup = m.kind == 'meetup' || m.kind == 'system';

    if (m.kind == 'place') return _placeCard(m, p, isMe);

    if (isMeetup) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(m.body,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
        ),
      );
    }

    final isEmojiOnly = m.kind == 'emoji';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        // G2: 길게 누르면 신고 옵션 (본인 메시지는 제외).
        onLongPress: isMe ? null : () => _showMessageMenu(m, p?.nickname),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _miniAvatar(p),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      // #8 닉네임 탭 → peer 프로필 카드 (친구 신청 가능).
                      child: GestureDetector(
                        onTap: () => PeerProfileCard.show(context, m.userId),
                        child: Text(p?.nickname ?? '',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  Container(
                    padding: isEmojiOnly
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                    decoration: isEmojiOnly
                        ? null
                        : BoxDecoration(
                            color: isMe
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                    child: Text(
                      m.body,
                      style: TextStyle(
                          fontSize: isEmojiOnly ? 36 : 14,
                          color: isMe ? cs.onPrimaryContainer : cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageMenu(RoomMessage m, String? senderNickname) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.red),
              title: const Text('이 메시지 신고',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ReportSheet.showForMessage(context, m.id, preview: m.body);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: Text('${senderNickname ?? '사용자'} 차단'),
              onTap: () {
                Navigator.pop(context);
                showAdaptiveConfirmDialog(
                  context: context,
                  title: '${senderNickname ?? '사용자'} 차단',
                  content: '차단하면 같은 방에서 즉시 강퇴되고 메시지도 보이지 않아요.',
                  confirmText: '차단',
                  isDestructive: true,
                  onConfirm: () =>
                      MultiplayerService.instance.blockUser(m.userId),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniAvatar(MultiplayerProfile? p) {
    final cs = Theme.of(context).colorScheme;
    if (p == null) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: cs.surfaceContainerHighest,
        child: Icon(Icons.person, size: 14, color: cs.onSurfaceVariant),
      );
    }
    final v = int.parse(p.pinColor.substring(1), radix: 16);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Color(0xFF000000 | v)),
      alignment: Alignment.center,
      child: Text(p.pinEmoji, style: const TextStyle(fontSize: 14)),
    );
  }
}
