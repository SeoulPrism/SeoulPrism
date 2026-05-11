// 멀티플레이어 데이터 모델 (Supabase row 1:1 매핑).

import 'dart:ui' show Color;

class MultiplayerProfile {
  final String userId;
  final String nickname;
  final String pinColor;   // '#RRGGBB'
  final String pinEmoji;   // '🦊'
  final String visibility; // 'friends' | 'ghost' (Phase B 까지 'public' 비활성)
  final int birthYear;
  final String? friendCode; // 8자리, 평생.
  final PeerTrack? currentTrack; // Spotify 듣는 곡 (B26).
  /// Supabase Storage `avatars` bucket 의 public URL. null 이면 이모지 fallback.
  final String? avatarUrl;

  const MultiplayerProfile({
    required this.userId,
    required this.nickname,
    required this.pinColor,
    required this.pinEmoji,
    required this.visibility,
    required this.birthYear,
    this.friendCode,
    this.currentTrack,
    this.avatarUrl,
  });

  factory MultiplayerProfile.fromJson(Map<String, dynamic> j) => MultiplayerProfile(
        userId: j['user_id'] as String,
        nickname: j['nickname'] as String,
        pinColor: (j['pin_color'] as String?) ?? '#7C5CFF',
        pinEmoji: (j['pin_emoji'] as String?) ?? '📍',
        visibility: (j['visibility'] as String?) ?? 'ghost',
        birthYear: (j['birth_year'] as num).toInt(),
        friendCode: j['friend_code'] as String?,
        currentTrack: PeerTrack.tryFromJson(j['current_track']),
        avatarUrl: (j['avatar_url'] as String?)?.trim().isEmpty == true
            ? null
            : j['avatar_url'] as String?,
      );

  // avatar_url 은 별도 upload 경로에서 set — toUpsert 에는 포함하지 않음
  // (닉네임 저장 시 실수로 사진을 null 로 덮어쓰지 않도록).
  Map<String, dynamic> toUpsert() => {
        'user_id': userId,
        'nickname': nickname,
        'pin_color': pinColor,
        'pin_emoji': pinEmoji,
        'visibility': visibility,
        'birth_year': birthYear,
      };

  /// pinColor 가 잘못된 hex (#GG0000, 빈 문자열 등) 일 때도 죽지 않게 fallback.
  Color get safePinColor {
    try {
      final s = pinColor.startsWith('#') ? pinColor.substring(1) : pinColor;
      if (s.length != 6) return const Color(0xFF7C5CFF);
      return Color(0xFF000000 | int.parse(s, radix: 16));
    } catch (_) {
      return const Color(0xFF7C5CFF);
    }
  }

  /// 표시용 닉네임 — 빈 문자열이면 fallback.
  String get displayNickname =>
      nickname.trim().isEmpty ? '익명' : nickname;
}

/// 친구가 지금 듣는 곡 (profiles.current_track jsonb 미러).
class PeerTrack {
  final String name;
  final String artist;
  final String? albumImageUrl;
  final String? externalUrl;
  /// 곡 정보 마지막 갱신 시각 — Spotify polling 이 sync 한 시각.
  /// 너무 오래된 정보 (예: 1시간 이상) 면 UI 가 흐릿하게 표시.
  final DateTime? updatedAt;

  const PeerTrack({
    required this.name,
    required this.artist,
    this.albumImageUrl,
    this.externalUrl,
    this.updatedAt,
  });

  static PeerTrack? tryFromJson(dynamic j) {
    if (j is! Map) return null;
    final name = j['name'] as String?;
    if (name == null || name.isEmpty) return null;
    DateTime? updatedAt;
    final ts = j['updated_at'];
    if (ts is String) updatedAt = DateTime.tryParse(ts);
    return PeerTrack(
      name: name,
      artist: (j['artist'] as String?) ?? '',
      albumImageUrl: j['album_image_url'] as String?,
      externalUrl: j['external_url'] as String?,
      updatedAt: updatedAt,
    );
  }

  /// 1시간 이상 갱신 없으면 stale — UI 가 시각적 구분 (흐림/오래된 표시).
  bool get isStale {
    final at = updatedAt;
    if (at == null) return false;
    return DateTime.now().difference(at).inMinutes > 60;
  }
}

