import 'package:flutter/material.dart';

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
    final myProfile = svc.myProfile;
    final room = svc.currentRoom;
    final memberIds = svc.currentRoomMembers;
    final peers = svc.peerLocations;

    final visibility = myProfile?.visibility ?? '(프로필 없음)';
    final roomLabel = room == null
        ? '없음'
        : '${room.inviteCode} (${memberIds.length}명)';
    final lastTrack = svc.lastRoomTrackAt;
    final lastTrackText = lastTrack == null
        ? '아직 송신 안함'
        : '${DateTime.now().difference(lastTrack).inSeconds}초 전';
    final trackErr = svc.lastRoomTrackError;
    final presenceStatus = svc.roomPresenceStatus ?? '(미연결)';
    final worldStatus = svc.worldChannelStatus ?? '(미사용)';
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
          const Text('실시간 진단'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('내 ID', svc.myId ?? '(없음)', cs),
            _row('공개 범위', visibility, cs,
                warn: visibility == 'ghost'),
            _row('방', roomLabel, cs, warn: room == null),
            _row('받는 peer', '${peers.length}명', cs),
            const Divider(),
            _row('Presence 상태', presenceStatus, cs,
                warn: !presenceStatus.contains('SUBSCRIBED')),
            _row('World 상태', worldStatus, cs),
            _row('마지막 송신', lastTrackText, cs,
                warn: lastTrack == null ||
                    DateTime.now().difference(lastTrack).inSeconds > 30),
            if (trackErr != null) _row('송신 오류', trackErr, cs, warn: true),
            const Divider(),
            _row('GPS', hasGps ? '있음' : '없음', cs, warn: !hasGps),
            _row('일시정지', svc.seoulLivePaused ? 'YES' : 'no', cs,
                warn: svc.seoulLivePaused),
            if (svc.activityFailCount > 0)
              _row('활동기록 실패', '${svc.activityFailCount}회', cs, warn: true),
            if (svc.lastActivityError != null)
              _row('최근 활동 오류', svc.lastActivityError!, cs, warn: true),
            const SizedBox(height: 12),
            Text(
              '문제 있으면 이 화면 캡처해서 공유',
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
          child: const Text('닫기'),
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
