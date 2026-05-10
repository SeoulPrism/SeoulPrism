import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/api_keys.dart';

/// Spotify Web API 통합 (Phase B10).
///
/// 흐름 (PKCE):
///   1. connect() → auth URL 생성 → external 브라우저 launch
///   2. Spotify → com.seoul.prism://spotify-callback?code=... 로 redirect
///   3. AppLinks listener 가 callback 잡아 token 교환 → secure storage 저장
///   4. fetchCurrentlyPlaying() — 주기적 / on-demand
///
/// 사용자 설정 필요:
///   - https://developer.spotify.com 에서 앱 만들고 Client ID 발급
///   - Redirect URI 등록: com.seoul.prism://spotify-callback
///   - Client ID 를 ApiKeys.spotifyClientId 에 주입
class SpotifyService extends ChangeNotifier {
  SpotifyService._();
  static final SpotifyService instance = SpotifyService._();

  static const _kAccessKey = 'spotify_access_token';
  static const _kRefreshKey = 'spotify_refresh_token';
  static const _kExpiresKey = 'spotify_expires_at';
  static const _kVerifierKey = 'spotify_pkce_verifier';

  final _storage = const FlutterSecureStorage();
  // AppLinks listener 는 DeepLinkRouter 에서 통합 관리 → 여기서 직접 init 안 함.

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  /// 현재 재생중 트랙. null = 없거나 비연결.
  SpotifyTrack? _currentTrack;
  SpotifyTrack? get currentTrack => _currentTrack;

  bool get isConnected => _accessToken != null;
  bool get isConfigured => ApiKeys.spotifyClientId.isNotEmpty;

  /// 부팅 시 호출 — 저장된 토큰 로드. AppLinks 는 DeepLinkRouter 가 처리.
  Future<void> init() async {
    try {
      _accessToken = await _storage.read(key: _kAccessKey);
      _refreshToken = await _storage.read(key: _kRefreshKey);
      final exp = await _storage.read(key: _kExpiresKey);
      _expiresAt = exp != null ? DateTime.tryParse(exp) : null;
    } catch (e) {
      debugPrint('[Spotify] storage read 실패: $e');
    }

    if (isConnected) {
      // 만료 임박이면 refresh 시도, 그 다음 currently playing 갱신.
      await _maybeRefresh();
      await fetchCurrentlyPlaying();
    }
  }

  /// DeepLinkRouter 가 com.seoul.prism://spotify-callback 받으면 호출.
  Future<void> handleCallback(Uri uri) => _onIncomingLink(uri);

