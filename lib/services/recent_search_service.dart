import 'package:shared_preferences/shared_preferences.dart';

/// 최근 검색 기록 서비스 (SharedPreferences)
class RecentSearchService {
  static const _key = 'recent_searches';
  static const _maxItems = 20;
  static RecentSearchService? _instance;
  RecentSearchService._();
  static RecentSearchService get instance {
    _instance ??= RecentSearchService._();
    return _instance!;
  }

  List<String> _items = [];
  List<String> get items => _items;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _items = prefs.getStringList(_key) ?? [];
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _items);
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _items.remove(trimmed); // 중복 제거
    _items.insert(0, trimmed); // 맨 앞에
    if (_items.length > _maxItems) _items = _items.sublist(0, _maxItems);
    await _save();
  }

  Future<void> remove(String query) async {
    _items.remove(query);
    await _save();
  }

  Future<void> clear() async {
    _items.clear();
    await _save();
  }
}
