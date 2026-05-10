import 'package:flutter/material.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    MultiplayerService.instance.removeListener(_onChanged);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  Future<void> _send({String? body, String kind = 'text'}) async {
    final text = body ?? _ctrl.text;
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    await MultiplayerService.instance.sendMessage(text, kind: kind);
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
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _bubble(messages[i]),
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

  Widget _bubble(RoomMessage m) {
    final cs = Theme.of(context).colorScheme;
    final svc = MultiplayerService.instance;
    final isMe = m.userId == svc.myId;
    final p = svc.peerProfile(m.userId);
    final isMeetup = m.kind == 'meetup' || m.kind == 'system';

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
                      child: Text(p?.nickname ?? '',
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
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
