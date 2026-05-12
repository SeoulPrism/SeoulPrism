import 'dart:io';
import 'dart:ui' show VoidCallback;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/debug_log.dart';

/// 앱 설정 영속화 서비스
/// SharedPreferences를 통해 설정을 저장/로드
class SettingsService {
  static SettingsService? _instance;
  late final SharedPreferences _prefs;

  SettingsService._(this._prefs);

  static Future<SettingsService> init() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = SettingsService._(prefs);
    DebugLog.enabled = prefs.getBool(_kDebugLogs) ?? false;
    // 1회 마이그레이션: 온보딩이 잘못 저장한 selected_lines='1001' 만 있는 경우
    // 사용자가 의도해서 1호선만 본 게 아닐 확률이 높으므로 null (전체) 로 리셋.
    const migKey = '_mig_v1_selected_lines';
    if (!(prefs.getBool(migKey) ?? false)) {
      final cur = prefs.getString(_kSelectedLines);
      if (cur == '1001') {
        await prefs.remove(_kSelectedLines);
      }
      await prefs.setBool(migKey, true);
    }
    return _instance!;
  }

  static SettingsService get instance => _instance!;

  // 범용 getter/setter
  bool getBool(String key, {bool defaultValue = false}) => _prefs.getBool(key) ?? defaultValue;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  String getString(String key, {String defaultValue = ''}) => _prefs.getString(key) ?? defaultValue;
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  // ── Keys ──
  static const _kShowRoutes = 'show_routes';
  static const _kShowTrains = 'show_trains';
  static const _kShowStations = 'show_stations';
  static const _kMode = 'subway_mode'; // 'live' | 'demo'
  static const _kAutoLighting = 'auto_lighting';
  static const _kLightPreset = 'light_preset';
  /// 'auto' | 'clear' | 'cloudy' | 'rain' | 'drizzle' | 'snow' | 'fog' | 'thunderstorm'
  /// auto 면 OpenMeteo 실제 날씨 사용. 그 외엔 강제 오버라이드 (지도 fog + 위젯 표시 모두).
  static const _kWeatherOverride = 'weather_override';
  static const _kSelectedLines = 'selected_lines'; // comma-separated or null
  static const _kQualityPreset = 'quality_preset'; // 'high' | 'medium' | 'low'
  static const _kUseSeoulApi = 'use_seoul_api';
  static const _kUseNaverApi = 'use_naver_api';
  static const _kThemeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const _kDebugLogs = 'debug_logs';
  static const _kShowBuses = 'show_buses';
  static const _kShowRiverBus = 'show_river_bus';
  static const _kShowFlights = 'show_flights';
  static const _kAiLanguage = 'ai_language'; // 'ko' | 'en' | 'ja'
  // UI 표시 언어. 'system' = OS 설정 추종, 그 외 'ko'|'en'|'ja'|'zh'.
  // aiLanguage 는 Gemini 응답 언어로 별개 (의도적 분리: 영문 UI + 한국어 AI 같은 조합 허용).
  static const _kAppLanguage = 'app_language';
  // 평상시 숨겨진 개발자 섹션 노출 토글. 설정 화면의 앱 버전 행을 5회 탭하면 켜짐.
  static const _kDeveloperMode = 'developer_mode';

  // ── Getters ──
  bool get showRoutes => _prefs.getBool(_kShowRoutes) ?? true;
  bool get showTrains => _prefs.getBool(_kShowTrains) ?? true;
  bool get showStations => _prefs.getBool(_kShowStations) ?? true;
  String get mode => _prefs.getString(_kMode) ?? 'demo';
  bool get autoLighting => _prefs.getBool(_kAutoLighting) ?? true;
  String get lightPreset => _prefs.getString(_kLightPreset) ?? 'auto';
  String get weatherOverride => _prefs.getString(_kWeatherOverride) ?? 'auto';

  String get qualityPreset =>
      _prefs.getString(_kQualityPreset) ?? (Platform.isAndroid ? 'medium' : 'high');
  bool get useSeoulApi => _prefs.getBool(_kUseSeoulApi) ?? true;
  bool get useNaverApi => _prefs.getBool(_kUseNaverApi) ?? true;
  String get themeMode => _prefs.getString(_kThemeMode) ?? 'dark';
  bool get debugLogs => _prefs.getBool(_kDebugLogs) ?? false;
  bool get showBuses => _prefs.getBool(_kShowBuses) ?? true;
  bool get showRiverBus => _prefs.getBool(_kShowRiverBus) ?? true;
  bool get showFlights => _prefs.getBool(_kShowFlights) ?? true;
  String get aiLanguage => _prefs.getString(_kAiLanguage) ?? 'ko';
  String get appLanguage => _prefs.getString(_kAppLanguage) ?? 'system';
  bool get developerMode => _prefs.getBool(_kDeveloperMode) ?? false;

  Set<String>? get selectedLines {
    final val = _prefs.getString(_kSelectedLines);
    if (val == null || val.isEmpty) return null;
    return val.split(',').toSet();
  }

  // ── Setters ──
  Future<void> setShowRoutes(bool v) => _prefs.setBool(_kShowRoutes, v);
  Future<void> setShowTrains(bool v) => _prefs.setBool(_kShowTrains, v);
  Future<void> setShowStations(bool v) => _prefs.setBool(_kShowStations, v);
  Future<void> setMode(String v) => _prefs.setString(_kMode, v);
  Future<void> setAutoLighting(bool v) async {
    await _prefs.setBool(_kAutoLighting, v);
    _notifyEnvironment();
  }
  Future<void> setLightPreset(String v) async {
    await _prefs.setString(_kLightPreset, v);
    _notifyEnvironment();
  }
  Future<void> setWeatherOverride(String v) async {
    await _prefs.setString(_kWeatherOverride, v);
    _notifyEnvironment();
  }

  // ── 환경(라이팅/날씨) 변경 리스너 ──
  // Settings 화면에서 라이팅/날씨를 바꿔도 살아있는 지도에 즉시 반영하기 위함.
  // SubwayOverlayController 가 등록 → 변경 시 mapController 에 push.
  final List<VoidCallback> _envListeners = [];
  void addEnvironmentListener(VoidCallback cb) => _envListeners.add(cb);
  void removeEnvironmentListener(VoidCallback cb) => _envListeners.remove(cb);
  void _notifyEnvironment() {
    for (final cb in List<VoidCallback>.from(_envListeners)) {
      try {
        cb();
      } catch (e) {
        DebugLog.log('[SettingsService] env listener 실패: $e');
      }
    }
  }
  Future<void> setQualityPreset(String v) => _prefs.setString(_kQualityPreset, v);
  Future<void> setUseSeoulApi(bool v) => _prefs.setBool(_kUseSeoulApi, v);
  Future<void> setUseNaverApi(bool v) => _prefs.setBool(_kUseNaverApi, v);
  Future<void> setThemeMode(String v) => _prefs.setString(_kThemeMode, v);
  Future<void> setDebugLogs(bool v) async {
    await _prefs.setBool(_kDebugLogs, v);
    DebugLog.enabled = v;
  }
  Future<void> setShowBuses(bool v) => _prefs.setBool(_kShowBuses, v);
  Future<void> setShowRiverBus(bool v) => _prefs.setBool(_kShowRiverBus, v);
  Future<void> setShowFlights(bool v) => _prefs.setBool(_kShowFlights, v);
  Future<void> setAiLanguage(String v) => _prefs.setString(_kAiLanguage, v);
  Future<void> setAppLanguage(String v) => _prefs.setString(_kAppLanguage, v);
  Future<void> setDeveloperMode(bool v) => _prefs.setBool(_kDeveloperMode, v);

  Future<void> setSelectedLines(Set<String>? lines) async {
    if (lines == null) {
      await _prefs.remove(_kSelectedLines);
    } else {
      await _prefs.setString(_kSelectedLines, lines.join(','));
    }
  }
}
