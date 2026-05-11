import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/multiplayer_service.dart';
import '../app_snackbar.dart';
import 'live_sharing_diagnostics_dialog.dart';

/// 위치 공유 중일 때 화면 상단에 떠있는 작은 배지.
/// iOS: BackdropFilter 글라스, Android: Material 3 surface elevated.
/// short-tap: [onTap] 호출 (없으면 즉시 ghost 토글, 기존 동작),
/// long-press: 실시간 진단 다이얼로그.
///
/// 친구가 새 곡을 시작하면 잠깐 "{닉네임}이 ~~~ 듣고 있어요" 로 바뀌었다가
/// 원래 "N명에게 위치 공유 중" 으로 돌아온다.
class LiveSharingBadge extends StatefulWidget {
  final VoidCallback? onMutedToGhost;
  final VoidCallback? onTap;
  const LiveSharingBadge({super.key, this.onMutedToGhost, this.onTap});

  @override
  State<LiveSharingBadge> createState() => _LiveSharingBadgeState();
}

class _LiveSharingBadgeState extends State<LiveSharingBadge> {
  static const _kFlashDuration = Duration(seconds: 4);

  String? _flashMessage;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    final svc = MultiplayerService.instance;
    svc.addListener(_onChanged);
    svc.addPeerTrackListener(_onPeerTrack);
  }

  @override
  void dispose() {
    final svc = MultiplayerService.instance;
    svc.removeListener(_onChanged);
    svc.removePeerTrackListener(_onPeerTrack);
    _flashTimer?.cancel();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onPeerTrack(String userId, String track, String artist) {
    if (!mounted) return;
    final svc = MultiplayerService.instance;
    // 같은 방 멤버일 때만 노출.
    if (svc.currentRoom == null) return;
    if (!svc.currentRoomMembers.contains(userId)) return;
    final l = AppL10n.of(context);
    final nickname = svc.peerProfile(userId)?.nickname ?? l.dmDefaultPeer;
    _flashTimer?.cancel();
    setState(() {
      _flashMessage = l.liveBadgePeerTrack(nickname, track);
    });
    _flashTimer = Timer(_kFlashDuration, () {
      if (!mounted) return;
      setState(() => _flashMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = MultiplayerService.instance;
    final shouldShow = svc.currentRoom != null &&
        (svc.myProfile?.visibility ?? 'ghost') != 'ghost';
    if (!shouldShow) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final memberCount = (svc.currentRoomMembers.length - 1).clamp(0, 7);
    final isFlash = _flashMessage != null;
    final textColor = Platform.isIOS ? Colors.white : cs.onPrimaryContainer;

    final inner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFlash
                  ? const Color(0xFF1DB954) // Spotify green
                  : const Color(0xFF34C759), // iOS-style green
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.35),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: ConstrainedBox(
              key: ValueKey(_flashMessage ?? '__base__'),
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                isFlash
                    ? _flashMessage!
                    : AppL10n.of(context).liveBadgeSharing(memberCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.close_rounded, size: 14, color: textColor),
        ],
      ),
    );

    return GestureDetector(
      onTap: () async {
        if (widget.onTap != null) {
          widget.onTap!();
          return;
        }
        await svc.setVisibility('ghost');
        widget.onMutedToGhost?.call();
        if (mounted) showAppSnackBar(AppL10n.of(context).liveBadgeStopped);
      },
      onLongPress: () => LiveSharingDiagnosticsDialog.show(context),
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
