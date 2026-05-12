import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';
import 'report_sheet.dart';

/// 노래를 듣고 있는 친구 핀을 탭했을 때 진입하는 풀스크린 뷰.
/// 큰 앨범 아트 + 트랙 + 프로필 + 액션을 한 번에 보여준다.
class PeerNowPlayingView extends StatefulWidget {
  final String userId;
  const PeerNowPlayingView({super.key, required this.userId});

  static Future<void> push(BuildContext context, String userId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PeerNowPlayingView(userId: userId),
      ),
    );
  }

  @override
  State<PeerNowPlayingView> createState() => _PeerNowPlayingViewState();
}

class _PeerNowPlayingViewState extends State<PeerNowPlayingView> {
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
        .where((x) => x.otherSide(me) == widget.userId)
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

  String _formatDistance(BuildContext ctx, double meters) {
    final l = AppL10n.of(ctx);
    if (meters < 1000) return l.peerDistanceMeters(meters.round());
    return l.peerDistanceKm((meters / 1000).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final cs = Theme.of(context).colorScheme;

    if (p == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
            child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final track = p.currentTrack;
    final v = int.parse(p.pinColor.substring(1), radix: 16);
    final pinColor = Color(0xFF000000 | v);

    // 배경: 앨범아트가 있으면 블러 + 어둡게, 없으면 pinColor 기반 그라디언트.
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: AppL10n.of(context).peerReport,
            onPressed: () {
              ReportSheet.showForUser(context, widget.userId,
                  nickname: p.nickname);
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 — 앨범아트 블러 또는 pinColor 그라디언트.
          if (track?.albumImageUrl != null)
            Image.network(
              track!.albumImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradientBg(pinColor),
            )
          else
            _gradientBg(pinColor),
          // 어둡게 + 블러.
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
          // 콘텐츠.
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  if (track != null)
                    _AlbumArt(track: track)
                  else
                    _AvatarBig(profile: p, color: pinColor),
                  const SizedBox(height: 24),
                  if (track != null) ...[
                    Text(
                      track.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SpotifyChip(track: track),
                    const SizedBox(height: 28),
                  ],
                  // 프로필 카드.
                  _ProfileBlock(
                    profile: p,
                    distanceLabel: _distanceM != null
                        ? _formatDistance(context, _distanceM!)
                        : null,
                    pinColor: pinColor,
                  ),
                  const SizedBox(height: 24),
                  _primaryAction(_friendState, p, cs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBg(Color base) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(alpha: 0.85),
            Colors.black,
          ],
        ),
      ),
    );
  }

  Widget _primaryAction(_FriendState state, MultiplayerProfile p, ColorScheme cs) {
    final l = AppL10n.of(context);
    return switch (state) {
      _FriendState.friend => _GhostBtn(label: l.peerNowPlayingBtnFriend, enabled: false),
      _FriendState.requested =>
        _GhostBtn(label: l.peerNowPlayingBtnRequested, enabled: false),
      _FriendState.incoming => _GhostBtn(
          label: _busy ? '...' : l.peerNowPlayingBtnAccept,
          enabled: !_busy,
          onTap: () => _runWithBusy(() async {
            final svc = MultiplayerService.instance;
            final f = svc.friendships.firstWhere(
                (x) => x.otherSide(svc.myId ?? '') == widget.userId);
            await svc.acceptFriendRequest(f);
            if (!mounted) return;
            showAppSnackBar(AppL10n.of(context).peerNowFriend(p.nickname));
          }),
        ),
      _FriendState.none => _GhostBtn(
          label: _busy ? '...' : l.peerNowPlayingBtnSendRequest,
          enabled: !_busy,
          onTap: () => _runWithBusy(() async {
            await MultiplayerService.instance.sendFriendRequest(widget.userId);
            if (!mounted) return;
            showAppSnackBar(AppL10n.of(context).peerRequestSent(p.nickname));
          }),
        ),
    };
  }
}

enum _FriendState { none, requested, incoming, friend }

class _AlbumArt extends StatelessWidget {
  final PeerTrack track;
  const _AlbumArt({required this.track});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: track.albumImageUrl != null
            ? Image.network(track.albumImageUrl!, fit: BoxFit.cover)
            : Container(
                color: const Color(0xFF1DB954),
                alignment: Alignment.center,
                child: const Icon(Icons.music_note_rounded,
                    size: 80, color: Colors.white),
              ),
      ),
    );
  }
}

class _AvatarBig extends StatelessWidget {
  final MultiplayerProfile profile;
  final Color color;
  const _AvatarBig({required this.profile, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      alignment: Alignment.center,
      child: Text(profile.pinEmoji, style: const TextStyle(fontSize: 96)),
    );
  }
}

class _SpotifyChip extends StatelessWidget {
  final PeerTrack track;
  const _SpotifyChip({required this.track});

  @override
  Widget build(BuildContext context) {
    final url = track.externalUrl;
    return GestureDetector(
      onTap: url == null
          ? null
          : () => launchUrl(Uri.parse(url),
              mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1DB954),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1DB954).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              AppL10n.of(context).peerNowPlayingOpenInSpotify,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBlock extends StatelessWidget {
  final MultiplayerProfile profile;
  final String? distanceLabel;
  final Color pinColor;
  const _ProfileBlock({
    required this.profile,
    required this.distanceLabel,
    required this.pinColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.18), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: pinColor),
                alignment: Alignment.center,
                child: Text(profile.pinEmoji,
                    style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(profile.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    if (distanceLabel != null)
                      Text(distanceLabel!,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7))),
                    if (profile.friendCode != null) ...[
                      const SizedBox(height: 2),
                      Text(AppL10n.of(context).peerFriendCode(profile.friendCode ?? ''),
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.55))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  const _GhostBtn({
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AdaptiveGlassButton(
        label: label,
        onPressed: enabled ? onTap : null,
      ),
    );
  }
}
