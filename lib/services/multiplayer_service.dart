import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/debug_log.dart';
import '../models/multiplayer_models.dart';

/// Seoul Live — 멀티플레이어 코어.
class MultiplayerService with WidgetsBindingObserver {
  MultiplayerService._() {
    _ensureLifecycleObserver();
  }
  static final MultiplayerService instance = MultiplayerService._();

  bool _lifecycleObserverRegistered = false;
  void _ensureLifecycleObserver() {
    if (_lifecycleObserverRegistered) return;
    WidgetsBinding.instance.addObserver(this);
    _lifecycleObserverRegistered = true;
  }

  /// 정리 — 호출 안 해도 무방하지만 호출 시 lifecycle observer 해제.
  /// hot reload / 테스트 종료 시 안전망.
  void dispose() {
    if (_lifecycleObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _lifecycleObserverRegistered = false;
    }
    _cancelAllReconnects();
    _locationTimer?.cancel();
    _staleTickTimer?.cancel();
    _authSub?.cancel();
    // cache / inflight 정리 — 다음 init 시 stale future 가 stale state 에
    // 결과 쓰는 race 차단.
    _inflightProfileFetches.clear();
    _peerVisibleCache.clear();
    _peerProfiles.clear();
  }

  // ── Supabase shortcut ──────────────────────────────────────────────
  SupabaseClient get _sb => Supabase.instance.client;
  String? get myId => _sb.auth.currentUser?.id;

  /// 디바이스별 고유 ID — 같은 user 가 폰 2개로 로그인 시 presence key 충돌 차단.
  /// 인스턴스 lifetime 동안만 unique 면 충분 (영구 저장 X).
  late final String _deviceId =
      '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(99999)}';
  String? get _presenceKey =>
      myId == null ? null : '${myId!}:$_deviceId';

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

  /// 전 세계 공개 모드 peers 만 (룸 멤버 제외).
  Map<String, PeerLocation> get worldPeerLocations =>
      Map.unmodifiable(_worldPeerLocations);

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
  /// 앱 재시작 시 마지막 친구방을 복원하기 위한 키.
  static const String _kActiveRoomPrefsKey = 'mp_active_room_id';

  // ── 채널 / 타이머 ──────────────────────────────────────────────────
  RealtimeChannel? _presenceChannel;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _membersChannel;
  RealtimeChannel? _roomMetaChannel; // rooms 테이블 자체의 update (목적지 등).
  RealtimeChannel? _proposalChannel; // 방 목적지 후보(투표).
  RealtimeChannel? _voteChannel;     // 후보 투표 변경.

  // 방 목적지 후보 (Phase B6 v2 — 투표 시스템).
  DestinationProposal? _activeProposal;
  // proposal_id → {userId → vote}. 활성 proposal 만 채워짐.
  final Map<String, Map<String, bool>> _proposalVotes = {};
  RealtimeChannel? _friendsChannel;
  /// 전 세계 공개 사용자 채널 (visibility=public).
  RealtimeChannel? _worldChannel;
  /// 세계 채널 peers — 룸 peers 와 별도 저장 후 getter 에서 merge.
  final Map<String, PeerLocation> _worldPeerLocations = {};
  Timer? _locationTimer;
  Timer? _staleTickTimer;
  StreamSubscription<AuthState>? _authSub;
  String? _lastKnownUserId;

  // ── 공통 채널 재구독 helper ──
  // Supabase 채널은 closed/channelError/timedOut 으로 가도 자동 재구독 안 함.
  // 모든 Postgres-changes 채널이 같은 패턴이라 key 별 timer/attempts 로 일괄 관리.
  final Map<String, Timer> _reconnectTimers = {};
  final Map<String, int> _reconnectAttempts = {};

  void _scheduleReconnect(
    String key,
    Future<void> Function() restart, {
    required bool Function() stillNeeded,
  }) {
    if (_reconnectTimers[key] != null) return;
    final attempts = (_reconnectAttempts[key] ?? 0) + 1;
    _reconnectAttempts[key] = attempts;
    final secs = (1 << attempts.clamp(1, 5)).clamp(2, 30);
    DebugLog.log('[Multi:$key] reconnect scheduled in ${secs}s '
        '(attempt $attempts)');
    _reconnectTimers[key] = Timer(Duration(seconds: secs), () async {
      _reconnectTimers.remove(key);
      if (!stillNeeded()) return;
      DebugLog.log('[Multi:$key] reconnect now');
      try {
        await restart();
      } catch (e) {
        debugPrint('[Multi:$key] restart 실패: $e');
      }
    });
  }

  void _resetReconnect(String key) {
    _reconnectTimers.remove(key)?.cancel();
    _reconnectAttempts[key] = 0;
  }

  void _cancelAllReconnects() {
    for (final t in _reconnectTimers.values) {
      t.cancel();
    }
    _reconnectTimers.clear();
    _reconnectAttempts.clear();
  }

