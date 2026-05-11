import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../theme/app_typography.dart';
import '../../../widgets/adaptive/adaptive.dart';

/// 온보딩 마지막 직전 — 5개 권한 한 화면에 모아 일괄 동의.
/// 각 권한은 거부해도 앱은 동작 (해당 기능만 제한).
class PermissionsPage extends StatefulWidget {
  static const id = 'permissions_v2';
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

enum _PermState { idle, granted, denied }

class _PermItem {
  final String key;
  final IconData icon;
  final String name;
  final String desc;
  _PermState state;
  _PermItem({
    required this.key,
    required this.icon,
    required this.name,
    required this.desc,
    this.state = _PermState.idle,
  });
}

class _PermissionsPageState extends State<PermissionsPage> {
  bool _requesting = false;

  late final List<_PermItem> _items = [
    _PermItem(
      key: 'location',
      icon: Icons.location_on_rounded,
      name: '위치',
      desc: '지도에 내 위치 표시 + 친구방 실시간 공유',
    ),
    _PermItem(
      key: 'notification',
      icon: Icons.notifications_rounded,
      name: '알림',
      desc: '친구 신청 / 채팅 / 만남 알림',
    ),
    _PermItem(
      key: 'camera',
      icon: Icons.camera_alt_rounded,
      name: '카메라',
      desc: '장소 사진 분석 + 친구 채팅 사진',
    ),
    _PermItem(
      key: 'photos',
      icon: Icons.photo_library_rounded,
      name: '사진',
      desc: '갤러리 사진을 채팅에 공유',
    ),
    _PermItem(
      key: 'microphone',
      icon: Icons.mic_rounded,
      name: '마이크',
      desc: 'AI 음성 대화 + 음성 메시지',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _refreshStates();
  }

  Future<_PermState> _currentStateFor(String key) async {
    switch (key) {
      case 'location':
        final p = await Geolocator.checkPermission();
        if (p == LocationPermission.always ||
            p == LocationPermission.whileInUse) {
          return _PermState.granted;
        }
        if (p == LocationPermission.denied ||
            p == LocationPermission.deniedForever) {
          return _PermState.denied;
        }
        return _PermState.idle;
      case 'notification':
        final s = await FirebaseMessaging.instance.getNotificationSettings();
        if (s.authorizationStatus == AuthorizationStatus.authorized ||
            s.authorizationStatus == AuthorizationStatus.provisional) {
          return _PermState.granted;
        }
        if (s.authorizationStatus == AuthorizationStatus.denied) {
          return _PermState.denied;
        }
        return _PermState.idle;
      case 'camera':
        return _statusToEnum(await Permission.camera.status);
      case 'photos':
        // Android 13+ / iOS 14+ photo picker — photos 또는 photosAddOnly.
        return _statusToEnum(await Permission.photos.status);
      case 'microphone':
        return _statusToEnum(await Permission.microphone.status);
    }
    return _PermState.idle;
  }

  _PermState _statusToEnum(PermissionStatus s) {
    if (s.isGranted || s.isLimited || s.isProvisional) return _PermState.granted;
    if (s.isDenied || s.isPermanentlyDenied || s.isRestricted) {
      return _PermState.denied;
    }
    return _PermState.idle;
  }

  Future<void> _refreshStates() async {
    for (final item in _items) {
      final s = await _currentStateFor(item.key);
      if (!mounted) return;
      setState(() => item.state = s);
    }
  }

  Future<void> _requestOne(_PermItem item) async {
    switch (item.key) {
      case 'location':
        var p = await Geolocator.checkPermission();
        if (p == LocationPermission.denied) {
          p = await Geolocator.requestPermission();
        }
        item.state = (p == LocationPermission.always ||
                p == LocationPermission.whileInUse)
            ? _PermState.granted
            : _PermState.denied;
        break;
      case 'notification':
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true, badge: true, sound: true,
        );
        item.state =
            (settings.authorizationStatus == AuthorizationStatus.authorized ||
                    settings.authorizationStatus ==
                        AuthorizationStatus.provisional)
                ? _PermState.granted
                : _PermState.denied;
        break;
      case 'camera':
        final s = await Permission.camera.request();
        item.state = _statusToEnum(s);
        break;
      case 'photos':
        final s = await Permission.photos.request();
        item.state = _statusToEnum(s);
        break;
      case 'microphone':
        final s = await Permission.microphone.request();
        item.state = _statusToEnum(s);
        break;
    }
  }

