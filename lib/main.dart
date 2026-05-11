import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/gen/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'services/deep_link_router.dart';
import 'services/multiplayer_service.dart';
import 'services/notification_service.dart';
import 'services/spotify_service.dart';
import 'theme/app_theme.dart';
import 'widgets/notification_banner_overlay.dart';
import 'widgets/app_snackbar.dart';
import 'views/home_view.dart';
import 'views/onboarding/city_pulse_loading_view.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/onboarding/widgets/onboarding_map_background.dart';
import 'views/whats_new_sheet.dart';

/// 어디서나 라우팅 가능한 글로벌 navigator (push 알림 deep-link 등).
final rootNavigatorKey = GlobalKey<NavigatorState>();

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

  // Settings 초기화 (Mapbox 언어를 사용자 설정 기준으로 잡으려면 먼저 init 필요)
  await SettingsService.init();
  MapboxMapsOptions.setLanguage(_resolveMapboxLanguage());

  // 튜토리얼 진행 상태 초기화 (어떤 페이지를 봤는지 추적)
  await OnboardingService.init();

  // 기기 프로필 감지 (Android: 기기별 최적화)
  await DeviceProfileService.init();

  // Firebase + Supabase 초기화 — 서로 독립이라 병렬로 (iOS 콜드 스타트 단축).
  // authFlowType=implicit 로 두는 이유:
  //  - 우리 OAuth 는 Google/Apple Native SDK 로 별도 처리 (Supabase OAuth 미사용)
  //  - 기본 PKCE 면 supabase_flutter 가 "code" param 있는 모든 deep link 를
  //    auth callback 으로 오인 → Spotify callback (com.seoul.prism://spotify-callback?code=...)
  //    까지 가로채서 "Code verifier could not be found" 에러 발생.
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Supabase.initialize(
      url: ApiKeys.supabaseUrl,
      anonKey: ApiKeys.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    ),
  ]);

  // Crashlytics — debug 빌드는 보내지 않고 release 만 수집. (Firebase init 후)
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

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

  // 즐겨찾기 + 최근 검색 + 최근 길찾기 페어 로드 — 서로 독립이라 병렬로.
  // 직렬 await 였을 때 첫 frame 까지 + ~100ms 추가됐음.
  await Future.wait([
    FavoritesService.instance.load(),
    RecentSearchService.instance.load(),
    VisitHistoryService.instance.load(),
    RecentRouteService.instance.load(),
  ]);

  // user (익명 또는 정식) 가 있으면 realtime 구독 시작.
  if (Supabase.instance.client.auth.currentUser != null) {
    FavoritesService.instance.startRealtimeSync();
    VisitHistoryService.instance.startRealtimeSync();
    RecentRouteService.instance.startRealtimeSync();
    // 멀티플레이 init — UI 가 먼저 뜨도록 fire-and-forget.
    // ChangeNotifier 라 _notify() 시 listening 위젯이 자동 rebuild.
    MultiplayerService.instance.init();
    // 푸시 알림 — 권한/토큰 등록 (백그라운드 진행 OK).
    NotificationService.instance.init();
    // foreground 복귀 시 알림 권한 재검사 — iOS 설정에서 끈 경우 즉시 반영.
    MultiplayerService.instance.addForegroundListener(() {
      NotificationService.instance.recheckPermissionFromForeground();
    });
    // Spotify (선택 기능). client_id 없으면 isConnected=false 로 idle.
    SpotifyService.instance.init();
  }

  // 딥링크 라우터 — room/friend/spotify-callback 모두 잡음.
  // (SpotifyService 의 AppLinks 와 중복 방지를 위해 SpotifyService 는 자체 listener 사용)
  DeepLinkRouter.instance.start();

  runApp(const SeoulPrismApp());
}

final supabase = Supabase.instance.client;

