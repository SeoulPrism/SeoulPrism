import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart' show rootNavigatorKey;
import '../views/multiplayer/chat_sheet.dart';
import '../views/multiplayer/friends_view.dart';
import '../views/multiplayer/multiplayer_hub_view.dart';
import '../views/multiplayer/room_view.dart';
import 'multiplayer_service.dart';

/// Seoul Live 푸시 / 인앱 알림 통합 서비스.
///
/// 흐름:
/// 1. 앱 부팅 → init() → 권한 요청 → FCM 토큰 획득 → user_devices 등록
/// 2. 트리거 (가입/친구신청/수락/메시지 등) → DB notification_queue insert
/// 3. Edge Function `notify` 가 큐 polling → FCM HTTP v1 → 단말 수신
/// 4. 앱 foreground 면 in-app banner / background 면 시스템 알림
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  /// 인앱 banner 콜백 — 메시지 수신 시 호출 (UI 가 listen).
  final List<void Function(String title, String body, Map<String, String> data)>
      _bannerListeners = [];
  void addBannerListener(
          void Function(String, String, Map<String, String>) l) =>
      _bannerListeners.add(l);
  void removeBannerListener(
          void Function(String, String, Map<String, String>) l) =>
      _bannerListeners.remove(l);

  bool _initialized = false;

  /// 부팅 시 호출 — 권한 요청은 안 하고 로컬 채널 + 메시지 리스너만 셋업.
  /// 권한이 이미 허용된 상태면 토큰 등록까지 자동 진행.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[Notif] init() 시작');

    try {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _local.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (resp) {
          final payload = resp.payload;
          if (payload == null || payload.isEmpty) return;
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map) _routeFromData(Map<String, dynamic>.from(decoded));
          } catch (_) {/* 옛 payload (kind 단일 string) 호환 — 무시 */}
        },
      );
      debugPrint('[Notif] local notif 초기화 OK');
    } catch (e) {
      debugPrint('[Notif] local notif 초기화 실패: $e');
    }

    if (Platform.isAndroid) {
      try {
        const channel = AndroidNotificationChannel(
          'seoul_live_default',
          'Seoul Live',
          description: '친구 신청, 메시지, 만남 등 Seoul Live 알림',
          importance: Importance.high,
        );
        await _local
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      } catch (e) {
        debugPrint('[Notif] Android 채널 생성 실패: $e');
      }
    }

    // FCM 호출은 모두 timeout 으로 감쌈 — iOS 에서 native init 안 되면 hang.
    AuthorizationStatus? status;
    try {
      final settings = await _fcm.getNotificationSettings()
          .timeout(const Duration(seconds: 5));
      status = settings.authorizationStatus;
      debugPrint('[Notif] 권한 상태: $status');
    } on TimeoutException {
      debugPrint('[Notif] ⚠️ getNotificationSettings 5초 timeout — Firebase native init 미작동');
    } catch (e) {
      debugPrint('[Notif] 권한 조회 실패: $e');
    }

    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      await _setupAfterPermission();
    } else if (status == AuthorizationStatus.notDetermined) {
      debugPrint('[Notif] 권한 미결정 — 자동 요청');
      final granted = await requestPermissionAndRegister();
      if (granted) await _setupAfterPermission();
    } else if (status == AuthorizationStatus.denied) {
      debugPrint('[Notif] 권한 거부됨 — 설정 → 알림 에서 허용 필요');
    }

    debugPrint('[Notif] init() 종료');
  }

  /// 권한 받은 후 — foreground options + 메시지 리스너 + 토큰 등록.
  Future<void> _setupAfterPermission() async {
    try {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      ).timeout(const Duration(seconds: 5));
      debugPrint('[Notif] foreground options OK');
    } catch (e) {
      debugPrint('[Notif] foreground options 실패: $e');
    }
    // onMessage / onMessageOpenedApp 은 stream 등록만 하므로 await 없이 즉시 OK.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    debugPrint('[Notif] 메시지 리스너 등록 OK');
    // getInitialMessage 는 hang 가능 — 백그라운드로 보내고 진행.
    _fcm.getInitialMessage()
        .timeout(const Duration(seconds: 5),
            onTimeout: () => null)
        .then((initial) {
      if (initial != null) _onMessageOpenedApp(initial);
    }).catchError((_) {});

    // 가장 중요: 토큰 등록.
    await _registerTokenWithServer();
    _fcm.onTokenRefresh.listen((_) => _registerTokenWithServer());
  }

  /// 명시적 권한 요청 (온보딩 화면에서 호출).
  Future<bool> requestPermissionAndRegister() async {
    NotificationSettings? settings;
    try {
      settings = await _fcm.requestPermission(
        alert: true, badge: true, sound: true,
      ).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      debugPrint('[Notif] requestPermission timeout');
      return false;
    } catch (e) {
      debugPrint('[Notif] requestPermission 실패: $e');
      return false;
    }
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    debugPrint('[Notif] 권한 결과: ${settings.authorizationStatus}');
    if (granted) {
      await _registerTokenWithServer();
      _fcm.onTokenRefresh.listen((_) => _registerTokenWithServer());
    }
    return granted;
  }

  Future<bool> hasPermission() async {
    final s = await _fcm.getNotificationSettings();
    final granted =
        s.authorizationStatus == AuthorizationStatus.authorized ||
            s.authorizationStatus == AuthorizationStatus.provisional;
    _lastKnownPermission = granted;
    return granted;
  }

  /// 최근 hasPermission() 호출의 캐시. 외부 listener 가 빠르게 확인.
  /// recheckPermissionFromForeground() 가 호출될 때마다 갱신.
  bool _lastKnownPermission = false;
  bool get lastKnownPermission => _lastKnownPermission;

  /// foreground 복귀 시 호출 — iOS 설정에서 사용자가 알림 끈 경우 즉시 반영.
  /// permission 이 denied 로 바뀐 게 감지되면 listener 들에게 알림 (UI 가
  /// "푸시 권한 없음" 안내 가능).
  Future<void> recheckPermissionFromForeground() async {
    final before = _lastKnownPermission;
    final after = await hasPermission();
    if (before && !after) {
      debugPrint('[Notif] 권한이 외부에서 해제됨');
      for (final l in List.of(_permissionRevokedListeners)) {
        try { l(); } catch (_) {}
      }
    }
  }

  final List<VoidCallback> _permissionRevokedListeners = [];
  void addPermissionRevokedListener(VoidCallback l) =>
      _permissionRevokedListeners.add(l);
  void removePermissionRevokedListener(VoidCallback l) =>
      _permissionRevokedListeners.remove(l);

  Future<void> _registerTokenWithServer() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      if (Platform.isIOS) {
        try {
          await _fcm.setAutoInitEnabled(true);
        } catch (_) {}
        // APNs 토큰 polling — 30초까지 (iOS 첫 등록 느릴 수 있음).
        String? apns;
        for (var i = 0; i < 30; i++) {
          try {
            apns = await _fcm.getAPNSToken();
          } catch (e) {
            debugPrint('[Notif] getAPNSToken throw (try $i): $e');
          }
          if (apns != null) break;
          if (i % 5 == 4) {
            debugPrint('[Notif] APNs 대기 ${i + 1}s...');
          }
          await Future.delayed(const Duration(seconds: 1));
        }
        if (apns == null) {
          debugPrint('[Notif] ⚠️ iOS APNs 토큰 30초 후에도 null');
          debugPrint('[Notif] 진단:');
          debugPrint('[Notif]   1. Apple Developer 의 App ID(com.seoul.prism) 에 Push Notifications 활성화됐나?');
          debugPrint('[Notif]   2. Provisioning profile 갱신됐나? (Xcode → Signing & Capabilities → Team ⚠️ 클릭)');
          debugPrint('[Notif]   3. Firebase Console 의 iOS 앱 bundle ID 가 com.seoul.prism 맞나?');
          debugPrint('[Notif]   4. 인터넷 연결 정상? (APNs 서버 접근 필요)');
          return;
        }
        debugPrint('[Notif] iOS APNs 토큰 OK (length=${apns.length})');
      }
      final token = await _fcm.getToken().timeout(const Duration(seconds: 10));
      if (token == null) {
        debugPrint('[Notif] FCM 토큰 null');
        return;
      }
      // 같은 user+platform 에 stale token row 가 있을 수 있음 (PK 가
      // (user_id, fcm_token) 이라 token 바뀌면 row 누적). 새 token 등록 전
      // 기존 다른 token 모두 정리 — notify 가 stale 토큰에 발송하지 않도록.
      final platform = Platform.isIOS ? 'ios' : 'android';
      try {
        await Supabase.instance.client
            .from('user_devices')
            .delete()
            .eq('user_id', user.id)
            .eq('platform', platform)
            .neq('fcm_token', token);
      } catch (e) {
        debugPrint('[Notif] stale token cleanup 실패: $e');
      }
      await Supabase.instance.client.from('user_devices').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _lastRegisteredUserId = user.id;
      _lastRegisteredToken = token;
      debugPrint('[Notif] FCM 토큰 등록 완료 (${Platform.isIOS ? 'iOS' : 'Android'})');
    } catch (e, st) {
      debugPrint('[Notif] 토큰 등록 실패: $e\n$st');
    }
  }

  /// 로그아웃 시 토큰 삭제.
  /// 마지막 등록된 (userId, token) — signOut 후에도 정리 가능.
  String? _lastRegisteredUserId;
  String? _lastRegisteredToken;

  /// signOut 시 호출 — 이전 user 의 fcm_token row 삭제.
  /// 안 호출하면 같은 device 에 다른 user 로그인 시 두 사용자 모두 같은
  /// device 에 알림 받음 (privacy leak).
  Future<void> unregister() async {
    final uid =
        _lastRegisteredUserId ?? Supabase.instance.client.auth.currentUser?.id;
    final token = _lastRegisteredToken ?? await _fcm.getToken();
    if (uid == null || token == null) return;
    try {
      await Supabase.instance.client
          .from('user_devices')
          .delete()
          .eq('user_id', uid)
          .eq('fcm_token', token);
      _lastRegisteredUserId = null;
      _lastRegisteredToken = null;
    } catch (e) {
      debugPrint('[Notif] unregister 실패: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage msg) {
    final title = msg.notification?.title ?? msg.data['title'] ?? '';
    final body = msg.notification?.body ?? msg.data['body'] ?? '';
    final data = msg.data.map((k, v) => MapEntry(k, v.toString()));

    // 1. 인앱 banner 리스너 호출 (UI 가 처리).
    for (final l in List.of(_bannerListeners)) {
      try {
        l(title, body, data);
      } catch (_) {}
    }

    // 2. Local notification 도 표시 (iOS 자동, Android 는 수동).
    if (Platform.isAndroid) {
      _local.show(
        msg.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'seoul_live_default',
            'Seoul Live',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        // 탭 시 deep-link 라우팅에 쓰일 전체 data 를 JSON 으로 박아둠.
        payload: jsonEncode(msg.data),
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage msg) {
    debugPrint('[Notif] 알림 탭으로 진입: ${msg.data}');
    _routeFromData(Map<String, dynamic>.from(msg.data));
  }

  /// kind 별 deep navigation. nav 또는 auth 가 아직 없으면 잠시 후 재시도.
  /// 콜드 스타트 시 알림 탭 → auth restore 전 라우팅 → RLS reject → 빈 화면 방지.
  int _routeRetryCount = 0;
  static const int _kMaxRouteRetries = 20; // 약 10초 (500ms × 20)

  void _routeFromData(Map<String, dynamic> data) {
    final kind = (data['kind'] as String?)?.trim();
    if (kind == null || kind.isEmpty) return;
    final nav = rootNavigatorKey.currentState;
    final authReady = Supabase.instance.client.auth.currentUser != null;
    if (nav == null || !authReady) {
      if (_routeRetryCount >= _kMaxRouteRetries) {
        debugPrint('[Notif] deep-link route 포기 (nav=$nav, auth=$authReady)');
        _routeRetryCount = 0;
        return;
      }
      _routeRetryCount++;
      Future.delayed(const Duration(milliseconds: 500),
          () => _routeFromData(data));
      return;
    }
    _routeRetryCount = 0;
    debugPrint('[Notif] deep-link route: $kind data=$data');
    switch (kind) {
      case 'friend_request':
      case 'friend_accept':
      case 'friend_accepted':
        nav.push(MaterialPageRoute(builder: (_) => const FriendsView()));
        return;
      case 'room_message':
      case 'meetup':
      case 'meetup_proposed':
      case 'meetup_accepted':
      case 'meetup_started':
        // 채팅 메시지/만남 — 현재 방이 있으면 RoomView 후 ChatSheet 까지.
        nav.push(MaterialPageRoute(
          builder: (_) => const MultiplayerHubView(),
        ));
        if (MultiplayerService.instance.currentRoom != null) {
          // hub 마운트 후 RoomView 마운트 후 ChatSheet 마운트.
          Future.delayed(const Duration(milliseconds: 250), () {
            final n = rootNavigatorKey.currentState;
            if (n == null) return;
            n.push(MaterialPageRoute(builder: (_) => const RoomView()));
            Future.delayed(const Duration(milliseconds: 250), () {
              final n2 = rootNavigatorKey.currentState;
              if (n2 != null) ChatSheet.show(n2.context);
            });
          });
        }
        return;
      case 'room_kicked':
      case 'welcome':
      default:
        nav.push(
            MaterialPageRoute(builder: (_) => const MultiplayerHubView()));
        return;
    }
  }
}
