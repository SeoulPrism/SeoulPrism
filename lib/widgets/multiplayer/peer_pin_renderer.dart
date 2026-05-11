import 'package:flutter/widgets.dart';

import '../../core/debug_log.dart';
import '../../core/map_interface.dart';
import '../../services/building_presence_tracker.dart';
import '../../services/multiplayer_service.dart';

/// MultiplayerService 의 peerLocations 변경을 듣고
/// IMapController 에 peer 핀을 sync 하는 비-UI 컨트롤러.
///
/// 추가 책임:
/// - BuildingPresenceTracker 에서 실내로 판정된 peer 의 person 핀은 그리지 않고
///   건물 centroid 위에 단일 badge ('🏢 N명') 1개만 표시.
class PeerPinRenderer {
  final IMapController map;
  final MultiplayerService _svc = MultiplayerService.instance;
  final BuildingPresenceTracker _bldg = BuildingPresenceTracker.instance;
  final Set<String> _renderedIds = {};

  PeerPinRenderer(this.map);

  void attach() {
    _bldg.attach(map);
    _svc.addListener(_sync);
    _bldg.addListener(_sync);
    DebugLog.log('[PinRenderer] attached');
    _sync();
  }

  void detach() {
    _svc.removeListener(_sync);
    _bldg.removeListener(_sync);
    _bldg.detach();
    map.clearPeerPins();
    _renderedIds.clear();
    DebugLog.log('[PinRenderer] detached');
  }

  static const _kDestId = '__room_destination__';

  void _sync() {
    final peers = _svc.peerLocations;
    // G9: 60초 이상 stale → 사실상 오프라인 → 제거.
    final visiblePeers = {
      for (final e in peers.entries)
        if (!e.value.isOffline) e.key: e.value
    };
    // 실내 peer 는 person 핀 대신 건물 badge 로 통합 → 핀 그리지 않음.
    final outdoorPeers = <String, dynamic>{};
    for (final entry in visiblePeers.entries) {
      if (!_bldg.isPeerIndoor(entry.key)) {
        outdoorPeers[entry.key] = entry.value;
      }
    }
    final newIds = outdoorPeers.keys.toSet();
    final room = _svc.currentRoom;
    if (room != null && room.hasDestination) newIds.add(_kDestId);

    if (newIds.length != _renderedIds.length || newIds.isNotEmpty) {
      DebugLog.log('[PinRenderer] sync — peers=${peers.length} '
          'outdoor=${outdoorPeers.length} '
          'rendered=${_renderedIds.length}');
    }

    // 1. 사라진/오프라인 peer + 해제된 destination 제거.
    for (final id in _renderedIds.difference(newIds)) {
      map.removePeerPin(id);
    }

    // 2. 옥외 peer upsert.
    for (final entry in outdoorPeers.entries) {
      final loc = entry.value;
      final profile = _svc.peerProfile(entry.key);

      // B9: peer 가 selected_groups 모드면 서버에 visibility 검증 후 캐시.
      // 캐시 미스면 일단 표시하고 백그라운드로 검증 → 다음 sync 때 반영.
      if (profile?.visibility == 'selected_groups') {
        final allowed = _svc.canSeePeerLocation(entry.key);
        allowed.then((ok) {
          if (!ok && _renderedIds.contains(entry.key)) {
            map.removePeerPin(entry.key);
            _renderedIds.remove(entry.key);
          }
        });
      }

      var color = profile != null
          ? _hexToColor(profile.pinColor)
          : const Color(0xFF7C5CFF);
      if (loc.isStale) {
        color = const Color(0xFF999999);
      }
      map.upsertPeerPin(entry.key, loc.lat, loc.lng,
          color: color, label: profile?.nickname);
    }

    // 3. 방 목적지 pin.
    if (room != null && room.hasDestination) {
      map.upsertPeerPin(
        _kDestId,
        room.destLat!,
        room.destLng!,
        color: const Color(0xFFFF7A00),
        label: '🎯 ${room.destName ?? '목적지'}',
      );
    }

    _renderedIds
      ..clear()
      ..addAll(newIds);
  }

  Color _hexToColor(String hex) {
    final v = int.parse(hex.substring(1), radix: 16);
    return Color(0xFF000000 | v);
  }
}
