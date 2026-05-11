import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // 룸 코드(6자) / 친구 코드(8자) — 영숫자 화이트리스트. unicode homoglyph 차단.
  static final RegExp _roomCodeRe = RegExp(r'^[A-Z0-9]{4,8}$');
  static final RegExp _friendCodeRe = RegExp(r'^[A-Z0-9]{4,12}$');

  void _handle(Uri uri) {
    if (uri.scheme != 'com.seoul.prism') return;
    debugPrint('[DeepLink] $uri');
    switch (uri.host) {
      case 'spotify-callback':
        SpotifyService.instance.handleCallback(uri);
        return;
      case 'room':
        final raw = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first.toUpperCase()
            : null;
        if (raw != null && _roomCodeRe.hasMatch(raw)) {
          _enterRoom(raw);
        } else {
          debugPrint('[DeepLink] 잘못된 룸 코드 — 무시: $raw');
        }
        return;
      case 'friend':
        final raw = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first.toUpperCase()
            : null;
        if (raw != null && _friendCodeRe.hasMatch(raw)) {
          _showFriendCode(raw);
        } else {
          debugPrint('[DeepLink] 잘못된 친구 코드 — 무시: $raw');
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
    // 익명 사용자는 룸 입장 불가 — 명시적 안내.
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      showAppSnackBar('정식 로그인 후 방에 입장할 수 있어요');
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
