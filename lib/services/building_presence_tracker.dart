import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/debug_log.dart';
import '../core/map_interface.dart';
import '../models/building_hit.dart';
import 'multiplayer_service.dart';

/// peer (그리고 자기 자신) 의 GPS 위치가 건물 footprint 안에 있는지 추적.
///
/// MultiplayerService 의 위치 변경을 듣고, 새 좌표가 들어올 때마다
/// IMapController.queryBuildingAt 로 hit-test. 결과는 peerId → BuildingHit 캐시.
///
/// 사용처:
/// - peer_pin_renderer: 실내 peer 들의 person 핀 숨김 + 건물별 badge 1개로 통합
/// - map_view: 자기 자신이 실내일 때 칩 오버레이
class BuildingPresenceTracker {
  BuildingPresenceTracker._();
  static final BuildingPresenceTracker instance = BuildingPresenceTracker._();

  IMapController? _map;
  final MultiplayerService _svc = MultiplayerService.instance;

  /// peerId → 마지막으로 hit 된 건물 (null = 실외).
  final Map<String, BuildingHit?> _peerBuilding = {};

  /// buildingId → 안에 있는 peerId 집합.
  final Map<String, Set<String>> _buildingPeers = {};

  /// buildingId → BuildingHit (centroid/name 등 표시용).
  final Map<String, BuildingHit> _buildingMeta = {};

  /// 자기 자신이 들어가있는 건물 (없으면 null).
  BuildingHit? _myBuilding;
  BuildingHit? get myBuilding => _myBuilding;

  /// 마지막으로 query 했던 (uid → '${lat},${lng}') — 좌표 동일하면 재query 스킵.
  final Map<String, String> _lastQueriedKey = {};
  /// max-age — cache key 매칭이어도 30초 지나면 force re-query (in→out 빠른 전환 누락 방지).
  final Map<String, DateTime> _lastQueriedAt = {};
  static const Duration _kMaxCacheAge = Duration(seconds: 30);

  bool _isCacheStale(String key) {
    final at = _lastQueriedAt[key];
    if (at == null) return true;
    return DateTime.now().difference(at) > _kMaxCacheAge;
  }

