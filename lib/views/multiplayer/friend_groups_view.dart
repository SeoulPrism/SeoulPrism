import 'package:flutter/material.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';

/// 친구 그룹 관리 — 생성/삭제/멤버 토글.
/// 향후: 그룹별 visibility filter (DB RLS 작업 필요).
class FriendGroupsView extends StatefulWidget {
  const FriendGroupsView({super.key});

  @override
  State<FriendGroupsView> createState() => _FriendGroupsViewState();
}

class _FriendGroupsViewState extends State<FriendGroupsView> {
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

  Future<void> _createGroup() async {
    final ctrl = TextEditingController();
    String emoji = '👥';
    final result = await showDialog<({String name, String emoji})?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return AlertDialog(
            title: const Text('새 그룹'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdaptiveTextField(
                  controller: ctrl,
                  placeholder: '그룹 이름',
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['👥', '🎮', '🍻', '💼', '🏃', '🎓', '❤️', '✈️']
                      .map((e) => GestureDetector(
                            onTap: () => setSt(() => emoji = e),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: emoji == e
                                  ? Theme.of(ctx).colorScheme.primary
                                  : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                              child: Text(e, style: const TextStyle(fontSize: 18)),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx, (name: name, emoji: emoji));
                },
                child: const Text('만들기'),
              ),
            ],
          );
        });
      },
    );
    if (result == null) return;
    try {
      await MultiplayerService.instance.createFriendGroup(
        name: result.name,
        emoji: result.emoji,
      );
      if (mounted) showAppSnackBar('그룹 만들어졌어요');
    } catch (e) {
      if (mounted) showAppSnackBar('실패: $e');
    }
  }

  Future<void> _confirmDelete(FriendGroup g) async {
    showAdaptiveConfirmDialog(
      context: context,
      title: '${g.emoji} ${g.name} 삭제',
      content: '그룹을 삭제해요. 친구는 사라지지 않아요.',
      confirmText: '삭제',
      isDestructive: true,
      onConfirm: () async {
        try {
          await MultiplayerService.instance.deleteFriendGroup(g.id);
        } catch (e) {
          if (mounted) showAppSnackBar('실패: $e');
        }
      },
    );
  }

  Future<void> _editMembers(FriendGroup g) async {
    final svc = MultiplayerService.instance;
    final friends = svc.acceptedFriends;
    final me = svc.myId ?? '';
    final selected = Set<String>.from(g.memberIds);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${g.emoji} ${g.name} 멤버',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (friends.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('아직 친구가 없어요',
                          style: TextStyle(
                              color: Theme.of(ctx)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: friends.map((f) {
                          final other = f.otherSide(me);
                          final p = svc.peerProfile(other);
                          final on = selected.contains(other);
                          return CheckboxListTile(
                            value: on,
                            title: Text(p?.nickname ?? other.substring(0, 6)),
                            secondary: Text(p?.pinEmoji ?? '📍',
                                style: const TextStyle(fontSize: 22)),
                            onChanged: (v) async {
                              setSt(() {
                                if (v == true) {
                                  selected.add(other);
                                } else {
                                  selected.remove(other);
                                }
                              });
                              try {
                                await svc.setFriendInGroup(
                                    g.id, other, v == true);
                              } catch (_) {/* UI 는 이미 반영됨 */}
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = MultiplayerService.instance;
    final groups = svc.friendGroups;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(
        title: '친구 그룹',
        actions: [
          AdaptiveAppBarAction(
            icon: Icons.add_rounded,
            tooltip: '새 그룹',
            onPressed: _createGroup,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: groups.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_outlined,
                          size: 48, color: cs.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('아직 그룹이 없어요',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('상단 + 로 친구를 묶어 보세요',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final g = groups[i];
                  return AdaptiveSurfaceCard(
                    borderRadius: 14,
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: cs.primary.withValues(alpha: 0.15),
                        child: Text(g.emoji,
                            style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(g.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${g.memberIds.length}명',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'members') _editMembers(g);
                          if (v == 'delete') _confirmDelete(g);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'members', child: Text('멤버 편집')),
                          PopupMenuItem(
                              value: 'delete',
                              child: Text('삭제',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                      onTap: () => _editMembers(g),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
