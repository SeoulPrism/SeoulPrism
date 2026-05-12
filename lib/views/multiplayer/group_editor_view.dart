import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';

/// 친구 그룹 편집.
class GroupEditorView extends StatefulWidget {
  const GroupEditorView({super.key});

  @override
  State<GroupEditorView> createState() => _GroupEditorViewState();
}

class _GroupEditorViewState extends State<GroupEditorView> {
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

  Future<void> _newGroup() async {
    final l = AppL10n.of(context);
    final name = await _promptName(context, l.groupEditorNew);
    if (name == null || name.isEmpty) return;
    try {
      await MultiplayerService.instance.createFriendGroup(name: name);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(AppL10n.of(context).groupEditorFailure(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final svc = MultiplayerService.instance;
    final groups = svc.friendGroups;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(
        title: l.groupEditorTitle,
        actions: [
          AdaptiveAppBarAction(
            icon: Icons.add_rounded,
            tooltip: l.groupEditorNew,
            onPressed: _newGroup,
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
                      Icon(Icons.groups_outlined,
                          size: 56, color: cs.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(l.groupEditorEmpty,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(l.groupEditorEmptyHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: groups.map((g) => _GroupCard(group: g)).toList(),
              ),
      ),
    );
  }

  Future<String?> _promptName(BuildContext context, String title) async {
    final ctrl = TextEditingController();
    String? result;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final l = AppL10n.of(ctx);
        final inset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, inset + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(l.groupEditorHelper,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),
              AdaptiveTextField(
                controller: ctrl,
                placeholder: l.groupEditorNamePlaceholder,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              const SizedBox(height: 16),
              AdaptiveGlassButton(
                label: l.groupEditorCreate,
                onPressed: () {
                  result = ctrl.text.trim();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
    return result;
  }
}

class _GroupCard extends StatelessWidget {
  final FriendGroup group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final svc = MultiplayerService.instance;
    final friends = svc.acceptedFriends;
    final me = svc.myId ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AdaptiveSectionCard(children: [
        // 헤더.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Row(
            children: [
              Text(group.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(group.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Text(l.groupEditorMemberCount(group.memberIds.length),
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: cs.error),
                onPressed: () {
                  showAdaptiveConfirmDialog(
                    context: context,
                    title: l.groupEditorDeleteTitle(group.name),
                    content: l.groupEditorDeleteBody,
                    cancelText: l.commonCancel,
                    confirmText: l.groupEditorDelete,
                    isDestructive: true,
                    onConfirm: () =>
                        svc.deleteFriendGroup(group.id),
                  );
                },
              ),
            ],
          ),
        ),
        if (friends.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(l.groupEditorAddFriendsHint,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant)),
          )
        else
          ...friends.map((f) {
            final friendId = f.otherSide(me);
            final p = svc.peerProfile(friendId);
            final inGroup = group.memberIds.contains(friendId);
            return CheckboxListTile(
              value: inGroup,
              onChanged: (v) => svc.setFriendInGroup(
                  group.id, friendId, v ?? false),
              title: Text(p?.nickname ?? friendId.substring(0, 8)),
              secondary: p != null
                  ? Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF000000 |
                              int.parse(p.pinColor.substring(1),
                                  radix: 16))),
                      alignment: Alignment.center,
                      child: Text(p.pinEmoji,
                          style: const TextStyle(fontSize: 16)),
                    )
                  : const CircleAvatar(child: Icon(Icons.person)),
            );
          }),
      ]),
    );
  }
}
