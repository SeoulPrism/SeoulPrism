import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 최근 사용한 길찾기 출발-도착 페어. visit_history 와 비슷한 구조이되, 페어(쌍) 단위로 묶어 관리.
class RecentRoute {
  final String departure;
  final String arrival;
  final double? depLat, depLng;
  final double? arrLat, arrLng;
  final DateTime lastUsedAt;
  final int useCount;

  RecentRoute({
    required this.departure,
    required this.arrival,
    this.depLat,
    this.depLng,
    this.arrLat,
    this.arrLng,
    DateTime? lastUsedAt,
    this.useCount = 1,
  }) : lastUsedAt = lastUsedAt ?? DateTime.now();

  String get pairKey => '$departure⇢$arrival';

  Map<String, dynamic> toJson() => {
    'departure': departure,
    'arrival': arrival,
    'depLat': depLat,
    'depLng': depLng,
    'arrLat': arrLat,
    'arrLng': arrLng,
    'lastUsedAt': lastUsedAt.toIso8601String(),
    'useCount': useCount,
  };

  factory RecentRoute.fromJson(Map<String, dynamic> j) => RecentRoute(
    departure: j['departure'] ?? '',
    arrival: j['arrival'] ?? '',
    depLat: (j['depLat'] as num?)?.toDouble(),
    depLng: (j['depLng'] as num?)?.toDouble(),
    arrLat: (j['arrLat'] as num?)?.toDouble(),
    arrLng: (j['arrLng'] as num?)?.toDouble(),
    lastUsedAt:
        DateTime.tryParse(j['lastUsedAt'] ?? j['last_used_at'] ?? '') ??
        DateTime.now(),
    useCount: (j['useCount'] ?? j['use_count'] ?? 1) as int,
  );
}

/// 최근 길찾기 페어 서비스. 로컬 캐시 + Supabase 동기화 (테이블 `route_history`).
/// Supabase 테이블이 없으면 로컬만 동작 (catch 후 silent).
class RecentRouteService {
  static const _key = 'recent_routes';
  static const _maxItems = 20;
  static RecentRouteService? _instance;
  RecentRouteService._();
  static RecentRouteService get instance {
    _instance ??= RecentRouteService._();
    return _instance!;
  }

  List<RecentRoute> _routes = [];
  List<RecentRoute> get routes => List.unmodifiable(_routes);

  SupabaseClient get _sb => Supabase.instance.client;
  String? get _userId => _sb.auth.currentUser?.id;

  // 테이블 누락/RLS 차단 등으로 한 번 실패하면 같은 세션에선 더 시도하지 않음 (로그 spam 차단).
  // 핫 리로드/재시작 시 초기화되므로 SQL 으로 테이블 생성 후 다시 동작.
  bool _supabaseDisabled = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _routes = raw.map((s) => RecentRoute.fromJson(jsonDecode(s))).toList();

    if (_userId != null && !_supabaseDisabled) {
      try {
        final res = await _sb
            .from('route_history')
            .select()
            .eq('user_id', _userId!)
            .order('last_used_at', ascending: false)
            .limit(_maxItems);
        _routes = (res as List)
            .map(
              (r) => RecentRoute(
                departure: r['departure'] ?? '',
                arrival: r['arrival'] ?? '',
                depLat: (r['dep_lat'] as num?)?.toDouble(),
                depLng: (r['dep_lng'] as num?)?.toDouble(),
                arrLat: (r['arr_lat'] as num?)?.toDouble(),
                arrLng: (r['arr_lng'] as num?)?.toDouble(),
                lastUsedAt:
                    DateTime.tryParse(r['last_used_at'] ?? '') ??
                    DateTime.now(),
                useCount: r['use_count'] ?? 1,
              ),
            )
            .toList();
        await _saveLocal();
      } catch (e) {
        // 테이블 없거나 RLS 막힘 → 로컬만 사용. 다음 호출부터 비활성화.
        _supabaseDisabled = true;
        debugPrint('[RecentRoute] Supabase 비활성화 — 로컬 캐시만 사용: $e');
      }
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _routes.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  /// 길찾기 성공 시 호출. 같은 페어가 있으면 useCount 증가 + 맨 앞으로.
  Future<void> record({
    required String departure,
    required String arrival,
    double? depLat,
    double? depLng,
    double? arrLat,
    double? arrLng,
  }) async {
    if (departure.isEmpty || arrival.isEmpty) return;
    if (departure == arrival) return;
    // '내 위치' 출발은 페어로 의미 없음 (실제 좌표가 매번 다르므로).
    final dep = departure.trim();
    final arr = arrival.trim();

    final existingIdx = _routes.indexWhere(
      (r) => r.departure == dep && r.arrival == arr,
    );
    final newRecord = RecentRoute(
      departure: dep,
      arrival: arr,
      depLat: depLat,
      depLng: depLng,
      arrLat: arrLat,
      arrLng: arrLng,
      useCount: existingIdx >= 0 ? _routes[existingIdx].useCount + 1 : 1,
    );
    if (existingIdx >= 0) _routes.removeAt(existingIdx);
    _routes.insert(0, newRecord);
    if (_routes.length > _maxItems) {
      _routes = _routes.sublist(0, _maxItems);
    }
    await _saveLocal();

    if (_userId != null && !_supabaseDisabled) {
      try {
        await _sb.from('route_history').upsert({
          'user_id': _userId,
          'departure': dep,
          'arrival': arr,
          'dep_lat': depLat,
          'dep_lng': depLng,
          'arr_lat': arrLat,
          'arr_lng': arrLng,
          'use_count': newRecord.useCount,
          'last_used_at': newRecord.lastUsedAt.toIso8601String(),
        }, onConflict: 'user_id,departure,arrival');
      } catch (e) {
        _supabaseDisabled = true;
        debugPrint('[RecentRoute] Supabase 비활성화 — 로컬 캐시만 사용: $e');
      }
    }
  }

  Future<void> remove(String departure, String arrival) async {
    _routes.removeWhere(
      (r) => r.departure == departure && r.arrival == arrival,
    );
    await _saveLocal();
    if (_userId != null && !_supabaseDisabled) {
      try {
        await _sb
            .from('route_history')
            .delete()
            .eq('user_id', _userId!)
            .eq('departure', departure)
            .eq('arrival', arrival);
      } catch (e) {
        _supabaseDisabled = true;
      }
    }
  }

  Future<void> clear() async {
    _routes.clear();
    await _saveLocal();
    if (_userId != null && !_supabaseDisabled) {
      try {
        await _sb.from('route_history').delete().eq('user_id', _userId!);
      } catch (e) {
        _supabaseDisabled = true;
      }
    }
  }
}
