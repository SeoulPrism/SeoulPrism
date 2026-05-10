import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      await _local.initialize(initSettings);
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
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

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
      await Supabase.instance.client.from('user_devices').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[Notif] FCM 토큰 등록 완료 (${Platform.isIOS ? 'iOS' : 'Android'})');
    } catch (e, st) {
      debugPrint('[Notif] 토큰 등록 실패: $e\n$st');
    }
  }

  /// 로그아웃 시 토큰 삭제.
  Future<void> unregister() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await Supabase.instance.client
          .from('user_devices')
          .delete()
          .eq('user_id', user.id)
          .eq('fcm_token', token);
    } catch (_) {}
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
        payload: msg.data['kind'] as String?,
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage msg) {
    debugPrint('[Notif] 알림 탭으로 진입: ${msg.data}');
    // TODO: kind 별 deep navigation (room_message → 룸 화면, friend_request → 친구 화면 등)
  }
}
