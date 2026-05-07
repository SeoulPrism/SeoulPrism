import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'core/api_keys.dart';
import 'services/device_profile_service.dart';
import 'services/onboarding_service.dart';
import 'services/settings_service.dart';
import 'services/favorites_service.dart';
import 'services/recent_search_service.dart';
import 'services/recent_route_service.dart';
import 'services/visit_history_service.dart';
import 'theme/app_theme.dart';
import 'views/home_view.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/onboarding/widgets/onboarding_map_background.dart';

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

  // 튜토리얼 진행 상태 초기화 (어떤 페이지를 봤는지 추적)
  await OnboardingService.init();

  // 기기 프로필 감지 (Android: 기기별 최적화)
  await DeviceProfileService.init();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Supabase 초기화
  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );

  // 게스트 모드: 사용자 입력 없이 자동 익명 로그인 → user_id 확보.
  // Apple 심사 5.1.1(v) 대응 (계정 기반 아닌 기능에 등록 강제 금지) +
  // 즐겨찾기/방문/길찾기 페어 동기화 유지. 정식 로그인 시 linkIdentity 로 전환.
  if (Supabase.instance.client.auth.currentUser == null) {
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } catch (e) {
      // 네트워크 또는 익명 sign-in 비활성 시 → 로컬만 사용 (앱은 정상 동작).
      debugPrint('[Auth] 익명 로그인 실패: $e');
    }
  }

  // 즐겨찾기 + 최근 검색 + 최근 길찾기 페어 로드
  await FavoritesService.instance.load();
  await RecentSearchService.instance.load();
  await VisitHistoryService.instance.load();
  await RecentRouteService.instance.load();

  // user (익명 또는 정식) 가 있으면 realtime 구독 시작.
  if (Supabase.instance.client.auth.currentUser != null) {
    FavoritesService.instance.startRealtimeSync();
    VisitHistoryService.instance.startRealtimeSync();
    RecentRouteService.instance.startRealtimeSync();
  }

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
    supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        // 새 계정으로 로그인 시 다시 load + realtime 구독.
        await FavoritesService.instance.load();
        await VisitHistoryService.instance.load();
        await RecentRouteService.instance.load();
        FavoritesService.instance.startRealtimeSync();
        VisitHistoryService.instance.startRealtimeSync();
        RecentRouteService.instance.startRealtimeSync();
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeView()),
          (_) => false,
        );
      } else if (event == AuthChangeEvent.signedOut) {
        FavoritesService.instance.stopRealtimeSync();
        VisitHistoryService.instance.stopRealtimeSync();
        RecentRouteService.instance.stopRealtimeSync();
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
      // App Store 심사 가이드 5.1.1(v) — 계정 기반이 아닌 기능에 로그인 강제 금지.
      // 항상 HomeView 부터 진입 (게스트 허용). 로그인은 사용자가 명시적으로 시작 (즐겨찾기 동기화/프로필 등).
      home: const _RootGate(),
    );
  }
}

/// 첫 진입 / 버전 업데이트 후 새 페이지가 있으면 OnboardingView 를,
/// 그 외에는 HomeView 를 보여줌.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _onboardingDone = false;

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone) return const HomeView();
    final view = OnboardingView.buildIfNeeded(
      background: const OnboardingMapBackground(),
      onComplete: () => setState(() => _onboardingDone = true),
    );
    return view ?? const HomeView();
  }
}
