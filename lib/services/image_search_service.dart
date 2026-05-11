import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_keys.dart';
import '../core/debug_log.dart';

/// 카카오 이미지 검색 API 래퍼.
/// - 메모리 캐시로 같은 query 재호출 차단.
/// - 동시 in-flight 요청 ≤ [_maxConcurrent] 로 제한 — 탭 빠르게 전환할 때
///   수십 개 HTTP 요청이 쌓이며 UI 가 멈추는 문제 방지.
/// - 한 query 가 동시에 두 번 fetch 되지 않도록 inflight 맵으로 dedup.
class ImageSearchService {
  ImageSearchService._();
  static final ImageSearchService instance = ImageSearchService._();

  /// 동시 fetch 최대 개수.
  static const int _maxConcurrent = 3;

  final Map<String, String?> _cache = {};
  final Map<String, Completer<String?>> _inflight = {};
  final Queue<String> _queue = Queue<String>();
  int _running = 0;

  Future<String?> firstImageFor(String query) {
    final q = query.trim();
    if (q.isEmpty) return Future.value(null);
    if (_cache.containsKey(q)) return Future.value(_cache[q]);

    final existing = _inflight[q];
    if (existing != null) return existing.future;

    final completer = Completer<String?>();
    _inflight[q] = completer;
    _queue.add(q);
    _pump();
    return completer.future;
  }

  /// 캐시/in-flight 모두 비움 — 패널 닫힐 때 호출해 메모리 정리 + 잔존 요청
  /// 무력화. (요청 자체는 timeout 까지 계속 돌아가지만 결과는 무시됨.)
  void cancelAll() {
    _queue.clear();
    for (final c in _inflight.values) {
      if (!c.isCompleted) c.complete(null);
    }
    _inflight.clear();
  }

  void _pump() {
    while (_running < _maxConcurrent && _queue.isNotEmpty) {
      final q = _queue.removeFirst();
      final completer = _inflight[q];
      if (completer == null || completer.isCompleted) continue;
      _running++;
      _fetch(q).then((url) {
        _cache[q] = url;
        if (!completer.isCompleted) completer.complete(url);
        _inflight.remove(q);
        _running--;
        _pump();
      }).catchError((e) {
        _cache[q] = null;
        if (!completer.isCompleted) completer.complete(null);
        _inflight.remove(q);
        _running--;
        _pump();
      });
    }
  }

  Future<String?> _fetch(String query) async {
    final encoded = Uri.encodeComponent(query);
    final endpoint =
        'https://dapi.kakao.com/v2/search/image?query=$encoded&size=1&sort=accuracy';
    try {
      final res = await http.get(
        Uri.parse(endpoint),
        headers: {'Authorization': 'KakaoAK ${ApiKeys.kakaoRestApiKey}'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) {
        DebugLog.log('[ImageSearch] ${res.statusCode} for "$query"');
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final docs = data['documents'] as List? ?? const [];
      if (docs.isEmpty) return null;
      final first = docs.first as Map<String, dynamic>;
      // thumbnail_url 이 작아서 빠름. 원본은 image_url.
      return (first['thumbnail_url'] ?? first['image_url'])?.toString();
    } catch (e) {
      DebugLog.log('[ImageSearch] error: $e');
      return null;
    }
  }
}
