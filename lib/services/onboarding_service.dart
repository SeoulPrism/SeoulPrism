import 'package:shared_preferences/shared_preferences.dart';

/// 튜토리얼 진행 상태 추적.
/// 페이지 ID 단위로 "본 페이지" 를 저장 → 버전 업데이트로 새 페이지가 추가되면
/// 그 페이지만 다시 보여줄 수 있음.
class OnboardingService {
  static OnboardingService? _instance;
  final SharedPreferences _prefs;
  OnboardingService._(this._prefs);

  static Future<OnboardingService> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = OnboardingService._(prefs);
    return _instance!;
  }

  static OnboardingService get instance => _instance!;

  static const _kSeenPages = 'onboarding_seen_pages';
  static const _kLastWhatsNew = 'whats_new_last_seen_version';

  Set<String> get seenPages {
    final list = _prefs.getStringList(_kSeenPages) ?? const [];
    return list.toSet();
  }

  /// [allPageIds] 중 아직 안 본 페이지만 반환. 입력 순서 유지.
  List<String> remainingPages(List<String> allPageIds) {
    final seen = seenPages;
    return allPageIds.where((id) => !seen.contains(id)).toList();
  }

  Future<void> markSeen(Iterable<String> pageIds) async {
    final updated = seenPages..addAll(pageIds);
    await _prefs.setStringList(_kSeenPages, updated.toList());
  }

  /// 디버그/설정에서 "튜토리얼 다시 보기" 용.
  Future<void> reset() => _prefs.remove(_kSeenPages);

  /// What's New 시트 — 마지막으로 본 앱 버전.
  String? get lastSeenWhatsNewVersion => _prefs.getString(_kLastWhatsNew);

  Future<void> markWhatsNewSeen(String version) =>
      _prefs.setString(_kLastWhatsNew, version);

  /// '새 기능 다시 보기' — 다음 실행 시 자동 표시되도록 초기화.
  Future<void> resetWhatsNew() => _prefs.remove(_kLastWhatsNew);
}
