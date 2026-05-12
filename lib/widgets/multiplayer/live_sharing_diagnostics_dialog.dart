import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/multiplayer_service.dart';

/// LiveSharingBadge 길게 누르기 → 실시간 진단 정보 보여주는 다이얼로그.
/// 위치 공유가 안 될 때 친구한테 화면 캡처 요청해서 원인 즉시 진단.
class LiveSharingDiagnosticsDialog extends StatelessWidget {
  const LiveSharingDiagnosticsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const LiveSharingDiagnosticsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = MultiplayerService.instance;
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final myProfile = svc.myProfile;
    final room = svc.currentRoom;
    final memberIds = svc.currentRoomMembers;
    final peers = svc.peerLocations;

    final visibility = myProfile?.visibility ?? l.liveDiagNoProfile;
    final roomLabel = room == null
        ? l.liveDiagNone
        : l.liveDiagRoomLabel(room.inviteCode, memberIds.length);
    final lastTrack = svc.lastRoomTrackAt;
    final lastTrackText = lastTrack == null
        ? l.liveDiagNotSent
        : l.liveDiagSecondsAgo(DateTime.now().difference(lastTrack).inSeconds);
    final trackErr = svc.lastRoomTrackError;
    final presenceStatus = svc.roomPresenceStatus ?? l.liveDiagNotConnected;
    final worldStatus = svc.worldChannelStatus ?? l.liveDiagNotUsed;
    final lastBroadcasted = svc.lastBroadcasted;
    final hasGps = lastBroadcasted != null;

    bool isOk = visibility != 'ghost' &&
        room != null &&
        presenceStatus.contains('SUBSCRIBED') &&
        lastTrack != null &&
        DateTime.now().difference(lastTrack).inSeconds < 30 &&
        trackErr == null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: isOk ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(l.liveDiagTitle),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(l.liveDiagMyId, svc.myId ?? l.liveDiagNone, cs),
            _row(l.liveDiagVisibility, visibility, cs,
                warn: visibility == 'ghost'),
            _row(l.liveDiagRoom, roomLabel, cs, warn: room == null),
            _row(l.liveDiagPeers, l.liveDiagPeersValue(peers.length), cs),
            const Divider(),
            _row(l.liveDiagPresenceStatus, presenceStatus, cs,
                warn: !presenceStatus.contains('SUBSCRIBED')),
            _row(l.liveDiagWorldStatus, worldStatus, cs),
            _row(l.liveDiagLastSent, lastTrackText, cs,
                warn: lastTrack == null ||
                    DateTime.now().difference(lastTrack).inSeconds > 30),
            if (trackErr != null) _row(l.liveDiagSendError, trackErr, cs, warn: true),
            const Divider(),
            _row(l.liveDiagGps, hasGps ? l.liveDiagGpsHas : l.liveDiagGpsNo, cs,
                warn: !hasGps),
            _row(l.liveDiagPaused, svc.seoulLivePaused ? 'YES' : 'no', cs,
                warn: svc.seoulLivePaused),
            if (svc.activityFailCount > 0)
              _row(l.liveDiagActivityFailCount,
                  l.liveDiagActivityFailValue(svc.activityFailCount), cs, warn: true),
            if (svc.lastActivityError != null)
              _row(l.liveDiagLastActivityError, svc.lastActivityError!, cs, warn: true),
            const SizedBox(height: 12),
            Text(
              l.liveDiagFooter,
              style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.liveDiagClose),
        ),
      ],
    );
  }

  Widget _row(String label, String value, ColorScheme cs,
      {bool warn = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: warn ? Colors.orange : cs.onSurface,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
