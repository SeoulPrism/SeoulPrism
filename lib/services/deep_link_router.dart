import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../main.dart' show rootNavigatorKey;
import '../views/multiplayer/friend_code_share.dart';
import '../widgets/app_snackbar.dart';
import 'multiplayer_service.dart';
import 'spotify_service.dart';

/// 단일 글로벌 딥링크 처리. 콜드 스타트 + warm 둘 다 잡음.
/// scheme: com.seoul.prism
///   //spotify-callback?code=...   → Spotify OAuth
///   //room/<CODE>                 → 친구방 입장
///   //friend/<CODE>               → 친구 추가 (코드 시트 자동 채움)
class DeepLinkRouter {
  DeepLinkRouter._();
  static final DeepLinkRouter instance = DeepLinkRouter._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _sub = _appLinks.uriLinkStream.listen(_handle);
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (_) {}
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  void _handle(Uri uri) {
    if (uri.scheme != 'com.seoul.prism') return;
    debugPrint('[DeepLink] $uri');
    switch (uri.host) {
      case 'spotify-callback':
        SpotifyService.instance.handleCallback(uri);
        return;
      case 'room':
        final code = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first.toUpperCase()
            : null;
        if (code != null && code.isNotEmpty) {
          _enterRoom(code);
        }
        return;
      case 'friend':
        final code = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first.toUpperCase()
            : null;
        if (code != null && code.isNotEmpty) {
          _showFriendCode(code);
        }
        return;
    }
  }

  Future<void> _enterRoom(String code) async {
    // nav 가 없으면 다음 프레임 재시도 (콜드 스타트).
    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _enterRoom(code));
      return;
    }
    try {
      await MultiplayerService.instance.joinRoomByCode(code);
      showAppSnackBar('방 입장 — 코드 $code');
    } catch (e) {
      showAppSnackBar('방 입장 실패: $e');
    }
  }

  void _showFriendCode(String code) {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFriendCode(code));
      return;
    }
    final ctx = nav.context;
    FriendCodeShareSheet.show(ctx, prefillCode: code);
  }
}
