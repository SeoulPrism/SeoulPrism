import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/multiplayer_models.dart';

/// Seoul Live — 멀티플레이어 코어.
class MultiplayerService with WidgetsBindingObserver {
  MultiplayerService._() {
    WidgetsBinding.instance.addObserver(this);
  }
  static final MultiplayerService instance = MultiplayerService._();

  // ── Supabase shortcut ──────────────────────────────────────────────
  SupabaseClient get _sb => Supabase.instance.client;
  String? get myId => _sb.auth.currentUser?.id;

  // ── 상태 ───────────────────────────────────────────────────────────
  MultiplayerProfile? _myProfile;
  MultiplayerProfile? get myProfile => _myProfile;

  final List<Friendship> _friendships = [];
  List<Friendship> get friendships => List.unmodifiable(_friendships);

  final Map<String, MultiplayerProfile> _peerProfiles = {};
  MultiplayerProfile? peerProfile(String userId) => _peerProfiles[userId];

  Room? _currentRoom;
  Room? get currentRoom => _currentRoom;

  final List<String> _currentRoomMembers = [];
  List<String> get currentRoomMembers => List.unmodifiable(_currentRoomMembers);

  final Map<String, PeerLocation> _peerLocations = {};
  /// 룸 peers + world peers 머지 (룸 우선).
  Map<String, PeerLocation> get peerLocations {
    final merged = <String, PeerLocation>{};
    merged.addAll(_worldPeerLocations);
    merged.addAll(_peerLocations);
    return Map.unmodifiable(merged);
  }

  final List<RoomMessage> _messages = [];
  List<RoomMessage> get messages => List.unmodifiable(_messages);

  bool _loadingMoreMessages = false;
  bool _hasMoreMessages = true;
  bool get loadingMoreMessages => _loadingMoreMessages;
  bool get hasMoreMessages => _hasMoreMessages;

  /// 채팅에서 공유된 장소 카드 탭 → 맵 점프 요청. map_view 가 listen.
  /// 페이로드: {lat, lng, name?}.
  final ValueNotifier<Map<String, dynamic>?> pendingMapJump =
      ValueNotifier(null);
  void requestMapJump({required double lat, required double lng, String? name}) {
    pendingMapJump.value = {'lat': lat, 'lng': lng, if (name != null) 'name': name};
  }

  final Set<String> _blockedUserIds = {};
  bool isBlocked(String userId) => _blockedUserIds.contains(userId);

  final Set<String> _activeMeetups = {};
  Set<String> get activeMeetups => Set.unmodifiable(_activeMeetups);

  /// X9: 같은 peer 와 60초 내 만남 알림 dedupe.
  final Map<String, DateTime> _lastMeetupNotifiedAt = {};

  final List<FriendGroup> _friendGroups = [];
  List<FriendGroup> get friendGroups => List.unmodifiable(_friendGroups);

  /// 채팅 미확인 수: roomId → count.
  final Map<String, int> _unreadCounts = {};
  int unreadCount(String roomId) => _unreadCounts[roomId] ?? 0;
  int get totalUnread =>
      _unreadCounts.values.fold(0, (a, b) => a + b);

  /// Seoul Live 모드 + 일시정지.
  bool _seoulLiveActive = false;
  bool get seoulLiveActive => _seoulLiveActive;

  bool _seoulLivePaused = false;
  bool get seoulLivePaused => _seoulLivePaused;

  /// 배터리 모드.
  BatteryMode _batteryMode = BatteryMode.balanced;
  BatteryMode get batteryMode => _batteryMode;

  /// 이동 중인지 (정지면 더 긴 주기 사용).
  bool _isStationary = false;

  /// 백그라운드 진입 시 송신 일시정지 플래그.
  bool _isInBackground = false;

  // ── 상수 ───────────────────────────────────────────────────────────
  static const int kRoomCapacity = 8;
  static const double kMeetupRadiusMeters = 50.0;
  static const int kMinAgeYears = 14;
  static const int kFriendLimit = 200;
  static const Duration _stationaryThreshold = Duration(seconds: 60);
  static const double _stationaryMeters = 8.0;

  // ── 채널 / 타이머 ──────────────────────────────────────────────────
  RealtimeChannel? _presenceChannel;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _membersChannel;
  RealtimeChannel? _roomMetaChannel; // rooms 테이블 자체의 update (목적지 등).
  RealtimeChannel? _friendsChannel;
  /// 전 세계 공개 사용자 채널 (visibility=public).
  RealtimeChannel? _worldChannel;
  /// 세계 채널 peers — 룸 peers 와 별도 저장 후 getter 에서 merge.
  final Map<String, PeerLocation> _worldPeerLocations = {};
  Timer? _locationTimer;
  Timer? _staleTickTimer;
  StreamSubscription<AuthState>? _authSub;
  String? _lastKnownUserId;