  /// 채널 subscribe status 콜백 공통 처리. subscribed 면 attempts 리셋,
  /// closed/error/timedOut 이면 stillNeeded 인지 체크 후 백오프 재시작.
  void Function(RealtimeSubscribeStatus status, Object? error)
      _onChannelStatus(
    String key,
    Future<void> Function() restart, {
    required bool Function() stillNeeded,
  }) {
    return (status, error) {
      DebugLog.log('[Multi:$key] subscribe status=$status err=$error');
      if (status == RealtimeSubscribeStatus.subscribed) {
        _resetReconnect(key);
      } else if (stillNeeded()) {
        _scheduleReconnect(key, restart, stillNeeded: stillNeeded);
      }
      _notify();
    };
  }

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
              // visibility 변경 시 그 peer 의 가시성 캐시 무효화.
              if (prev != null && prev.visibility != updated.visibility) {
                _peerVisibleCache.remove(updated.userId);
              }
              // 곡 변경 감지 — 새로 시작/스왑(곡 또는 아티스트) 모두 감지.
              final newName = updated.currentTrack?.name;
              final newArtist = updated.currentTrack?.artist;
              final oldName = prev?.currentTrack?.name;
              final oldArtist = prev?.currentTrack?.artist;
              final changed =
                  newName != oldName || newArtist != oldArtist;
              if (newName != null && changed && updated.userId != myId) {
                for (final l in List.of(_peerTrackListeners)) {
                  try {
                    l(updated.userId, newName, newArtist ?? '');
                  } catch (_) {}
                }
              }
              _notify();
            } catch (e) {
              debugPrint('[Multi] peer profile parse 실패: $e');
            }
          },
        )
        .subscribe(_onChannelStatus(
          'peer.profiles',
          () async {
            try { await _profilesChannel?.unsubscribe(); } catch (_) {}
            _profilesChannel = null;
            _subscribeFriendProfiles();
          },
          stillNeeded: () => myId != null && _currentRoom != null,
        ));
  }

  /// B7 게이미피케이션 — 내 점수/뱃지.
  UserScore? _myScore;
  UserScore? get myScore => _myScore;
  RealtimeChannel? _scoreChannel;

  /// 최근 만남 기록 (최대 20개). SharedPreferences 영속화 — 재시작 시 복원.
  final List<({String userId, DateTime at})> _meetupHistory = [];
  List<({String userId, DateTime at})> get meetupHistory =>
      List.unmodifiable(_meetupHistory);
  static const String _kMeetupHistoryPrefsKey = 'mp_meetup_history';

  Future<void> _loadMeetupHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kMeetupHistoryPrefsKey);
      if (raw == null || raw.isEmpty) return;
      // 형식: "uid|ms,uid|ms,...".
      _meetupHistory.clear();
      for (final entry in raw.split(',')) {
        final parts = entry.split('|');
        if (parts.length != 2) continue;
        final ms = int.tryParse(parts[1]);
        if (ms == null) continue;
        _meetupHistory.add((
          userId: parts[0],
          at: DateTime.fromMillisecondsSinceEpoch(ms),
        ));
      }
    } catch (e) {
      debugPrint('[Multi] _loadMeetupHistory 실패: $e');
    }
  }

  Future<void> _saveMeetupHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _meetupHistory
          .map((e) => '${e.userId}|${e.at.millisecondsSinceEpoch}')
          .join(',');
      await prefs.setString(_kMeetupHistoryPrefsKey, encoded);
    } catch (e) {
      debugPrint('[Multi] _saveMeetupHistory 실패: $e');
    }
  }

  void _recordMeetup(String userId) {
    _meetupHistory.insert(0, (userId: userId, at: DateTime.now()));
    if (_meetupHistory.length > 20) _meetupHistory.removeLast();
    _saveMeetupHistory(); // fire-and-forget
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

  /// 강퇴됐을 때 알림 (UI 가 토스트/안내 표시).
  final List<VoidCallback> _kickedListeners = [];
  void addKickedListener(VoidCallback l) => _kickedListeners.add(l);
  void removeKickedListener(VoidCallback l) => _kickedListeners.remove(l);

  // ──────────────────────────────────────────────────────────────────
  // 앱 라이프사이클 — 백그라운드 진입 시 위치 송신 일시정지.
  // ──────────────────────────────────────────────────────────────────

  /// foreground 복귀 시 외부 hook (NotificationService 등이 등록).
  final List<VoidCallback> _foregroundListeners = [];
  void addForegroundListener(VoidCallback l) => _foregroundListeners.add(l);
  void removeForegroundListener(VoidCallback l) =>
      _foregroundListeners.remove(l);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasBg = _isInBackground;
    _isInBackground = state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
    if (wasBg && !_isInBackground) {
      // foreground 복귀 listener 들에게 알림 (notif permission 재검사 등).
      for (final l in List.of(_foregroundListeners)) {
        try { l(); } catch (_) {}
      }
      // 포그라운드 복귀 — 채널이 백그라운드 동안 close 됐을 수 있으니
      // currentRoom / public 둘 다 강제 재구독.
      if (_currentRoom != null && _myProfile?.visibility != 'ghost') {
        _restartRoomPresence();
      }
      if (_myProfile?.visibility == 'public') {
        try {
          _worldChannel?.unsubscribe();
        } catch (_) {}
        _worldChannel = null;
        _worldPeerLocations.clear();
        _syncWorldChannel();
      } else {
        _syncWorldChannel();
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
    await _loadMeetupHistory();
    _subscribeMyScore();
    _subscribeFriendshipUpdates();
    _subscribeGroupVisibilityChanges();
    _startStaleTick();
    _syncWorldChannel();
    await _restoreActiveRoomIfAny();
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
    await _loadMeetupHistory();
        _subscribeMyScore();
        _subscribeFriendshipUpdates();
        _startStaleTick();
        _syncWorldChannel();
        await _restoreActiveRoomIfAny();
      }
    });
  }

  Future<void> _resetAllState() async {
    _locationTimer?.cancel();
    _locationTimer = null;
    _staleTickTimer?.cancel();
    _staleTickTimer = null;
    _cancelAllReconnects();
    try {
      await _presenceChannel?.unsubscribe();
      await _messagesChannel?.unsubscribe();
      await _membersChannel?.unsubscribe();
      await _roomMetaChannel?.unsubscribe();
      await _profilesChannel?.unsubscribe();
      await _friendsChannel?.unsubscribe();
      await _worldChannel?.unsubscribe();
      await _scoreChannel?.unsubscribe();
      await _groupVisibilityChannel?.unsubscribe();
    } catch (_) {}
    _presenceChannel = null;
    _messagesChannel = null;
    _membersChannel = null;
    _roomMetaChannel = null;
    _profilesChannel = null;
    _friendsChannel = null;
    _worldChannel = null;
    _scoreChannel = null;
    _groupVisibilityChannel = null;
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
    _meetupHistory.clear();
    _seoulLiveActive = false;
    _seoulLivePaused = false;
    _lastBroadcasted = null;
    _isStationary = false;
    await _clearActiveRoomId();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kMeetupHistoryPrefsKey);
    } catch (_) {}
    _notify();
  }

  /// 30초 주기로 stale presence + 만료 임박 체크 → UI re-render.
  void _startStaleTick() {
    _staleTickTimer?.cancel();
    _staleTickTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      // 방 만료 자동 감지 — server 가 RLS reject 하기 전에 클라가 먼저 나감.
      final room = _currentRoom;
      if (room != null && room.expiresAt.isBefore(DateTime.now())) {
        debugPrint('[Multi] 방 만료 감지 → 자동 leave');
        for (final l in List.of(_kickedListeners)) {
          try { l(); } catch (_) {}
        }
        leaveCurrentRoom();
        return;
      }
      _notify();
    });
  }

  // ──────────────────────────────────────────────────────────────────
  // 프로필
  // ──────────────────────────────────────────────────────────────────
  Future<void> _loadMyProfile() async {
    if (myId == null) return;
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
    // 정확한 생년월일 없이 birth_year 만 받으므로 — 생일 전인지 후인지 모름.
    // PIPA 14세 미만 가입 금지 — 보수적으로 (현재년도 - birth_year - 1) 으로
    // 계산해 "최대 14세 미만" 인 경우를 차단. 예: 2026년, 2012년생 = 정확히는
    // 14세 또는 13세 (생일 전). 13세 가능성 있으므로 거절.
    final conservativeAge = DateTime.now().year - birthYear - 1;
    if (conservativeAge < kMinAgeYears) {
      throw ArgumentError('14세 미만은 가입할 수 없습니다.');
    }
    // 가시성 검증 — UI 의 4가지 옵션을 모두 받는다.
    if (!const ['public', 'friends', 'ghost', 'selected_groups']
        .contains(visibility)) {
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

  /// 여러 peer 프로필을 한 쿼리로 가져옴 — N+1 회피.
  /// 차단된 uid 는 자동 제외. 캐시에 이미 있으면 query 에서 빠짐.
  Future<void> fetchPeerProfilesBatch(Iterable<String> userIds) async {
    final ids = userIds
        .where((u) => !_peerProfiles.containsKey(u) && !isBlocked(u))
        .toSet()
        .toList();
    if (ids.isEmpty) return;
    try {
      final res = await _sb.from('profiles').select().inFilter('user_id', ids);
      for (final r in (res as List)) {
        try {
          final p = MultiplayerProfile.fromJson(r as Map<String, dynamic>);
          _peerProfiles[p.userId] = p;
        } catch (e) {
          debugPrint('[Multi] batch profile parse 실패: $e');
        }
      }
      _notify();
    } catch (e) {
      debugPrint('[Multi] fetchPeerProfilesBatch 실패: $e');
    }
  }

  /// in-flight fetch dedup — 같은 uid 동시 호출 시 같은 Future 공유.
  final Map<String, Future<MultiplayerProfile?>> _inflightProfileFetches = {};

  Future<MultiplayerProfile?> fetchPeerProfile(String userId) async {
    if (isBlocked(userId)) return null;
    if (_peerProfiles.containsKey(userId)) return _peerProfiles[userId];
    final inflight = _inflightProfileFetches[userId];
    if (inflight != null) return inflight;
    final future = _doFetchPeerProfile(userId);
    _inflightProfileFetches[userId] = future;
    try {
      return await future;
    } finally {
      _inflightProfileFetches.remove(userId);
    }
  }

  Future<MultiplayerProfile?> _doFetchPeerProfile(String userId) async {
    try {
      final res = await _sb
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null) {
        final p = MultiplayerProfile.fromJson(res);
        // realtime 이 await 사이에 더 신선한 데이터를 넣었을 수 있음 — 그 경우 덮어쓰지 X.
        if (!_peerProfiles.containsKey(userId)) {
          _peerProfiles[userId] = p;
          _notify();
        }
        return _peerProfiles[userId];
      }
    } catch (e) {
      debugPrint('[Multi] fetchPeerProfile $userId 실패: $e');
    }
    return null;
  }

  /// 닉네임으로 검색. RPC 가 RLS 우회 + 차단 자동 필터.
  Future<List<MultiplayerProfile>> searchByNickname(String nickname) async {
    // 입력 검증 — 빈/너무 길음/길면 RPC 부담 + 의미없는 결과.
    final q = nickname.trim();
    if (q.isEmpty || q.length > 40) return [];
    try {
      final res = await _sb.rpc(
        'search_profile_by_nickname',
        params: {'p_nickname': q},
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
  static final RegExp _friendCodeRe = RegExp(r'^[A-Z0-9]{8}$');

  Future<MultiplayerProfile?> searchByFriendCode(String code) async {
    final upper = code.toUpperCase().trim();
    if (!_friendCodeRe.hasMatch(upper)) return null;
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
    if (myId == null) return;
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

  /// 보낸 친구 신청 취소 — pending 상태이고 본인이 initiated_by 인 것만.
  Future<void> cancelFriendRequest(String otherUserId) async {
    if (myId == null) return;
    final a = myId!.compareTo(otherUserId) < 0 ? myId! : otherUserId;
    final b = myId!.compareTo(otherUserId) < 0 ? otherUserId : myId!;
    try {
      await _sb
          .from('friendships')
          .delete()
          .eq('user_a', a)
          .eq('user_b', b)
          .eq('status', 'pending')
          .eq('initiated_by', myId!);
      await _loadFriendships();
    } on PostgrestException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> removeFriend(String otherUserId) async {
    if (myId == null) return;
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
        .subscribe(_onChannelStatus(
          'friendships',
          () async {
            try { await _friendsChannel?.unsubscribe(); } catch (_) {}
            _friendsChannel = null;
            _subscribeFriendshipUpdates();
            // 재연결 사이 변경 누락 보전.
            await _loadFriendships();
          },
          stillNeeded: () => myId != null,
        ));
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
    if (myId == null) return;
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
    // 친구 신청 cooldown 도 정리 — 차단된 사용자는 7일 cooldown 도 의미 없음.
    final a = myId!.compareTo(userId) < 0 ? myId! : userId;
    final b = myId!.compareTo(userId) < 0 ? userId : myId!;
    try {
      await _sb
          .from('friend_request_cooldowns')
          .delete()
          .eq('user_a', a)
          .eq('user_b', b);
    } catch (e) {
      debugPrint('[Multi] block 시 cooldown 정리 실패: $e');
    }
    await _loadBlocks();
    await _refreshRoomMembers();
    // #18 차단된 사용자의 기존 메시지도 클라 캐시에서 즉시 제거.
    _messages.removeWhere((m) => m.userId == userId);
    // peer 핀 + 프로필 캐시 + 가시성 캐시 즉시 정리.
    _peerLocations.remove(userId);
    _worldPeerLocations.remove(userId);
    _peerProfiles.remove(userId);
    _peerVisibleCache.remove(userId);
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
    if (myId == null) return;
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

  /// 그룹 가시성 캐시 무효화 트리거: peer 가 자기 visible group 설정을 바꾸거나
  /// 그룹 멤버 변경/그룹 삭제 시 fired. _peerVisibleCache 를 비워서 다음
  /// canSeePeerLocation 호출에 새로 RPC 검증.
  RealtimeChannel? _groupVisibilityChannel;

  void _subscribeGroupVisibilityChanges() {
    if (myId == null) return;
    _groupVisibilityChannel = _sb
        .channel('group_visibility_$myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profile_visible_groups',
          callback: (_) => _onGroupVisibilityChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friend_group_members',
          callback: (_) => _onGroupVisibilityChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friend_groups',
          callback: (_) => _onGroupVisibilityChanged(),
        )
        .subscribe(_onChannelStatus(
          'group.visibility',
          () async {
            try { await _groupVisibilityChannel?.unsubscribe(); } catch (_) {}
            _groupVisibilityChannel = null;
            _subscribeGroupVisibilityChanges();
          },
          stillNeeded: () => myId != null,
        ));
  }

  void _onGroupVisibilityChanged() {
    debugPrint('[Multi] group visibility 변경 감지 → 캐시 무효화');
    _peerVisibleCache.clear();
    _notify();
  }

  /// peer 가 selected_groups 모드일 때 내가 그 사람의 핀을 볼 수 있는지.
  /// 결과는 캐시 — 반복 호출 시 즉시 반환. FIFO 500개 cap (메모리 누수 방지).
  static const int _kMaxVisibilityCacheSize = 500;

  Future<bool> canSeePeerLocation(String peerId) async {
    final cached = _peerVisibleCache[peerId];
    if (cached != null) return cached;
    try {
      final res = await _sb.rpc('am_i_visible_to', params: {'p_owner': peerId});
      final v = res == true;
      // cap 도달 시 가장 오래된 entry 제거 (Map 은 insertion order 유지).
      if (_peerVisibleCache.length >= _kMaxVisibilityCacheSize) {
        _peerVisibleCache.remove(_peerVisibleCache.keys.first);
      }
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
  /// 진단용 — activity_log insert 실패 누적 카운트. 다이얼로그에 표시.
  int _activityFailCount = 0;
  int get activityFailCount => _activityFailCount;
  String? _lastActivityError;
  String? get lastActivityError => _lastActivityError;

  void logActivity(String kind, {Map<String, dynamic> payload = const {}}) {
    if (myId == null) return;
    _sb.from('activity_log').insert({
      'user_id': myId,
      'kind': kind,
      'payload': payload,
    }).then((_) {
      // 성공 — 이전 실패 메시지 클리어 (최근 상태 유지).
      _lastActivityError = null;
    }, onError: (e) {
      _activityFailCount++;
      _lastActivityError = e.toString();
      debugPrint('[Multi] logActivity 실패 ($kind, total=$_activityFailCount): $e');
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
              } catch (e) {
                debugPrint('[Multi] user score parse 실패: $e');
              }
            }
          },
        )
        .subscribe(_onChannelStatus(
          'user.score',
          () async {
            try { await _scoreChannel?.unsubscribe(); } catch (_) {}
            _scoreChannel = null;
            _subscribeMyScore();
            await _loadMyScore();
    await _loadMeetupHistory();
          },
          stillNeeded: () => myId != null,
        ));
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
    PostgrestException? lastErr;
    // invite_code unique constraint 충돌 시 새 코드로 최대 5회 재시도.
    for (int i = 0; i < 5; i++) {
      final code = _generateInviteCode();
      try {
        final res = await _sb.from('rooms').insert({
          'invite_code': code,
          'owner_id': myId,
          'name': name,
        }).select().single();
        final room = Room.fromJson(res);
        await _sb
            .from('room_members')
            .insert({'room_id': room.id, 'user_id': myId});
        await enterRoom(room);
        return room;
      } on PostgrestException catch (e) {
        // 23505 = unique_violation. 다른 에러는 즉시 throw.
        if (e.code == '23505' && e.message.contains('invite_code') && i < 4) {
          debugPrint('[Multi] invite code 충돌 — 재시도 ${i + 1}/5');
          lastErr = e;
          continue;
        }
        throw _mapError(e);
      }
    }
    throw _mapError(lastErr!);
  }

  static final RegExp _roomCodeRe = RegExp(r'^[A-Z0-9]{4,8}$');

  Future<Room> joinRoomByCode(String code) async {
    final upper = code.toUpperCase().trim();
    // 클라이언트 측 입력 검증 — 빈/너무 짧음/너무 김/특수문자 즉시 거절.
    if (!_roomCodeRe.hasMatch(upper)) {
      throw Exception('코드가 잘못됐어요 (4~8자 영문/숫자).');
    }
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
    // 방 입장 = 위치 공유 의도. ghost 인 채로 들어가면 다른 멤버가 내 위치를
    // 못 봐서 "친구 폰에선 다른 사람 위치 안 보임" 식 사일런트 실패 발생.
    // → 자동으로 'friends' 로 promote.
    if (_myProfile?.visibility == 'ghost') {
      debugPrint('[Multi] 방 입장 시 visibility ghost 감지 → friends 로 자동 변경');
      try {
        await setVisibility('friends');
      } catch (e) {
        debugPrint('[Multi] visibility 자동 변경 실패: $e');
      }
    }

    // 이전 룸의 채널 정리.
    if (_currentRoom != null && _currentRoom!.id != room.id) {
      try {
        await _presenceChannel?.unsubscribe();
        await _messagesChannel?.unsubscribe();
        await _membersChannel?.unsubscribe();
        await _roomMetaChannel?.unsubscribe();
        await _proposalChannel?.unsubscribe();
        await _voteChannel?.unsubscribe();
      } catch (_) {}
      _presenceChannel = null;
      _messagesChannel = null;
      _membersChannel = null;
      _proposalChannel = null;
      _voteChannel = null;
      _activeProposal = null;
      _proposalVotes.clear();
    }

    _currentRoom = room;
    _peerLocations.clear();
    _activeMeetups.clear();
    _messages.clear();
    _hasMoreMessages = true;
    // 처음 들어가는 방이면 0, 이전에 있던 방이면 이전 카운트 유지 (재진입 reset 방지).
    _unreadCounts.putIfAbsent(room.id, () => 0);
    // 매 방 입장 시 권한 안내 dedup 리셋 — 권한 거부면 이번에 다시 알림.
    _locPermissionWarned = false;
    await _saveActiveRoomId(room.id);

    await _refreshRoomMembers();
    await _loadInitialMessages();
    _subscribeRoomMembers();
    _subscribeRoomMessages();
    _subscribeRoomMeta();
    _subscribeRoomProposals();
    await _refreshActiveProposal();
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
    // 본인이 owner 이고 본인이 마지막 멤버라면 → 떠나기 전에 destination 정리.
    // 안 그러면 stale dest_* 가 행에 남아 다음 사람이 이 방 코드로 들어오면 보임.
    final isOwner = room.ownerId == myId;
    final isLast = _currentRoomMembers.length <= 1;
    if (isOwner && isLast && room.hasDestination) {
      try {
        await _sb.rpc('clear_room_destination', params: {'p_room_id': room.id});
      } catch (e) {
        debugPrint('[Multi] leave 시 destination 정리 실패: $e');
      }
    }
    _stopLocationBroadcast();
    await _presenceChannel?.unsubscribe();
    await _messagesChannel?.unsubscribe();
    await _membersChannel?.unsubscribe();
    await _roomMetaChannel?.unsubscribe();
    await _proposalChannel?.unsubscribe();
    await _voteChannel?.unsubscribe();
    await _profilesChannel?.unsubscribe();
    _presenceChannel = null;
    _messagesChannel = null;
    _membersChannel = null;
    _roomMetaChannel = null;
    _proposalChannel = null;
    _voteChannel = null;
    _profilesChannel = null;
    _activeProposal = null;
    _proposalVotes.clear();
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
    // _unreadCounts 는 leave 시 정리하지 않음 — 다시 들어가도 안 읽은 카운트 보존.
    _roomPresenceStatus = null;
    _lastRoomTrackAt = null;
    _lastRoomTrackError = null;
    _resetReconnect('room.presence');
    _resetReconnect('room.messages');
    _resetReconnect('room.members');
    _resetReconnect('room.meta');
    _resetReconnect('peer.profiles');
    _resetReconnect('friendships');
    _resetReconnect('user.score');
    await _clearActiveRoomId();
    _notify();
  }

  Future<void> _saveActiveRoomId(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kActiveRoomPrefsKey, roomId);
    } catch (e) {
      debugPrint('[Multi] _saveActiveRoomId 실패: $e');
    }
  }

  Future<void> _clearActiveRoomId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kActiveRoomPrefsKey);
    } catch (_) {}
  }

  /// 앱 재시작 시 마지막으로 들어가 있던 친구방을 복원.
  /// 멤버십이 사라졌거나(강퇴/만료) 방이 만료됐다면 키를 지우고 종료.
  Future<void> _restoreActiveRoomIfAny() async {
    if (myId == null || _currentRoom != null) return;
    String? roomId;
    try {
      final prefs = await SharedPreferences.getInstance();
      roomId = prefs.getString(_kActiveRoomPrefsKey);
    } catch (_) {}
    if (roomId == null) return;
    try {
      final memberRow = await _sb
          .from('room_members')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('user_id', myId!)
          .maybeSingle();
      if (memberRow == null) {
        await _clearActiveRoomId();
        return;
      }
      final roomRow =
          await _sb.from('rooms').select().eq('id', roomId).maybeSingle();
      if (roomRow == null) {
        await _clearActiveRoomId();
        return;
      }
      final room = Room.fromJson(roomRow);
      if (room.expiresAt.isBefore(DateTime.now())) {
        await _clearActiveRoomId();
        return;
      }
      debugPrint('[Multi] 친구방 복원 ${room.inviteCode}');
      await enterRoom(room);
    } catch (e) {
      debugPrint('[Multi] _restoreActiveRoomIfAny 실패: $e');
    }
  }

  Future<void> _refreshRoomMembers() async {
    if (_currentRoom == null) return;
    try {
      final res = await _sb
          .from('room_members')
          .select('user_id')
          .eq('room_id', _currentRoom!.id);
      final fresh = (res as List).map((r) => r['user_id'] as String).toList();
      _currentRoomMembers
        ..clear()
        ..addAll(fresh);
      // 강퇴 race: 내 myId 가 멤버 목록에 없으면 → 강퇴됐거나 RLS 권한 사라짐.
      // 자동으로 방 떠나기 + listener 알림.
      if (myId != null && !fresh.contains(myId)) {
        debugPrint('[Multi] 멤버 목록에 본인 없음 → 강퇴 처리');
        for (final l in List.of(_kickedListeners)) {
          try { l(); } catch (_) {}
        }
        await leaveCurrentRoom();
        return;
      }
      // 누락된 프로필 batch fetch — 멤버 N명에 대해 1회 쿼리.
      await fetchPeerProfilesBatch(_currentRoomMembers);
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
    final roomId = _currentRoom!.id;
    // myId 노출 마스킹 — 앞 8자만.
    DebugLog.log('[Multi:room] presence subscribe begin room=$roomId '
        'uid=${myId!.substring(0, 8)}…');
    _presenceChannel = _sb
        .channel(
          'room_presence_$roomId',
          opts: RealtimeChannelConfig(self: false, key: _presenceKey!),
        )
        .onPresenceSync((p) {
          DebugLog.log('[Multi:room] presence SYNC');
          _onPresenceSync();
        })
        .onPresenceJoin((p) {
          DebugLog.log('[Multi:room] presence JOIN ${p.newPresences.length}');
          _onPresenceSync();
        })
        .onPresenceLeave((p) {
          DebugLog.log('[Multi:room] presence LEAVE ${p.leftPresences.length}');
          _onPresenceSync();
        })
        .subscribe((status, error) {
          _roomPresenceStatus = status.toString();
          _onChannelStatus('room.presence', _restartRoomPresence,
              stillNeeded: () => _currentRoom?.id == roomId)(status, error);
        });
  }

  Future<void> _restartRoomPresence() async {
    if (_currentRoom == null) return;
    DebugLog.log('[Multi:room] restart presence channel');
    try {
      await _presenceChannel?.unsubscribe();
    } catch (_) {}
    _presenceChannel = null;
    _startPresence();
    _startLocationBroadcast();
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
    DebugLog.log('[Multi] presence sync — state=${state.length} '
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
    if (_seoulLivePaused) {
      DebugLog.log('[Multi] broadcast skip — paused');
      return;
    }
    if (_isInBackground) {
      DebugLog.log('[Multi] broadcast skip — background');
      return;
    }
    if (_myProfile?.visibility == 'ghost') {
      DebugLog.log('[Multi] broadcast skip — visibility=ghost');
      return;
    }
    // 룸 채널 또는 world 채널 둘 중 하나라도 있어야 함.
    if (_presenceChannel == null && _worldChannel == null) {
      DebugLog.log('[Multi] broadcast skip — no channel');
      return;
    }
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
  /// 외부 노출용 — BuildingPresenceTracker 등에서 자기 위치 조회.
  Position? get lastBroadcasted => _lastBroadcasted;

  /// 진단용 — 마지막으로 room presence 에 track 성공한 시각.
  DateTime? _lastRoomTrackAt;
  DateTime? get lastRoomTrackAt => _lastRoomTrackAt;
  String? _lastRoomTrackError;
  String? get lastRoomTrackError => _lastRoomTrackError;
  /// 진단용 — room presence 채널의 마지막 subscribe status 문자열.
  String? _roomPresenceStatus;
  String? get roomPresenceStatus => _roomPresenceStatus;
  /// 진단용 — world 채널의 마지막 subscribe status.
  String? _worldChannelStatus;
  String? get worldChannelStatus => _worldChannelStatus;

  bool _locPermissionWarned = false;

  Future<void> _broadcastOnce() async {
    if (_seoulLivePaused) return;
    if (_isInBackground) return;
    if (_myProfile?.visibility == 'ghost') return;
    if (myId == null) return;
    // 둘 다 없으면 송신 불가 (룸도 없고 world 도 없음).
    if (_presenceChannel == null && _worldChannel == null) {
      DebugLog.log('[Multi] broadcast skip — no channel');
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
      // 권한 + GPS fix 가 끝난 후 visibility 가 ghost 로 토글됐을 수 있음 (race).
      // 마지막 좌표가 정확히 송신되면 사용자가 비공개로 바꾼 직후 1회 leak.
      // → track 직전에 visibility 재검사.
      if (_seoulLivePaused || _myProfile?.visibility == 'ghost') {
        debugPrint('[Multi] broadcast aborted — visibility 변경 race');
        return;
      }
      // 룸 멤버에겐 정확한 위치, world peers 에겐 ~50m grid 로 라운딩 (스토킹 방지).
      final exactPayload = {
        'user_id': myId,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'heading': pos.heading,
        'ts': DateTime.now().millisecondsSinceEpoch,
      };
      if (_presenceChannel != null) {
        try {
          await _presenceChannel!.track(exactPayload);
          _lastRoomTrackAt = DateTime.now();
          _lastRoomTrackError = null;
          // PII 보호 — 정확 좌표 대신 ~1km grid 라운딩으로 마스킹.
          DebugLog.log('[Multi:room] track OK '
              '(~${pos.latitude.toStringAsFixed(2)}, '
              '~${pos.longitude.toStringAsFixed(2)})');
        } catch (e) {
          _lastRoomTrackError = e.toString();
          debugPrint('[Multi:room] track 실패: $e');
        }
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
        try {
          await _worldChannel!.track(fuzzedPayload);
          DebugLog.log('[Multi:public] world track OK '
              '(${fuzzedPayload['lat']}, ${fuzzedPayload['lng']})');
        } catch (e) {
          debugPrint('[Multi:public] world track 실패: $e');
        }
      }
    } catch (e) {
      debugPrint('[Multi] broadcastOnce 실패: $e');
    }
  }

  /// World 채널 sync — public 전용 (대칭성: 보려면 본인도 공개).
  void _syncWorldChannel() {
    final vis = _myProfile?.visibility;
    final shouldBeActive = vis == 'public' &&
        !_seoulLivePaused &&
        !_isInBackground &&
        myId != null;
    DebugLog.log('[Multi:public] _syncWorldChannel — vis=$vis '
        'paused=$_seoulLivePaused bg=$_isInBackground '
        'shouldBeActive=$shouldBeActive '
        'currentChannel=${_worldChannel == null ? "null" : "exists"}');
    if (shouldBeActive && _worldChannel == null) {
      _startWorldChannel();
    } else if (!shouldBeActive && _worldChannel != null) {
      _stopWorldChannel();
    }
    if (shouldBeActive) _broadcastOnce();
  }

  void _startWorldChannel() {
    if (_worldChannel != null || myId == null) return;
    DebugLog.log('[Multi:public] _startWorldChannel subscribe begin '
        'uid=${myId!.substring(0, 8)}…');
    _worldChannel = _sb
        .channel(
          'seoul_live_world',
          opts: RealtimeChannelConfig(self: false, key: _presenceKey!),
        )
        .onPresenceSync((p) {
          DebugLog.log('[Multi:public] presence SYNC');
          _onWorldSync();
        })
        .onPresenceJoin((p) {
          DebugLog.log('[Multi:public] presence JOIN ${p.newPresences.length}');
          _onWorldSync();
        })
        .onPresenceLeave((p) {
          DebugLog.log('[Multi:public] presence LEAVE ${p.leftPresences.length}');
          _onWorldSync();
        })
        .subscribe((status, error) {
          _worldChannelStatus = status.toString();
          _onChannelStatus('public.world', _restartWorldChannel,
              stillNeeded: () => _myProfile?.visibility == 'public')(
              status, error);
        });
    // 처음 시작 시에도 위치 송신 시작 (룸 안이 아니어도).
    if (_locationTimer == null) _startLocationBroadcast();
  }

  Future<void> _restartWorldChannel() async {
    DebugLog.log('[Multi:public] restart world channel');
    try {
      await _worldChannel?.unsubscribe();
    } catch (_) {}
    _worldChannel = null;
    _worldPeerLocations.clear();
    _startWorldChannel();
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
          debugPrint('[Multi:public] presence parse 실패 uid=$uid: $e');
        }
      }
    }
    DebugLog.log('[Multi:public] world sync — state=${state.length} '
        'presences=$totalPresences peers=${next.length}');
    _worldPeerLocations
      ..clear()
      ..addAll(next);
    // 새 peer 프로필 prefetch — 1회 batch query (백그라운드, await X).
    fetchPeerProfilesBatch(next.keys);
    _notify();
  }

  // ──────────────────────────────────────────────────────────────────
  // 만남 감지
  // ──────────────────────────────────────────────────────────────────
  /// Hysteresis: 한 번 만남 상태가 되면 [_kMeetupExitRadius] 벗어나야 종료.
  /// 50m ↔ 60m GPS 진동 시 메시지 토글 방지.
  static const double _kMeetupExitRadius = 80.0;
  /// 같은 peer 만남 알림 dedup 윈도우 — 60s 는 같은 카페 머무는 동안 GPS 진동
  /// 으로 in/out 반복 시 부족했음. 5분으로 늘림.
  static const Duration _kMeetupDedupWindow = Duration(minutes: 5);

  void _checkMeetups() {
    final me = _lastBroadcasted;
    if (me == null) return;
    final newlyMeeting = <String>{};
    for (final p in _peerLocations.values) {
      if (p.isOffline) continue;
      final dist = Geolocator.distanceBetween(
          me.latitude, me.longitude, p.lat, p.lng);
      final wasMeeting = _activeMeetups.contains(p.userId);
      // hysteresis: 이미 만남 중이면 exit radius, 아니면 entry radius.
      final threshold =
          wasMeeting ? _kMeetupExitRadius : kMeetupRadiusMeters;
      if (dist <= threshold) newlyMeeting.add(p.userId);
    }
    final started = newlyMeeting.difference(_activeMeetups);
    final ended = _activeMeetups.difference(newlyMeeting);
    _activeMeetups
      ..clear()
      ..addAll(newlyMeeting);
    for (final uid in started) {
      final last = _lastMeetupNotifiedAt[uid];
      if (last != null &&
          DateTime.now().difference(last) < _kMeetupDedupWindow) continue;
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
    final roomId = _currentRoom!.id;
    _messagesChannel = _sb
        .channel('room_msgs_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'room_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            final m = RoomMessage.fromJson(payload.newRecord);
            if (isBlocked(m.userId)) return;
            _messages.add(m);
            if (m.userId != myId) {
              _unreadCounts[m.roomId] = (_unreadCounts[m.roomId] ?? 0) + 1;
            }
            _notify();
          },
        )
        .subscribe(_onChannelStatus(
          'room.messages',
          () async {
            try { await _messagesChannel?.unsubscribe(); } catch (_) {}
            _messagesChannel = null;
            _subscribeRoomMessages();
          },
          stillNeeded: () => _currentRoom?.id == roomId,
        ));
  }

  void _subscribeRoomMembers() {
    if (_currentRoom == null) return;
    final roomId = _currentRoom!.id;
    _membersChannel = _sb
        .channel('room_members_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (_) => _refreshRoomMembers(),
        )
        .subscribe(_onChannelStatus(
          'room.members',
          () async {
            try { await _membersChannel?.unsubscribe(); } catch (_) {}
            _membersChannel = null;
            _subscribeRoomMembers();
            // 재연결 사이 변경 누락 보전.
            await _refreshRoomMembers();
          },
          stillNeeded: () => _currentRoom?.id == roomId,
        ));
  }

  /// rooms 테이블 자체 (목적지 등 메타) update 구독.
  void _subscribeRoomMeta() {
    if (_currentRoom == null) return;
    final roomId = _currentRoom!.id;
    _roomMetaChannel = _sb
        .channel('room_meta_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: roomId,
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
        .subscribe(_onChannelStatus(
          'room.meta',
          () async {
            try { await _roomMetaChannel?.unsubscribe(); } catch (_) {}
            _roomMetaChannel = null;
            _subscribeRoomMeta();
          },
          stillNeeded: () => _currentRoom?.id == roomId,
        ));
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
      // 좌표는 location history 가 되므로 logActivity 에 안 보냄. 이름만.
      logActivity('destination_set', payload: {'name': name});
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
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 방 목적지 후보 / 투표 (Phase B6 v2)
  // ──────────────────────────────────────────────────────────────────

  DestinationProposal? get activeProposal => _activeProposal;

  /// proposal_id 의 투표 — user_id → vote (true=yes, false=no).
  Map<String, bool> votesFor(String proposalId) =>
      _proposalVotes[proposalId] ?? const {};

  Future<String?> proposeRoomDestination({
    required String name,
    required double lat,
    required double lng,
    String? address,
  }) async {
    if (_currentRoom == null) throw Exception('방에 입장해 있어야 해요.');
    try {
      final res = await _sb.rpc('propose_room_destination', params: {
        'p_room_id': _currentRoom!.id,
        'p_name': name,
        'p_lat': lat,
        'p_lng': lng,
        'p_address': address,
      });
      logActivity('destination_proposed', payload: {'name': name});
      await _refreshActiveProposal();
      return res as String?;
    } catch (e) {
      debugPrint('[Multi] proposeRoomDestination 실패: $e');
      rethrow;
    }
  }

  Future<void> voteRoomDestination(String proposalId, bool vote) async {
    try {
      await _sb.rpc('vote_room_destination', params: {
        'p_proposal_id': proposalId,
        'p_vote': vote,
      });
      // 본인 vote 즉시 반영 — realtime broadcast 도 곧 옴.
      _proposalVotes.putIfAbsent(proposalId, () => <String, bool>{});
      if (myId != null) _proposalVotes[proposalId]![myId!] = vote;
      _notify();
      // 임계 도달 시 active proposal 상태가 바뀌었을 수 있으므로 refetch.
      await _refreshActiveProposal();
    } catch (e) {
      debugPrint('[Multi] voteRoomDestination 실패: $e');
      rethrow;
    }
  }

  Future<void> cancelRoomDestinationProposal(String proposalId) async {
    try {
      await _sb.rpc('cancel_room_destination_proposal',
          params: {'p_proposal_id': proposalId});
      await _refreshActiveProposal();
    } catch (e) {
      debugPrint('[Multi] cancelRoomDestinationProposal 실패: $e');
      rethrow;
    }
  }

  Future<void> _refreshActiveProposal() async {
    if (_currentRoom == null) {
      _activeProposal = null;
      _proposalVotes.clear();
      _notify();
      return;
    }
    try {
      final res = await _sb
          .from('room_destination_proposals')
          .select()
          .eq('room_id', _currentRoom!.id)
          .eq('status', 'voting')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (res != null) {
        _activeProposal = DestinationProposal.fromJson(res);
        await _refreshProposalVotes(_activeProposal!.id);
      } else {
        _activeProposal = null;
      }
      _notify();
    } catch (e) {
      debugPrint('[Multi] _refreshActiveProposal 실패: $e');
    }
  }

  Future<void> _refreshProposalVotes(String proposalId) async {
    try {
      final res = await _sb
          .from('room_destination_votes')
          .select()
          .eq('proposal_id', proposalId);
      final map = <String, bool>{};
      for (final r in (res as List)) {
        map[r['user_id'] as String] = r['vote'] as bool;
      }
      _proposalVotes[proposalId] = map;
      _notify();
    } catch (e) {
      debugPrint('[Multi] _refreshProposalVotes 실패: $e');
    }
  }

  void _subscribeRoomProposals() {
    if (_currentRoom == null) return;
    final roomId = _currentRoom!.id;
    _proposalChannel = _sb
        .channel('room_proposals_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_destination_proposals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (_) => _refreshActiveProposal(),
        )
        .subscribe(_onChannelStatus(
          'room.proposals',
          () async {
            try { await _proposalChannel?.unsubscribe(); } catch (_) {}
            _proposalChannel = null;
            _subscribeRoomProposals();
          },
          stillNeeded: () => _currentRoom?.id == roomId,
        ));

    // votes 채널 — proposal_id 필터를 active 만으로 좁히면 active 가 바뀔 때마다
    // 재구독해야 해서 복잡. 그냥 모든 vote 변경 받고, active 일 때만 refresh.
    _voteChannel = _sb
        .channel('room_votes_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_destination_votes',
          callback: (payload) {
            final newRow = payload.newRecord;
            final oldRow = payload.oldRecord;
            final pid = (newRow['proposal_id'] ??
                oldRow['proposal_id']) as String?;
            if (pid == null) return;
            if (_activeProposal?.id == pid) {
              _refreshProposalVotes(pid);
            }
          },
        )
        .subscribe(_onChannelStatus(
          'room.votes',
          () async {
            try { await _voteChannel?.unsubscribe(); } catch (_) {}
            _voteChannel = null;
            _subscribeRoomProposals();
          },
          stillNeeded: () => _currentRoom?.id == roomId,
        ));
  }

  /// 클라이언트 throttle — 마지막 sendMessage 후 _minSendInterval 안 호출은
  /// 서버 round trip 없이 즉시 거절. 서버측 P0016 rate-limit 도달 전 차단.
  DateTime? _lastSendAt;
  static const Duration _minSendInterval = Duration(milliseconds: 700);

  Future<void> sendMessage(String body, {String kind = 'text'}) async {
    if (_currentRoom == null || myId == null) return;
    final trimmed = body.trim();
    // 글자수 500 + UTF-8 byte 2KB — 한글/이모지가 char_length 안 늘리고
    // byte 만 폭발하는 케이스 차단 (스토리지 / FCM payload 도 보호).
    if (trimmed.isEmpty || trimmed.length > 500) return;
    if (utf8.encode(trimmed).length > 2000) {
      throw Exception('메시지가 너무 길어요.');
    }
    final now = DateTime.now();
    if (_lastSendAt != null &&
        now.difference(_lastSendAt!) < _minSendInterval) {
      throw Exception('메시지를 너무 빨리 보내고 있어요.');
    }
    _lastSendAt = now;
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
    // 에러는 swallow 하지 않고 throw — 호출자가 권한 거부/네트워크 등 구분.
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
  }

  Future<void> sendDm(String threadId, String body,
      {String kind = 'text'}) async {
    if (myId == null) return;
    final t = body.trim();
    if (t.isEmpty || t.length > 2000) return;
    if (utf8.encode(t).length > 8000) {
      throw Exception('메시지가 너무 길어요.');
    }
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

  // ── DM 채널 — service 가 thread 별 자동 재구독 관리 ──
  final Map<String, RealtimeChannel> _dmChannels = {};
  final Map<String, void Function(DmMessage)> _dmListeners = {};

  /// thread 의 새 메시지 realtime 구독. close/error 시 자동 재구독.
  /// 같은 threadId 로 다시 호출하면 listener 만 교체.
  void subscribeDm(String threadId, void Function(DmMessage) onNew) {
    _dmListeners[threadId] = onNew;
    if (_dmChannels.containsKey(threadId)) return;
    _dmChannels[threadId] = _sb
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
              final m = DmMessage.fromJson(payload.newRecord);
              _dmListeners[threadId]?.call(m);
            } catch (e) {
              debugPrint('[Multi] DM parse 실패 thread=$threadId: $e');
            }
          },
        )
        .subscribe(_onChannelStatus(
          'dm.$threadId',
          () async {
            try { await _dmChannels[threadId]?.unsubscribe(); } catch (_) {}
            _dmChannels.remove(threadId);
            // listener 가 아직 살아있으면 재구독.
            final listener = _dmListeners[threadId];
            if (listener != null) {
              subscribeDm(threadId, listener);
            }
          },
          stillNeeded: () => _dmListeners.containsKey(threadId),
        ));
  }

  Future<void> unsubscribeDm(String threadId) async {
    _dmListeners.remove(threadId);
    final ch = _dmChannels.remove(threadId);
    if (ch != null) {
      try { await ch.unsubscribe(); } catch (_) {}
    }
    _resetReconnect('dm.$threadId');
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
    // 좌표는 logActivity 에 영구 저장 안 함 — 이름만.
    logActivity('place_shared', payload: {'name': cleaned});
  }

  /// G13: 채팅 화면 열렸을 때 호출 → 미확인 0 + 서버 last_read_at 갱신.
  /// RPC 실패하면 optimistic update 롤백 (이전 카운트 복원).
  Future<void> markCurrentRoomRead() async {
    if (_currentRoom == null) return;
    final roomId = _currentRoom!.id;
    final prev = _unreadCounts[roomId] ?? 0;
    _unreadCounts[roomId] = 0;
    _notify();
    try {
      await _sb.rpc('mark_room_read', params: {'p_room_id': roomId});
    } catch (e) {
      debugPrint('[Multi] mark_room_read 실패: $e');
      // 롤백 — 단, 그 사이 새 메시지가 도착해서 _unreadCounts 가 변경됐을 수 있음.
      // 0 이면 우리가 설정한 값이 그대로 → 이전 값 복원. 0 이 아니면 그 사이 값
      // 이 더 정확하므로 그대로 둠.
      if (_unreadCounts[roomId] == 0 && prev > 0) {
        _unreadCounts[roomId] = prev;
        _notify();
      }
    }
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
