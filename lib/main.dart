import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/api_keys.dart';
import 'services/settings_service.dart';
import 'views/auth_view.dart';
import 'views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mapbox 초기화
  MapboxOptions.setAccessToken(ApiKeys.mapboxAccessToken);
  MapboxMapsOptions.setLanguage('ko');

  // Settings 초기화
  await SettingsService.init();

  // Supabase 초기화
  await Supabase.initialize(
    url: 'https://aqigicmkzthuqwmconqb.supabase.co',
    anonKey: 'sb_publishable_YVBZin5LSf5_YiZNRf_JFA_HeNY52IF',
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
      if (event == AuthChangeEvent.signedIn) {
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
      title: 'Seoul Prism',
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
