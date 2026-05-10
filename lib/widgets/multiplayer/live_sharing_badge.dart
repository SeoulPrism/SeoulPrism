import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../services/multiplayer_service.dart';
import '../app_snackbar.dart';

/// 위치 공유 중일 때 화면 상단에 떠있는 작은 배지.
/// iOS: BackdropFilter 글라스, Android: Material 3 surface elevated.
/// 탭하면 즉시 ghost 모드로 전환.
class LiveSharingBadge extends StatefulWidget {
  final VoidCallback? onMutedToGhost;
  const LiveSharingBadge({super.key, this.onMutedToGhost});

  @override
  State<LiveSharingBadge> createState() => _LiveSharingBadgeState();
}

class _LiveSharingBadgeState extends State<LiveSharingBadge> {
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

  @override
  Widget build(BuildContext context) {
    final svc = MultiplayerService.instance;
    final shouldShow = svc.currentRoom != null &&
        (svc.myProfile?.visibility ?? 'ghost') != 'ghost';
    if (!shouldShow) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final memberCount = (svc.currentRoomMembers.length - 1).clamp(0, 7);

    final inner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF34C759), // iOS-style green
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$memberCount명에게 위치 공유 중',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Platform.isIOS ? Colors.white : cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.close_rounded,
              size: 14,
              color: Platform.isIOS ? Colors.white : cs.onPrimaryContainer),
        ],
      ),
    );

    return GestureDetector(
      onTap: () async {
        await svc.setVisibility('ghost');
        widget.onMutedToGhost?.call();
        showAppSnackBar('위치 공유를 중지했어요');
      },
      child: Platform.isIOS
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.5,
                    ),
                  ),
                  child: inner,
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: inner,
            ),
    );
  }
}