/// Mapbox 라벨에 쓸 BCP-47 코드. 'system' 이면 OS 언어로 폴백 (지원 외엔 'en').
String _resolveMapboxLanguage() {
  final raw = SettingsService.instance.appLanguage;
  final code = raw == 'system'
      ? PlatformDispatcher.instance.locale.languageCode
      : raw;
  return const {'ko', 'en', 'ja', 'zh'}.contains(code) ? code : 'en';
}

/// SettingsService.appLanguage → MaterialApp.locale.
/// 'system' 일 때 null 을 반환해 MaterialApp 이 OS 언어로 폴백하게 함.
Locale? _localeFromAppLanguage(String code) {
  if (code == 'system') return null;
  return Locale(code);
}

class SeoulPrismApp extends StatefulWidget {
  const SeoulPrismApp({super.key});

  /// 외부에서 테마 변경 시 호출
  static void setThemeMode(BuildContext context, String mode) {
    context.findAncestorStateOfType<_SeoulPrismAppState>()?.setThemeMode(mode);
  }

  /// 외부에서 앱 표시 언어 변경 시 호출. code 는 'system'|'ko'|'en'|'ja'|'zh'.
  static void setAppLanguage(BuildContext context, String code) {
    context.findAncestorStateOfType<_SeoulPrismAppState>()?.setAppLanguage(code);
  }

  /// 위젯 트리 전체 재구성 — 테마 변경 후 모든 캐시된 색상/native 위젯 새로 빌드.
  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_SeoulPrismAppState>()?.restartApp();
  }

  @override
  State<SeoulPrismApp> createState() => _SeoulPrismAppState();
}

class _SeoulPrismAppState extends State<SeoulPrismApp> {
  GlobalKey<NavigatorState> get _navigatorKey => rootNavigatorKey;
  Key _appKey = UniqueKey();
  late ThemeMode _themeMode;
  late String _appLanguage;

