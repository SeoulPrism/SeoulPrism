import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// 기기 성능 등급
enum DeviceTier {
  flagship,  // 최신 플래그십 (S24 Ultra, Pixel 8 Pro 등)
  high,      // 상위 기기 (S23, Pixel 7 등)
  mid,       // 중급 (A54, Pixel 6a 등)
  low,       // 저사양
}

/// 기기별 최적화 프로필
class DeviceProfile {
  final String deviceName;
  final DeviceTier tier;
  final int animFps;
  final int naverPollMs;
  final String qualityPreset;

  const DeviceProfile({
    required this.deviceName,
    required this.tier,
    required this.animFps,
    required this.naverPollMs,
    required this.qualityPreset,
  });

  static const flagship = DeviceProfile(
    deviceName: 'Flagship',
    tier: DeviceTier.flagship,
    animFps: 30,
    naverPollMs: 200,
    qualityPreset: 'high',
  );

  static const high = DeviceProfile(
    deviceName: 'High',
    tier: DeviceTier.high,
    animFps: 30,
    naverPollMs: 300,
    qualityPreset: 'high',
  );

  static const mid = DeviceProfile(
    deviceName: 'Mid',
    tier: DeviceTier.mid,
    animFps: 20,
    naverPollMs: 500,
    qualityPreset: 'medium',
  );

  static const low = DeviceProfile(
    deviceName: 'Low',
    tier: DeviceTier.low,
    animFps: 10,
    naverPollMs: 1000,
    qualityPreset: 'low',
  );

  /// iOS 프로필 (Metal 렌더링, 항상 high)
  static const ios = DeviceProfile(
    deviceName: 'iOS',
    tier: DeviceTier.flagship,
    animFps: 60,
    naverPollMs: 100,
    qualityPreset: 'high',
  );
}

class DeviceProfileService {
  static DeviceProfileService? _instance;
  late final DeviceProfile profile;
  late final String rawModel;

  DeviceProfileService._();

  static DeviceProfileService get instance => _instance!;

  static Future<DeviceProfileService> init() async {
    if (_instance != null) return _instance!;
    final svc = DeviceProfileService._();
    await svc._detect();
    _instance = svc;
    return svc;
  }

  Future<void> _detect() async {
    if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      rawModel = info.utsname.machine; // e.g. "iPhone16,1"
      final tier = _matchIosDevice(rawModel);

      debugPrint('[DeviceProfile] iOS $rawModel (${info.systemVersion}) → ${tier.name}');

      switch (tier) {
        case DeviceTier.flagship:
          profile = DeviceProfile(deviceName: rawModel, tier: tier,
            animFps: 60, naverPollMs: 100, qualityPreset: 'high');
        case DeviceTier.high:
          profile = DeviceProfile(deviceName: rawModel, tier: tier,
            animFps: 60, naverPollMs: 150, qualityPreset: 'high');
        case DeviceTier.mid:
          profile = DeviceProfile(deviceName: rawModel, tier: tier,
            animFps: 30, naverPollMs: 300, qualityPreset: 'medium');
        case DeviceTier.low:
          profile = DeviceProfile(deviceName: rawModel, tier: tier,
            animFps: 20, naverPollMs: 500, qualityPreset: 'low');
      }
      return;
    }

    final info = await DeviceInfoPlugin().androidInfo;
    rawModel = '${info.manufacturer} ${info.model}';
    final model = info.model.toUpperCase();
    final brand = info.brand.toUpperCase();
    final sdkInt = info.version.sdkInt;

    debugPrint('[DeviceProfile] $brand $model (SDK $sdkInt, '
        'cores: ${info.supportedAbis.length > 0 ? info.supportedAbis.first : "?"})');

    // 알려진 기기 매칭
    final tier = _matchKnownDevice(brand, model, sdkInt);
    switch (tier) {
      case DeviceTier.flagship:
        profile = DeviceProfile(
          deviceName: rawModel, tier: tier,
          animFps: 30, naverPollMs: 200, qualityPreset: 'high',
        );
      case DeviceTier.high:
        profile = DeviceProfile(
          deviceName: rawModel, tier: tier,
          animFps: 30, naverPollMs: 300, qualityPreset: 'high',
        );
      case DeviceTier.mid:
        profile = DeviceProfile(
          deviceName: rawModel, tier: tier,
          animFps: 20, naverPollMs: 500, qualityPreset: 'medium',
        );
      case DeviceTier.low:
        profile = DeviceProfile(
          deviceName: rawModel, tier: tier,
          animFps: 10, naverPollMs: 1000, qualityPreset: 'low',
        );
    }