  bool _attached = false;
  Timer? _myCheckTimer;

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback l) => _listeners.add(l);
  void removeListener(VoidCallback l) => _listeners.remove(l);
  void _notify() {
    for (final l in List.of(_listeners)) {
      try { l(); } catch (_) {}
    }
  }

  BuildingHit? peerBuilding(String userId) => _peerBuilding[userId];

  /// peerId 에 building 이 있으면 true (즉 실내).
  bool isPeerIndoor(String userId) => _peerBuilding[userId] != null;

  /// 현재 한 명 이상 peer 가 들어있는 건물들의 메타.
  List<BuildingHit> get occupiedBuildings {
    final ids = <String>{};
    for (final entry in _buildingPeers.entries) {
      if (entry.value.isNotEmpty) ids.add(entry.key);
    }
    return ids.map((id) => _buildingMeta[id]).whereType<BuildingHit>().toList();
  }

  Set<String> peersInBuilding(String buildingId) =>
      Set.unmodifiable(_buildingPeers[buildingId] ?? const <String>{});

  /// 내 위치가 들어있는 건물에 다른 peer 가 있으면 그 목록 (자기 자신 제외).
  /// 없으면 빈 set.
  Set<String> peersInMyBuilding() {
    final b = _myBuilding;
    if (b == null) return const {};
    return peersInBuilding(b.id);
  }

  void attach(IMapController map) {
    _map = map;
    if (_attached) return;
    _attached = true;
    _svc.addListener(_onSvcChanged);
    // 내 위치는 listener 가 자주 안 부르므로 5초 주기로 체크.
    _myCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkMyPosition();
    });
    // attach 직후엔 타일이 아직 로드 전일 수 있어 1초 후 한 번 더 시도.
    Future.delayed(const Duration(seconds: 1), _checkMyPosition);
    _onSvcChanged();
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    _svc.removeListener(_onSvcChanged);
    _myCheckTimer?.cancel();
    _myCheckTimer = null;
    _peerBuilding.clear();
    _buildingPeers.clear();
    _buildingMeta.clear();
    _myBuilding = null;
    _lastQueriedKey.clear();
    _lastQueriedAt.clear();
    _notify();
  }

  void _onSvcChanged() {
    _checkPeers();
    _checkMyPosition();
  }

  Future<void> _checkPeers() async {
    final map = _map;
    if (map == null) return;
    final peers = _svc.peerLocations;
    final activeIds = peers.keys.toSet();

    // 사라진 peer 정리.
    final stale = _peerBuilding.keys.toSet().difference(activeIds);
    for (final uid in stale) {
      _removePeerFromBuilding(uid);
      _lastQueriedKey.remove(uid);
    }

    var changed = false;
    for (final entry in peers.entries) {
      final uid = entry.key;
      final loc = entry.value;
      // 4자리 (~10m grid) — 같은 grid 안 작은 이동 무시. 같은 key 면 max-age 검사.
      final key = '${loc.lat.toStringAsFixed(4)},${loc.lng.toStringAsFixed(4)}';
      if (_lastQueriedKey[uid] == key && !_isCacheStale(uid)) continue;
      _lastQueriedKey[uid] = key;
      _lastQueriedAt[uid] = DateTime.now();
      final hit = await map.queryBuildingAt(loc.lat, loc.lng);
      final prev = _peerBuilding[uid];
      if ((prev?.id) == hit?.id) continue;
      // building 변경 — 이전 건물에서 제거 + 새 건물에 추가.
      _removePeerFromBuilding(uid);
      if (hit != null) {
        _peerBuilding[uid] = hit;
        _buildingMeta[hit.id] = hit;
        _buildingPeers.putIfAbsent(hit.id, () => <String>{}).add(uid);
      } else {
        _peerBuilding[uid] = null;
      }
      changed = true;
    }
    if (changed) _notify();
  }

  Future<void> _checkMyPosition() async {
    final map = _map;
    if (map == null) return;
    // _svc.lastBroadcasted 는 visibility=ghost 이거나 방/공개 둘다 없을 때 null.
    // → Geolocator.getLastKnownPosition 우선, 그것도 null 이면 lastBroadcasted.
    Position? me;
    try {
      me = await Geolocator.getLastKnownPosition();
    } catch (_) {}
    me ??= _svc.lastBroadcasted;
    if (me == null) {
      DebugLog.log('[Building] self check skip — 위치 없음');
      return;
    }
    final key =
        '${me.latitude.toStringAsFixed(4)},${me.longitude.toStringAsFixed(4)}';
    const selfKey = '__self__';
    if (_lastQueriedKey[selfKey] == key && !_isCacheStale(selfKey)) return;
    _lastQueriedKey[selfKey] = key;
    _lastQueriedAt[selfKey] = DateTime.now();
    final hit = await map.queryBuildingAt(me.latitude, me.longitude);
    DebugLog.log(
        '[Building] self ($key) → ${hit == null ? "outdoor" : "INDOOR ${hit.displayName}"}');
    if ((_myBuilding?.id) == hit?.id) return;
    _myBuilding = hit;
    if (hit != null) _buildingMeta[hit.id] = hit;
    _notify();
  }

  void _removePeerFromBuilding(String uid) {
    final prev = _peerBuilding[uid];
    if (prev == null) return;
    final set = _buildingPeers[prev.id];
    if (set != null) {
      set.remove(uid);
      if (set.isEmpty) {
        _buildingPeers.remove(prev.id);
        // 빈 건물이고 self 도 거기 없으면 meta 도 제거.
        if (_myBuilding?.id != prev.id) {
          _buildingMeta.remove(prev.id);
        }
      }
    }
    _peerBuilding[uid] = null;
  }
}
