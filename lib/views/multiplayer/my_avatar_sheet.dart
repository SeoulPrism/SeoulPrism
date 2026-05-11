import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import 'peer_profile_card.dart';
import 'peer_now_playing_view.dart';

/// 내 3D 아바타를 탭했을 때 뜨는 시트.
/// 친구방 멤버들의 닉네임 / 핀 / 지금 듣는 곡(Spotify) 을 한 번에 보여준다.
/// 멤버를 탭하면 PeerProfileCard 로 넘어간다.
class MyAvatarSheet extends StatefulWidget {
  const MyAvatarSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const MyAvatarSheet(),
    );
  }

  @override
  State<MyAvatarSheet> createState() => _MyAvatarSheetState();
}

class _MyAvatarSheetState extends State<MyAvatarSheet> {
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
    final cs = Theme.of(context).colorScheme;
    final me = svc.myProfile;
    final inset = MediaQuery.of(context).viewInsets.bottom;

    final memberIds =
        svc.currentRoomMembers.where((id) => id != svc.myId).toList();
    final inRoom = svc.currentRoom != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, inset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 내 정보 헤더.
          if (me != null) _MeHeader(profile: me),
          const SizedBox(height: 16),

          if (!inRoom)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '친구방에 들어가면 친구들이 여기에 보여요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            )
          else if (memberIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '아직 같이 있는 친구가 없어요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                '같이 있는 친구 ${memberIds.length}명',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant),
              ),
            ),
            ...memberIds.map((uid) => _MemberRow(userId: uid)),
          ],
        ],
      ),
    );
  }
}

class _MeHeader extends StatelessWidget {
  final MultiplayerProfile profile;
  const _MeHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = int.parse(profile.pinColor.substring(1), radix: 16);
    final color = Color(0xFF000000 | v);
    final track = profile.currentTrack;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          alignment: Alignment.center,
          child: Text(profile.pinEmoji, style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(profile.nickname,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              const SizedBox(height: 2),
              Text('나의 핀',
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant)),
              if (track != null) ...[
                const SizedBox(height: 6),
                _TrackInline(track: track),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberRow extends StatefulWidget {
  final String userId;
  const _MemberRow({required this.userId});

  @override
  State<_MemberRow> createState() => _MemberRowState();
}

class _MemberRowState extends State<_MemberRow> {
  MultiplayerProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = MultiplayerService.instance;
    final p =
        svc.peerProfile(widget.userId) ?? await svc.fetchPeerProfile(widget.userId);
    if (!mounted) return;
    setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = _profile;
    if (p == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
            height: 36,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final v = int.parse(p.pinColor.substring(1), radix: 16);
    final color = Color(0xFF000000 | v);
    final track = p.currentTrack;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pop(context);
          if (track != null) {
            PeerNowPlayingView.push(context, widget.userId);
          } else {
            PeerProfileCard.show(context, widget.userId);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                alignment: Alignment.center,
                child:
                    Text(p.pinEmoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.nickname,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                    const SizedBox(height: 2),
                    if (track != null)
                      _TrackInline(track: track)
                    else
                      Text('지금 듣는 곡 없음',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// 멤버 행 안에 들어가는 컴팩트한 Spotify 라인.
class _TrackInline extends StatelessWidget {
  final PeerTrack track;
  const _TrackInline({required this.track});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: track.externalUrl == null
          ? null
          : () => launchUrl(Uri.parse(track.externalUrl!),
              mode: LaunchMode.externalApplication),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: track.albumImageUrl != null
                ? Image.network(track.albumImageUrl!,
                    width: 18, height: 18, fit: BoxFit.cover)
                : Container(
                    width: 18,
                    height: 18,
                    color: const Color(0xFF1DB954),
                    alignment: Alignment.center,
                    child: const Icon(Icons.music_note_rounded,
                        size: 10, color: Colors.white)),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${track.name} · ${track.artist}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1DB954),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
