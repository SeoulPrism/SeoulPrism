import 'dart:io';
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
  static const _kSelectedLines = 'selected_lines'; // comma-separated or null
  static const _kQualityPreset = 'quality_preset'; // 'high' | 'medium' | 'low'
  static const _kUseSeoulApi = 'use_seoul_api';
  static const _kUseNaverApi = 'use_naver_api';
  static const _kThemeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const _kDebugLogs = 'debug_logs';
  static const _kShowBuses = 'show_buses';
  static const _kShowRiverBus = 'show_river_bus';
  static const _kShowFlights = 'show_flights';

  // ── Getters ──
  bool get showRoutes => _prefs.getBool(_kShowRoutes) ?? true;
  bool get showTrains => _prefs.getBool(_kShowTrains) ?? true;
  bool get showStations => _prefs.getBool(_kShowStations) ?? true;
  String get mode => _prefs.getString(_kMode) ?? 'demo';
  bool get autoLighting => _prefs.getBool(_kAutoLighting) ?? true;
  String get lightPreset => _prefs.getString(_kLightPreset) ?? 'auto';

  String get qualityPreset =>
      _prefs.getString(_kQualityPreset) ?? (Platform.isAndroid ? 'medium' : 'high');
  bool get useSeoulApi => _prefs.getBool(_kUseSeoulApi) ?? true;
  bool get useNaverApi => _prefs.getBool(_kUseNaverApi) ?? true;
  String get themeMode => _prefs.getString(_kThemeMode) ?? 'dark';
  bool get debugLogs => _prefs.getBool(_kDebugLogs) ?? false;
  bool get showBuses => _prefs.getBool(_kShowBuses) ?? true;
  bool get showRiverBus => _prefs.getBool(_kShowRiverBus) ?? true;
  bool get showFlights => _prefs.getBool(_kShowFlights) ?? true;

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
  Future<void> setAutoLighting(bool v) => _prefs.setBool(_kAutoLighting, v);
  Future<void> setLightPreset(String v) => _prefs.setString(_kLightPreset, v);
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

  Future<void> setSelectedLines(Set<String>? lines) async {
    if (lines == null) {
      await _prefs.remove(_kSelectedLines);
    } else {
      await _prefs.setString(_kSelectedLines, lines.join(','));
    }
  }
}
