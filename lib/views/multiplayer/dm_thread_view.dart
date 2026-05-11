import 'package:flutter/material.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';

/// 친구별 1:1 채팅 화면.
class DmThreadView extends StatefulWidget {
  final String threadId;
  final String otherUserId;
  const DmThreadView({
    super.key,
    required this.threadId,
    required this.otherUserId,
  });

  @override
  State<DmThreadView> createState() => _DmThreadViewState();
}

class _DmThreadViewState extends State<DmThreadView> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<DmMessage> _msgs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    MultiplayerService.instance.subscribeDm(widget.threadId, _onNew);
  }

  @override
  void dispose() {
    MultiplayerService.instance.unsubscribeDm(widget.threadId);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final msgs =
          await MultiplayerService.instance.loadDmMessages(widget.threadId);
      if (!mounted) return;
      setState(() {
        _msgs = msgs;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollBottom());
      MultiplayerService.instance.markDmRead(widget.threadId);
    } catch (e) {
      if (!mounted) return;
      // RLS / 네트워크 / 권한 거부 — 명시적 안내 후 빠져나감.
      showAppSnackBar('대화에 접근할 수 없어요');
      Navigator.of(context).pop();
    }
  }

  void _onNew(DmMessage m) {
    if (!mounted) return;
    setState(() => _msgs.add(m));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 80) {
          _scrollBottom();
        }
      }
    });
    if (m.senderId != MultiplayerService.instance.myId) {
      MultiplayerService.instance.markDmRead(widget.threadId);
    }
  }

  void _scrollBottom() {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    try {
      await MultiplayerService.instance.sendDm(widget.threadId, t);
    } catch (e) {
      showAppSnackBar('전송 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = MultiplayerService.instance;
    final p = svc.peerProfile(widget.otherUserId);
    final myId = svc.myId;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(title: p?.nickname ?? '친구'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _msgs.isEmpty
                      ? Center(
                          child: Text('첫 메시지를 보내보세요',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _msgs.length,
                          itemBuilder: (_, i) {
                            final m = _msgs[i];
                            final isMe = m.senderId == myId;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisAlignment: isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? cs.primaryContainer
                                            : cs.surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: Text(m.body,
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: isMe
                                                  ? cs.onPrimaryContainer
                                                  : cs.onSurface)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AdaptiveTextField(
                      controller: _ctrl,
                      placeholder: '메시지',
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
      ),
    );
  }
}
