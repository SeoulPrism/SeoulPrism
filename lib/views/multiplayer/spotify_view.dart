import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final svc = SpotifyService.instance;
    final t = svc.currentTrack;
    if (t == null) {
      showAppSnackBar('재생 중인 곡이 없어요');
      return;
    }
    final mp = MultiplayerService.instance;
    if (mp.currentRoom == null) {
      showAppSnackBar('친구방에 입장한 뒤 다시 시도해주세요');
      return;
    }
    try {
      await mp.sendMessage(t.toChatBody(), kind: 'spotify');
      if (mounted) showAppSnackBar('🎵 친구방에 공유했어요');
    } catch (e) {
      if (mounted) {
        showAppSnackBar('공유 실패: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }
  }

  Future<void> _disconnect() async {
    showAdaptiveConfirmDialog(
      context: context,
      title: 'Spotify 연결 해제',
      content: '저장된 토큰을 삭제하고 친구에게 곡 공유가 중단돼요.',
      confirmText: '해제',
      isDestructive: true,
      onConfirm: () async {
        await SpotifyService.instance.disconnect();
        if (mounted) showAppSnackBar('Spotify 해제됨');
      },
    );
  }

  Future<void> _connect() async {
    try {
      await SpotifyService.instance.connect();
      if (mounted) {
        showAppSnackBar('Spotify 인증 후 자동으로 돌아와요');
      }
    } catch (e) {
      if (mounted) showAppSnackBar('연결 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                  text: '개발자 SPOTIFY_CLIENT_ID 미설정',
                ),
              if (spotify.isConfigured && !spotify.isConnected) ...[
                if (spotify.tokenInvalidated)
                  _Notice(
                    icon: Icons.warning_amber_rounded,
                    text: '연결이 만료됐어요. 다시 로그인해주세요.',
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
                Text(spotify.tokenInvalidated ? 'Spotify 다시 연결' : 'Spotify 연결',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface)),
                const SizedBox(height: 8),
                Text(
                    '연결하면 친구방 채팅에 듣고 있는 곡을\n공유할 수 있고, 친구도 내가 듣는 곡을 봐요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurfaceVariant)),
                const Spacer(),
                AdaptiveGlassButton(
                  label: 'Spotify 로 로그인',
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
                        Text('재생 중인 곡이 없어요',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                AdaptiveGlassButton(
                  label: '친구방에 공유',
                  onPressed: t == null ? null : _shareToRoom,
                ),
                const SizedBox(height: 8),
                if (t?.externalUrl != null)
                  TextButton.icon(
                    onPressed: () =>
                        launchUrl(Uri.parse(t!.externalUrl!),
                            mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Spotify 에서 열기'),
                  ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _disconnect,
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                  child: const Text('연결 해제'),
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
        Text(track == null ? 'Spotify 연결됨 (재생 없음)' : '지금 듣는 곡',
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
