import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/api_keys.dart';
import 'services/device_profile_service.dart';
import 'services/settings_service.dart';
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

  @override
  State<SeoulPrismApp> createState() => _SeoulPrismAppState();
}

class _SeoulPrismAppState extends State<SeoulPrismApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Seoul Vista',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6E7BFF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: supabase.auth.currentSession != null
          ? const HomeView()
          : const AuthView(),
    );
  }
}