  Future<void> _requestAll() async {
    if (_requesting) return;
    setState(() => _requesting = true);

    // 1. 위치 + 알림 — 각자 별도 SDK (Geolocator, FCM). 순차로.
    final loc = _items.firstWhere((i) => i.key == 'location');
    if (loc.state != _PermState.granted) {
      try { await _requestOne(loc); } catch (_) {}
      if (mounted) setState(() {});
    }
    final notif = _items.firstWhere((i) => i.key == 'notification');
    if (notif.state != _PermState.granted) {
      try { await _requestOne(notif); } catch (_) {}
      if (mounted) setState(() {});
    }

    // 2. 카메라 / 사진 / 마이크 — permission_handler batch 로 한 번에.
    //    Android 는 한 dialog 에 묶음, iOS 는 순차 dialog 자동.
    //    개별 호출 시 일부 누락되던 문제 (사용자 보고) 해결.
    final batch = <Permission>[];
    final batchKeys = <String>[];
    for (final key in ['camera', 'photos', 'microphone']) {
      final item = _items.firstWhere((i) => i.key == key);
      if (item.state == _PermState.granted) continue;
      batchKeys.add(key);
      batch.add(switch (key) {
        'camera' => Permission.camera,
        'photos' => Permission.photos,
        'microphone' => Permission.microphone,
        _ => Permission.unknown,
      });
    }
    if (batch.isNotEmpty) {
      try {
        final statuses = await batch.request();
        for (var i = 0; i < batchKeys.length; i++) {
          final k = batchKeys[i];
          final item = _items.firstWhere((it) => it.key == k);
          item.state = _statusToEnum(statuses[batch[i]] ?? PermissionStatus.denied);
        }
      } catch (e) {
        debugPrint('[Perm] batch 요청 실패: $e');
      }
      if (mounted) setState(() {});
    }

    if (!mounted) return;
    setState(() => _requesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;
    final titleColor = isIos ? Colors.white : cs.onSurface;
    final bodyColor =
        isIos ? Colors.white.withValues(alpha: 0.75) : cs.onSurfaceVariant;
    final allGranted = _items.every((i) => i.state == _PermState.granted);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C5CFF), Color(0xFF5CC8FF)],
                ),
              ),
              child: Icon(
                allGranted ? Icons.verified_rounded : Icons.shield_outlined,
                size: 38,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '권한 설정',
              style: AppTypography.displayLg.copyWith(
                color: titleColor,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '아래 권한을 한 번에 설정해두면\n앱을 쓰다가 멈추는 일이 없어요.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: bodyColor,
                height: 1.45,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ..._items.map((it) => _row(it, isIos, cs)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: AdaptiveGlassButton(
                label: _requesting
                    ? '요청 중...'
                    : (allGranted ? '✓ 모두 허용됨' : '한 번에 허용'),
                onPressed: _requesting || allGranted ? null : _requestAll,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '거부해도 앱은 동작해요. 해당 기능만 제한됨.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: bodyColor.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(_PermItem it, bool isIos, ColorScheme cs) {
    final fg = isIos ? Colors.white : cs.onSurface;
    final sub = isIos ? Colors.white.withValues(alpha: 0.6) : cs.onSurfaceVariant;
    final indicator = switch (it.state) {
      _PermState.granted => const Icon(Icons.check_circle_rounded,
          color: Color(0xFF34C759), size: 22),
      _PermState.denied => Icon(Icons.cancel_rounded,
          color: cs.error.withValues(alpha: 0.8), size: 22),
      _PermState.idle => Icon(Icons.radio_button_unchecked_rounded,
          color: sub.withValues(alpha: 0.5), size: 22),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        // 거부된 권한 탭 → system 설정 열기 (재요청은 OS 가 더 이상 dialog 안 띄움).
        onTap: it.state == _PermState.denied
            ? () async {
                await openAppSettings();
                // 설정 다녀온 뒤 상태 갱신.
                Future.delayed(const Duration(milliseconds: 500), _refreshStates);
              }
            : null,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isIos ? Colors.white : cs.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(it.icon,
                  size: 20,
                  color: isIos ? Colors.white : cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(it.name,
                      style: TextStyle(
                          color: fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(
                      it.state == _PermState.denied
                          ? '${it.desc} (탭하면 설정 열기)'
                          : it.desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: sub, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            indicator,
          ],
        ),
      ),
    );
  }
}