  // ── 리스너 ─────────────────────────────────────────────────────────
  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback l) => _listeners.add(l);
  void removeListener(VoidCallback l) => _listeners.remove(l);
  void _notify() {
    for (final l in List.of(_listeners)) {
      try { l(); } catch (_) {}
    }
  }

  final List<void Function(String peerUserId, bool started)> _meetupListeners = [];
  void addMeetupListener(void Function(String, bool) l) => _meetupListeners.add(l);

  /// peer 가 새 곡을 시작했을 때 알림. (peerUserId, trackName, artist).
  final List<void Function(String userId, String track, String artist)>
      _peerTrackListeners = [];
  void addPeerTrackListener(
          void Function(String, String, String) l) =>
      _peerTrackListeners.add(l);
  void removePeerTrackListener(
          void Function(String, String, String) l) =>
      _peerTrackListeners.remove(l);

  RealtimeChannel? _profilesChannel;

  /// 친구방 입장 시 호출 — 같은 방 멤버들의 profile 변경 (특히 current_track) 구독.
  void _subscribeFriendProfiles() {
    if (myId == null) return;
    _profilesChannel?.unsubscribe();
    _profilesChannel = _sb
        .channel('profiles_friends_$myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          callback: (payload) async {
            try {
              final updated = MultiplayerProfile.fromJson(payload.newRecord);
              final prev = _peerProfiles[updated.userId];
              _peerProfiles[updated.userId] = updated;
              // 곡 변경 감지 → 리스너 호출.
              final newName = updated.currentTrack?.name;
              final oldName = prev?.currentTrack?.name;
              if (newName != null && newName != oldName &&
                  updated.userId != myId) {
                for (final l in List.of(_peerTrackListeners)) {
                  try {
                    l(updated.userId, newName,
                        updated.currentTrack?.artist ?? '');
                  } catch (_) {}
                }
              }
              _notify();
            } catch (_) {}
          },
        )
        .subscribe();
  }

  /// B7 게이미피케이션 — 내 점수/뱃지.
  UserScore? _myScore;
  UserScore? get myScore => _myScore;
  RealtimeChannel? _scoreChannel;

  /// 최근 만남 기록 (in-memory, 최대 20개). 앱 재시작 시 사라짐.
  final List<({String userId, DateTime at})> _meetupHistory = [];
  List<({String userId, DateTime at})> get meetupHistory =>
      List.unmodifiable(_meetupHistory);
  void _recordMeetup(String userId) {
    _meetupHistory.insert(0, (userId: userId, at: DateTime.now()));
    if (_meetupHistory.length > 20) _meetupHistory.removeLast();
    logActivity('meetup', payload: {'peer': userId});
    _notify();
  }
  void removeMeetupListener(void Function(String, bool) l) =>
      _meetupListeners.remove(l);

  /// 친구 신청 받았을 때 콜백 (UI 토스트/배지 트리거용).
  final List<VoidCallback> _friendRequestListeners = [];
  void addFriendRequestListener(VoidCallback l) =>
      _friendRequestListeners.add(l);
  void removeFriendRequestListener(VoidCallback l) =>
      _friendRequestListeners.remove(l);

  /// 위치 권한 거부 시 1회 알림 (UI 가 SnackBar 등으로 안내).
  final List<VoidCallback> _locationDeniedListeners = [];
  void addLocationDeniedListener(VoidCallback l) =>
      _locationDeniedListeners.add(l);
  void removeLocationDeniedListener(VoidCallback l) =>
      _locationDeniedListeners.remove(l);

  // ──────────────────────────────────────────────────────────────────
  // 앱 라이프사이클 — 백그라운드 진입 시 위치 송신 일시정지.
  // ──────────────────────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasBg = _isInBackground;
    _isInBackground = state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
    if (wasBg && !_isInBackground) {
      // 포그라운드 복귀.
      _syncWorldChannel();
      if (_currentRoom != null && _myProfile?.visibility != 'ghost') {
        _startLocationBroadcast();
      }
    } else if (!wasBg && _isInBackground) {
      // 백그라운드 — 즉시 송신 중단 + world 채널 untrack.
      _stopLocationBroadcast();
      _worldChannel?.untrack();
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 초기화
  // ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _ensureAuthListener();
    final user = _sb.auth.currentUser;
    if (user == null || user.isAnonymous) return;
    _lastKnownUserId = user.id;
    await _loadBatteryMode();
    await _loadMyProfile();
    await _loadFriendships();
    await _loadBlocks();
    await _loadFriendGroups();
    await loadMyVisibleGroups();
    await loadNotifPrefs();
    await _loadMyScore();
    _subscribeMyScore();
    _subscribeFriendshipUpdates();
    _startStaleTick();
    _syncWorldChannel();
  }

  void _ensureAuthListener() {
    _authSub ??= _sb.auth.onAuthStateChange.listen((data) async {
      final newUser = data.session?.user;
      final newId = newUser?.id;

      if (newUser == null || newUser.isAnonymous) {
        await _resetAllState();
        _lastKnownUserId = newId;
        return;
      }

      if (newId != _lastKnownUserId) {
        await _resetAllState();
        _lastKnownUserId = newId;
        await _loadBatteryMode();
        await _loadMyProfile();
        await _loadFriendships();
        await _loadBlocks();
        await _loadFriendGroups();
        await loadMyVisibleGroups();
        await loadNotifPrefs();
        await _loadMyScore();
        _subscribeMyScore();
        _subscribeFriendshipUpdates();
        _startStaleTick();
        _syncWorldChannel();
      }
    });
  }

  Future<void> _resetAllState() async {
    _locationTimer?.cancel();
    _locationTimer = null;
    _staleTickTimer?.cancel();
    _staleTickTimer = null;
    try {
      await _presenceChannel?.unsubscribe();
      await _messagesChannel?.unsubscribe();
      await _membersChannel?.unsubscribe();
      await _roomMetaChannel?.unsubscribe();
      await _profilesChannel?.unsubscribe();
      await _friendsChannel?.unsubscribe();
      await _worldChannel?.unsubscribe();
      await _scoreChannel?.unsubscribe();
    } catch (_) {}
    _presenceChannel = null;
    _messagesChannel = null;
    _membersChannel = null;
    _roomMetaChannel = null;
    _profilesChannel = null;
    _friendsChannel = null;
    _worldChannel = null;
    _scoreChannel = null;
    _myScore = null;
    _myVisibleGroupIds.clear();
    _peerVisibleCache.clear();
    _worldPeerLocations.clear();

    _myProfile = null;
    _friendships.clear();
    _peerProfiles.clear();
    _currentRoom = null;
    _currentRoomMembers.clear();
    _peerLocations.clear();
    _messages.clear();
    _blockedUserIds.clear();
    _activeMeetups.clear();
    _friendGroups.clear();
    _unreadCounts.clear();
    _seoulLiveActive = false;
    _seoulLivePaused = false;
    _lastBroadcasted = null;
    _isStationary = false;
    _notify();
  }

  /// 30초 주기로 stale presence + 만료 임박 체크 → UI re-render.
  void _startStaleTick() {
    _staleTickTimer?.cancel();
    _staleTickTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _notify());
  }

  // ──────────────────────────────────────────────────────────────────
  // 프로필
  // ──────────────────────────────────────────────────────────────────
  Future<void> _loadMyProfile() async {
    try {
      final res = await _sb
          .from('profiles')
          .select()
          .eq('user_id', myId!)
          .maybeSingle();
      if (res != null) {
        _myProfile = MultiplayerProfile.fromJson(res);
        _peerProfiles[myId!] = _myProfile!;
        _seoulLiveActive = true;
      }
      _notify();
    } catch (e) {
      debugPrint('[Multi] _loadMyProfile 실패: $e');
    }
  }

  Future<MultiplayerProfile> upsertMyProfile({
    required String nickname,
    required int birthYear,
    String pinColor = '#7C5CFF',
    String pinEmoji = '📍',
    String visibility = 'friends',
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('정식 로그인이 필요합니다.');
    }
    final age = DateTime.now().year - birthYear;
    if (age < kMinAgeYears) {
      throw ArgumentError('14세 미만은 가입할 수 없습니다.');
    }
    // 가시성 검증.
    if (!const ['public', 'friends', 'ghost'].contains(visibility)) {
      visibility = 'friends';
    }

    final profile = MultiplayerProfile(
      userId: myId!,
      nickname: nickname,
      pinColor: pinColor,
      pinEmoji: pinEmoji,
      visibility: visibility,
      birthYear: birthYear,
    );

    try {
      final res = await _sb
          .from('profiles')
          .upsert(profile.toUpsert())
          .select()
          .single();

      final wasNewProfile = _myProfile == null;
      _myProfile = MultiplayerProfile.fromJson(res);
      _peerProfiles[myId!] = _myProfile!;

      if (_myProfile!.visibility == 'ghost') {
        _stopLocationBroadcast();
      } else if (_currentRoom != null) {
        _startLocationBroadcast();
      }
      // public ↔ friends/ghost 전환 시 world 채널 sync.
      _syncWorldChannel();

      if (wasNewProfile) _seoulLiveActive = true;
      _notify();
      return _myProfile!;
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> setVisibility(String visibility) async {
    if (_myProfile == null) return;
    await upsertMyProfile(
      nickname: _myProfile!.nickname,
      birthYear: _myProfile!.birthYear,
      pinColor: _myProfile!.pinColor,
      pinEmoji: _myProfile!.pinEmoji,
      visibility: visibility,
    );
  }

  /// G3 - Seoul Live 일시정지. 데이터는 유지.
  void setSeoulLivePaused(bool paused) {
    if (_seoulLivePaused == paused) return;
    _seoulLivePaused = paused;
    if (paused) {
      _stopLocationBroadcast();
      _worldChannel?.untrack();
    } else if (_currentRoom != null && _myProfile?.visibility != 'ghost') {
      _startLocationBroadcast();
    }
    _syncWorldChannel();
    _notify();
  }

  Future<MultiplayerProfile?> fetchPeerProfile(String userId) async {
    if (_peerProfiles.containsKey(userId)) return _peerProfiles[userId];
    try {
      final res = await _sb
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null) {
        final p = MultiplayerProfile.fromJson(res);
        _peerProfiles[userId] = p;
        _notify();
        return p;
      }
    } catch (e) {
      debugPrint('[Multi] fetchPeerProfile $userId 실패: $e');
    }
    return null;
  }

  /// 닉네임으로 검색. RPC 가 RLS 우회 + 차단 자동 필터.
  Future<List<MultiplayerProfile>> searchByNickname(String nickname) async {
    try {
      final res = await _sb.rpc(
        'search_profile_by_nickname',
        params: {'p_nickname': nickname},
      );
      return (res as List).map((r) {
        final m = r as Map<String, dynamic>;
        return MultiplayerProfile(
          userId: m['user_id'] as String,
          nickname: m['nickname'] as String,
          pinColor: (m['pin_color'] as String?) ?? '#7C5CFF',
          pinEmoji: (m['pin_emoji'] as String?) ?? '📍',
          visibility: 'friends',
          birthYear: 2000, // 검색 결과엔 노출 X (stub).
          friendCode: m['friend_code'] as String?,
        );
      }).where((p) => !isBlocked(p.userId)).toList();
    } catch (e) {
      debugPrint('[Multi] searchByNickname 실패: $e');
      return [];
    }
  }

  /// 친구 + 본인 점수 랭킹 (B18).
  Future<List<({String userId, String nickname, String pinColor,
      String pinEmoji, int totalPoints, int meetupCount, int friendCount,
      int currentStreakDays, List<String> badges})>> loadFriendLeaderboard() async {
    if (myId == null) return [];
    try {
      final res = await _sb.rpc('friend_leaderboard');
      return (res as List).map((r) {
        final m = r as Map<String, dynamic>;
        return (
          userId: m['user_id'] as String,
          nickname: m['nickname'] as String,
          pinColor: (m['pin_color'] as String?) ?? '#7C5CFF',
          pinEmoji: (m['pin_emoji'] as String?) ?? '📍',
          totalPoints: (m['total_points'] as num?)?.toInt() ?? 0,
          meetupCount: (m['meetup_count'] as num?)?.toInt() ?? 0,
          friendCount: (m['friend_count'] as num?)?.toInt() ?? 0,
          currentStreakDays: (m['current_streak_days'] as num?)?.toInt() ?? 0,
          badges: ((m['badges'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[Multi] loadFriendLeaderboard 실패: $e');
      return [];
    }
  }

  /// 친구 추천 — 친구의 친구 (mutual count 내림차순). 차단/이미친구/요청중 제외.
  Future<List<({MultiplayerProfile profile, int mutualCount})>>
      loadSuggestedFriends({int limit = 10}) async {
    if (myId == null) return [];
    try {
      final res =
          await _sb.rpc('suggested_friends', params: {'p_limit': limit});
      return (res as List).map((r) {
        final m = r as Map<String, dynamic>;
        return (
          profile: MultiplayerProfile(
            userId: m['user_id'] as String,
            nickname: m['nickname'] as String,
            pinColor: (m['pin_color'] as String?) ?? '#7C5CFF',
            pinEmoji: (m['pin_emoji'] as String?) ?? '📍',
            visibility: 'friends',
            birthYear: 2000,
            friendCode: m['friend_code'] as String?,
          ),
          mutualCount: (m['mutual_count'] as num).toInt(),
        );
      }).where((r) => !isBlocked(r.profile.userId)).toList();
    } catch (e) {
      debugPrint('[Multi] loadSuggestedFriends 실패: $e');
      return [];
    }
  }

  /// G11: 친구 코드로 정확 매치 검색.
  Future<MultiplayerProfile?> searchByFriendCode(String code) async {
    final upper = code.toUpperCase().trim();
    if (upper.length != 8) return null;
    try {
      final res = await _sb.rpc(
        'search_profile_by_friend_code',
        params: {'p_code': upper},
      );
      if (res is! List || res.isEmpty) return null;
      final m = res.first as Map<String, dynamic>;
      return MultiplayerProfile(
        userId: m['user_id'] as String,
        nickname: m['nickname'] as String,
        pinColor: (m['pin_color'] as String?) ?? '#7C5CFF',
        pinEmoji: (m['pin_emoji'] as String?) ?? '📍',
        visibility: 'friends',
        birthYear: 2000,
        friendCode: m['friend_code'] as String?,
      );
    } catch (e) {
      debugPrint('[Multi] searchByFriendCode 실패: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 친구
  // ──────────────────────────────────────────────────────────────────
  Future<void> _loadFriendships() async {
    try {
      final res = await _sb
          .from('friendships')
          .select()
          .or('user_a.eq.$myId,user_b.eq.$myId');
      _friendships
        ..clear()
        ..addAll((res as List)
            .map((r) => Friendship.fromJson(r as Map<String, dynamic>)));

      for (final f in _friendships) {
        await fetchPeerProfile(f.otherSide(myId!));
      }
      _notify();
    } catch (e) {
      debugPrint('[Multi] _loadFriendships 실패: $e');
    }
  }

  Future<void> sendFriendRequest(String otherUserId) async {
    if (myId == null) return;
    final a = myId!.compareTo(otherUserId) < 0 ? myId! : otherUserId;
    final b = myId!.compareTo(otherUserId) < 0 ? otherUserId : myId!;
    try {
      await _sb.from('friendships').insert({
        'user_a': a, 'user_b': b,
        'status': 'pending', 'initiated_by': myId!,
      });
      await _loadFriendships();
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> acceptFriendRequest(Friendship f) async {
    try {
      await _sb
          .from('friendships')
          .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_a', f.userA)
          .eq('user_b', f.userB);
      await _loadFriendships();
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> removeFriend(String otherUserId) async {
    final a = myId!.compareTo(otherUserId) < 0 ? myId! : otherUserId;
    final b = myId!.compareTo(otherUserId) < 0 ? otherUserId : myId!;
    await _sb.from('friendships').delete().eq('user_a', a).eq('user_b', b);
    await _loadFriendships();
  }

  List<Friendship> get incomingRequests =>
      _friendships.where((f) => f.isIncoming(myId ?? '')).toList();
  List<Friendship> get acceptedFriends =>
      _friendships.where((f) => f.isAccepted).toList();

  /// 친구 신청 알림용 — RLS 가 어차피 내가 볼 수 있는 row 만 흘려보내지만,
  /// 명시적 필터로 부하 더 줄임 (X2). user_a 또는 user_b 가 나인 row 만 두 채널로.
  void _subscribeFriendshipUpdates() {
    _friendsChannel?.unsubscribe();
    if (myId == null) return;
    _friendsChannel = _sb
        .channel('friendships_$myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_a',
            value: myId!,
          ),
          callback: _onFriendshipChange,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_b',
            value: myId!,
          ),
          callback: _onFriendshipChange,
        )
        .subscribe();
  }

  void _onFriendshipChange(PostgresChangePayload payload) async {
    await _loadFriendships();
    if (payload.eventType == PostgresChangeEvent.insert) {
      final r = payload.newRecord;
      if (r['initiated_by'] != myId && r['status'] == 'pending') {
        for (final l in List.of(_friendRequestListeners)) {
          try { l(); } catch (_) {}
        }
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 차단
  // ──────────────────────────────────────────────────────────────────
  Future<void> _loadBlocks() async {
    try {
      final res = await _sb.from('blocks').select('blocked_id').eq('blocker_id', myId!);
      _blockedUserIds
        ..clear()
        ..addAll((res as List).map((r) => r['blocked_id'] as String));
      _notify();
    } catch (e) {
      debugPrint('[Multi] _loadBlocks 실패: $e');
    }
  }

  Future<void> blockUser(String userId) async {
    if (myId == null || userId == myId) return;
    await _sb.from('blocks').upsert({'blocker_id': myId, 'blocked_id': userId});
    await removeFriend(userId);
    await _loadBlocks();
    await _refreshRoomMembers();
    // #18 차단된 사용자의 기존 메시지도 클라 캐시에서 즉시 제거.
    _messages.removeWhere((m) => m.userId == userId);
    // peer 핀도 즉시 제거.
    _peerLocations.remove(userId);
    _worldPeerLocations.remove(userId);
    _notify();
  }

  /// #19 친구 신청 cooldown 조회 — 검색 결과 UI 에서 "재신청 가능: ~까지" 표시용.
  Future<DateTime?> friendRequestCooldownUntil(String otherUserId) async {
    if (myId == null) return null;
    final a = myId!.compareTo(otherUserId) < 0 ? myId! : otherUserId;
    final b = myId!.compareTo(otherUserId) < 0 ? otherUserId : myId!;
    try {
      final res = await _sb
          .from('friend_request_cooldowns')
          .select('expires_at')
          .eq('user_a', a)
          .eq('user_b', b)
          .maybeSingle();
      if (res == null) return null;
      final until = DateTime.parse(res['expires_at'] as String);
      if (until.isBefore(DateTime.now())) return null;
      return until;
    } catch (_) {
      return null;
    }
  }

  Future<void> unblockUser(String userId) async {
    await _sb.from('blocks').delete().eq('blocker_id', myId!).eq('blocked_id', userId);
    await _loadBlocks();
  }

  /// 차단 목록 + 각 사용자 프로필 (UI 표시용).
  Future<List<MultiplayerProfile>> fetchBlockedProfiles() async {
    if (myId == null) return [];
    final result = <MultiplayerProfile>[];
    for (final uid in _blockedUserIds) {
      final p = await fetchPeerProfile(uid);
      if (p != null) {
        result.add(p);
      } else {
        // 프로필 없어도 placeholder.
        result.add(MultiplayerProfile(
          userId: uid,
          nickname: uid.substring(0, 8),
          pinColor: '#7C5CFF',
          pinEmoji: '👤',
          visibility: 'ghost',
          birthYear: 2000,
        ));
      }
    }
    return result;
  }

  // ──────────────────────────────────────────────────────────────────
  // 친구 그룹 (G21)
  // ──────────────────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────
  // 알림 prefs (B12)
  // ──────────────────────────────────────────────────────────────────
  static const _kNotifKinds = [
    'friend_request', 'friend_accept', 'room_message',
    'meetup', 'destination', 'welcome',
  ];
  Map<String, bool> _notifPrefs = {for (final k in _kNotifKinds) k: true};
  Map<String, bool> get notifPrefs => Map.unmodifiable(_notifPrefs);
  static List<String> get notifPrefKinds => _kNotifKinds;

  Future<void> loadNotifPrefs() async {
    if (myId == null) return;
    try {
      final res = await _sb
          .from('user_notification_prefs')
          .select()
          .eq('user_id', myId!)
          .maybeSingle();
      if (res != null) {
        _notifPrefs = {for (final k in _kNotifKinds) k: res[k] as bool? ?? true};
      } else {
        _notifPrefs = {for (final k in _kNotifKinds) k: true};
      }
      _notify();
    } catch (e) {
      debugPrint('[Multi] loadNotifPrefs 실패: $e');
    }
  }

  Future<void> setNotifPref(String kind, bool enabled) async {
    if (myId == null) return;
    if (!_kNotifKinds.contains(kind)) return;
    _notifPrefs[kind] = enabled;
    _notify();
    try {
      await _sb.from('user_notification_prefs').upsert({
        'user_id': myId,
        kind: enabled,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[Multi] setNotifPref 실패: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 그룹별 visibility (B9)
  // ──────────────────────────────────────────────────────────────────
  /// 내 visibility=selected_groups 일 때 허용한 그룹 id 들.
  final Set<String> _myVisibleGroupIds = {};
  Set<String> get myVisibleGroupIds => Set.unmodifiable(_myVisibleGroupIds);

  /// peer 가 나에게 위치를 보여줄지 (false 면 핀 숨김). 자동 cache.
  final Map<String, bool> _peerVisibleCache = {};

  Future<void> loadMyVisibleGroups() async {
    if (myId == null) return;
    try {
      final res = await _sb
          .from('profile_visible_groups')
          .select('group_id')
          .eq('user_id', myId!);
      _myVisibleGroupIds
        ..clear()
        ..addAll((res as List).map((r) => r['group_id'] as String));
      _notify();
    } catch (e) {
      debugPrint('[Multi] loadMyVisibleGroups 실패: $e');
    }
  }

  Future<void> setMyVisibleGroups(Set<String> groupIds) async {
    try {
      await _sb.rpc('set_my_visible_groups',
          params: {'p_group_ids': groupIds.toList()});
      _myVisibleGroupIds
        ..clear()
        ..addAll(groupIds);
      _notify();
    } catch (e) {
      debugPrint('[Multi] setMyVisibleGroups 실패: $e');
      rethrow;
    }
  }

  /// peer 가 selected_groups 모드일 때 내가 그 사람의 핀을 볼 수 있는지.
  /// 결과는 캐시 — 반복 호출 시 즉시 반환.
  Future<bool> canSeePeerLocation(String peerId) async {
    final cached = _peerVisibleCache[peerId];
    if (cached != null) return cached;
    try {
      final res = await _sb.rpc('am_i_visible_to', params: {'p_owner': peerId});
      final v = res == true;
      _peerVisibleCache[peerId] = v;
      return v;
    } catch (e) {
      debugPrint('[Multi] canSeePeerLocation 실패: $e');
      return true; // 실패 시 보이게 (안전한 fallback).
    }
  }

  void invalidatePeerVisibilityCache() {
    _peerVisibleCache.clear();
    _notify();
  }

  // ──────────────────────────────────────────────────────────────────
  // 활동 로그 (B8)
  // ──────────────────────────────────────────────────────────────────
  /// fire-and-forget 활동 기록.
  void logActivity(String kind, {Map<String, dynamic> payload = const {}}) {
    if (myId == null) return;
    _sb.from('activity_log').insert({
      'user_id': myId,
      'kind': kind,
      'payload': payload,
    }).then((_) {}, onError: (e) {
      debugPrint('[Multi] logActivity 실패 ($kind): $e');
    });
  }

  /// 최근 7일 (또는 days 일) 활동을 kind 별/일자별 카운트로 반환.
  Future<List<({DateTime day, String kind, int cnt})>>
      loadActivitySummary({int days = 7}) async {
    if (myId == null) return [];
    try {
      final res = await _sb.rpc(
        'activity_weekly_summary',
        params: {'p_days': days},
      );
      return (res as List).map((r) {
        final m = r as Map<String, dynamic>;
        return (
          day: DateTime.parse(m['day'] as String),
          kind: m['kind'] as String,
          cnt: (m['cnt'] as num).toInt(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[Multi] loadActivitySummary 실패: $e');
      return [];
    }
  }

  /// 최근 활동 로우 N개.
  Future<List<({DateTime at, String kind, Map<String, dynamic> payload})>>
      loadRecentActivities({int limit = 20}) async {
    if (myId == null) return [];
    try {
      final res = await _sb
          .from('activity_log')
          .select()
          .eq('user_id', myId!)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List).map((r) {
        final m = r as Map<String, dynamic>;
        return (
          at: DateTime.parse(m['created_at'] as String),
          kind: m['kind'] as String,
          payload: (m['payload'] as Map?)?.cast<String, dynamic>() ?? {},
        );
      }).toList();
    } catch (e) {
      debugPrint('[Multi] loadRecentActivities 실패: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 게이미피케이션 (B7)
  // ──────────────────────────────────────────────────────────────────
  Future<void> _loadMyScore() async {
    if (myId == null) return;
    try {
      final res = await _sb
          .from('user_scores')
          .select()
          .eq('user_id', myId!)
          .maybeSingle();
      if (res != null) {
        _myScore = UserScore.fromJson(res);
      } else {
        _myScore = const UserScore(
          userId: '', totalPoints: 0, meetupCount: 0,
          friendCount: 0, roomsJoined: 0,
          currentStreakDays: 0, longestStreakDays: 0, badges: [],
        );
      }
      _notify();
    } catch (e) {
      debugPrint('[Multi] _loadMyScore 실패: $e');
    }
  }

  void _subscribeMyScore() {
    if (myId == null) return;
    _scoreChannel = _sb
        .channel('user_scores_$myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_scores',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: myId!,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              try {
                _myScore = UserScore.fromJson(payload.newRecord);
                _notify();
              } catch (_) {}
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadFriendGroups() async {
    if (myId == null) return;
    try {
      final groups = await _sb
          .from('friend_groups')
          .select()
          .eq('user_id', myId!)
          .order('sort_order');
      final members = await _sb
          .from('friend_group_members')
          .select('group_id, friend_id');
      final byGroup = <String, List<String>>{};
      for (final m in (members as List)) {
        (byGroup[m['group_id'] as String] ??= []).add(m['friend_id'] as String);
      }
      _friendGroups
        ..clear()
        ..addAll((groups as List).map((g) => FriendGroup.fromJson(
              g as Map<String, dynamic>,
              memberIds: byGroup[g['id']] ?? const [],
            )));
      _notify();
    } catch (e) {
      debugPrint('[Multi] _loadFriendGroups 실패: $e');
    }
  }

  Future<FriendGroup> createFriendGroup({
    required String name,
    String emoji = '👥',
  }) async {
    final res = await _sb.from('friend_groups').insert({
      'user_id': myId, 'name': name, 'emoji': emoji,
      'sort_order': _friendGroups.length,
    }).select().single();
    await _loadFriendGroups();
    return FriendGroup.fromJson(res);
  }

  Future<void> deleteFriendGroup(String groupId) async {
    await _sb.from('friend_groups').delete().eq('id', groupId);
    await _loadFriendGroups();
  }

  Future<void> setFriendInGroup(
      String groupId, String friendId, bool inGroup) async {
    if (inGroup) {
      await _sb.from('friend_group_members').upsert({
        'group_id': groupId, 'friend_id': friendId,
      });
    } else {
      await _sb
          .from('friend_group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('friend_id', friendId);
    }
    await _loadFriendGroups();
  }

  // ──────────────────────────────────────────────────────────────────
  // 친구방
  // ──────────────────────────────────────────────────────────────────
  Future<Room> createRoom({String? name}) async {
    if (myId == null) throw StateError('로그인이 필요합니다.');
    final code = _generateInviteCode();
    try {
      final res = await _sb.from('rooms').insert({
        'invite_code': code, 'owner_id': myId, 'name': name,
      }).select().single();
      final room = Room.fromJson(res);
      await _sb.from('room_members').insert({'room_id': room.id, 'user_id': myId});
      await enterRoom(room);
      return room;
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Room> joinRoomByCode(String code) async {
    final upper = code.toUpperCase().trim();
    try {
      final roomId = await _sb.rpc('join_room_by_code', params: {'p_code': upper}) as String;
      final res = await _sb.from('rooms').select().eq('id', roomId).single();
      final room = Room.fromJson(res);
      await enterRoom(room);
      return room;
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  /// G22: 방장 강퇴.
  Future<void> kickMember(String userId) async {
    if (_currentRoom == null) return;
    try {
      await _sb.rpc('kick_room_member', params: {
        'p_room_id': _currentRoom!.id,
        'p_user_id': userId,
      });
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  /// G23: 초대 코드 회전.
  Future<String> rotateInviteCode() async {
    if (_currentRoom == null) throw StateError('방 안에서만 가능합니다.');
    try {
      final code = await _sb.rpc('rotate_room_invite_code',
          params: {'p_room_id': _currentRoom!.id}) as String;
      // currentRoom 갱신.
      _currentRoom = Room(
        id: _currentRoom!.id,
        inviteCode: code,
        ownerId: _currentRoom!.ownerId,
        name: _currentRoom!.name,
        expiresAt: _currentRoom!.expiresAt,
      );
      _notify();
      return code;
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  /// G10: 룸 이름 변경.
  Future<void> updateRoomName(String name) async {
    if (_currentRoom == null) return;
    try {
      await _sb.from('rooms')
          .update({'name': name})
          .eq('id', _currentRoom!.id);
      _currentRoom = Room(
        id: _currentRoom!.id,
        inviteCode: _currentRoom!.inviteCode,
        ownerId: _currentRoom!.ownerId,
        name: name,
        expiresAt: _currentRoom!.expiresAt,
      );
      _notify();
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> enterRoom(Room room) async {
    // 1인 1룸 강제 — 다른 룸 멤버십 일괄 정리 (좀비 멤버십 방지).
    if (myId != null) {
      try {
        await _sb
            .from('room_members')
            .delete()
            .eq('user_id', myId!)
            .neq('room_id', room.id);
      } catch (e) {
        debugPrint('[Multi] 이전 룸 정리 실패: $e');
      }
    }

    // 이전 룸의 채널 정리.
    if (_currentRoom != null && _currentRoom!.id != room.id) {
      try {
        await _presenceChannel?.unsubscribe();
        await _messagesChannel?.unsubscribe();
        await _membersChannel?.unsubscribe();
        await _roomMetaChannel?.unsubscribe();
      } catch (_) {}
      _presenceChannel = null;
      _messagesChannel = null;
      _membersChannel = null;
    }

    _currentRoom = room;
    _peerLocations.clear();
    _activeMeetups.clear();
    _messages.clear();
    _hasMoreMessages = true;
    _unreadCounts[room.id] = 0;

    await _refreshRoomMembers();
    await _loadInitialMessages();
    _subscribeRoomMembers();
    _subscribeRoomMessages();
    _subscribeRoomMeta();
    _subscribeFriendProfiles();
    _startPresence();
    _startLocationBroadcast();
    logActivity('room_joined', payload: {'room_id': room.id, 'code': room.inviteCode});
    _notify();
    debugPrint('[Multi] enterRoom ${room.inviteCode} (${_currentRoomMembers.length}명)');
  }

  Future<void> leaveCurrentRoom() async {
    final room = _currentRoom;
    if (room == null || myId == null) return;
    _stopLocationBroadcast();
    await _presenceChannel?.unsubscribe();
    await _messagesChannel?.unsubscribe();
    await _membersChannel?.unsubscribe();
    await _roomMetaChannel?.unsubscribe();
    await _profilesChannel?.unsubscribe();
    _presenceChannel = null;
    _messagesChannel = null;
    _membersChannel = null;
    _roomMetaChannel = null;
    _profilesChannel = null;
    try {
      await _sb
          .from('room_members')
          .delete()
          .eq('room_id', room.id)
          .eq('user_id', myId!);
    } catch (e) {
      debugPrint('[Multi] leaveCurrentRoom 실패: $e');
    }
    _currentRoom = null;
    _currentRoomMembers.clear();
    _peerLocations.clear();
    _activeMeetups.clear();
    _messages.clear();
    _unreadCounts.remove(room.id);
    _notify();
  }

  Future<void> _refreshRoomMembers() async {
    if (_currentRoom == null) return;
    try {
      final res = await _sb
          .from('room_members')
          .select('user_id')
          .eq('room_id', _currentRoom!.id);
      _currentRoomMembers
        ..clear()
        ..addAll((res as List).map((r) => r['user_id'] as String));
      for (final uid in _currentRoomMembers) {
        if (!_peerProfiles.containsKey(uid)) {
          await fetchPeerProfile(uid);
        }
      }
      _notify();
    } catch (e) {
      debugPrint('[Multi] _refreshRoomMembers 실패: $e');
    }
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // ──────────────────────────────────────────────────────────────────
  // Realtime — Presence
  // ──────────────────────────────────────────────────────────────────
  void _startPresence() {
    if (_currentRoom == null || myId == null) return;
    _presenceChannel = _sb
        .channel(
          'room_presence_${_currentRoom!.id}',
          opts: RealtimeChannelConfig(self: false, key: myId!),
        )
        .onPresenceSync((p) => _onPresenceSync())
        .onPresenceJoin((p) => _onPresenceSync())
        .onPresenceLeave((p) => _onPresenceSync())
        .subscribe();
  }

  void _onPresenceSync() {
    final channel = _presenceChannel;
    if (channel == null) return;
    final state = channel.presenceState();
    final next = <String, PeerLocation>{};
    var totalPresences = 0;
    for (final entry in state) {
      for (final p in entry.presences) {
        totalPresences++;
        final payload = p.payload;
        final uid = (payload['user_id'] as String?) ?? entry.key;
        if (uid == myId || isBlocked(uid)) continue;
        try {
          next[uid] = PeerLocation.fromPresence(uid, payload);
        } catch (e) {
          debugPrint('[Multi] presence parse 실패 uid=$uid: $e');
        }
      }
    }
    debugPrint('[Multi] presence sync — state=${state.length} '
        'presences=$totalPresences peers=${next.length}');
    _peerLocations
      ..clear()
      ..addAll(next);
    _checkMeetups();
    _notify();
  }

  // ──────────────────────────────────────────────────────────────────
  // 위치 송신 + 배터리 모드 + 정지 감지
  // ──────────────────────────────────────────────────────────────────
  void _startLocationBroadcast() {
    _locationTimer?.cancel();
    if (_seoulLivePaused) return;
    if (_isInBackground) return;
    if (_myProfile?.visibility == 'ghost') return;
    // 룸 채널 또는 world 채널 둘 중 하나라도 있어야 함.
    if (_presenceChannel == null && _worldChannel == null) return;
    final base = _batteryMode.intervalSec;
    final intervalSec = _isStationary ? (base * 2).clamp(5, 60) : base;
    _locationTimer = Timer.periodic(
      Duration(seconds: intervalSec),
      (_) => _broadcastOnce(),
    );
    _broadcastOnce();
  }

  void _stopLocationBroadcast() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _presenceChannel?.untrack();
    _worldChannel?.untrack();
  }

  Position? _lastBroadcasted;

  bool _locPermissionWarned = false;

  Future<void> _broadcastOnce() async {
    if (_seoulLivePaused) return;
    if (_isInBackground) return;
    if (_myProfile?.visibility == 'ghost') return;
    if (myId == null) return;
    // 둘 다 없으면 송신 불가 (룸도 없고 world 도 없음).
    if (_presenceChannel == null && _worldChannel == null) {
      debugPrint('[Multi] broadcast skip — no channel');
      return;
    }
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!_locPermissionWarned) {
          _locPermissionWarned = true;
          debugPrint('[Multi] ⚠️ 위치 권한 없음 — 친구가 내 핀을 못 봄');
          // 사용자 알림 — 한 번만.
          for (final l in List.of(_locationDeniedListeners)) {
            try { l(); } catch (_) {}
          }
        }
        return;
      }
      _locPermissionWarned = false;
      final accuracy = _batteryMode == BatteryMode.saver
          ? LocationAccuracy.medium
          : LocationAccuracy.high;
      // iOS 첫 fix 가 느려서 4초로는 부족. 15초 + last known fallback.
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: accuracy,
            timeLimit: const Duration(seconds: 15),
          ),
        );
      } on TimeoutException {
        // 15초 안에도 못 받으면 마지막 알려진 위치라도 송신.
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) {
          debugPrint('[Multi] 위치 fix 실패 (timeout) + last known 없음');
          return;
        }
        debugPrint('[Multi] 위치 timeout — last known fallback');
        pos = last;
      }

      // 정지 감지: 직전 위치와 현재 위치 거리 + 시간 비교.
      final prev = _lastBroadcasted;
      if (prev != null) {
        final dist = Geolocator.distanceBetween(
            prev.latitude, prev.longitude, pos.latitude, pos.longitude);
        final dt = pos.timestamp.difference(prev.timestamp);
        final wasStationary = _isStationary;
        _isStationary =
            dist < _stationaryMeters && dt > _stationaryThreshold;
        if (wasStationary != _isStationary) {
          // 주기 재계산.
          _startLocationBroadcast();
          return;
        }
      }
      _lastBroadcasted = pos;
      // 룸 멤버에겐 정확한 위치, world peers 에겐 ~50m grid 로 라운딩 (스토킹 방지).
      final exactPayload = {
        'user_id': myId,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'heading': pos.heading,
        'ts': DateTime.now().millisecondsSinceEpoch,
      };
      if (_presenceChannel != null) {
        await _presenceChannel!.track(exactPayload);
      }
      if (_worldChannel != null && _myProfile?.visibility == 'public') {
        // 0.0005도 ≈ 55m 그리드.
        final fuzzedPayload = Map<String, dynamic>.from(exactPayload);
        fuzzedPayload['lat'] = (pos.latitude * 2000).round() / 2000;
        fuzzedPayload['lng'] = (pos.longitude * 2000).round() / 2000;
        // heading 도 16방위로 라운딩 (정확한 향 노출 X).
        if (pos.heading > 0) {
          fuzzedPayload['heading'] =
              ((pos.heading / 22.5).round() * 22.5);
        }
        await _worldChannel!.track(fuzzedPayload);
      }
    } catch (e) {
      debugPrint('[Multi] broadcastOnce 실패: $e');
    }
  }

  /// World 채널 sync — public 전용 (대칭성: 보려면 본인도 공개).
  void _syncWorldChannel() {
    final shouldBeActive = _myProfile?.visibility == 'public' &&
        !_seoulLivePaused &&
        !_isInBackground &&
        myId != null;
    if (shouldBeActive && _worldChannel == null) {
      _startWorldChannel();
    } else if (!shouldBeActive && _worldChannel != null) {
      _stopWorldChannel();
    }
    if (shouldBeActive) _broadcastOnce();
  }

  void _startWorldChannel() {
    if (_worldChannel != null || myId == null) return;
    _worldChannel = _sb
        .channel(
          'seoul_live_world',
          opts: RealtimeChannelConfig(self: false, key: myId!),
        )
        .onPresenceSync((p) => _onWorldSync())
        .onPresenceJoin((p) => _onWorldSync())
        .onPresenceLeave((p) => _onWorldSync())
        .subscribe();
    // 처음 시작 시에도 위치 송신 시작 (룸 안이 아니어도).
    if (_locationTimer == null) _startLocationBroadcast();
  }

  void _stopWorldChannel() {
    try {
      _worldChannel?.untrack();
      _worldChannel?.unsubscribe();
    } catch (_) {}
    _worldChannel = null;
    _worldPeerLocations.clear();
    // 룸도 없으면 송신 자체 중단.
    if (_presenceChannel == null) {
      _stopLocationBroadcast();
    }
    _notify();
  }

  void _onWorldSync() {
    final ch = _worldChannel;
    if (ch == null) return;
    final state = ch.presenceState();
    final next = <String, PeerLocation>{};
    for (final entry in state) {
      for (final p in entry.presences) {
        final payload = p.payload;
        final uid = (payload['user_id'] as String?) ?? entry.key;
        if (uid == myId || isBlocked(uid)) continue;
        try {
          next[uid] = PeerLocation.fromPresence(uid, payload);
        } catch (_) {}
      }
    }
    _worldPeerLocations
      ..clear()
      ..addAll(next);
    // 새 peer 프로필 prefetch (백그라운드).
    for (final uid in next.keys) {
      if (!_peerProfiles.containsKey(uid)) {
        fetchPeerProfile(uid);
      }
    }
    _notify();
  }

  // ──────────────────────────────────────────────────────────────────
  // 만남 감지
  // ──────────────────────────────────────────────────────────────────
  void _checkMeetups() {
    final me = _lastBroadcasted;
    if (me == null) return;
    final newlyMeeting = <String>{};
    for (final p in _peerLocations.values) {
      if (p.isOffline) continue;
      final dist = Geolocator.distanceBetween(
          me.latitude, me.longitude, p.lat, p.lng);
      if (dist <= kMeetupRadiusMeters) newlyMeeting.add(p.userId);
    }
    final started = newlyMeeting.difference(_activeMeetups);
    final ended = _activeMeetups.difference(newlyMeeting);
    _activeMeetups
      ..clear()
      ..addAll(newlyMeeting);
    for (final uid in started) {
      // 60초 내 같은 peer 재만남 dedupe — 같은 카페/장소에서 핀이 출렁여도 한 번만.
      final last = _lastMeetupNotifiedAt[uid];
      if (last != null &&
          DateTime.now().difference(last).inSeconds < 60) continue;
      _lastMeetupNotifiedAt[uid] = DateTime.now();
      _recordMeetup(uid);
      for (final l in List.of(_meetupListeners)) {
        try { l(uid, true); } catch (_) {}
      }
    }
    for (final uid in ended) {
      for (final l in List.of(_meetupListeners)) {
        try { l(uid, false); } catch (_) {}
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 채팅
  // ──────────────────────────────────────────────────────────────────
  static const int _kMessagesPageSize = 30;

  Future<void> _loadInitialMessages() async {
    if (_currentRoom == null) return;
    try {
      final res = await _sb
          .from('room_messages')
          .select()
          .eq('room_id', _currentRoom!.id)
          .order('created_at', ascending: false)
          .limit(_kMessagesPageSize);
      final list = (res as List)
          .map((r) => RoomMessage.fromJson(r as Map<String, dynamic>))
          .toList();
      _messages
        ..clear()
        ..addAll(list.reversed);
      _hasMoreMessages = list.length >= _kMessagesPageSize;
      _notify();
    } catch (e) {
      debugPrint('[Multi] _loadInitialMessages 실패: $e');
    }
  }

  /// 위로 스크롤 시 호출 — 가장 오래된 메시지 이전 [_kMessagesPageSize] 개 더 로드.
  Future<void> loadMoreMessages() async {
    if (_currentRoom == null) return;
    if (_loadingMoreMessages || !_hasMoreMessages) return;
    if (_messages.isEmpty) return;
    _loadingMoreMessages = true;
    _notify();
    try {
      final oldest = _messages.first.createdAt;
      final res = await _sb
          .from('room_messages')
          .select()
          .eq('room_id', _currentRoom!.id)
          .lt('created_at', oldest.toIso8601String())
          .order('created_at', ascending: false)
          .limit(_kMessagesPageSize);
      final older = (res as List)
          .map((r) => RoomMessage.fromJson(r as Map<String, dynamic>))
          .where((m) => !isBlocked(m.userId))
          .toList()
          .reversed
          .toList();
      _messages.insertAll(0, older);
      if (older.length < _kMessagesPageSize) _hasMoreMessages = false;
    } catch (e) {
      debugPrint('[Multi] loadMoreMessages 실패: $e');
    } finally {
      _loadingMoreMessages = false;
      _notify();
    }
  }

  void _subscribeRoomMessages() {
    if (_currentRoom == null) return;
    _messagesChannel = _sb
        .channel('room_msgs_${_currentRoom!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'room_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: _currentRoom!.id,
          ),
          callback: (payload) {
            final m = RoomMessage.fromJson(payload.newRecord);
            if (isBlocked(m.userId)) return;
            _messages.add(m);
            // G13: 내가 안 보낸 메시지면 unread 카운트 증가.
            if (m.userId != myId) {
              _unreadCounts[m.roomId] = (_unreadCounts[m.roomId] ?? 0) + 1;
            }
            _notify();
          },
        )
        .subscribe();
  }

  void _subscribeRoomMembers() {
    if (_currentRoom == null) return;
    _membersChannel = _sb
        .channel('room_members_${_currentRoom!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: _currentRoom!.id,
          ),
          callback: (_) => _refreshRoomMembers(),
        )
        .subscribe();
  }

  /// rooms 테이블 자체 (목적지 등 메타) update 구독.
  void _subscribeRoomMeta() {
    if (_currentRoom == null) return;
    _roomMetaChannel = _sb
        .channel('room_meta_${_currentRoom!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _currentRoom!.id,
          ),
          callback: (payload) {
            try {
              _currentRoom = Room.fromJson(payload.newRecord);
              _notify();
            } catch (e) {
              debugPrint('[Multi] room meta update parse fail: $e');
            }
          },
        )
        .subscribe();
  }

  Future<void> setRoomDestination({
    required String name,
    required double lat,
    required double lng,
  }) async {
    if (_currentRoom == null) return;
    try {
      await _sb.rpc('set_room_destination', params: {
        'p_room_id': _currentRoom!.id,
        'p_name': name,
        'p_lat': lat,
        'p_lng': lng,
      });
      logActivity('destination_set',
          payload: {'name': name, 'lat': lat, 'lng': lng});
      // realtime 으로도 오지만 즉시 반영해서 UI 가 안 끌리게.
      _currentRoom = Room(
        id: _currentRoom!.id,
        inviteCode: _currentRoom!.inviteCode,
        ownerId: _currentRoom!.ownerId,
        name: _currentRoom!.name,
        expiresAt: _currentRoom!.expiresAt,
        destName: name, destLat: lat, destLng: lng, destSetBy: myId,
      );
      _notify();
    } catch (e) {
      debugPrint('[Multi] setRoomDestination 실패: $e');
      rethrow;
    }
  }

  Future<void> clearRoomDestination() async {
    if (_currentRoom == null) return;
    try {
      await _sb.rpc('clear_room_destination',
          params: {'p_room_id': _currentRoom!.id});
      _currentRoom = Room(
        id: _currentRoom!.id,
        inviteCode: _currentRoom!.inviteCode,
        ownerId: _currentRoom!.ownerId,
        name: _currentRoom!.name,
        expiresAt: _currentRoom!.expiresAt,
      );
      _notify();
    } catch (e) {
      debugPrint('[Multi] clearRoomDestination 실패: $e');
    }
  }

  Future<void> sendMessage(String body, {String kind = 'text'}) async {
    if (_currentRoom == null || myId == null) return;
    final trimmed = body.trim();
    if (trimmed.isEmpty || trimmed.length > 500) return;
    try {
      await _sb.from('room_messages').insert({
        'room_id': _currentRoom!.id,
        'user_id': myId,
        'body': trimmed,
        'kind': kind,
      });
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  static final _mediaRand = Random.secure();

  // ──────────────────────────────────────────────────────────────────
  // 1:1 DM (B17)
  // ──────────────────────────────────────────────────────────────────
  Future<List<DmThreadSummary>> loadDmList() async {
    if (myId == null) return [];
    try {
      final res = await _sb.rpc('my_dm_list');
      return (res as List).map((r) {
        final m = r as Map<String, dynamic>;
        return DmThreadSummary(
          threadId: m['thread_id'] as String,
          otherUserId: m['other_user_id'] as String,
          lastMessageAt: DateTime.parse(m['last_message_at'] as String),
          lastBody: m['last_body'] as String?,
          lastKind: m['last_kind'] as String?,
          unreadCount: (m['unread_count'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('[Multi] loadDmList 실패: $e');
      return [];
    }
  }

  Future<String?> ensureDmThread(String otherUserId) async {
    try {
      final res = await _sb
          .rpc('ensure_dm_thread', params: {'p_other': otherUserId});
      return res as String?;
    } catch (e) {
      debugPrint('[Multi] ensureDmThread 실패: $e');
      rethrow;
    }
  }

  Future<List<DmMessage>> loadDmMessages(String threadId,
      {int limit = 50}) async {
    try {
      final res = await _sb
          .from('dm_messages')
          .select()
          .eq('thread_id', threadId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List)
          .map((r) => DmMessage.fromJson(r as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      debugPrint('[Multi] loadDmMessages 실패: $e');
      return [];
    }
  }

  Future<void> sendDm(String threadId, String body,
      {String kind = 'text'}) async {
    if (myId == null) return;
    final t = body.trim();
    if (t.isEmpty || t.length > 2000) return;
    try {
      await _sb.from('dm_messages').insert({
        'thread_id': threadId,
        'sender_id': myId,
        'body': t,
        'kind': kind,
      });
    } catch (e) {
      debugPrint('[Multi] sendDm 실패: $e');
      rethrow;
    }
  }

  Future<void> markDmRead(String threadId) async {
    try {
      await _sb.rpc('mark_dm_read', params: {'p_thread': threadId});
    } catch (_) {}
  }

  /// thread 의 새 메시지 realtime 구독. listener 가 새 메시지 받음.
  RealtimeChannel subscribeDm(
      String threadId, void Function(DmMessage) onNew) {
    return _sb
        .channel('dm_$threadId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'dm_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'thread_id',
            value: threadId,
          ),
          callback: (payload) {
            try {
              onNew(DmMessage.fromJson(payload.newRecord));
            } catch (_) {}
          },
        )
        .subscribe();
  }

  /// 음성/이미지 등 chat-media 업로드. localPath → public URL 반환.
  /// path = `<my_uid>/<ts>-<rand>.<ext>` 형식.
  Future<String?> uploadChatMedia(String localPath, {required String ext}) async {
    if (myId == null) return null;
    try {
      final id = DateTime.now().millisecondsSinceEpoch;
      final name = '$myId/$id-${_mediaRand.nextInt(1 << 30)}.$ext';
      final file = File(localPath);
      await _sb.storage.from('chat-media').upload(name, file);
      return _sb.storage.from('chat-media').getPublicUrl(name);
    } catch (e) {
      debugPrint('[Multi] uploadChatMedia 실패: $e');
      return null;
    }
  }

  /// body = `<url>|<duration_ms>` 형식 (chat 가 parse).
  Future<void> sendVoiceMessage(String localPath, int durationMs) async {
    final url = await uploadChatMedia(localPath, ext: 'm4a');
    if (url == null) return;
    await sendMessage('$url|$durationMs', kind: 'voice');
  }

  /// body = url 단일.
  Future<void> sendImageMessage(String localPath) async {
    final url = await uploadChatMedia(localPath, ext: 'jpg');
    if (url == null) return;
    await sendMessage(url, kind: 'image');
  }

  /// 친구방에 장소 카드 공유. body 는 `<name>|<lat>|<lng>` 형식 (parse 는 chat 측).
  Future<void> sharePlaceToRoom({
    required String name,
    required double lat,
    required double lng,
  }) async {
    final cleaned = name.trim().replaceAll('|', ' ');
    final body = '$cleaned|${lat.toStringAsFixed(6)}|${lng.toStringAsFixed(6)}';
    await sendMessage(body, kind: 'place');
    logActivity('place_shared', payload: {'name': cleaned, 'lat': lat, 'lng': lng});
  }

  /// G13: 채팅 화면 열렸을 때 호출 → 미확인 0 + 서버 last_read_at 갱신.
  Future<void> markCurrentRoomRead() async {
    if (_currentRoom == null) return;
    _unreadCounts[_currentRoom!.id] = 0;
    _notify();
    try {
      await _sb.rpc('mark_room_read', params: {'p_room_id': _currentRoom!.id});
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────────────
  // 신고 (G2)
  // ──────────────────────────────────────────────────────────────────
  Future<void> reportUser(String targetUserId, String reason) async {
    if (myId == null) return;
    try {
      await _sb.from('reports').insert({
        'reporter_id': myId,
        'target_type': 'user',
        'target_user_id': targetUserId,
        'reason': reason,
      });
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> reportMessage(String messageId, String reason) async {
    if (myId == null) return;
    try {
      await _sb.from('reports').insert({
        'reporter_id': myId,
        'target_type': 'message',
        'target_message_id': messageId,
        'reason': reason,
      });
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Seoul Live 탈퇴 (전체 데이터 삭제)
  // ──────────────────────────────────────────────────────────────────
  Future<void> deleteMyData() async {
    if (myId == null) return;
    // 룸에서 먼저 나감.
    if (_currentRoom != null) await leaveCurrentRoom();
    try {
      await _sb.rpc('delete_my_multiplayer_data');
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
    await _resetAllState();
    await setConsent(false);
  }

  // ──────────────────────────────────────────────────────────────────
  // 동의 / 튜토리얼 / 배터리 (로컬 캐시)
  // ──────────────────────────────────────────────────────────────────
  static const _kConsentKey = 'multiplayer_consent_v1';
  static const _kTutorialKey = 'seoul_live_tutorial_seen_v1';
  static const _kBatteryKey = 'seoul_live_battery_mode_v1';

  static Future<bool> hasConsent() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kConsentKey) ?? false;
  }

  static Future<void> setConsent(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kConsentKey, v);
  }

  static Future<bool> hasSeenTutorial() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kTutorialKey) ?? false;
  }

  static Future<void> markTutorialSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kTutorialKey, true);
  }

  /// G3: 튜토리얼 다시 보기.
  static Future<void> resetTutorial() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kTutorialKey);
  }

  Future<void> _loadBatteryMode() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kBatteryKey);
    _batteryMode = BatteryMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => BatteryMode.balanced,
    );
  }

  Future<void> setBatteryMode(BatteryMode mode) async {
    if (_batteryMode == mode) return;
    _batteryMode = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBatteryKey, mode.name);
    if (_currentRoom != null) _startLocationBroadcast();
    _notify();
  }

  // ──────────────────────────────────────────────────────────────────
  // 에러 매핑 (G5)
  // ──────────────────────────────────────────────────────────────────
  Exception _mapError(PostgrestException e) {
    final code = e.code ?? '';
    final friendly = switch (code) {
      'P0001' => '14세 미만은 가입할 수 없어요.',
      'P0002' => '방이 만료됐어요.',
      'P0003' => '방이 가득 찼어요 (8명).',
      'P0004' => '차단된 사용자가 이미 방에 있어요.',
      'P0005' => '코드가 잘못됐거나 만료됐어요.',
      'P0006' => '친구가 200명을 초과했어요.',
      'P0007' => '상대방의 친구 한도가 가득 찼어요.',
      'P0008' => '거절된 신청은 7일 후 다시 보낼 수 있어요.',
      'P0009' => '방을 찾을 수 없어요.',
      'P0010' => '방장만 코드를 갱신할 수 있어요.',
      'P0011' => '방장만 강퇴할 수 있어요.',
      'P0012' => '방장은 강퇴할 수 없어요.',
      'P0013' => '로그인이 필요해요.',
      'P0014' => '관리자 전용 기능이에요.',
      'P0015' => '잘못된 상태값이에요.',
      'P0016' => '메시지를 너무 빨리 보내고 있어요.',
      'P0017' => '서로 차단된 사용자 사이에는 친구 신청을 보낼 수 없어요.',
      '23505' => '이미 존재하는 항목이에요.',
      '23503' => '연관된 데이터가 없어 처리할 수 없어요.',
      _ => e.message,
    };
    return Exception(friendly);
  }

  // ──────────────────────────────────────────────────────────────────
  // 관리자 모니터링 (G19) — RPC 가 admin email 검증.
  // ──────────────────────────────────────────────────────────────────
  static const _adminEmails = {
    'rush94434@gmail.com',
    'banavana22@gmail.com',
  };

  bool get isAdmin {
    final email = _sb.auth.currentUser?.email;
    return email != null && _adminEmails.contains(email);
  }

  Future<Map<String, int>> adminFetchMetrics() async {
    final res = await _sb.rpc('admin_get_metrics');
    if (res is List && res.isNotEmpty) {
      final row = res.first as Map<String, dynamic>;
      return row.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> adminFetchAbuseSignals() async {
    final res = await _sb.rpc('admin_get_abuse_signals');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> adminFetchReports({
    String status = 'pending',
  }) async {
    final res = await _sb.rpc('admin_get_reports', params: {'p_status': status});
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> adminUpdateReportStatus(String reportId, String status) async {
    await _sb.rpc('admin_update_report_status', params: {
      'p_report_id': reportId,
      'p_status': status,
    });
  }

  // ──────────────────────────────────────────────────────────────────
  // 디바이스 신호 (G20 — 가짜 위치/시뮬레이터 감지 — 운영용)
  // ──────────────────────────────────────────────────────────────────
  bool get isLikelySimulator {
    // iOS Simulator 는 Platform.isIOS && Platform.environment 에 SIMULATOR_HOST_HOME.
    if (Platform.isIOS) {
      return Platform.environment.containsKey('SIMULATOR_HOST_HOME');
    }
    return false;
  }
}
