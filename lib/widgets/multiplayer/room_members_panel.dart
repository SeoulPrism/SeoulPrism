import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../app_snackbar.dart';

/// "N명에게 위치 공유 중" 배지 탭 시 위에서 슬라이드 다운하는 친구 목록 패널.
/// 친구 행을 탭하면 [onPeerTap] 콜백으로 (lat, lng, userId) 전달 → 카메라 이동.
class RoomMembersPanel extends StatefulWidget {
  final bool open;
  final VoidCallback onDismiss;
  final void Function(String userId, double lat, double lng) onPeerTap;

  const RoomMembersPanel({
    super.key,
    required this.open,
    required this.onDismiss,
    required this.onPeerTap,
  });

  @override
  State<RoomMembersPanel> createState() => _RoomMembersPanelState();
}

class _RoomMembersPanelState extends State<RoomMembersPanel> {
  static const double _kNearbyRadiusMeters = 500.0;

  Position? _myPos;
  bool _showAllPublic = false;

  @override
  void initState() {
    super.initState();
    MultiplayerService.instance.addListener(_onChanged);
    _refreshMyPos();
  }

  @override
  void didUpdateWidget(RoomMembersPanel old) {
    super.didUpdateWidget(old);
    if (widget.open && !old.open) {
      _refreshMyPos();
      _showAllPublic = false;
    }
  }

  @override
  void dispose() {
    MultiplayerService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshMyPos() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (mounted) setState(() => _myPos = pos);
    } catch (_) {}
  }

  double? _distanceMeters(double lat, double lng) {
    final me = _myPos;
    if (me == null) return null;
    return Geolocator.distanceBetween(me.latitude, me.longitude, lat, lng);
  }

  String _distanceLabel(double lat, double lng) {
    final m = _distanceMeters(lat, lng);
    if (m == null) return '';
    if (m < 1000) return '${m.round()}m';
    return '${(m / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    final svc = MultiplayerService.instance;
    final cs = Theme.of(context).colorScheme;
    final myId = svc.myId;

    final memberIds =
        svc.currentRoomMembers.where((id) => id != myId).toList();

    // 룸 멤버를 제외한 public peers — 500m 이내 / 밖으로 분류.
    final memberIdSet = memberIds.toSet();
    final nearby = <String>[];
    final farther = <String>[];
    svc.worldPeerLocations.forEach((uid, loc) {
      if (uid == myId || memberIdSet.contains(uid)) return;
      if (svc.isBlocked(uid)) return;
      final dist = _distanceMeters(loc.lat, loc.lng);
      if (dist != null && dist <= _kNearbyRadiusMeters) {
        nearby.add(uid);
      } else {
        farther.add(uid);
      }
    });

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.12),
          end: Offset.zero,
        ).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: !widget.open
          ? const SizedBox.shrink()
          : _Panel(
              key: const ValueKey('panel-open'),
              memberIds: memberIds,
              nearbyPublicIds: nearby,
              fartherPublicIds: farther,
              showAllPublic: _showAllPublic,
              onTogglePublic: () =>
                  setState(() => _showAllPublic = !_showAllPublic),
              cs: cs,
              distanceFor: _distanceLabel,
              onPeerTap: widget.onPeerTap,
              onDismiss: widget.onDismiss,
            ),
    );
  }
}

class _Panel extends StatelessWidget {
  final List<String> memberIds;
  final List<String> nearbyPublicIds;
  final List<String> fartherPublicIds;
  final bool showAllPublic;
  final VoidCallback onTogglePublic;
  final ColorScheme cs;
  final String Function(double, double) distanceFor;
  final void Function(String, double, double) onPeerTap;
  final VoidCallback onDismiss;

