import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 즐겨찾기 장소
class FavoritePlace {
  final String name;
  final String address;
  final String category;
  final double lat;
  final double lng;
  final DateTime addedAt;

  FavoritePlace({
    required this.name,
    required this.address,
    required this.category,
    required this.lat,
    required this.lng,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'name': name, 'address': address, 'category': category,
    'lat': lat, 'lng': lng, 'addedAt': addedAt.toIso8601String(),
  };

  factory FavoritePlace.fromJson(Map<String, dynamic> json) => FavoritePlace(
    name: json['name'] ?? '',
    address: json['address'] ?? '',
    category: json['category'] ?? '',
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
    addedAt: DateTime.tryParse(json['addedAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
  );
}

/// 즐겨찾기 서비스 (로컬 캐시 + Supabase 동기화)
class FavoritesService {
  static const _key = 'favorite_places';
  static FavoritesService? _instance;
  FavoritesService._();
  static FavoritesService get instance {
    _instance ??= FavoritesService._();
    return _instance!;
  }

  List<FavoritePlace> _favorites = [];
  List<FavoritePlace> get favorites => _favorites;

  SupabaseClient get _sb => Supabase.instance.client;
  String? get _userId => _sb.auth.currentUser?.id;

  // 변경 알림 — UI 가 등록해 setState 트리거.
  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback l) => _listeners.add(l);
  void removeListener(VoidCallback l) => _listeners.remove(l);
  void _notify() {
    for (final l in List.of(_listeners)) {
      try {
        l();
      } catch (_) {}
    }
  }

  RealtimeChannel? _channel;

  Future<void> load() async {
    // 로컬 캐시 먼저
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _favorites = raw.map((s) => FavoritePlace.fromJson(jsonDecode(s))).toList();

    // Supabase에서 동기화
    if (_userId != null) {
      try {
        final res = await _sb.from('favorites')
            .select()
            .eq('user_id', _userId!)
            .order('created_at', ascending: false);
        _favorites = (res as List).map((r) => FavoritePlace(
          name: r['name'] ?? '',
          address: r['address'] ?? '',
          category: r['category'] ?? '',
          lat: (r['lat'] as num).toDouble(),
          lng: (r['lng'] as num).toDouble(),
          addedAt: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
        )).toList();
        await _saveLocal();
      } catch (e) {
        debugPrint('[Favorites] Supabase 동기화 실패: $e');
      }
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _favorites.map((f) => jsonEncode(f.toJson())).toList());
  }

  bool isFavorite(String name) => _favorites.any((f) => f.name == name);

  Future<void> add(FavoritePlace place) async {
    if (isFavorite(place.name)) return;
    _favorites.insert(0, place);
    await _saveLocal();

    if (_userId != null) {
      try {
        await _sb.from('favorites').upsert({
          'user_id': _userId,
          'name': place.name,
          'address': place.address,
          'category': place.category,
          'lat': place.lat,
          'lng': place.lng,
        });
      } catch (e) {
        debugPrint('[Favorites] Supabase 추가 실패: $e');
      }
    }
  }

  Future<void> remove(String name) async {
    _favorites.removeWhere((f) => f.name == name);
    await _saveLocal();

    if (_userId != null) {
      try {
        await _sb.from('favorites').delete().eq('user_id', _userId!).eq('name', name);
      } catch (e) {
        debugPrint('[Favorites] Supabase 삭제 실패: $e');
      }
    }
  }

  Future<void> toggle(FavoritePlace place) async {
    if (isFavorite(place.name)) {
      await remove(place.name);
    } else {
      await add(place);
    }
  }

  Future<void> clear() async {
    _favorites.clear();
    await _saveLocal();
    if (_userId != null) {
      try {
        await _sb.from('favorites').delete().eq('user_id', _userId!);
      } catch (e) {
        debugPrint('[Favorites] Supabase 전체 삭제 실패: $e');
      }
    }
  }

  /// 다른 디바이스에서 변경 시 자동 동기화. 로그인 후 호출.
  /// RLS SELECT 정책에 의해 본인 row 의 INSERT/UPDATE/DELETE 이벤트만 수신.
  void startRealtimeSync() {
    if (_userId == null) return;
    _channel?.unsubscribe();
    _channel = _sb
        .channel('favorites_${_userId!}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'favorites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId!,
          ),
          callback: (_) async {
            await load();
            _notify();
          },
        )
        .subscribe();
  }

  void stopRealtimeSync() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