  Future<void> connect() async {
    if (!isConfigured) {
      throw StateError(
          'SPOTIFY_CLIENT_ID 가 비어있어요. ApiKeys 설정을 확인하세요.');
    }
    final verifier = _generateVerifier();
    final challenge = _challengeForVerifier(verifier);
    await _storage.write(key: _kVerifierKey, value: verifier);

    final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': ApiKeys.spotifyClientId,
      'response_type': 'code',
      'redirect_uri': ApiKeys.spotifyRedirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': challenge,
      'scope': 'user-read-currently-playing user-read-playback-state',
    });
    if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
      throw StateError('브라우저를 열 수 없어요');
    }
  }

  Future<void> disconnect() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _currentTrack = null;
    await _storage.delete(key: _kAccessKey);
    await _storage.delete(key: _kRefreshKey);
    await _storage.delete(key: _kExpiresKey);
    notifyListeners();
  }

  Future<void> _onIncomingLink(Uri uri) async {
    if (uri.scheme != 'com.seoul.prism' || uri.host != 'spotify-callback') {
      return;
    }
    final code = uri.queryParameters['code'];
    final err = uri.queryParameters['error'];
    if (err != null) {
      debugPrint('[Spotify] OAuth 에러: $err');
      return;
    }
    if (code == null) return;

    final verifier = await _storage.read(key: _kVerifierKey);
    if (verifier == null) {
      debugPrint('[Spotify] PKCE verifier 없음 — 무시');
      return;
    }
    try {
      final res = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': ApiKeys.spotifyRedirectUri,
          'client_id': ApiKeys.spotifyClientId,
          'code_verifier': verifier,
        },
      );
      if (res.statusCode != 200) {
        debugPrint('[Spotify] token exchange 실패: ${res.statusCode} ${res.body}');
        return;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      await _saveTokens(
        access: body['access_token'] as String,
        refresh: body['refresh_token'] as String?,
        expiresIn: (body['expires_in'] as num).toInt(),
      );
      await fetchCurrentlyPlaying();
    } catch (e) {
      debugPrint('[Spotify] token exchange 에러: $e');
    }
  }

  Future<void> _saveTokens({
    required String access,
    String? refresh,
    required int expiresIn,
  }) async {
    _accessToken = access;
    if (refresh != null) _refreshToken = refresh;
    _expiresAt =
        DateTime.now().add(Duration(seconds: expiresIn - 30)); // 30s 마진.
    await _storage.write(key: _kAccessKey, value: _accessToken);
    if (_refreshToken != null) {
      await _storage.write(key: _kRefreshKey, value: _refreshToken);
    }
    await _storage.write(
        key: _kExpiresKey, value: _expiresAt!.toIso8601String());
    notifyListeners();
  }

  Future<void> _maybeRefresh() async {
    if (_refreshToken == null) return;
    if (_expiresAt != null && _expiresAt!.isAfter(DateTime.now())) return;
    try {
      final res = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
          'client_id': ApiKeys.spotifyClientId,
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        await _saveTokens(
          access: body['access_token'] as String,
          refresh: body['refresh_token'] as String?,
          expiresIn: (body['expires_in'] as num).toInt(),
        );
      } else {
        debugPrint('[Spotify] refresh 실패: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('[Spotify] refresh 에러: $e');
    }
  }

  Future<SpotifyTrack?> fetchCurrentlyPlaying() async {
    if (!isConnected) return null;
    await _maybeRefresh();
    try {
      final res = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/player/currently-playing'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (res.statusCode == 204 || res.body.isEmpty) {
        _currentTrack = null;
        notifyListeners();
        return null;
      }
      if (res.statusCode != 200) {
        debugPrint('[Spotify] currently-playing ${res.statusCode}');
        return _currentTrack;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final item = body['item'] as Map<String, dynamic>?;
      if (item == null) {
        _currentTrack = null;
      } else {
        final artists = (item['artists'] as List? ?? const [])
            .map((a) => (a as Map)['name'] as String)
            .join(', ');
        final album = item['album'] as Map<String, dynamic>?;
        final imgs = (album?['images'] as List? ?? const []);
        final imgUrl = imgs.isNotEmpty
            ? (imgs.first as Map)['url'] as String?
            : null;
        _currentTrack = SpotifyTrack(
          name: item['name'] as String? ?? '',
          artist: artists,
          albumImageUrl: imgUrl,
          spotifyUri: item['uri'] as String?,
          externalUrl: ((item['external_urls'] as Map?)?['spotify']) as String?,
        );
      }
      notifyListeners();
      return _currentTrack;
    } catch (e) {
      debugPrint('[Spotify] currently-playing 에러: $e');
      return _currentTrack;
    }
  }

  // ── PKCE helpers ──

  String _generateVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final r = Random.secure();
    return List.generate(96, (_) => chars[r.nextInt(chars.length)]).join();
  }

  String _challengeForVerifier(String verifier) {
    final bytes = sha256.convert(utf8.encode(verifier)).bytes;
    return base64Url
        .encode(bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }
}

class SpotifyTrack {
  final String name;
  final String artist;
  final String? albumImageUrl;
  final String? spotifyUri;
  final String? externalUrl;
  const SpotifyTrack({
    required this.name,
    required this.artist,
    this.albumImageUrl,
    this.spotifyUri,
    this.externalUrl,
  });

  /// chat 메시지 body 직렬화 (`name|artist|external_url`).
  String toChatBody() => '$name|$artist|${externalUrl ?? ''}';
}
