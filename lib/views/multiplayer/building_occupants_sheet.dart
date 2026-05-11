import 'package:flutter/material.dart';

import '../../models/building_hit.dart';
import '../../models/multiplayer_models.dart';
import '../../services/building_presence_tracker.dart';
import '../../services/multiplayer_service.dart';
import 'peer_now_playing_view.dart';
import 'peer_profile_card.dart';

/// 건물 badge 를 탭했을 때 뜨는 시트 — 그 건물 안에 있는 peer 들을 나열.
/// 자기 자신은 제외 (사용자 요구).
class BuildingOccupantsSheet extends StatefulWidget {
  final String buildingId;
  const BuildingOccupantsSheet({super.key, required this.buildingId});

  static Future<void> show(BuildContext context, String buildingId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BuildingOccupantsSheet(buildingId: buildingId),
    );
  }

  @override
  State<BuildingOccupantsSheet> createState() => _BuildingOccupantsSheetState();
}

class _BuildingOccupantsSheetState extends State<BuildingOccupantsSheet> {
  @override
  void initState() {
    super.initState();
    BuildingPresenceTracker.instance.addListener(_onChanged);
    MultiplayerService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    BuildingPresenceTracker.instance.removeListener(_onChanged);
    MultiplayerService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tracker = BuildingPresenceTracker.instance;
    final peerIds = tracker.peersInBuilding(widget.buildingId)
        .where((id) => id != MultiplayerService.instance.myId)
        .toList();
    // building meta 는 직접 노출되지 않음 → occupiedBuildings 에서 찾기.
    BuildingHit? hit;
    for (final b in tracker.occupiedBuildings) {
      if (b.id == widget.buildingId) {
        hit = b;
        break;
      }
    }
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final title = hit?.displayName ?? '건물';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, inset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C42).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('🏢', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text('${peerIds.length}명이 안에 있어요',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (peerIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '건물을 떠났어요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            )
          else
            ...peerIds.map((uid) => _OccupantRow(userId: uid)),
        ],
      ),
    );
  }
}

class _OccupantRow extends StatefulWidget {
  final String userId;
  const _OccupantRow({required this.userId});

  @override
  State<_OccupantRow> createState() => _OccupantRowState();
}

class _OccupantRowState extends State<_OccupantRow> {
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

    // 채팅 메시지 풍 — 좌측 아바타, 우측 닉네임 + 말풍선(현재 행동).
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            if (track != null) {
              PeerNowPlayingView.push(context, widget.userId);
            } else {
              PeerProfileCard.show(context, widget.userId);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                  alignment: Alignment.center,
                  child: Text(p.pinEmoji,
                      style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 2),
                        child: Text(p.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant)),
                      ),
                      _Bubble(
                        track: track,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 채팅 말풍선 풍의 한 줄 — currentTrack 있으면 Spotify 컬러, 없으면 surface.
class _Bubble extends StatelessWidget {
  final PeerTrack? track;
  const _Bubble({required this.track});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasTrack = track != null;
    final bg = hasTrack
        ? const Color(0xFF1DB954).withValues(alpha: 0.18)
        : cs.surfaceContainerHigh;
    final border = hasTrack
        ? const Color(0xFF1DB954).withValues(alpha: 0.45)
        : cs.outlineVariant.withValues(alpha: 0.5);
    final fg = hasTrack
        ? const Color(0xFF1DB954)
        : cs.onSurface;

    final text = hasTrack
        ? '🎵 ${track!.name} · ${track!.artist} 듣는 중'
        : '🏢 건물 안에 있어요';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.3,
        ),
      ),
    );
  }
}

