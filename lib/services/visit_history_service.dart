import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 방문 기록
class VisitRecord {
  final String name;
  final String category;
  final double lat;
  final double lng;
  final DateTime visitedAt;
  int visitCount;

  VisitRecord({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.visitedAt,
    this.visitCount = 1,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'category': category, 'lat': lat, 'lng': lng,
    'visitedAt': visitedAt.toIso8601String(), 'visitCount': visitCount,
  };

  factory VisitRecord.fromJson(Map<String, dynamic> json) => VisitRecord(
    name: json['name'] ?? '',
    category: json['category'] ?? '',
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0,
    visitedAt: DateTime.tryParse(json['visitedAt'] ?? json['last_visited_at'] ?? '') ?? DateTime.now(),
    visitCount: json['visitCount'] ?? json['visit_count'] ?? 1,
  );
}

/// 방문 기록 서비스 (로컬 캐시 + Supabase 동기화)
class VisitHistoryService {
  static const _key = 'visit_history';
  static const _maxItems = 50;
  static VisitHistoryService? _instance;
  VisitHistoryService._();
  static VisitHistoryService get instance {
    _instance ??= VisitHistoryService._();
    return _instance!;
  }

  List<VisitRecord> _records = [];

  SupabaseClient get _sb => Supabase.instance.client;
  String? get _userId => _sb.auth.currentUser?.id;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _records = raw.map((s) => VisitRecord.fromJson(jsonDecode(s))).toList();

    if (_userId != null) {
      try {
        final res = await _sb.from('visit_history')
            .select()
            .eq('user_id', _userId!)
            .order('last_visited_at', ascending: false);
        _records = (res as List).map((r) => VisitRecord(
          name: r['name'] ?? '',
          category: r['category'] ?? '',
          lat: (r['lat'] as num).toDouble(),
          lng: (r['lng'] as num).toDouble(),
          visitedAt: DateTime.tryParse(r['last_visited_at'] ?? '') ?? DateTime.now(),
          visitCount: r['visit_count'] ?? 1,
        )).toList();
        await _saveLocal();
      } catch (e) {
        debugPrint('[VisitHistory] Supabase 동기화 실패: $e');
      }
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _records.map((r) => jsonEncode(r.toJson())).toList());
  }

  Future<void> recordVisit(String name, String category, double lat, double lng) async {
    final existing = _records.indexWhere((r) => r.name == name);
    if (existing != -1) {
      _records[existing].visitCount++;
      final record = VisitRecord(
        name: name, category: category, lat: lat, lng: lng,
        visitedAt: DateTime.now(), visitCount: _records[existing].visitCount,
      );
      _records.removeAt(existing);
      _records.insert(0, record);
    } else {
      _records.insert(0, VisitRecord(
        name: name, category: category, lat: lat, lng: lng, visitedAt: DateTime.now(),
      ));
    }
    if (_records.length > _maxItems) _records = _records.sublist(0, _maxItems);
    await _saveLocal();

    // Supabase 동기화
    if (_userId != null) {
      try {
        final count = _records.firstWhere((r) => r.name == name).visitCount;
        await _sb.from('visit_history').upsert({
          'user_id': _userId,
          'name': name,
          'category': category,
          'lat': lat,
          'lng': lng,
          'visit_count': count,
          'last_visited_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,name');
      } catch (e) {
        debugPrint('[VisitHistory] Supabase 기록 실패: $e');
      }
    }
  }

  Future<void> clear() async {
    _records.clear();
    await _saveLocal();
    if (_userId != null) {
      try {
        await _sb.from('visit_history').delete().eq('user_id', _userId!);
      } catch (e) {
        debugPrint('[VisitHistory] Supabase 삭제 실패: $e');
      }
    }
  }

  List<VisitRecord> get recentVisits => _records.take(10).toList();

  List<VisitRecord> get frequentVisits {
    final sorted = List<VisitRecord>.from(_records)
      ..sort((a, b) => b.visitCount.compareTo(a.visitCount));
    return sorted.take(10).toList();
  }
}