class Friendship {
  final String userA;
  final String userB;
  final String status;
  final String initiatedBy;

  const Friendship({
    required this.userA,
    required this.userB,
    required this.status,
    required this.initiatedBy,
  });

  String otherSide(String me) => userA == me ? userB : userA;
  bool get isAccepted => status == 'accepted';
  bool isIncoming(String me) => initiatedBy != me && status == 'pending';

  factory Friendship.fromJson(Map<String, dynamic> j) => Friendship(
        userA: j['user_a'] as String,
        userB: j['user_b'] as String,
        status: j['status'] as String,
        initiatedBy: j['initiated_by'] as String,
      );
}

class Room {
  final String id;
  final String inviteCode;
  final String ownerId;
  final String? name;
  final DateTime expiresAt;
  /// 방 공통 목적지 (Phase B6 같이 가기). null = 미설정.
  final String? destName;
  final double? destLat;
  final double? destLng;
  final String? destSetBy;

  const Room({
    required this.id,
    required this.inviteCode,
    required this.ownerId,
    required this.name,
    required this.expiresAt,
    this.destName,
    this.destLat,
    this.destLng,
    this.destSetBy,
  });

  bool get hasDestination => destLat != null && destLng != null;

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        id: j['id'] as String,
        inviteCode: j['invite_code'] as String,
        ownerId: j['owner_id'] as String,
        name: j['name'] as String?,
        expiresAt: DateTime.parse(j['expires_at'] as String),
        destName: j['dest_name'] as String?,
        destLat: (j['dest_lat'] as num?)?.toDouble(),
        destLng: (j['dest_lng'] as num?)?.toDouble(),
        destSetBy: j['dest_set_by'] as String?,
      );
}

class RoomMessage {
  final String id;
  final String roomId;
  final String userId;
  final String body;
  final String kind;
  final DateTime createdAt;

  const RoomMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.body,
    required this.kind,
    required this.createdAt,
  });

  factory RoomMessage.fromJson(Map<String, dynamic> j) => RoomMessage(
        id: j['id'] as String,
        roomId: j['room_id'] as String,
        userId: j['user_id'] as String,
        body: j['body'] as String,
        kind: (j['kind'] as String?) ?? 'text',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class PeerLocation {
  final String userId;
  final double lat;
  final double lng;
  final double? heading;
  final DateTime timestamp;

  const PeerLocation({
    required this.userId,
    required this.lat,
    required this.lng,
    this.heading,
    required this.timestamp,
  });

  /// 송신/수신 클라이언트 시계 어긋남 보정 — abs() 로 negative 일 때도 측정.
  int get _ageSeconds =>
      DateTime.now().difference(timestamp).inSeconds.abs();

  /// 30초 이상 업데이트 X 면 stale (지도에 흐릿하게).
  bool get isStale => _ageSeconds > 30;

  /// 60초 이상이면 사실상 오프라인 (핀 제거 또는 심하게 흐리게).
  bool get isOffline => _ageSeconds > 60;

  factory PeerLocation.fromPresence(String userId, Map<String, dynamic> p) {
    // ts 가 비정상 (현재 ± 1년 이상) 이면 now() 로 fallback. 잘못된 단위
    // (nanosecond, future timestamp) 로 들어와도 staleness 계산 망가지지 않음.
    final rawTs = (p['ts'] as num?)?.toInt();
    final now = DateTime.now().millisecondsSinceEpoch;
    const yearMs = 365 * 24 * 60 * 60 * 1000;
    final ts = (rawTs == null || (rawTs - now).abs() > yearMs) ? now : rawTs;
    return PeerLocation(
      userId: userId,
      lat: (p['lat'] as num).toDouble(),
      lng: (p['lng'] as num).toDouble(),
      // heading: payload 에 key 없으면 null, 0 이면 0.0. 둘 다 의미 다름.
      heading: p.containsKey('heading')
          ? (p['heading'] as num?)?.toDouble()
          : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
    );
  }

  Map<String, dynamic> toPayload() => {
        'lat': lat,
        'lng': lng,
        if (heading != null) 'heading': heading,
        'ts': timestamp.millisecondsSinceEpoch,
      };
}

/// 친구 그룹.
class FriendGroup {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final int sortOrder;
  /// 그룹에 포함된 친구 user_id 리스트 (별도 fetch).
  final List<String> memberIds;

  const FriendGroup({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.sortOrder,
    required this.memberIds,
  });

  factory FriendGroup.fromJson(
    Map<String, dynamic> j, {
    List<String> memberIds = const [],
  }) =>
      FriendGroup(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        name: j['name'] as String,
        emoji: (j['emoji'] as String?) ?? '👥',
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
        memberIds: memberIds,
      );
}

/// 위치 송신 배터리/정확도 모드.
enum BatteryMode {
  precise(label: '정확', intervalSec: 3),
  balanced(label: '표준', intervalSec: 5),
  saver(label: '절약', intervalSec: 15);

  final String label;
  final int intervalSec;
  const BatteryMode({required this.label, required this.intervalSec});
}

/// 신고 종류.
enum ReportTargetType { user, message }

/// 1:1 DM (Phase B17).
class DmMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String body;
  final String kind;
  final DateTime createdAt;
  final bool readByRecipient;

  const DmMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    required this.kind,
    required this.createdAt,
    required this.readByRecipient,
  });

  factory DmMessage.fromJson(Map<String, dynamic> j) => DmMessage(
        id: j['id'] as String,
        threadId: j['thread_id'] as String,
        senderId: j['sender_id'] as String,
        body: j['body'] as String,
        kind: (j['kind'] as String?) ?? 'text',
        createdAt: DateTime.parse(j['created_at'] as String),
        readByRecipient: (j['read_by_recipient'] as bool?) ?? false,
      );
}

