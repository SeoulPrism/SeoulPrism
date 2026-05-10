import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import 'report_sheet.dart';
import '../../widgets/app_snackbar.dart';

/// 지도 위 peer 핀 탭 시 노출되는 미니 프로필 카드.
class PeerProfileCard extends StatelessWidget {
  final String userId;
  const PeerProfileCard({super.key, required this.userId});

  static Future<void> show(BuildContext context, String userId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PeerProfileCard(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Body(userId: userId);
  }
}

class _Body extends StatefulWidget {
  final String userId;
  const _Body({required this.userId});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  MultiplayerProfile? _profile;
  double? _distanceM;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    MultiplayerService.instance.addListener(_onChanged);
    _load();
  }

  @override
  void dispose() {
    MultiplayerService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final svc = MultiplayerService.instance;
    final p = svc.peerProfile(widget.userId) ??
        await svc.fetchPeerProfile(widget.userId);
    final loc = svc.peerLocations[widget.userId];
    double? dist;
    if (loc != null) {
      try {
        final me = await Geolocator.getCurrentPosition();
        dist = Geolocator.distanceBetween(
            me.latitude, me.longitude, loc.lat, loc.lng);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _profile = p;
      _distanceM = dist;
    });
  }

  _FriendState get _friendState {
    final svc = MultiplayerService.instance;
    final me = svc.myId ?? '';
    final f = svc.friendships
        .where((x) =>
            x.otherSide(me) == widget.userId)
        .firstOrNull;
    if (f == null) return _FriendState.none;
    if (f.status == 'accepted') return _FriendState.friend;
    if (f.isIncoming(me)) return _FriendState.incoming;
    return _FriendState.requested;
  }

  Future<void> _runWithBusy(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e) {
      showAppSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = _profile;
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final state = _friendState;
    final svc = MultiplayerService.instance;
    final isMe = widget.userId == svc.myId;

    if (p == null) {
      return SizedBox(
        height: 200,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, inset + 20),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final v = int.parse(p.pinColor.substring(1), radix: 16);
    final color = Color(0xFF000000 | v);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, inset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 아바타.
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            alignment: Alignment.center,
            child: Text(p.pinEmoji, style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 12),
          Text(p.nickname,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          if (_distanceM != null)
            Text(_formatDistance(_distanceM!),
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          if (p.friendCode != null) ...[
            const SizedBox(height: 2),
            Text('친구 코드 ${p.friendCode}',
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
          ],

          if (p.currentTrack != null) ...[
            const SizedBox(height: 16),
            _NowPlayingChip(track: p.currentTrack!),
          ],

          const SizedBox(height: 24),

          if (isMe)
            Text('나의 핀이에요',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant))
          else ...[
            // 액션 버튼.
            _primaryAction(state, p),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ReportSheet.showForUser(context, widget.userId,
                          nickname: p.nickname);
                    },
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    label: const Text('신고'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showAdaptiveConfirmDialog(
                        context: context,
                        title: '${p.nickname} 차단',
                        content: '차단하면 같은 방에서 강퇴되고 메시지/핀이 보이지 않아요.',
                        confirmText: '차단',
                        isDestructive: true,
                        onConfirm: () =>
                            MultiplayerService.instance.blockUser(widget.userId),
                      );
                    },
                    icon: const Icon(Icons.block_rounded, size: 18),
                    label: const Text('차단'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _primaryAction(_FriendState state, MultiplayerProfile p) {
    return switch (state) {
      _FriendState.friend => AdaptiveGlassButton(
          label: '친구입니다 ✓',
          onPressed: null,
        ),
      _FriendState.requested => AdaptiveGlassButton(
          label: '신청 보냄',
          onPressed: null,
        ),
      _FriendState.incoming => AdaptiveGlassButton(
          label: _busy ? '...' : '친구 신청 수락',
          onPressed: _busy
              ? null
              : () => _runWithBusy(() async {
                    final svc = MultiplayerService.instance;
                    final f = svc.friendships
                        .firstWhere((x) => x.otherSide(svc.myId ?? '') == widget.userId);
                    await svc.acceptFriendRequest(f);
                    if (!mounted) return;
                    showAppSnackBar('${p.nickname} 와 친구가 됐어요');
                  }),
        ),
      _FriendState.none => AdaptiveGlassButton(
          label: _busy ? '...' : '친구 신청 보내기',
          onPressed: _busy
              ? null
              : () => _runWithBusy(() async {
                    await MultiplayerService.instance.sendFriendRequest(widget.userId);
                    if (!mounted) return;
                    showAppSnackBar('${p.nickname} 에게 신청을 보냈어요');
                  }),
        ),
    };
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m 거리';
    return '${(meters / 1000).toStringAsFixed(1)}km 거리';
  }
}

enum _FriendState { none, requested, incoming, friend }

/// Spotify "지금 듣는 곡" chip — peer profile card 안에 표시.
class _NowPlayingChip extends StatelessWidget {
  final PeerTrack track;
  const _NowPlayingChip({required this.track});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: track.externalUrl == null
          ? null
          : () => launchUrl(Uri.parse(track.externalUrl!),
              mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1DB954).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF1DB954).withValues(alpha: 0.5),
              width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: track.albumImageUrl != null
                  ? Image.network(track.albumImageUrl!,
                      width: 28, height: 28, fit: BoxFit.cover)
                  : Container(
                      width: 28, height: 28,
                      color: const Color(0xFF1DB954),
                      alignment: Alignment.center,
                      child: const Icon(Icons.music_note_rounded,
                          size: 14, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎵 ${track.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800)),
                  Text(track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
