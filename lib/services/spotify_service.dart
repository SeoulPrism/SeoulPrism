import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Timer? _pollTimer;

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
      _startPolling();
    }
  }

  /// 30초 주기 곡 폴링. 변경 시 profiles.current_track 자동 sync.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchCurrentlyPlaying();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
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
    _stopPolling();
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _currentTrack = null;
    await _storage.delete(key: _kAccessKey);
    await _storage.delete(key: _kRefreshKey);
    await _storage.delete(key: _kExpiresKey);
    await _syncTrackToProfile(null);
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
      _startPolling();
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

  /// 토큰이 영구적으로 무효 (4xx) — UI 가 "다시 연결" 안내. true 면 isConnected 도 false.
  bool _tokenInvalidated = false;
  bool get tokenInvalidated => _tokenInvalidated;

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
        _tokenInvalidated = false;
      } else {
        debugPrint('[Spotify] refresh 실패: ${res.statusCode}');
        // 4xx — refresh token 무효 (사용자가 Spotify 측에서 권한 회수 / 비번 변경 등).
        // 5xx / 네트워크 일시 오류는 retry 가능하므로 invalidated 처리 X.
        if (res.statusCode >= 400 && res.statusCode < 500) {
          _tokenInvalidated = true;
          // 토큰 클리어 — 다음번 isConnected 가 false.
          _accessToken = null;
          _refreshToken = null;
          _expiresAt = null;
          await _storage.delete(key: _kAccessKey);
          await _storage.delete(key: _kRefreshKey);
          await _storage.delete(key: _kExpiresKey);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[Spotify] refresh 에러: $e');
    }
  }

  /// trackId → AudioFeatures 메모리 캐시 (per-track 1회만 호출). FIFO cap.
  final Map<String, SpotifyAudioFeatures?> _featuresCache = {};
  static const int _kMaxFeaturesCacheSize = 1000;

  void _putFeatureCache(String trackId, SpotifyAudioFeatures? f) {
    if (_featuresCache.length >= _kMaxFeaturesCacheSize) {
      _featuresCache.remove(_featuresCache.keys.first);
    }
    _featuresCache[trackId] = f;
  }

  /// 현재 트랙의 분위기 메트릭. 미연결/실패면 null.
  Future<SpotifyAudioFeatures?> getAudioFeatures(String trackId) async {
    if (!isConnected) return null;
    if (_featuresCache.containsKey(trackId)) return _featuresCache[trackId];
    await _maybeRefresh();
    try {
      final res = await http.get(
        Uri.parse('https://api.spotify.com/v1/audio-features/$trackId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) {
        debugPrint('[Spotify] audio-features ${res.statusCode}');
        _putFeatureCache(trackId, null);
        return null;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final f = SpotifyAudioFeatures(
        valence: (body['valence'] as num? ?? 0.5).toDouble(),
        energy: (body['energy'] as num? ?? 0.5).toDouble(),
        danceability: (body['danceability'] as num? ?? 0.5).toDouble(),
        tempo: (body['tempo'] as num? ?? 100).toDouble(),
      );
      _putFeatureCache(trackId, f);
      return f;
    } catch (e) {
      debugPrint('[Spotify] audio-features 에러: $e');
      _putFeatureCache(trackId, null);
      return null;
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
      // 401 = 토큰 무효 — 즉시 refresh 시도, 그래도 안 되면 invalidated 처리.
      // 안 그러면 30초마다 401 계속 받음.
      if (res.statusCode == 401) {
        debugPrint('[Spotify] currently-playing 401 — token refresh 강제');
        _expiresAt = null; // refresh 강제 트리거.
        await _maybeRefresh();
        if (!isConnected) {
          // refresh 도 4xx 였음 → tokenInvalidated 가 set 됐을 것. 폴링 중단.
          _stopPolling();
        }
        return _currentTrack;
      }
      if (res.statusCode != 200) {
        debugPrint('[Spotify] currently-playing ${res.statusCode}');
        return _currentTrack;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final item = body['item'] as Map<String, dynamic>?;
      // is_playing=false (일시정지) 면 stale 노출 방지 — null 처리.
      final isPlaying = body['is_playing'] as bool? ?? false;
      // name+artist 핑거프린트 — 곡명만 같고 아티스트가 다른 경우(커버/리믹스 등)도 변경으로 본다.
      final prevFp = _trackFingerprint(_currentTrack);
      if (item == null || !isPlaying) {
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
      // 곡이 변했으면 profiles.current_track 동기화 → realtime 으로 친구에게 전파.
      if (prevFp != _trackFingerprint(_currentTrack)) {
        _syncTrackToProfile(_currentTrack);
      }
      notifyListeners();
      return _currentTrack;
    } catch (e) {
      debugPrint('[Spotify] currently-playing 에러: $e');
      return _currentTrack;
    }
  }

  static String? _trackFingerprint(SpotifyTrack? t) =>
      t == null ? null : '${t.name}${t.artist}';

  /// profiles.current_track 에 현재 곡 sync (없으면 null). 친구가 realtime 으로 받음.
  Future<void> _syncTrackToProfile(SpotifyTrack? t) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'current_track': t == null
                ? null
                : {
                    'name': t.name,
                    'artist': t.artist,
                    'album_image_url': t.albumImageUrl,
                    'external_url': t.externalUrl,
                    'updated_at': DateTime.now().toIso8601String(),
                  }
          })
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('[Spotify] profile sync 실패: $e');
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

  /// `spotify:track:abc123` 에서 마지막 segment 만 추출.
  String? get trackId {
    final uri = spotifyUri;
    if (uri == null || !uri.contains(':')) return null;
    return uri.split(':').last;
  }

  /// chat 메시지 body 직렬화 (`name|artist|external_url`).
  String toChatBody() => '$name|$artist|${externalUrl ?? ''}';
}

/// Spotify Audio Features — 곡의 분위기 메트릭.
class SpotifyAudioFeatures {
  /// 0.0 (슬픔/우울) ~ 1.0 (밝음/긍정).
  final double valence;
  /// 0.0 (조용함) ~ 1.0 (격렬함/에너지 ↑).
  final double energy;
  /// 0.0 ~ 1.0 — 댄스 적합성.
  final double danceability;
  /// BPM (대략 60~200).
  final double tempo;
  const SpotifyAudioFeatures({
    required this.valence,
    required this.energy,
    required this.danceability,
    required this.tempo,
  });
}