class DmThreadSummary {
  final String threadId;
  final String otherUserId;
  final DateTime lastMessageAt;
  final String? lastBody;
  final String? lastKind;
  final int unreadCount;

  const DmThreadSummary({
    required this.threadId,
    required this.otherUserId,
    required this.lastMessageAt,
    required this.lastBody,
    required this.lastKind,
    required this.unreadCount,
  });
}

/// 게이미피케이션 점수/뱃지 (Phase B7).
class UserScore {
  final String userId;
  final int totalPoints;
  final int meetupCount;
  final int friendCount;
  final int roomsJoined;
  final int currentStreakDays;
  final int longestStreakDays;
  final List<String> badges;

  const UserScore({
    required this.userId,
    required this.totalPoints,
    required this.meetupCount,
    required this.friendCount,
    required this.roomsJoined,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.badges,
  });

  factory UserScore.fromJson(Map<String, dynamic> j) => UserScore(
        userId: j['user_id'] as String,
        totalPoints: (j['total_points'] as num?)?.toInt() ?? 0,
        meetupCount: (j['meetup_count'] as num?)?.toInt() ?? 0,
        friendCount: (j['friend_count'] as num?)?.toInt() ?? 0,
        roomsJoined: (j['rooms_joined'] as num?)?.toInt() ?? 0,
        currentStreakDays: (j['current_streak_days'] as num?)?.toInt() ?? 0,
        longestStreakDays: (j['longest_streak_days'] as num?)?.toInt() ?? 0,
        badges: ((j['badges'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  static const empty = UserScore(
    userId: '',
    totalPoints: 0,
    meetupCount: 0,
    friendCount: 0,
    roomsJoined: 0,
    currentStreakDays: 0,
    longestStreakDays: 0,
    badges: [],
  );
}

/// 뱃지 메타 — 코드 → 이모지 + 한글 라벨.
class BadgeMeta {
  final String code;
  final String emoji;
  final String label;
  const BadgeMeta(this.code, this.emoji, this.label);

  static const all = <BadgeMeta>[
    BadgeMeta('first_friend', '🤝', '첫 친구'),
    BadgeMeta('ten_friends', '🫂', '친구 10명'),
    BadgeMeta('first_meetup', '🎉', '첫 만남'),
    BadgeMeta('ten_meetups', '🥳', '만남 10회'),
    BadgeMeta('fifty_meetups', '🏆', '만남 50회'),
    BadgeMeta('streak_7', '🔥', '7일 연속'),
    BadgeMeta('night_owl', '🌙', '심야 만남'),
  ];

  static BadgeMeta? lookup(String code) {
    for (final b in all) {
      if (b.code == code) return b;
    }
    return null;
  }
}
