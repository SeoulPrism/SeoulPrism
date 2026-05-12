import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
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
        final l = AppL10n.of(ctx);
        return StatefulBuilder(builder: (ctx, setSt) {
          return AlertDialog(
            title: Text(l.friendGroupsNewTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.friendGroupsName,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                AdaptiveTextField(
                  controller: ctrl,
                  placeholder: l.friendGroupsNamePlaceholder,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                const SizedBox(height: 16),
                Text(l.friendGroupsIcon,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['👥', '🎮', '🍻', '💼', '🏃', '🎓', '❤️', '✈️']
                      .map((e) => GestureDetector(
                            onTap: () => setSt(() => emoji = e),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: emoji == e
                                  ? Theme.of(ctx).colorScheme.primary
                                  : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                              child: Text(e, style: const TextStyle(fontSize: 20)),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text(l.commonCancel),
              ),
              TextButton(
                onPressed: () {
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx, (name: name, emoji: emoji));
                },
                child: Text(l.friendGroupsCreate),
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
      if (mounted) showAppSnackBar(AppL10n.of(context).friendGroupsCreated);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).friendGroupsFailure(e.toString()));
      }
    }
  }

  Future<void> _confirmDelete(FriendGroup g) async {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.friendGroupsDeleteTitle(g.emoji, g.name),
      content: l.friendGroupsDeleteBody,
      confirmText: l.friendGroupsDelete,
      isDestructive: true,
      onConfirm: () async {
        try {
          await MultiplayerService.instance.deleteFriendGroup(g.id);
        } catch (e) {
          if (mounted) {
            showAppSnackBar(
                AppL10n.of(context).friendGroupsFailure(e.toString()));
          }
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
                  Text(AppL10n.of(ctx).friendGroupsMembersTitle(g.emoji, g.name),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (friends.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(AppL10n.of(ctx).friendGroupsEmptyFriendsBox,
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
        title: AppL10n.of(context).hubFriendGroupsTitle,
        actions: [
          AdaptiveAppBarAction(
            icon: Icons.add_rounded,
            tooltip: AppL10n.of(context).friendGroupsNewTooltip,
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
                      Text(AppL10n.of(context).friendGroupsEmpty,
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(AppL10n.of(context).friendGroupsEmptyHint,
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
                      subtitle: Text(
                          AppL10n.of(context).friendGroupsMemberCount(g.memberIds.length),
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'members') _editMembers(g);
                          if (v == 'delete') _confirmDelete(g);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 'members',
                              child: Text(AppL10n.of(context).friendGroupsEditMembers)),
                          PopupMenuItem(
                              value: 'delete',
                              child: Text(AppL10n.of(context).friendGroupsDelete,
                                  style: const TextStyle(color: Colors.red))),
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
