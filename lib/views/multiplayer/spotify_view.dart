import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/multiplayer_service.dart';
import '../../services/spotify_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';

/// Spotify 상태 + 현재 곡 + 친구방에 공유 + 연결 해제.
class SpotifyView extends StatefulWidget {
  const SpotifyView({super.key});

  @override
  State<SpotifyView> createState() => _SpotifyViewState();
}

class _SpotifyViewState extends State<SpotifyView> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    SpotifyService.instance.addListener(_onChanged);
    SpotifyService.instance.fetchCurrentlyPlaying();
    // 화면 보이는 동안 5초 마다 한 번 더 (서비스 자체 폴링 30s 보다 짧게).
    _refresh = Timer.periodic(const Duration(seconds: 5),
        (_) => SpotifyService.instance.fetchCurrentlyPlaying());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    SpotifyService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _shareToRoom() async {
    final l = AppL10n.of(context);
    final svc = SpotifyService.instance;
    final t = svc.currentTrack;
    if (t == null) {
      showAppSnackBar(l.spotifyNoTrack);
      return;
    }
    final mp = MultiplayerService.instance;
    if (mp.currentRoom == null) {
      showAppSnackBar(l.spotifyRoomRequired);
      return;
    }
    try {
      await mp.sendMessage(t.toChatBody(), kind: 'spotify');
      if (mounted) showAppSnackBar(AppL10n.of(context).spotifyShareSuccess);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).spotifyShareFailed(
            e.toString().replaceFirst('Exception: ', '')));
      }
    }
  }

  Future<void> _disconnect() async {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.spotifyDisconnectTitle,
      content: l.spotifyDisconnectBody,
      confirmText: l.spotifyDisconnectConfirm,
      isDestructive: true,
      onConfirm: () async {
        await SpotifyService.instance.disconnect();
        if (mounted) showAppSnackBar(AppL10n.of(context).spotifyDisconnected);
      },
    );
  }

  Future<void> _connect() async {
    try {
      await SpotifyService.instance.connect();
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).spotifyAuthRetryHint);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
            AppL10n.of(context).spotifyConnectFailed(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final spotify = SpotifyService.instance;
    final t = spotify.currentTrack;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AdaptiveAppBar(title: 'Spotify'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!spotify.isConfigured)
                _Notice(
                  icon: Icons.warning_amber_rounded,
                  text: l.spotifyClientIdMissing,
                ),
              if (spotify.isConfigured && !spotify.isConnected) ...[
                if (spotify.tokenInvalidated)
                  _Notice(
                    icon: Icons.warning_amber_rounded,
                    text: l.spotifyTokenExpired,
                  ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1DB954),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.music_note_rounded,
                        size: 56, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                    spotify.tokenInvalidated ? l.spotifyReconnect : l.spotifyConnect,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface)),
                const SizedBox(height: 8),
                Text(
                    l.spotifyConnectDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurfaceVariant)),
                const Spacer(),
                AdaptiveGlassButton(
                  label: l.spotifyLoginButton,
                  onPressed: _connect,
                ),
              ],
              if (spotify.isConnected) ...[
                _ConnectedHeader(track: t),
                const SizedBox(height: 24),
                if (t != null) ...[
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: t.albumImageUrl != null
                          ? Image.network(t.albumImageUrl!,
                              width: 220, height: 220, fit: BoxFit.cover)
                          : Container(
                              width: 220, height: 220,
                              color: cs.surfaceContainerHighest,
                              child: Icon(Icons.music_note_rounded,
                                  size: 80, color: cs.onSurfaceVariant)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(t.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text(t.artist,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: cs.onSurfaceVariant)),
                ] else ...[
                  const SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.pause_circle_outline_rounded,
                            size: 56, color: cs.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(l.spotifyNoTrack,
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                AdaptiveGlassButton(
                  label: l.spotifyShareToRoom,
                  onPressed: t == null ? null : _shareToRoom,
                ),
                const SizedBox(height: 8),
                if (t?.externalUrl != null)
                  TextButton.icon(
                    onPressed: () =>
                        launchUrl(Uri.parse(t!.externalUrl!),
                            mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(l.spotifyOpenInApp),
                  ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _disconnect,
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                  child: Text(l.spotifyDisconnect),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectedHeader extends StatelessWidget {
  final SpotifyTrack? track;
  const _ConnectedHeader({required this.track});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1DB954),
          ),
        ),
        const SizedBox(width: 6),
        Text(track == null ? l.spotifyConnectedNoTrack : l.spotifyNowPlaying,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Notice({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style:
                    TextStyle(fontSize: 12, color: cs.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