  const _Panel({
    super.key,
    required this.memberIds,
    required this.nearbyPublicIds,
    required this.fartherPublicIds,
    required this.showAllPublic,
    required this.onTogglePublic,
    required this.cs,
    required this.distanceFor,
    required this.onPeerTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final svc = MultiplayerService.instance;
    final l = AppL10n.of(context);
    final isIOS = Platform.isIOS;
    final dim = isIOS ? Colors.white.withValues(alpha: 0.65) : cs.onSurfaceVariant;

    Widget peerRow(String uid) => _MemberRow(
          userId: uid,
          cs: cs,
          distanceFor: distanceFor,
          onTap: (lat, lng) {
            onPeerTap(uid, lat, lng);
            onDismiss();
          },
        );

    final inner = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  memberIds.isEmpty
                      ? l.roomMembersEmpty
                      : l.roomMembersWithCount(memberIds.length),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isIOS
                        ? Colors.white.withValues(alpha: 0.85)
                        : cs.onSurfaceVariant,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await svc.setVisibility('ghost');
                  onDismiss();
                  if (context.mounted) {
                    showAppSnackBar(l.liveBadgeStopped);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIOS
                        ? Colors.white.withValues(alpha: 0.15)
                        : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_off_rounded,
                          size: 12,
                          color: isIOS ? Colors.white : cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(l.roomMembersGhost,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isIOS
                                  ? Colors.white
                                  : cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (memberIds.isNotEmpty) const SizedBox(height: 8),
          ...memberIds.map(peerRow),

          // 주변 (500m 이내) 전체 공개 사용자.
          if (nearbyPublicIds.isNotEmpty) ...[
            const SizedBox(height: 6),
            _SectionLabel(
                text: l.roomMembersNearbyHeader(nearbyPublicIds.length),
                color: dim),
            const SizedBox(height: 2),
            ...nearbyPublicIds.map(peerRow),
          ],

          // 500m 밖 public — 토글로 펼침.
          if (fartherPublicIds.isNotEmpty) ...[
            const SizedBox(height: 6),
            _ExpandButton(
              label: showAllPublic
                  ? l.roomMembersHidePublic
                  : l.roomMembersSeeAllPublic(fartherPublicIds.length),
              expanded: showAllPublic,
              onTap: onTogglePublic,
              color: dim,
              isIOS: isIOS,
              cs: cs,
            ),
            if (showAllPublic) ...[
              const SizedBox(height: 2),
              _SectionLabel(
                  text: l.roomMembersPublicSectionHeader, color: dim),
              const SizedBox(height: 2),
              ...fartherPublicIds.map(peerRow),
            ],
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Platform.isIOS
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
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
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: inner,
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  final String label;
  final bool expanded;
  final VoidCallback onTap;
  final Color color;
  final bool isIOS;
  final ColorScheme cs;

  const _ExpandButton({
    required this.label,
    required this.expanded,
    required this.onTap,
    required this.color,
    required this.isIOS,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isIOS
                ? Colors.white.withValues(alpha: 0.08)
                : cs.surfaceContainerHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatefulWidget {
  final String userId;
  final ColorScheme cs;
  final String Function(double, double) distanceFor;
  final void Function(double lat, double lng) onTap;

  const _MemberRow({
    required this.userId,
    required this.cs,
    required this.distanceFor,
    required this.onTap,
  });

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
    final p = svc.peerProfile(widget.userId) ??
        await svc.fetchPeerProfile(widget.userId);
    if (!mounted) return;
    setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    final svc = MultiplayerService.instance;
    final p = _profile;
    final loc = svc.peerLocations[widget.userId];

    final color = p != null
        ? Color(0xFF000000 | int.parse(p.pinColor.substring(1), radix: 16))
        : const Color(0xFF7C5CFF);

    final isLight = !Platform.isIOS;
    final fg = isLight ? widget.cs.onPrimaryContainer : Colors.white;
    final dim = isLight
        ? widget.cs.onSurfaceVariant
        : Colors.white.withValues(alpha: 0.65);

    final dist = loc == null ? '' : widget.distanceFor(loc.lat, loc.lng);
    final track = p?.currentTrack;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loc == null ? null : () => widget.onTap(loc.lat, loc.lng),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                alignment: Alignment.center,
                child: Text(p?.pinEmoji ?? '📍',
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p?.nickname ?? '...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: fg)),
                    if (track != null)
                      Text(
                        '🎵 ${track.name} · ${track.artist}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1DB954)),
                      )
                    else if (loc == null)
                      Text(AppL10n.of(context).roomMembersDisconnected,
                          style: TextStyle(fontSize: 10, color: dim))
                    else
                      Text(
                          loc.isStale
                              ? AppL10n.of(context).roomMembersStale
                              : AppL10n.of(context).roomMembersRealtime,
                          style: TextStyle(fontSize: 10, color: dim)),
                  ],
                ),
              ),
              if (dist.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(dist,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: dim)),
                ),
              const SizedBox(width: 4),
              Icon(Icons.navigation_rounded, size: 16, color: dim),
            ],
          ),
        ),
      ),
    );
  }
}
