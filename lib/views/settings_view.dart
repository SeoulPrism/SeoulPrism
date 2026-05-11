import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/ai_languages.dart';
import '../l10n/gen/app_localizations.dart';
import '../main.dart';
import '../services/onboarding_service.dart';
import '../services/settings_service.dart';
import '../services/favorites_service.dart';
import '../services/recent_search_service.dart';
import '../services/visit_history_service.dart';
import '../widgets/adaptive/adaptive.dart';
import '../widgets/app_snackbar.dart';
import 'auth_view.dart';
import 'settings/quality_preset_preview.dart';
import 'whats_new_sheet.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _screenAutoLockOff = false;
  bool _autoRotate = false;
  bool _alwaysMyLocation = true;
  // 영문 코드로 정규화 — 'light' | 'dark'. picker 표시 시 현지화 매핑.
  String _themeModeCode = SettingsService.instance.themeMode;
  String _language = aiLanguageByCode(SettingsService.instance.aiLanguage).label;
  String _appLangCode = SettingsService.instance.appLanguage;
  // 'default' | 'myLocation' | 'recent'. picker 표시 시 현지화 매핑.
  String _mapHomeCode = 'default';

  String _themeLabel(BuildContext ctx, String code) {
    final l = AppL10n.of(ctx);
    return code == 'light' ? l.settingsThemeLight : l.settingsThemeDark;
  }

  String _mapHomeLabel(BuildContext ctx, String code) {
    final l = AppL10n.of(ctx);
    return switch (code) {
      'myLocation' => l.settingsMapHomeMyLocation,
      'recent' => l.settingsMapHomeRecent,
      _ => l.settingsMapHomeDefault,
    };
  }

  String _subwayModeLabel(BuildContext ctx, String code) {
    final l = AppL10n.of(ctx);
    return code == 'live' ? l.settingsSubwayModeLive : l.settingsSubwayModeDemo;
  }

  String _lightLabel(BuildContext ctx, String code) {
    final l = AppL10n.of(ctx);
    return switch (code) {
      'dawn' => l.settingsLightDawn,
      'day' => l.settingsLightDay,
      'dusk' => l.settingsLightDusk,
      'night' => l.settingsLightNight,
      _ => l.settingsLightAuto,
    };
  }

  static const _appLangCodes = ['system', 'ko', 'en', 'ja', 'zh'];

  String _appLangLabel(BuildContext ctx, String code) {
    final l = AppL10n.of(ctx);
    return switch (code) {
      'ko' => l.languageKo,
      'en' => l.languageEn,
      'ja' => l.languageJa,
      'zh' => l.languageZh,
      _ => l.languageSystem,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: _SafeNativeView(
              fallback: Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.85), size: 20),
              child: AdaptiveGlassIconButton(
                icon: Icons.arrow_back_ios_rounded,
                onPressed: () => Navigator.of(context).pop(),
                iconSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          AppL10n.of(context).settingsTitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // 품질 프리셋 — 미리보기 + 인라인 세그먼트 컨트롤이 한 카드 안에 통합.
            // 카드 surface 톤에 맞춰 preview 가 자연스럽게 이어짐.
            AdaptiveSectionCard(
              children: [
                QualityPresetPreview(
                  preset: SettingsService.instance.qualityPreset,
                ),
                QualityPresetSegmented(
                  selected: SettingsService.instance.qualityPreset,
                  onChanged: (key) {
                    SettingsService.instance.setQualityPreset(key);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 1.5: 실시간 시각화 — 차량/노선 표시
            _SectionHeader(label: AppL10n.of(context).settingsSectionRealtime),
            AdaptiveSectionCard(
              children: [
                _SwitchItem(
                  label: AppL10n.of(context).settingsLineSubway,
                  value: SettingsService.instance.showRoutes,
                  onChanged: (v) {
                    SettingsService.instance.setShowRoutes(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsTrainPos,
                  value: SettingsService.instance.showTrains,
                  onChanged: (v) {
                    SettingsService.instance.setShowTrains(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsStations,
                  value: SettingsService.instance.showStations,
                  onChanged: (v) {
                    SettingsService.instance.setShowStations(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsBuses,
                  value: SettingsService.instance.showBuses,
                  onChanged: (v) {
                    SettingsService.instance.setShowBuses(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsRiverBus,
                  value: SettingsService.instance.showRiverBus,
                  onChanged: (v) {
                    SettingsService.instance.setShowRiverBus(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsFlights,
                  value: SettingsService.instance.showFlights,
                  onChanged: (v) {
                    SettingsService.instance.setShowFlights(v);
                    setState(() {});
                  },
                ),
              ],
            ),
            _RestartHint(),
            const SizedBox(height: 16),

            // Section 1.6: 데이터 소스 — 어떤 API 를 쓸 지
            _SectionHeader(label: AppL10n.of(context).settingsSectionDataSource),
            AdaptiveSectionCard(
              children: [
                _TrailingTextItem(
                  label: AppL10n.of(context).settingsSubwayMode,
                  trailing:
                      '${_subwayModeLabel(context, SettingsService.instance.mode)} >',
                  onTap: () {
                    final codes = ['live', 'demo'];
                    final labels =
                        codes.map((c) => _subwayModeLabel(context, c)).toList();
                    _showPicker(
                      title: AppL10n.of(context).settingsSubwayMode,
                      options: labels,
                      selected:
                          _subwayModeLabel(context, SettingsService.instance.mode),
                      onSelected: (v) {
                        final idx = labels.indexOf(v);
                        if (idx < 0) return;
                        SettingsService.instance.setMode(codes[idx]);
                        setState(() {});
                      },
                    );
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsSeoulApi,
                  value: SettingsService.instance.useSeoulApi,
                  onChanged: (v) {
                    SettingsService.instance.setUseSeoulApi(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsNaverApi,
                  value: SettingsService.instance.useNaverApi,
                  onChanged: (v) {
                    SettingsService.instance.setUseNaverApi(v);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 1.8: 라이팅
            _SectionHeader(label: AppL10n.of(context).settingsSectionLighting),
            AdaptiveSectionCard(
              children: [
                _SwitchItem(
                  label: AppL10n.of(context).settingsAutoLighting,
                  value: SettingsService.instance.autoLighting,
                  onChanged: (v) {
                    SettingsService.instance.setAutoLighting(v);
                    setState(() {});
                  },
                ),
                if (!SettingsService.instance.autoLighting) ...[
                  const _ItemDivider(),
                  _TrailingTextItem(
                    label: AppL10n.of(context).settingsLightPreset,
                    trailing: '${_lightLabel(context, SettingsService.instance.lightPreset)} >',
                    onTap: () {
                      final codes = ['dawn', 'day', 'dusk', 'night'];
                      final labels = codes.map((c) => _lightLabel(context, c)).toList();
                      _showPicker(
                        title: AppL10n.of(context).settingsLightPreset,
                        options: labels,
                        selected: _lightLabel(
                            context, SettingsService.instance.lightPreset),
                        onSelected: (v) {
                          final idx = labels.indexOf(v);
                          if (idx < 0) return;
                          SettingsService.instance.setLightPreset(codes[idx]);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Section 2: 데이터 관리
            AdaptiveSectionCard(
              children: [
                _InfoItem(
                    label: AppL10n.of(context).settingsLabelFavorites,
                    value: AppL10n.of(context).settingsCountValue(
                        FavoritesService.instance.favorites.length)),
                const _ItemDivider(),
                _InfoItem(
                    label: AppL10n.of(context).settingsLabelVisits,
                    value: AppL10n.of(context).settingsCountValue(
                        VisitHistoryService.instance.recentVisits.length)),
                const _ItemDivider(),
                _InfoItem(
                    label: AppL10n.of(context).settingsLabelRecentSearches,
                    value: AppL10n.of(context).settingsCountValue(
                        RecentSearchService.instance.items.length)),
              ],
            ),
            const SizedBox(height: 16),

            // Section 3: 일반 설정
            AdaptiveSectionCard(
              children: [
                _TrailingTextItem(
                  label: AppL10n.of(context).settingsAppLanguageTitle,
                  trailing: '${_appLangLabel(context, _appLangCode)} >',
                  onTap: () {
                    final labels = _appLangCodes
                        .map((c) => _appLangLabel(context, c))
                        .toList();
                    _showPicker(
                      title: AppL10n.of(context).settingsAppLanguageTitle,
                      options: labels,
                      selected: _appLangLabel(context, _appLangCode),
                      onSelected: (label) {
                        final idx = labels.indexOf(label);
                        if (idx < 0) return;
                        final picked = _appLangCodes[idx];
                        if (picked == _appLangCode) return;                        setState(() => _appLangCode = picked);
                        SeoulPrismApp.setAppLanguage(context, picked);
                        // iOS/Android 모두 위젯 트리 강제 재마운트 시도.
                        // iOS 는 한 frame placeholder 거쳐 native view 도
                        // dispose 되도록 처리됨 (main.dart restartApp).
                        SeoulPrismApp.restartApp(context);
                      },
                    );
                  },
                ),
                const _ItemDivider(),
                _TrailingTextItem(
                  label: AppL10n.of(context).settingsAiAssistantLanguage,
                  trailing: '$_language >',
                  onTap: () => _showPicker(
                    title: AppL10n.of(context).settingsAiAssistantLanguage,
                    options: kAiLanguages.map((l) => l.label).toList(),
                    selected: _language,
                    onSelected: (v) {
                      if (v == _language) return;
                      final picked = kAiLanguages.firstWhere(
                        (l) => l.label == v,
                        orElse: () => kAiLanguages.first,
                      );
                      setState(() => _language = picked.label);
                      // 다음 세션부터 적용 — 현재 세션은 그대로 유지.
                      SettingsService.instance.setAiLanguage(picked.code);
                    },
                  ),
                ),
                const _ItemDivider(),
                _TrailingTextItem(
                  label: AppL10n.of(context).settingsThemeMode,
                  trailing: '${_themeLabel(context, _themeModeCode)} >',
                  onTap: () {
                    final codes = ['light', 'dark'];
                    final labels =
                        codes.map((c) => _themeLabel(context, c)).toList();
                    _showPicker(
                      title: AppL10n.of(context).settingsThemeMode,
                      options: labels,
                      selected: _themeLabel(context, _themeModeCode),
                      onSelected: (v) {
                        final idx = labels.indexOf(v);
                        if (idx < 0) return;
                        final picked = codes[idx];
                        if (picked == _themeModeCode) return;
                        setState(() => _themeModeCode = picked);
                        SeoulPrismApp.setThemeMode(context, picked);
                        SeoulPrismApp.restartApp(context);
                      },
                    );
                  },
                ),
                const _ItemDivider(),
                _TrailingTextItem(
                  label: AppL10n.of(context).settingsMapHome,
                  trailing: '${_mapHomeLabel(context, _mapHomeCode)} >',
                  onTap: () {
                    final codes = ['default', 'myLocation', 'recent'];
                    final labels =
                        codes.map((c) => _mapHomeLabel(context, c)).toList();
                    _showPicker(
                      title: AppL10n.of(context).settingsMapHome,
                      options: labels,
                      selected: _mapHomeLabel(context, _mapHomeCode),
                      onSelected: (v) {
                        final idx = labels.indexOf(v);
                        if (idx < 0) return;
                        setState(() => _mapHomeCode = codes[idx]);
                      },
                    );
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsKeepScreenOn,
                  value: _screenAutoLockOff,
                  onChanged: (v) {
                    setState(() => _screenAutoLockOff = v);
                    if (v) {
                      SystemChrome.setEnabledSystemUIMode(
                          SystemUiMode.immersiveSticky);
                    }
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsAutoRotate,
                  value: _autoRotate,
                  onChanged: (v) {
                    setState(() => _autoRotate = v);
                    SystemChrome.setPreferredOrientations(
                      v
                          ? [
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]
                          : [DeviceOrientation.portraitUp],
                    );
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsAlwaysMyLocation,
                  value: _alwaysMyLocation,
                  onChanged: (v) => setState(() => _alwaysMyLocation = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 4: 데이터
            AdaptiveSectionCard(
              children: [
                _ChevronItem(
                  label: AppL10n.of(context).settingsClearHistory,
                  isDestructive: true,
                  onTap: () => _confirmDeleteHistory(),
                ),
                const _ItemDivider(),
                _ChevronItem(
                    label: AppL10n.of(context).settingsClearSearchHistory,
                    onTap: () => _confirmClearSearch()),
              ],
            ),
            const SizedBox(height: 16),

            // Section 5: 계정
            // 익명(게스트) 사용자는 비밀번호/로그아웃/탈퇴 의미 없음 → "정식 계정으로 전환" 만 노출.
            Builder(
              builder: (_) {
                final isGuest =
                    supabase.auth.currentUser?.isAnonymous ?? true;
                if (isGuest) {
                  return AdaptiveSectionCard(
                    children: [
                      _ChevronItem(
                        label: AppL10n.of(context).settingsConvertAccount,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthView(),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return AdaptiveSectionCard(
                  children: [
                    _ChevronItem(
                      label: AppL10n.of(context).settingsEditNameItem,
                      onTap: () => _editUsername(),
                    ),
                    const _ItemDivider(),
                    _ChevronItem(
                      label: AppL10n.of(context).settingsChangePassword,
                      onTap: () => _changePassword(),
                    ),
                    const _ItemDivider(),
                    _ChevronItem(
                      label: AppL10n.of(context).settingsLogout,
                      onTap: () => _confirmLogout(),
                    ),
                    const _ItemDivider(),
                    _ChevronItem(
                      label: AppL10n.of(context).settingsDeleteAccount,
                      isDestructive: true,
                      onTap: () => _confirmDeleteAccount(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // 지도 표시 + 데이터 소스 + 라이팅 통합 sub-view 진입.
            // 개발자 섹션 바로 위에 둔 이유: 자주 안 만지는 시각화 옵션이라
            // 메인 탭 흐름(품질 → 데이터 관리 → 일반 → 계정) 을 끊지 않게.
            AdaptiveSectionCard(
              children: [
                _ChevronItem(
                  label: AppL10n.of(context).settingsMapDataLabel,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MapDisplaySettingsView(),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 5.5: 개발자
            _SectionHeader(label: AppL10n.of(context).settingsSectionDeveloper),
            AdaptiveSectionCard(
              children: [
                _SwitchItem(
                  label: AppL10n.of(context).settingsDebugLogs,
                  value: SettingsService.instance.debugLogs,
                  onChanged: (v) {
                    SettingsService.instance.setDebugLogs(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _ChevronItem(
                  label: AppL10n.of(context).settingsResetTutorial,
                  onTap: () => _confirmResetTutorial(),
                ),
                const _ItemDivider(),
                _ChevronItem(
                  label: AppL10n.of(context).settingsReplayWhatsNew,
                  onTap: () async {
                    await OnboardingService.instance.resetWhatsNew();
                    if (!mounted) return;
                    showAppSnackBar(AppL10n.of(context).settingsWhatsNewToast);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 6: 앱 정보
            AdaptiveSectionCard(
              children: [
                _InfoItem(
                    label: AppL10n.of(context).settingsAppVersion,
                    value: 'v$kAppVersion'),
                const _ItemDivider(),
                _ChevronItem(
                  label: AppL10n.of(context).settingsPrivacy,
                  onTap: () => launchUrl(
                    Uri.parse('https://seoulprism.github.io/SeoulPrism_Docs/privacy-policy.html'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const _ItemDivider(),
                _ChevronItem(
                  label: AppL10n.of(context).settingsLicenses,
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Seoul Vista',
                      applicationVersion: '1.0.3',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteHistory() {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.settingsClearHistoryTitle,
      content: l.settingsClearHistoryBody,
      confirmText: l.commonDelete,
      isDestructive: true,
      onConfirm: () async {
        for (final f in List.from(FavoritesService.instance.favorites)) {
          await FavoritesService.instance.remove(f.name);
        }
        await RecentSearchService.instance.clear();
        await VisitHistoryService.instance.clear();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppL10n.of(context).settingsClearedHistoryToast),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF2C2C2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );
  }

  void _confirmClearSearch() {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.settingsClearSearchTitle,
      content: l.settingsClearSearchBody,
      confirmText: l.commonDelete,
      isDestructive: true,
      onConfirm: () async {
        await RecentSearchService.instance.clear();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppL10n.of(context).settingsClearedSearchToast),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF2C2C2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          );
        }
      },
    );
  }

  void _editUsername() {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.settingsEditNameDialogTitle,
      content: l.settingsEditNameDialogBody,
      confirmText: l.settingsEditNameConfirm,
      onConfirm: () async {
        if (!mounted) return;
        final l2 = AppL10n.of(context);
        final controller = TextEditingController(
          text: supabase.auth.currentUser?.userMetadata?['username'] ?? '',
        );
        final name = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l2.settingsNewNameDialogTitle),
            content: TextField(controller: controller, autofocus: true,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l2.commonCancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(l2.commonConfirm)),
            ],
          ),
        );
        if (name != null && name.isNotEmpty) {
          await supabase.auth.updateUser(UserAttributes(data: {'username': name}));
          if (mounted) setState(() {});
        }
      },
    );
  }

  void _changePassword() {
    final l = AppL10n.of(context);
    final email = supabase.auth.currentUser?.email;
    if (email == null) return;
    showAdaptiveConfirmDialog(
      context: context,
      title: l.settingsChangePasswordTitle,
      content: l.settingsChangePasswordBody(email),
      confirmText: l.settingsSendButton,
      onConfirm: () async {
        await supabase.auth.resetPasswordForEmail(email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppL10n.of(context).settingsPasswordResetSent),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF2C2C2E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          );
        }
      },
    );
  }

  void _confirmLogout() {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.settingsLogoutTitle,
      content: l.settingsLogoutBody,
      confirmText: l.settingsLogoutConfirm,
      isDestructive: true,
      onConfirm: () async {
        await supabase.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthView()),
            (route) => false,
          );
        }
      },
    );
  }

  void _confirmDeleteAccount() {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.settingsDeleteAccountTitle,
      content: l.settingsDeleteAccountBody,
      confirmText: l.settingsDeleteAccountConfirm,
      isDestructive: true,
      onConfirm: () async {
        try {
          await supabase.rpc('delete_user');
          await supabase.auth.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthView()),
              (route) => false,
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppL10n.of(context).settingsDeleteError),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFFFF453A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      },
    );
  }

  void _showPicker({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    showAdaptivePicker(
      context: context,
      title: title,
      options: options,
      selected: selected,
      onSelected: onSelected,
    );
  }

  // 품질 프리셋은 QualityPresetSegmented 가 직접 처리 — 매핑 함수 불필요.

  void _confirmResetTutorial() {
    final l = AppL10n.of(context);
    showAdaptiveConfirmDialog(
      context: context,
      title: l.settingsResetTutorialTitle,
      content: l.settingsResetTutorialBody,
      confirmText: l.settingsResetTutorialConfirm,
      onConfirm: () => OnboardingService.instance.reset(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Sub-view: 지도 표시 및 데이터 (settings 메인에서 chevron 으로 진입)
// settings_view.dart 의 helper widget(_SwitchItem 등)을 공유하기 위해 같은 파일에 둠.
// ─────────────────────────────────────────────────────────────────

class MapDisplaySettingsView extends StatefulWidget {
  const MapDisplaySettingsView({super.key});

  @override
  State<MapDisplaySettingsView> createState() => _MapDisplaySettingsViewState();
}

class _MapDisplaySettingsViewState extends State<MapDisplaySettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: _SafeNativeView(
              fallback: Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.85), size: 20),
              child: AdaptiveGlassIconButton(
                icon: Icons.arrow_back_ios_rounded,
                onPressed: () => Navigator.of(context).pop(),
                iconSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          AppL10n.of(context).settingsMapDisplayTitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _SectionHeader(label: AppL10n.of(context).settingsSectionMapDisplay),
            AdaptiveSectionCard(
              children: [
                _SwitchItem(
                  label: AppL10n.of(context).mapDisplay3D,
                  value: SettingsService.instance
                      .getBool('show3DBuildings', defaultValue: true),
                  onChanged: (v) {
                    SettingsService.instance.setBool('show3DBuildings', v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).mapDisplayPois,
                  value: SettingsService.instance
                      .getBool('showPOI', defaultValue: true),
                  onChanged: (v) {
                    SettingsService.instance.setBool('showPOI', v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).mapDisplayWeather,
                  value: SettingsService.instance
                      .getBool('weatherEffect', defaultValue: true),
                  onChanged: (v) {
                    SettingsService.instance.setBool('weatherEffect', v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).mapDisplayLiveSubway,
                  value: SettingsService.instance
                      .getBool('showSubway', defaultValue: true),
                  onChanged: (v) {
                    SettingsService.instance.setBool('showSubway', v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsLineSubway,
                  value: SettingsService.instance.showRoutes,
                  onChanged: (v) {
                    SettingsService.instance.setShowRoutes(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsTrainPos,
                  value: SettingsService.instance.showTrains,
                  onChanged: (v) {
                    SettingsService.instance.setShowTrains(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsStations,
                  value: SettingsService.instance.showStations,
                  onChanged: (v) {
                    SettingsService.instance.setShowStations(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsBuses,
                  value: SettingsService.instance.showBuses,
                  onChanged: (v) {
                    SettingsService.instance.setShowBuses(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsRiverBus,
                  value: SettingsService.instance.showRiverBus,
                  onChanged: (v) {
                    SettingsService.instance.setShowRiverBus(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsFlights,
                  value: SettingsService.instance.showFlights,
                  onChanged: (v) {
                    SettingsService.instance.setShowFlights(v);
                    setState(() {});
                  },
                ),
              ],
            ),
            _RestartHint(),
            const SizedBox(height: 16),
            _SectionHeader(label: AppL10n.of(context).settingsSectionDataSource),
            AdaptiveSectionCard(
              children: [
                _TrailingTextItem(
                  label: AppL10n.of(context).settingsSubwayMode,
                  trailing:
                      '${_subwayModeLabelStatic(context, SettingsService.instance.mode)} >',
                  onTap: () {
                    final codes = ['live', 'demo'];
                    final labels = codes
                        .map((c) => _subwayModeLabelStatic(context, c))
                        .toList();
                    showAdaptivePicker(
                      context: context,
                      title: AppL10n.of(context).settingsSubwayMode,
                      options: labels,
                      selected: _subwayModeLabelStatic(
                          context, SettingsService.instance.mode),
                      onSelected: (v) {
                        final idx = labels.indexOf(v);
                        if (idx < 0) return;
                        SettingsService.instance.setMode(codes[idx]);
                        setState(() {});
                      },
                    );
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsSeoulApi,
                  value: SettingsService.instance.useSeoulApi,
                  onChanged: (v) {
                    SettingsService.instance.setUseSeoulApi(v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: AppL10n.of(context).settingsNaverApi,
                  value: SettingsService.instance.useNaverApi,
                  onChanged: (v) {
                    SettingsService.instance.setUseNaverApi(v);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionHeader(label: AppL10n.of(context).settingsSectionLighting),
            AdaptiveSectionCard(
              children: [
                _SwitchItem(
                  label: AppL10n.of(context).settingsAutoLighting,
                  value: SettingsService.instance.autoLighting,
                  onChanged: (v) {
                    SettingsService.instance.setAutoLighting(v);
                    setState(() {});
                  },
                ),
                if (!SettingsService.instance.autoLighting) ...[
                  const _ItemDivider(),
                  _TrailingTextItem(
                    label: AppL10n.of(context).settingsLightPreset,
                    trailing:
                        '${_lightLabelStatic(context, SettingsService.instance.lightPreset)} >',
                    onTap: () {
                      final codes = ['dawn', 'day', 'dusk', 'night'];
                      final labels = codes
                          .map((c) => _lightLabelStatic(context, c))
                          .toList();
                      showAdaptivePicker(
                        context: context,
                        title: AppL10n.of(context).settingsLightPreset,
                        options: labels,
                        selected: _lightLabelStatic(
                            context, SettingsService.instance.lightPreset),
                        onSelected: (v) {
                          final idx = labels.indexOf(v);
                          if (idx < 0) return;
                          SettingsService.instance.setLightPreset(codes[idx]);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 라이트 프리셋 라벨 매핑.
  static String _lightLabelStatic(BuildContext ctx, String key) {
    final l = AppL10n.of(ctx);
    return switch (key) {
      'dawn' => l.settingsLightDawn,
      'day' => l.settingsLightDay,
      'dusk' => l.settingsLightDusk,
      'night' => l.settingsLightNight,
      _ => l.settingsLightAuto,
    };
  }

  static String _subwayModeLabelStatic(BuildContext ctx, String code) {
    final l = AppL10n.of(ctx);
    return code == 'live' ? l.settingsSubwayModeLive : l.settingsSubwayModeDemo;
  }
}


// ── Section header (above each AdaptiveSectionCard) ──
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

// ── 재시작 후 적용 안내 ──
class _RestartHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Text(
        '일부 변경은 앱 재시작 후 적용됩니다.',
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

// ─── Glass Section Card (replaced by AdaptiveSectionCard from adaptive.dart) ──

// ─── Item Divider ──────────────────────────────────────────

class _ItemDivider extends StatelessWidget {
  const _ItemDivider();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 0.5,
        thickness: 0.5,
        color: Platform.isIOS
            ? Colors.white.withValues(alpha: 0.10)
            : cs.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

// ─── Chevron Item ──────────────────────────────────────────

class _ChevronItem extends StatefulWidget {
  const _ChevronItem({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  State<_ChevronItem> createState() => _ChevronItemState();
}

class _ChevronItemState extends State<_ChevronItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const isM3 = true; // 설정 페이지는 항상 테마 기반

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed
            ? (isM3 ? cs.onSurface.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.08))
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.isDestructive
                      ? cs.error
                      : (isM3 ? cs.onSurface : Colors.white.withValues(alpha: 0.85)),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isM3 ? cs.onSurfaceVariant : Colors.white.withValues(alpha: 0.30),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trailing Text Item ────────────────────────────────────

class _TrailingTextItem extends StatefulWidget {
  const _TrailingTextItem({
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final String label;
  final String trailing;
  final VoidCallback onTap;

  @override
  State<_TrailingTextItem> createState() => _TrailingTextItemState();
}

class _TrailingTextItemState extends State<_TrailingTextItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const isM3 = true; // 설정 페이지는 항상 테마 기반

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed
            ? (isM3 ? cs.onSurface.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.08))
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: isM3 ? cs.onSurface : Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Text(
              widget.trailing,
              style: TextStyle(
                color: cs.primary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Item ─────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const isM3 = true; // 설정 페이지는 항상 테마 기반

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isM3 ? cs.onSurface : Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isM3 ? cs.onSurfaceVariant : Colors.white.withValues(alpha: 0.40),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Switch Item ───────────────────────────────────────────

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const isM3 = true; // 설정 페이지는 항상 테마 기반

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isM3 ? cs.onSurface : Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (isM3)
            Switch(
              value: value,
              onChanged: onChanged,
            )
          else
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: const Color(0xFF3B82F6),
            ),
        ],
      ),
    );
  }
}

// ─── Safe Native View ───────────────────────────────────────

class _SafeNativeView extends StatefulWidget {
  const _SafeNativeView({
    required this.child,
    required this.fallback,
  });

  final Widget child;
  final Widget fallback;

  @override
  State<_SafeNativeView> createState() => _SafeNativeViewState();
}

class _SafeNativeViewState extends State<_SafeNativeView> {
  bool _showNative = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null) {
      _showNative = true;
      return;
    }

    final animation = route.animation;
    if (animation != null) {
      if (animation.isCompleted) {
        if (!_showNative) setState(() => _showNative = true);
      } else {
        if (_showNative) setState(() => _showNative = false);
        animation.addStatusListener(_onStatus);
      }
    } else {
      _showNative = true;
    }

    route.secondaryAnimation?.addStatusListener(_onSecondary);
  }

  void _onStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed) {
      setState(() => _showNative = true);
    } else if (status == AnimationStatus.reverse) {
      setState(() => _showNative = false);
    }
  }

  void _onSecondary(AnimationStatus status) {
    if (!mounted) return;
    final transitioning =
        status == AnimationStatus.forward || status == AnimationStatus.reverse;
    setState(() => _showNative = !transitioning);
  }

  @override
  Widget build(BuildContext context) {
    return _showNative ? widget.child : widget.fallback;
  }
}
