import 'package:flutter/widgets.dart';

import '../../core/map_interface.dart';
import '../../services/multiplayer_service.dart';

/// MultiplayerService 의 peerLocations 변경을 듣고
/// IMapController 에 peer 핀을 sync 하는 비-UI 컨트롤러.
///
/// 사용법:
///   final renderer = PeerPinRenderer(map);
///   renderer.attach();   // 방 입장 후
///   renderer.detach();   // 방 퇴장 시
class PeerPinRenderer {
  final IMapController map;
  final MultiplayerService _svc = MultiplayerService.instance;
  final Set<String> _renderedIds = {};

  PeerPinRenderer(this.map);

  void attach() {
    _svc.addListener(_sync);
    debugPrint('[PinRenderer] attached');
    _sync();
  }

  void detach() {
    _svc.removeListener(_sync);
    map.clearPeerPins();
    _renderedIds.clear();
    debugPrint('[PinRenderer] detached');
  }

  static const _kDestId = '__room_destination__';

  void _sync() {
    final peers = _svc.peerLocations;
    // G9: 60초 이상 stale → 사실상 오프라인 → 제거.
    final visiblePeers = {
      for (final e in peers.entries)
        if (!e.value.isOffline) e.key: e.value
    };
    final newIds = visiblePeers.keys.toSet();
    final room = _svc.currentRoom;
    if (room != null && room.hasDestination) newIds.add(_kDestId);

    if (newIds.length != _renderedIds.length || newIds.isNotEmpty) {
      debugPrint('[PinRenderer] sync — peers=${peers.length} '
          'visible=${visiblePeers.length} rendered=${_renderedIds.length}');
    }

    // 1. 사라진/오프라인 peer + 해제된 destination 제거.
    for (final id in _renderedIds.difference(newIds)) {
      map.removePeerPin(id);
    }

    // 2. 새/갱신 peer upsert.
    for (final entry in visiblePeers.entries) {
      final profile = _svc.peerProfile(entry.key);

      // B9: peer 가 selected_groups 모드면 서버에 visibility 검증 후 캐시.
      // 캐시 미스면 일단 표시하고 백그라운드로 검증 → 다음 sync 때 반영.
      if (profile?.visibility == 'selected_groups') {
        final allowed = _svc.canSeePeerLocation(entry.key);
        // canSeePeerLocation 은 캐시되어 있으면 즉시 (Future.value), 아니면 RPC 호출.
        // dart:async 의 .then 기반으로 처리.
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
      // G9: stale (30~60초) → 회색 톤으로 흐리게.
      if (entry.value.isStale) {
        color = const Color(0xFF999999);
      }
      map.upsertPeerPin(entry.key, entry.value.lat, entry.value.lng,
          color: color, label: profile?.nickname);
    }

    // 3. 방 목적지 pin (peer 들과 별도 색).
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
