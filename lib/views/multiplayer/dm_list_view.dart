import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import 'dm_thread_view.dart';

/// 친구별 1:1 DM 리스트.
class DmListView extends StatefulWidget {
  const DmListView({super.key});

  @override
  State<DmListView> createState() => _DmListViewState();
}

class _DmListViewState extends State<DmListView> {
  bool _loading = true;
  List<DmThreadSummary> _threads = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final svc = MultiplayerService.instance;
    final t = await svc.loadDmList();
    // 프로필 캐시 미스 (deleted friend, 동기화 race) 보강.
    for (final th in t) {
      if (svc.peerProfile(th.otherUserId) == null) {
        await svc.fetchPeerProfile(th.otherUserId);
      }
    }
    if (!mounted) return;
    setState(() {
      _threads = t;
      _loading = false;
    });
  }

  String _ago(BuildContext ctx, DateTime t) {
    final l = AppL10n.of(ctx);
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return l.dmListAgoJust;
    if (d.inMinutes < 60) return l.dmListAgoMin(d.inMinutes);
    if (d.inHours < 24) return l.dmListAgoHour(d.inHours);
    return l.dmListAgoDay(d.inDays);
  }

  String _previewBody(BuildContext ctx, String? body, String? kind) {
    final l = AppL10n.of(ctx);
    if (kind == 'voice') return l.dmListKindVoice;
    if (kind == 'image') return l.dmListKindImage;
    if (kind == 'place') return l.dmListKindPlace;
    if (kind == 'spotify') return l.dmListKindSpotify;
    if (kind == 'emoji') return body ?? '';
    return body ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = MultiplayerService.instance;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AdaptiveAppBar(title: 'DM'),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _threads.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 48, color: cs.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(AppL10n.of(context).dmListEmpty,
                              style: TextStyle(color: cs.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(AppL10n.of(context).dmListEmptyHint,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _threads.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final t = _threads[i];
                        final p = svc.peerProfile(t.otherUserId);
                        return AdaptiveSurfaceCard(
                          borderRadius: 14,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p == null
                                    ? cs.surfaceContainerHighest
                                    : Color(int.parse(
                                        'FF${p.pinColor.substring(1)}',
                                        radix: 16)),
                              ),
                              alignment: Alignment.center,
                              child: Text(p?.pinEmoji ?? '👤',
                                  style: const TextStyle(fontSize: 18)),
                            ),
                            title: Text(p?.nickname ?? t.otherUserId.substring(0, 6),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              _previewBody(context, t.lastBody, t.lastKind),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_ago(context, t.lastMessageAt),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: cs.onSurfaceVariant)),
                                if (t.unreadCount > 0) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                        t.unreadCount > 99
                                            ? '99+'
                                            : '${t.unreadCount}',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: cs.onPrimary)),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DmThreadView(
                                    threadId: t.threadId,
                                    otherUserId: t.otherUserId,
                                  ),
                                ),
                              );
                              if (mounted) _load();
                            },
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
