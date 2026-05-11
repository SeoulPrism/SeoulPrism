import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../services/spotify_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';
import 'peer_profile_card.dart';
import 'report_sheet.dart';

class ChatSheet extends StatefulWidget {
  const ChatSheet({super.key});

  /// 풀스크린 채팅 페이지로 push (DM 과 동일 패턴).
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ChatSheet(),
    ));
  }

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _recorder = AudioRecorder();
  bool _recording = false;
  DateTime? _recordStartedAt;
  String? _recordPath;

  static const _quickEmojis = ['👋', '😂', '🔥', '👍', '❤️', '🥲', '🎉', '📍'];

  @override
  void initState() {
    super.initState();
    MultiplayerService.instance.addListener(_onChanged);
    // G13: 채팅 열림 → 미확인 0.
    MultiplayerService.instance.markCurrentRoomRead();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    MultiplayerService.instance.removeListener(_onChanged);
    _scroll.removeListener(_onScroll);
    _ctrl.dispose();
    _scroll.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    // 새 realtime 메시지가 도착해도 사용자가 위에서 옛 메시지 보고 있으면
    // 강제로 바닥으로 끌어내리지 않음.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final pos = _scroll.position;
      if (pos.pixels >= pos.maxScrollExtent - 80) {
        _scroll.jumpTo(pos.maxScrollExtent);
      }
    });
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels < 60) {
      _maybeLoadMore();
    }
  }

  Future<void> _maybeLoadMore() async {
    final svc = MultiplayerService.instance;
    if (!svc.hasMoreMessages || svc.loadingMoreMessages) return;
    final oldMax = _scroll.position.maxScrollExtent;
    final oldPx = _scroll.position.pixels;
    await svc.loadMoreMessages();
    // 옛 메시지가 위쪽에 prepend 됐으니 사용자가 보던 위치를 유지.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final delta = _scroll.position.maxScrollExtent - oldMax;
      if (delta > 0) _scroll.jumpTo(oldPx + delta);
    });
  }

  Future<void> _send({String? body, String kind = 'text'}) async {
    final text = body ?? _ctrl.text;
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    try {
      await MultiplayerService.instance.sendMessage(text, kind: kind);
    } catch (e) {
      // 실패 시 입력값 복원 + 안내. 사용자가 재시도 가능.
      if (!mounted) return;
      _ctrl.text = text;
      showAppSnackBar(AppL10n.of(context).chatSendFailed(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Widget _placeAction(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: cs.onSurface),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
          ],
        ),
      ),
    );
  }

  Future<void> _setRoomDestination(String name, double lat, double lng) async {
    try {
      await MultiplayerService.instance.setRoomDestination(
        name: name, lat: lat, lng: lng,
      );
      if (mounted) showAppSnackBar(AppL10n.of(context).chatRoomDestSet);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).chatActionFailed(e.toString()));
      }
    }
  }

  Future<void> _openExternalDirections(
      String name, double lat, double lng) async {
    // iOS: Apple Maps 우선, 없으면 Google Maps
    // Android: Google Maps geo intent
    final encoded = Uri.encodeComponent(name);
    final urls = <Uri>[
      // iOS Apple Maps
      Uri.parse('http://maps.apple.com/?daddr=$lat,$lng&q=$encoded'),
      // Google Maps universal
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$encoded'),
    ];
    for (final u in urls) {
      try {
        if (await canLaunchUrl(u)) {
          await launchUrl(u, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
    if (mounted) showAppSnackBar(AppL10n.of(context).chatMapAppUnavailable);
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          showAppSnackBar(AppL10n.of(context).chatMicPermissionRequired);
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: path,
      );
      setState(() {
        _recording = true;
        _recordPath = path;
        _recordStartedAt = DateTime.now();
      });
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).chatRecordStartFailed(e.toString()));
      }
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    if (!_recording) return;
    try {
      final path = await _recorder.stop();
      final startedAt = _recordStartedAt;
      setState(() {
        _recording = false;
        _recordStartedAt = null;
      });
      if (cancel || path == null || startedAt == null) return;
      final ms = DateTime.now().difference(startedAt).inMilliseconds;
      if (ms < 500) {
        if (mounted) showAppSnackBar(AppL10n.of(context).chatRecordTooShort);
        return;
      }
      await MultiplayerService.instance.sendVoiceMessage(path, ms);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).chatRecordStopFailed(e.toString()));
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (x == null) return;
      await MultiplayerService.instance.sendImageMessage(x.path);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).chatPhotoSendFailed(e.toString()));
      }
    }
  }

  Future<void> _shareSpotifyTrack() async {
    final l = AppL10n.of(context);
    final svc = SpotifyService.instance;
    if (!svc.isConfigured) {
      showAppSnackBar(l.chatSpotifyClientIdMissing);
      return;
    }
    if (!svc.isConnected) {
      try {
        await svc.connect();
        if (mounted) {
          showAppSnackBar(AppL10n.of(context).chatSpotifyAuthRetryHint);
        }
      } catch (e) {
        if (mounted) {
          showAppSnackBar(
              AppL10n.of(context).chatSpotifyAuthFailed(e.toString()));
        }
      }
      return;
    }
    final track = await svc.fetchCurrentlyPlaying();
    if (track == null) {
      if (mounted) showAppSnackBar(AppL10n.of(context).spotifyNoTrack);
      return;
    }
    try {
      await MultiplayerService.instance.sendMessage(track.toChatBody(),
          kind: 'spotify');
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).spotifyShareFailed(
            e.toString().replaceFirst('Exception: ', '')));
      }
    }
  }

  Future<void> _shareMyLocation() async {
    final l = AppL10n.of(context);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await MultiplayerService.instance.sharePlaceToRoom(
        name: l.chatMyLocation,
        lat: pos.latitude,
        lng: pos.longitude,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(AppL10n.of(context).chatLocationUnavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final svc = MultiplayerService.instance;
    final messages = svc.messages;
    final roomName = svc.currentRoom?.name ?? l.chatDefaultRoomName;
    final memberCount = svc.currentRoomMembers.length;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(
        title: '$roomName ($memberCount)',
      ),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          // (구) 드래그 핸들 제거 — 풀스크린 페이지로 전환됨.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(l.chatMembersInRoom(memberCount),
                    style:
                        TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const Spacer(),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? _ChatGreetingHero(roomName: svc.currentRoom?.name)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    // index 0 = 더 불러오기 인디케이터, 그 외는 메시지.
                    itemCount: messages.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) return _loadMoreHeader(svc);
                      return _bubble(messages[i - 1]);
                    },
                  ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickEmojis.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final e = _quickEmojis[i];
                return GestureDetector(
                  onTap: () => _send(body: e, kind: 'emoji'),
                  child: Container(
                    width: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_recording)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic_rounded, size: 18, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.chatRecordingHint,
                        style: TextStyle(
                            fontSize: 12, color: cs.onErrorContainer)),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                AdaptiveGlassIconButton(
                  icon: Icons.add_photo_alternate_outlined,
                  onPressed: _pickAndSendImage,
                ),
                const SizedBox(width: 4),
                AdaptiveGlassIconButton(
                  icon: Icons.place_outlined,
                  onPressed: _shareMyLocation,
                ),
                const SizedBox(width: 4),
                AdaptiveGlassIconButton(
                  icon: Icons.music_note_rounded,
                  onPressed: _shareSpotifyTrack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AdaptiveTextField(
                    controller: _ctrl,
                    placeholder:
                        _recording ? l.chatRecordingPlaceholder : l.chatMessageHint,
                    onSubmitted: (_) => _send(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (d) => _stopRecording(cancel: d.localPosition.dy < -50),
                  child: AdaptiveGlassIconButton(
                    icon:
                        _recording ? Icons.fiber_manual_record : Icons.mic_none_rounded,
                    onPressed: _recording ? null : null,
                  ),
                ),
                const SizedBox(width: 4),
                AdaptiveGlassIconButton(
                  icon: Icons.send_rounded,
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _placeCard(RoomMessage m, MultiplayerProfile? p, bool isMe) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final parts = m.body.split('|');
    if (parts.length < 3) {
      // 형식 깨진 메시지 — 그냥 텍스트로 fallback.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(m.body,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
      );
    }
    final name = parts[0];
    final lat = double.tryParse(parts[1]);
    final lng = double.tryParse(parts[2]);
    if (lat == null || lng == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[_miniAvatar(p), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxWidth: 260),
              decoration: BoxDecoration(
                color: isMe ? cs.primaryContainer : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                    width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.place_rounded,
                            color: cs.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isMe
                                    ? cs.onPrimaryContainer
                                    : cs.onSurface)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _placeAction(
                          icon: Icons.map_outlined,
                          label: l.chatActionMap,
                          onTap: () {
                            MultiplayerService.instance.requestMapJump(
                                lat: lat, lng: lng, name: name);
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _placeAction(
                          icon: Icons.directions_outlined,
                          label: l.chatActionDirections,
                          onTap: () => _openExternalDirections(name, lat, lng),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _placeAction(
                    icon: Icons.flag_rounded,
                    label: l.chatActionRoomDest,
                    onTap: () => _setRoomDestination(name, lat, lng),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _voiceCard(RoomMessage m, MultiplayerProfile? p, bool isMe) {
    final cs = Theme.of(context).colorScheme;
    final parts = m.body.split('|');
    final url = parts.isNotEmpty ? parts[0] : '';
    final ms = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final secs = (ms / 1000).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[_miniAvatar(p), const SizedBox(width: 8)],
          GestureDetector(
            onTap: () => _playVoice(url),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? cs.primaryContainer : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_fill_rounded,
                      size: 28, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(AppL10n.of(context).chatVoiceLabel(secs),
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              isMe ? cs.onPrimaryContainer : cs.onSurface)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playVoice(String url) async {
    try {
      final s = SoLoud.instance;
      if (!s.isInitialized) await s.init();
      final src = await s.loadUrl(url);
      await s.play(src);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(AppL10n.of(context).chatPlaybackFailed(e.toString()));
      }
    }
  }

  Widget _imageCard(RoomMessage m, MultiplayerProfile? p, bool isMe) {
    final cs = Theme.of(context).colorScheme;
    final url = m.body;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[_miniAvatar(p), const SizedBox(width: 8)],
          GestureDetector(
            onTap: () => _showImageViewer(url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                url,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 200, height: 120,
                  color: cs.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image_outlined,
                      color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageViewer(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40, right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spotifyCard(RoomMessage m, MultiplayerProfile? p, bool isMe) {
    final cs = Theme.of(context).colorScheme;
    final parts = m.body.split('|');
    final name = parts.isNotEmpty ? parts[0] : '';
    final artist = parts.length > 1 ? parts[1] : '';
    final url = parts.length > 2 ? parts[2] : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[_miniAvatar(p), const SizedBox(width: 8)],
          Flexible(
            child: GestureDetector(
              onTap: url.isEmpty
                  ? null
                  : () async {
                      final u = Uri.tryParse(url);
                      if (u != null) {
                        await launchUrl(u, mode: LaunchMode.externalApplication);
                      }
                    },
              child: Container(
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 260),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.5),
                      width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.music_note_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface)),
                          const SizedBox(height: 2),
                          Text(artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant)),
                          if (url.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(AppL10n.of(context).spotifyOpenInApp,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: const Color(0xFF1DB954),
                                    fontWeight: FontWeight.w700)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadMoreHeader(MultiplayerService svc) {
    final cs = Theme.of(context).colorScheme;
    if (svc.loadingMoreMessages) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!svc.hasMoreMessages) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(AppL10n.of(context).chatStart,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  Widget _bubble(RoomMessage m) {
    final cs = Theme.of(context).colorScheme;
    final svc = MultiplayerService.instance;
    final isMe = m.userId == svc.myId;
    final p = svc.peerProfile(m.userId);
    final isMeetup = m.kind == 'meetup' || m.kind == 'system';

    if (m.kind == 'place') return _placeCard(m, p, isMe);
    if (m.kind == 'spotify') return _spotifyCard(m, p, isMe);
    if (m.kind == 'voice') return _voiceCard(m, p, isMe);
    if (m.kind == 'image') return _imageCard(m, p, isMe);

    if (isMeetup) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(m.body,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
        ),
      );
    }

    final isEmojiOnly = m.kind == 'emoji';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        // G2: 길게 누르면 신고 옵션 (본인 메시지는 제외).
        onLongPress: isMe ? null : () => _showMessageMenu(m, p?.nickname),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _miniAvatar(p),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      // #8 닉네임 탭 → peer 프로필 카드 (친구 신청 가능).
                      child: GestureDetector(
                        onTap: () => PeerProfileCard.show(context, m.userId),
                        child: Text(p?.nickname ?? '',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  Container(
                    padding: isEmojiOnly
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                    decoration: isEmojiOnly
                        ? null
                        : BoxDecoration(
                            color: isMe
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                    child: Text(
                      m.body,
                      style: TextStyle(
                          fontSize: isEmojiOnly ? 36 : 14,
                          color: isMe ? cs.onPrimaryContainer : cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageMenu(RoomMessage m, String? senderNickname) {
    final l = AppL10n.of(context);
    final senderLabel = senderNickname ?? l.chatUnknownUser;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.red),
              title: Text(l.chatReport,
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ReportSheet.showForMessage(context, m.id, preview: m.body);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: Text(l.chatBlockDialogTitle(senderLabel)),
              onTap: () {
                Navigator.pop(context);
                showAdaptiveConfirmDialog(
                  context: context,
                  title: l.chatBlockDialogTitle(senderLabel),
                  content: l.chatBlockDialogBody,
                  confirmText: l.chatBlockConfirm,
                  isDestructive: true,
                  onConfirm: () =>
                      MultiplayerService.instance.blockUser(m.userId),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniAvatar(MultiplayerProfile? p) {
    final cs = Theme.of(context).colorScheme;
    if (p == null) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: cs.surfaceContainerHighest,
        child: Icon(Icons.person, size: 14, color: cs.onSurfaceVariant),
      );
    }
    final v = int.parse(p.pinColor.substring(1), radix: 16);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Color(0xFF000000 | v)),
      alignment: Alignment.center,
      child: Text(p.pinEmoji, style: const TextStyle(fontSize: 14)),
    );
  }
}

/// 디스코드식 인사 hero — 메시지 0개일 때만 표시.
/// 손 흔들기 애니메이션 + 환영 메시지.
class _ChatGreetingHero extends StatelessWidget {
  final String? roomName;
  const _ChatGreetingHero({required this.roomName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // 손 흔드는 emoji — flutter_animate 로 좌우 회전 반복.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, t, child) => Transform.scale(
              scale: 0.5 + 0.5 * t,
              child: Opacity(opacity: t.clamp(0, 1), child: child),
            ),
            child: const _WavingHand(),
          ),
          const SizedBox(height: 28),
          Text(
            roomName != null
                ? l.chatEmptyTitleNamed(roomName!)
                : l.chatEmptyTitleDefault,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l.chatEmptyBody,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WavingHand extends StatefulWidget {
  const _WavingHand();
  @override
  State<_WavingHand> createState() => _WavingHandState();
}

class _WavingHandState extends State<_WavingHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: false);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        // 0~0.6 구간 0→0.4 rad, 0.6~1 구간 holding 0
        final t = _ctrl.value;
        double angle;
        if (t < 0.15) {
          angle = (t / 0.15) * 0.6; // up
        } else if (t < 0.30) {
          angle = 0.6 - ((t - 0.15) / 0.15) * 1.2; // down
        } else if (t < 0.45) {
          angle = -0.6 + ((t - 0.30) / 0.15) * 1.2; // up
        } else if (t < 0.60) {
          angle = 0.6 - ((t - 0.45) / 0.15) * 0.6; // back to 0
        } else {
          angle = 0; // pause
        }
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: const Text('👋', style: TextStyle(fontSize: 88)),
        );
      },
    );
  }
}