    debugPrint('[DeviceProfile] → ${tier.name} (${profile.animFps}fps, '
        'poll:${profile.naverPollMs}ms, preset:${profile.qualityPreset})');
  }

  static DeviceTier _matchKnownDevice(String brand, String model, int sdkInt) {
    // ── Samsung Galaxy S 시리즈 ──
    if (brand == 'SAMSUNG') {
      // S24, S25 계열
      if (model.contains('S92') || model.contains('S93') ||
          model.contains('S928') || model.contains('S926') || model.contains('S921')) {
        return DeviceTier.flagship;
      }
      // S23 계열
      if (model.contains('S91') || model.contains('S918') ||
          model.contains('S916') || model.contains('S911')) {
        return DeviceTier.flagship;
      }
      // S22 계열
      if (model.contains('S90') || model.contains('S908') ||
          model.contains('S906') || model.contains('S901')) {
        return DeviceTier.high;
      }
      // S21 계열
      if (model.contains('G99')) return DeviceTier.high;
      // Z Fold/Flip 시리즈
      if (model.contains('F95') || model.contains('F94') ||
          model.contains('F93') || model.contains('F92') ||
          model.contains('F74') || model.contains('F73') ||
          model.contains('F72') || model.contains('F71')) {
        return DeviceTier.flagship;
      }
      // Galaxy A 시리즈 (중급)
      if (model.contains('A54') || model.contains('A55') ||
          model.contains('A34') || model.contains('A35')) {
        return DeviceTier.mid;
      }
      if (model.contains('A1') || model.contains('A2') || model.contains('A0')) {
        return DeviceTier.low;
      }
    }

    // ── Google Pixel ──
    if (brand == 'GOOGLE') {
      if (model.contains('PIXEL 9') || model.contains('PIXEL 8')) {
        return DeviceTier.flagship;
      }
      if (model.contains('PIXEL 7') || model.contains('PIXEL 6')) {
        return DeviceTier.high;
      }
      if (model.contains('PIXEL')) return DeviceTier.mid;
    }

    // ── OnePlus ──
    if (brand == 'ONEPLUS') {
      if (model.contains('12') || model.contains('11') || model.contains('10')) {
        return DeviceTier.flagship;
      }
      return DeviceTier.high;
    }

    // ── Xiaomi ──
    if (brand == 'XIAOMI' || brand == 'REDMI' || brand == 'POCO') {
      if (model.contains('14') || model.contains('13') || model.contains('12')) {
        return DeviceTier.high;
      }
      return DeviceTier.mid;
    }

    // ── 알 수 없는 기기 → SDK 버전 기반 추정 ──
    if (sdkInt >= 34) return DeviceTier.high;   // Android 14+
    if (sdkInt >= 31) return DeviceTier.mid;    // Android 12+
    return DeviceTier.low;
  }

  /// iOS 기기 매칭 (utsname.machine 기준)
  /// iPhone17,x = iPhone 16 시리즈 (2024)
  /// iPhone16,x = iPhone 15 시리즈 (2023)
  /// iPhone15,x = iPhone 14 시리즈 (2022)
  /// iPhone14,x = iPhone 13 시리즈 (2021)
  /// iPhone13,x = iPhone 12 시리즈 (2020)
  static DeviceTier _matchIosDevice(String machine) {
    final m = machine.toUpperCase();

    // iPhone 번호 추출 (e.g. "IPHONE17,3" → 17)
    final match = RegExp(r'IPHONE(\d+)').firstMatch(m);
    if (match != null) {
      final gen = int.tryParse(match.group(1)!) ?? 0;
      if (gen >= 17) return DeviceTier.flagship;  // iPhone 16+
      if (gen >= 15) return DeviceTier.high;      // iPhone 14, 15
      if (gen >= 13) return DeviceTier.mid;       // iPhone 12, 13
      return DeviceTier.low;                      // iPhone 11 이하
    }

    // iPad
    if (m.contains('IPAD')) {
      final ipadMatch = RegExp(r'IPAD(\d+)').firstMatch(m);
      if (ipadMatch != null) {
        final gen = int.tryParse(ipadMatch.group(1)!) ?? 0;
        if (gen >= 14) return DeviceTier.flagship; // M1+ iPad
        if (gen >= 11) return DeviceTier.high;
        return DeviceTier.mid;
      }
    }

    // 시뮬레이터 등
    return DeviceTier.high;
  }
}
