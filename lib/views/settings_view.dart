import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../services/settings_service.dart';
import '../services/favorites_service.dart';
import '../services/recent_search_service.dart';
import '../services/visit_history_service.dart';
import '../widgets/adaptive/adaptive.dart';
import 'auth_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _screenAutoLockOff = false;
  bool _autoRotate = false;
  bool _alwaysMyLocation = true;
  String _themeMode = SettingsService.instance.themeMode == 'light' ? '라이트' : '다크';
  String _language = '한국어';
  String _mapHome = '기본';

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
          '설정',
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
            // Section 1: 지도 관련
            AdaptiveSectionCard(
              children: [
                _SwitchItem(
                  label: '3D 건물 표시',
                  value: SettingsService.instance.getBool('show3DBuildings', defaultValue: true),
                  onChanged: (v) {
                    SettingsService.instance.setBool('show3DBuildings', v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: '실시간 지하철 표시',
                  value: SettingsService.instance.getBool('showSubway', defaultValue: true),
                  onChanged: (v) {
                    SettingsService.instance.setBool('showSubway', v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: 'POI 아이콘 표시',
                  value: SettingsService.instance.getBool('showPOI', defaultValue: true),
                  onChanged: (v) {
                    SettingsService.instance.setBool('showPOI', v);
                    setState(() {});
                  },
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: '날씨 효과 (안개/비)',
                  value: SettingsService.instance.getBool('weatherEffect', defaultValue: true),
                  onChanged: (v) {
                    SettingsService.instance.setBool('weatherEffect', v);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 2: 데이터 관리
            AdaptiveSectionCard(
              children: [
                _InfoItem(label: '즐겨찾기', value: '${FavoritesService.instance.favorites.length}개'),
                const _ItemDivider(),
                _InfoItem(label: '방문 기록', value: '${VisitHistoryService.instance.recentVisits.length}개'),
                const _ItemDivider(),
                _InfoItem(label: '최근 검색', value: '${RecentSearchService.instance.items.length}개'),
              ],
            ),
            const SizedBox(height: 16),

            // Section 3: 일반 설정
            AdaptiveSectionCard(
              children: [
                _TrailingTextItem(
                  label: '언어',
                  trailing: '$_language >',
                  onTap: () => _showPicker(
                    title: '언어',
                    options: ['한국어', 'English', '日本語', '中文'],
                    selected: _language,
                    onSelected: (v) => setState(() => _language = v),
                  ),
                ),
                const _ItemDivider(),
                _TrailingTextItem(
                  label: '화면 테마',
                  trailing: '$_themeMode >',
                  onTap: () => _showPicker(
                    title: '화면 테마',
                    options: ['라이트', '다크'],
                    selected: _themeMode,
                    onSelected: (v) {
                      setState(() => _themeMode = v);
                      final mode = v == '라이트' ? 'light' : 'dark';
                      SeoulPrismApp.setThemeMode(context, mode);
                    },
                  ),
                ),
                const _ItemDivider(),
                _TrailingTextItem(
                  label: '지도 홈 시작',
                  trailing: '$_mapHome >',
                  onTap: () => _showPicker(
                    title: '지도 홈 시작',
                    options: ['기본', '내 위치', '최근 검색'],
                    selected: _mapHome,
                    onSelected: (v) => setState(() => _mapHome = v),
                  ),
                ),
                const _ItemDivider(),
                _SwitchItem(
                  label: '화면 자동 잠금 안 함',
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
                  label: '화면 방향 자동 회전',
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
                  label: '길찾기 출발지를 항상 내위치로',
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
                  label: '사용 기록 전체 삭제',
                  isDestructive: true,
                  onTap: () => _confirmDeleteHistory(),
                ),
                const _ItemDivider(),
                _ChevronItem(label: '최근 검색 기록 삭제', onTap: () => _confirmClearSearch()),
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
                        label: '정식 계정으로 전환',
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
                      label: '이름 변경',
                      onTap: () => _editUsername(),
                    ),
                    const _ItemDivider(),
                    _ChevronItem(
                      label: '비밀번호 변경',
                      onTap: () => _changePassword(),
                    ),
                    const _ItemDivider(),
                    _ChevronItem(
                      label: '로그아웃',
                      onTap: () => _confirmLogout(),
                    ),
                    const _ItemDivider(),
                    _ChevronItem(
                      label: '회원 탈퇴',
                      isDestructive: true,
                      onTap: () => _confirmDeleteAccount(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Section 6: 앱 정보
            AdaptiveSectionCard(
              children: [
                _InfoItem(label: '앱 버전', value: '1.0.3'),
                const _ItemDivider(),
                _ChevronItem(
                  label: '개인정보처리방침',
                  onTap: () => launchUrl(
                    Uri.parse('https://seoulprism.github.io/SeoulPrism_Docs/privacy-policy.html'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const _ItemDivider(),
                _ChevronItem(
                  label: '오픈소스 라이선스',
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
    showAdaptiveConfirmDialog(
      context: context,
      title: '사용 기록 삭제',
      content: '모든 사용 기록이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      isDestructive: true,
      onConfirm: () async {
        // 즐겨찾기, 방문 기록, ���근 검색 모두 삭제
        for (final f in List.from(FavoritesService.instance.favorites)) {
          await FavoritesService.instance.remove(f.name);
        }
        await RecentSearchService.instance.clear();
        // 방��� 기록도 초기화
        await VisitHistoryService.instance.clear();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('모든 사용 기록이 삭제되었습니다'),
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
    showAdaptiveConfirmDialog(
      context: context,
      title: '검색 기록 삭제',
      content: '최근 검색 기록이 모두 삭제됩니다.',
      confirmText: '삭제',
      isDestructive: true,
      onConfirm: () async {
        await RecentSearchService.instance.clear();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('검색 기록이 삭제되었습니다'), behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF2C2C2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          );
        }
      },
    );
  }

  void _editUsername() {
    showAdaptiveConfirmDialog(
      context: context,
      title: '이름 변경',
      content: '변경할 이름을 입력해주세요.',
      confirmText: '변경',
      onConfirm: () async {
        // 다이얼로그 닫힌 후 입력 다이얼로그
        if (!mounted) return;
        final controller = TextEditingController(
          text: supabase.auth.currentUser?.userMetadata?['username'] ?? '',
        );
        final name = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('새 이름'),
            content: TextField(controller: controller, autofocus: true,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
              FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('확인')),
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
    final email = supabase.auth.currentUser?.email;
    if (email == null) return;
    showAdaptiveConfirmDialog(
      context: context,
      title: '비밀번호 변경',
      content: '$email 으로 비밀번호 재설정 링크를 보냅니다.',
      confirmText: '발송',
      onConfirm: () async {
        await supabase.auth.resetPasswordForEmail(email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('재설정 이메일이 발송되었습니다'), behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF2C2C2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          );
        }
      },
    );
  }

  void _confirmLogout() {
    showAdaptiveConfirmDialog(
      context: context,
      title: '로그아웃',
      content: '로그아웃 하시겠습니까?',
      confirmText: '로그아웃',
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
    showAdaptiveConfirmDialog(
      context: context,
      title: '회원 탈퇴',
      content: '계정과 모든 데이터가 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '탈퇴',
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
                content: const Text('탈퇴 처리 중 오류가 발생했습니다'),
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
