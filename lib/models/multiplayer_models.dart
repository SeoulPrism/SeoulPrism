// 멀티플레이어 데이터 모델 (Supabase row 1:1 매핑).

class MultiplayerProfile {
  final String userId;
  final String nickname;
  final String pinColor;   // '#RRGGBB'
  final String pinEmoji;   // '🦊'
  final String visibility; // 'friends' | 'ghost' (Phase B 까지 'public' 비활성)
  final int birthYear;
  final String? friendCode; // 8자리, 평생.

  const MultiplayerProfile({
    required this.userId,
    required this.nickname,
    required this.pinColor,
    required this.pinEmoji,
    required this.visibility,
    required this.birthYear,
    this.friendCode,
  });

  factory MultiplayerProfile.fromJson(Map<String, dynamic> j) => MultiplayerProfile(
        userId: j['user_id'] as String,
        nickname: j['nickname'] as String,
        pinColor: (j['pin_color'] as String?) ?? '#7C5CFF',
        pinEmoji: (j['pin_emoji'] as String?) ?? '📍',
        visibility: (j['visibility'] as String?) ?? 'ghost',
        birthYear: (j['birth_year'] as num).toInt(),
        friendCode: j['friend_code'] as String?,
      );

  Map<String, dynamic> toUpsert() => {
        'user_id': userId,
        'nickname': nickname,
        'pin_color': pinColor,
        'pin_emoji': pinEmoji,
        'visibility': visibility,
        'birth_year': birthYear,
      };
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

  /// 30초 이상 업데이트 X 면 stale (지도에 흐릿하게).
  bool get isStale =>
      DateTime.now().difference(timestamp).inSeconds > 30;

  /// 60초 이상이면 사실상 오프라인 (핀 제거 또는 심하게 흐리게).
  bool get isOffline =>
      DateTime.now().difference(timestamp).inSeconds > 60;

  factory PeerLocation.fromPresence(String userId, Map<String, dynamic> p) =>
      PeerLocation(
        userId: userId,
        lat: (p['lat'] as num).toDouble(),
        lng: (p['lng'] as num).toDouble(),
        heading: (p['heading'] as num?)?.toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch((p['ts'] as num).toInt()),
      );

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