  @override
  void initState() {
    super.initState();
    _themeMode = _parseThemeMode(SettingsService.instance.themeMode);
    _appLanguage = SettingsService.instance.appLanguage;
    // 글로벌 만남 알림 — 어떤 화면에 있어도 토스트.
    MultiplayerService.instance.addMeetupListener(_onGlobalMeetup);
    // 친구가 새 곡 시작 → 슬라이드 토스트.
    MultiplayerService.instance.addPeerTrackListener(_onPeerTrack);
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
        await MultiplayerService.instance.init();
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeView()),
          (_) => false,
        );
      } else if (event == AuthChangeEvent.signedOut) {
        FavoritesService.instance.stopRealtimeSync();
        VisitHistoryService.instance.stopRealtimeSync();
        RecentRouteService.instance.stopRealtimeSync();
        // Spotify 토큰/폴링 정리 — 다음 사용자가 이 디바이스 쓸 때 leak 방지.
        try {
          await SpotifyService.instance.disconnect();
        } catch (e) {
          debugPrint('[main] Spotify disconnect 실패: $e');
        }
        // FCM 토큰 정리 — 안 하면 다른 사용자가 같은 device 에 로그인했을 때
        // 이전 사용자 알림도 같이 받음 (privacy leak).
        try {
          await NotificationService.instance.unregister();
        } catch (e) {
          debugPrint('[main] FCM unregister 실패: $e');
        }
      }
    });
  }

  void setThemeMode(String mode) {
    setState(() => _themeMode = _parseThemeMode(mode));
    SettingsService.instance.setThemeMode(mode);
  }

  void setAppLanguage(String code) {
    setState(() => _appLanguage = code);
    SettingsService.instance.setAppLanguage(code);
    // 새로 만드는 Mapbox 맵의 라벨 언어 동기화. 이미 떠 있는 맵은 다음 스타일
    // 로드 때 반영 — restart 다이얼로그를 띄우는 이유.
    MapboxMapsOptions.setLanguage(_resolveMapboxLanguage());
  }

  void restartApp() {
    setState(() => _appKey = UniqueKey());
  }

  void _onGlobalMeetup(String userId, bool started) {
    if (!started) return;
    final svc = MultiplayerService.instance;
    final p = svc.peerProfile(userId);
    HapticFeedback.mediumImpact();
    showAppSnackBar('🎉  ${p?.nickname ?? '친구'}와 만났어요!',
        duration: const Duration(seconds: 4));
    // 채팅에도 system 형 'meetup' 메시지로 기록 — 실패해도 사용자 흐름 안 막지만 로깅.
    svc
        .sendMessage('${p?.nickname ?? '친구'}와 만났어요', kind: 'meetup')
        .catchError((e) {
      debugPrint('[main] meetup 메시지 전송 실패: $e');
    });
  }

  void _onPeerTrack(String userId, String track, String artist) {
    final svc = MultiplayerService.instance;
    final p = svc.peerProfile(userId);
    final nick = p?.nickname ?? '친구';
    final artistPart = artist.isEmpty ? '' : ' — $artist';
    showAppSnackBar('🎵  $nick 가 「$track」$artistPart 듣고 있어요',
        duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    MultiplayerService.instance.removeMeetupListener(_onGlobalMeetup);
    MultiplayerService.instance.removePeerTrackListener(_onPeerTrack);
    super.dispose();
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
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      onGenerateTitle: (ctx) => AppL10n.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      // 'system' → null 로 두어 OS 언어 추종. 그 외엔 강제 override.
      locale: _localeFromAppLanguage(_appLanguage),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      // 인앱 알림 배너 — foreground 푸시 메시지 수신 시 상단에 슬라이드.
      builder: (context, child) =>
          NotificationBannerOverlay(child: child ?? const SizedBox.shrink()),
      // App Store 심사 가이드 5.1.1(v) — 계정 기반이 아닌 기능에 로그인 강제 금지.
      // 항상 HomeView 부터 진입 (게스트 허용). 로그인은 사용자가 명시적으로 시작 (즐겨찾기 동기화/프로필 등).
      home: KeyedSubtree(key: _appKey, child: const _RootGate()),
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

enum _GatePhase {
  /// 튜토리얼 통과 사용자 — 로딩 화면 (subway 그리기 + 로고 + 페이드) 진행. HomeView 뒤에서 mount.
  launch,

  /// 튜토리얼 사용자 (신규) — 같은 로딩 화면 진행. OnboardingView 뒤에서 mount 해
  /// Mapbox/overlay 초기화 끝낸 뒤 시퀀스 종료 시 OnboardingView 노출. 첫 화면 + 무거운 init 겹침 회피.
  tutorialLoading,

  /// 튜토리얼 진행 중 — OnboardingView only.
  tutorial,

  /// 튜토리얼 finish 시퀀스 — HomeView 뒤에서 mount, OnboardingView 페이드/그리기.
  finishing,

  /// 시퀀스 완료 — OnboardingView/LaunchLoadingView 제거, HomeView 만.
  done,
}

class _RootGateState extends State<_RootGate> {
  // 신규 사용자 → tutorialLoading (로딩 후 OnboardingView). 통과 사용자 → launch (로딩 후 HomeView).
  // initState 에서 _onboardingView 결과에 따라 결정.
  _GatePhase _phase = _GatePhase.tutorialLoading;
  OnboardingView? _onboardingView;
  // GlobalKey 로 reparent 시 State 보존.
  final _onboardingKey = GlobalKey();
  // HomeView 도 마찬가지 — Stack 자식 → root 로 이동할 때 dispose 안 되도록.
  // 이 키 없으면 finish 시퀀스 후 HomeView 가 재마운트되어 맵이 다시 로딩됨.
  final _homeKey = GlobalKey();

  /// 백그라운드 위젯 (HomeView/OnboardingView) mount 보호 플래그.
  /// CityPulseLoadingView 의 entrance 첫 ~120ms 동안 false 로 두어, 무거운
  /// Mapbox init 이 같은 frame 에서 시작되어 페인터 entrance 가 끊기는 것을
  /// 막는다. 첫 build 후 PostFrameCallback + 짧은 지연으로 true 전환 →
  /// 시퀀스가 끝나는 ~3s 전까지 충분히 mount 완료.
  bool _backgroundMounted = false;

  @override
  void initState() {
    super.initState();
    _onboardingView = OnboardingView.buildIfNeeded(
      key: _onboardingKey,
      background: const OnboardingMapBackground(),
      onFinishStart: _onFinishStart,
      onFinishComplete: _onFinishComplete,
    );
    // 튜토리얼이 필요 없으면 launch 로딩 화면을 거쳐 HomeView 진입.
    _phase = _onboardingView == null
        ? _GatePhase.launch
        : _GatePhase.tutorialLoading;

    // entrance 첫 frame 이 그려진 후 ~120ms 지연 후 백그라운드 mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _backgroundMounted = true);
      });
    });
  }

  void _onLaunchLoadingComplete() {
    setState(() => _phase = _GatePhase.done);
    // 새 버전 첫 실행이면 What's New. HomeView mapbox init 끝난 뒤 띄워야
    // 메인 스레드 충돌로 freeze 안 됨 → 1.5s 지연.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      WhatsNewView.maybeShow(context);
    });
  }

  /// tutorialLoading 시퀀스 끝나면 OnboardingView 만 노출 (LaunchLoadingView 제거).
  void _onTutorialLoadingComplete() {
    setState(() => _phase = _GatePhase.tutorial);
  }

  void _onFinishStart() {
    setState(() => _phase = _GatePhase.finishing);
  }

  void _onFinishComplete() {
    setState(() => _phase = _GatePhase.done);
    // 튜토리얼 → 새 기능 안내 (있으면). HomeView 가 안정화될 때까지 약간 대기.
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      WhatsNewView.maybeShow(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // done — HomeView 단독.
    if (_phase == _GatePhase.done) {
      return HomeView(key: _homeKey);
    }

    // tutorial — OnboardingView 만 보임 (HomeView 미마운트, 자원 절약).
    if (_phase == _GatePhase.tutorial) {
      return _onboardingView!;
    }

    // launch — 튜토리얼 통과 사용자의 첫 진입. HomeView 가 뒤에서 mount, 로딩 화면 위에서 시퀀스.
    // _backgroundMounted=false 인 entrance 첫 ~120ms 동안엔 HomeView 미마운트
    // → 페인터 entrance 가 Mapbox init 과 같은 frame 에 끼지 않게 보호.
    if (_phase == _GatePhase.launch) {
      return Stack(
        children: [
          if (_backgroundMounted) HomeView(key: _homeKey),
          CityPulseLoadingView(onComplete: _onLaunchLoadingComplete),
        ],
      );
    }

    // tutorialLoading — 신규 사용자 진입. OnboardingView 가 뒤에서 mount(맵/오버레이 초기화)
    // 하는 동안 LaunchLoadingView 가 위에서 브랜드 시퀀스 진행. 시퀀스 끝나면 _onTutorialLoadingComplete
    // 가 phase=tutorial 로 전환해 OnboardingView 만 남김. 이렇게 하면 무거운 init 과 첫 화면 표시
    // 가 시간상 분리되어 사용자가 보는 첫 frame 부터 부드러움.
    if (_phase == _GatePhase.tutorialLoading) {
      return Stack(
        children: [
          if (_backgroundMounted) _onboardingView!,
          CityPulseLoadingView(onComplete: _onTutorialLoadingComplete),
        ],
      );
    }

    // finishing — HomeView 가 뒤에서 mount, OnboardingView 가 위에서 finish 시퀀스.
    return Stack(
      children: [
        HomeView(key: _homeKey),
        _onboardingView!,
      ],
    );
  }
}

