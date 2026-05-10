import 'package:flutter/material.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';

/// 차단 목록 — 차단 해제 가능.
class BlockedUsersView extends StatefulWidget {
  const BlockedUsersView({super.key});

  @override
  State<BlockedUsersView> createState() => _BlockedUsersViewState();
}

class _BlockedUsersViewState extends State<BlockedUsersView> {
  List<MultiplayerProfile>? _blocked;

  @override
  void initState() {
    super.initState();
    MultiplayerService.instance.addListener(_onChanged);
    _refresh();
  }

  @override
  void dispose() {
    MultiplayerService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) _refresh();
  }

  Future<void> _refresh() async {
    final list = await MultiplayerService.instance.fetchBlockedProfiles();
    if (!mounted) return;
    setState(() => _blocked = list);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = _blocked;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AdaptiveAppBar(title: '차단 목록'),
      body: SafeArea(
        child: list == null
            ? const Center(child: CircularProgressIndicator())
            : list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.block_rounded,
                              size: 56, color: cs.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('차단한 사용자가 없어요',
                              style:
                                  TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      AdaptiveSectionCard(children: [
                        for (var i = 0; i < list.length; i++) ...[
                          if (i > 0) const _Divider(),
                          _BlockedRow(profile: list[i]),
                        ],
                      ]),
                    ],
                  ),
      ),
    );
  }
}

class _BlockedRow extends StatelessWidget {
  final MultiplayerProfile profile;
  const _BlockedRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = int.parse(profile.pinColor.substring(1), radix: 16);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFF000000 | v)),
            alignment: Alignment.center,
            child: Text(profile.pinEmoji,
                style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(profile.nickname,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => showAdaptiveConfirmDialog(
              context: context,
              title: '${profile.nickname} 차단 해제',
              content: '차단을 해제하면 다시 만날 수 있고 메시지도 보입니다.',
              confirmText: '해제',
              onConfirm: () =>
                  MultiplayerService.instance.unblockUser(profile.userId),
            ),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
            child: const Text('해제'),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(
          height: 0.5,
          thickness: 0.5,
          color: cs.outlineVariant.withValues(alpha: 0.5)),
    );
  }
}
