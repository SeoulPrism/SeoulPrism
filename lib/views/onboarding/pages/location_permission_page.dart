import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../theme/app_typography.dart';
import '../../../widgets/adaptive/adaptive.dart';

/// 앱 일반 튜토리얼 끝 직전 — 위치 권한 요청.
class LocationPermissionPage extends StatefulWidget {
  static const id = 'location_permission_v1';
  const LocationPermissionPage({super.key});

  @override
  State<LocationPermissionPage> createState() =>
      _LocationPermissionPageState();
}

class _LocationPermissionPageState extends State<LocationPermissionPage> {
  bool _requesting = false;
  bool? _granted; // null = 미결정, true/false = 결과

  Future<void> _request() async {
    setState(() => _requesting = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final ok = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!mounted) return;
      setState(() {
        _granted = ok;
        _requesting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _granted = false;
        _requesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isIos = Platform.isIOS;
    final titleColor = isIos ? Colors.white : cs.onSurface;
    final bodyColor =
        isIos ? Colors.white.withValues(alpha: 0.75) : cs.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C5CFF), Color(0xFF5CC8FF)],
                ),
              ),
              child: Icon(
                _granted == true
                    ? Icons.check_rounded
                    : Icons.location_on_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '위치 권한이 필요해요',
              style: AppTypography.displayLg.copyWith(
                color: titleColor,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '현재 위치를 지도에 표시하고\n주변 정보 / 길찾기를 정확하게 안내하기 위해\n위치 권한이 필요해요.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: bodyColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (_granted == null)
              SizedBox(
                width: double.infinity,
                child: AdaptiveGlassButton(
                  label: _requesting ? '요청 중...' : '위치 권한 허용',
                  onPressed: _requesting ? null : _request,
                ),
              )
            else if (_granted == true)
              Text(
                '✓ 위치 권한 허용됨',
                style: TextStyle(
                  color: isIos
                      ? Colors.white
                      : cs.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Column(
                children: [
                  Text(
                    '거부됨 — 설정에서 직접 허용할 수 있어요',
                    style: TextStyle(
                      color: bodyColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _request,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
