import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'core/api_keys.dart';
import 'services/device_profile_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'views/auth_view.dart';
import 'views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 폰에서는 세로 고정, 태블릿은 자유 회전
  final data = WidgetsBinding.instance.platformDispatcher.views.first;
  final shortSide = data.physicalSize.shortestSide / data.devicePixelRatio;
  if (shortSide < 600) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // Mapbox 초기화
  debugPrint('[DEBUG] Mapbox token: ${ApiKeys.mapboxAccessToken}');
  MapboxOptions.setAccessToken(ApiKeys.mapboxAccessToken);
  MapboxMapsOptions.setLanguage('ko');

  // Settings 초기화
  await SettingsService.init();

  // 기기 프로필 감지 (Android: 기기별 최적화)
  await DeviceProfileService.init();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Supabase 초기화
  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );
  runApp(const SeoulPrismApp());
}

final supabase = Supabase.instance.client;

class SeoulPrismApp extends StatefulWidget {
  const SeoulPrismApp({super.key});

  /// 외부에서 테마 변경 시 호출
  static void setThemeMode(BuildContext context, String mode) {
    context.findAncestorStateOfType<_SeoulPrismAppState>()?.setThemeMode(mode);
  }

  @override
  State<SeoulPrismApp> createState() => _SeoulPrismAppState();
}

class _SeoulPrismAppState extends State<SeoulPrismApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = _parseThemeMode(SettingsService.instance.themeMode);
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeView()),
          (_) => false,
        );
      }
    });
  }

  void setThemeMode(String mode) {
    setState(() => _themeMode = _parseThemeMode(mode));
    SettingsService.instance.setThemeMode(mode);
  }

  ThemeMode _parseThemeMode(String mode) => switch (mode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.dark,
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Seoul Vista',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: supabase.auth.currentSession != null
          ? const HomeView()
          : const AuthView(),
    );
  }
}
