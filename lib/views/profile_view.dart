import 'dart:io';
import 'dart:ui';

import '../widgets/adaptive/adaptive.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../core/api_keys.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/favorites_service.dart';
import '../services/visit_history_service.dart';
import 'notifications_view.dart';
import 'settings_view.dart';
import 'multiplayer/multiplayer_consent_view.dart';
import 'multiplayer/multiplayer_hub_view.dart';
import '../services/multiplayer_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int _selectedCategoryIndex = 0;

  static const _kCategoryCount = 3;

  String _categoryLabel(BuildContext ctx, int index) {
    final l = AppL10n.of(ctx);
    return switch (index) {
      0 => l.profileCategoryFavorites,
      1 => l.profileCategoryRecent,
      _ => l.profileCategoryFrequent,
    };
  }

  /// 타임라인에서 펼친 날짜 그룹 라벨 ('오늘', '어제', '3일 전', ...).
  /// 기본은 모두 접힘 → 그룹당 5개 노출 + 더보기.
  final Set<String> _expandedTimelineGroups = {};

  /// 그룹당 기본 노출 개수 — 더보기 누르면 전부 노출.
  static const _kTimelineGroupLimit = 5;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildUserInfo(),
              const SizedBox(height: 28),
              _buildCategoryTabs(),
              const SizedBox(height: 16),
              _buildCategoryContent(),
              const SizedBox(height: 24),
              _buildMultiplayerEntry(),
              const SizedBox(height: 32),
              _buildTimelineSection(),
              const SizedBox(height: 40),
              _buildFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          AdaptiveGlassIconButton(
            icon: Icons.close_rounded,
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          AdaptiveGlassIconButton(
            icon: Icons.notifications_none_rounded,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const NotificationsView(),
              ));
            },
          ),
          const SizedBox(width: 8),
          AdaptiveGlassIconButton(
            icon: Icons.settings_outlined,
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const SettingsView(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ));
                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 350),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── User Info ───────────────────────────────────────────────

  Widget _buildUserInfo() {
    final cs = Theme.of(context).colorScheme;
    final isM3 = Platform.isAndroid;

    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isM3 ? cs.outlineVariant : Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
              color: isM3 ? cs.secondaryContainer : Colors.white.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: isM3 ? cs.onSecondaryContainer : Colors.white.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(height: 14),
          Builder(
            builder: (ctx) {
              final l = AppL10n.of(ctx);
              final user = supabase.auth.currentUser;
              final isGuest = user?.isAnonymous ?? true;
              final displayName = isGuest
                  ? l.profileGuestName
                  : (user?.userMetadata?['username'] ?? l.profileDefaultName);
              final subtitle = isGuest
                  ? l.profileSyncCta
                  : (user?.email ?? '');
              return Column(
                children: [
                  GestureDetector(
                    onTap: isGuest ? null : _editUsername,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        if (!isGuest) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.edit, size: 16, color: cs.onSurfaceVariant),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Category Tabs ───────────────────────────────────────────

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _kCategoryCount,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          final isM3 = Platform.isAndroid;

          if (isM3) {
            return FilterChip(
              selected: isSelected,
              label: Text(_categoryLabel(context, index)),
              onSelected: (_) => setState(() {
                _selectedCategoryIndex = index;
                _expandedAll = false;
              }),
              showCheckmark: false,
            );
          }

          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategoryIndex = index;
              _expandedAll = false;
            }),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.30)
                          : Colors.white.withValues(alpha: 0.12),
                      width: 0.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _categoryLabel(context, index),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.60),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Category Content ────────────────────

  /// 카테고리별 미리보기 5개 + 더 많으면 "자세히 보기" 버튼.
  static const int _previewCount = 5;
  bool _expandedAll = false;

  Widget _buildCategoryContent() {
    final cs = Theme.of(context).colorScheme;

    List<Widget> items;
    if (_selectedCategoryIndex == 0) {
      final favs = FavoritesService.instance.favorites;
      items = favs
          .map((f) => _buildPlaceCard(f.name, f.category, Icons.favorite,
              Colors.redAccent, cs,
              lat: f.lat, lng: f.lng))
          .toList();
    } else if (_selectedCategoryIndex == 1) {
      final l = AppL10n.of(context);
      final recent = VisitHistoryService.instance.recentVisits;
      items = recent.map((r) {
        final ago = DateTime.now().difference(r.visitedAt);
        final agoStr = ago.inDays > 0
            ? l.profileAgoDays(ago.inDays)
            : ago.inHours > 0
                ? l.profileAgoHours(ago.inHours)
                : l.profileAgoNow;
        return _buildPlaceCard(r.name, agoStr, Icons.history, cs.primary, cs,
            lat: r.lat, lng: r.lng);
      }).toList();
    } else {
      final l = AppL10n.of(context);
      final freq = VisitHistoryService.instance.frequentVisits;
      items = freq
          .map((r) => _buildPlaceCard(
              r.name, l.profileVisitCount(r.visitCount), Icons.repeat,
              cs.tertiary, cs,
              lat: r.lat, lng: r.lng))
          .toList();
    }

    if (items.isEmpty) {
      final l = AppL10n.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AdaptiveSurfaceCard(
          borderRadius: 20,
          child: SizedBox(
            width: double.infinity,
            height: 120,
            child: Center(
              child: Text(
                _selectedCategoryIndex == 0
                    ? l.profileEmptyFavorites
                    : l.profileEmptyVisits,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ),
      );
    }

    final hasMore = items.length > _previewCount;
    final visible = (_expandedAll || !hasMore)
        ? items
        : items.sublist(0, _previewCount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ...visible,
          if (hasMore) ...[
            const SizedBox(height: 8),
            _buildExpandToggle(cs, items.length),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandToggle(ColorScheme cs, int total) {
    final isExpanded = _expandedAll;
    final remaining = total - _previewCount;
    final l = AppL10n.of(context);
    return TextButton.icon(
      onPressed: () => setState(() => _expandedAll = !_expandedAll),
      icon: Icon(
        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
        size: 18,
      ),
      label: Text(
        isExpanded ? l.profileCollapse : l.profileMoreCount(remaining),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // ─── Multiplayer Entry ───────────────────────────────────────

  Widget _buildMultiplayerEntry() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AdaptiveSurfaceCard(
        borderRadius: 18,
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final hasConsent = await MultiplayerService.hasConsent();
            if (!mounted) return;
            if (hasConsent) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const MultiplayerHubView(),
              ));
            } else {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => MultiplayerConsentView(
                  onConsented: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (_) => const MultiplayerHubView(),
                    ));
                  },
                ),
              ));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7C5CFF), Color(0xFF5CC8FF)],
                    ),
                  ),
                  child: const Icon(Icons.public_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seoul Live',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface)),
                      const SizedBox(height: 2),
                      Text(AppL10n.of(context).profileLiveShareBeta,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Timeline Section ────────────────────────────────────────

  Widget _buildTimelineSection() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppL10n.of(context);
    final visits = VisitHistoryService.instance.recentVisits;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.profileTimeline,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              if (visits.isNotEmpty)
                Text(
                  l.profilePlaceCount(visits.length),
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Mapbox Static Image — 최근 방문지 핀 표시. 탭 → 메인 지도 +
          // 방문 타임라인 패널 (네이버 지도 스타일).
          GestureDetector(
            onTap: visits.isEmpty
                ? null
                : () => Navigator.pop(context, {'showTimeline': true}),
            child: _TimelineMapPreview(visits: visits, isDark: isDark),
          ),
          const SizedBox(height: 16),
          // 시간순 visit feed.
          if (visits.isEmpty)
            AdaptiveSurfaceCard(
              borderRadius: 16,
              child: SizedBox(
                width: double.infinity,
                height: 90,
                child: Center(
                  child: Text(
                    l.profileEmptyVisitsCta,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            ..._buildTimelineFeed(visits, cs),
        ],
      ),
    );
  }

  /// 방문 기록을 날짜별로 그룹핑 후 카드 리스트 생성.
  /// 그룹마다 5개까지 노출, 나머지는 더보기 토글.
  List<Widget> _buildTimelineFeed(List<VisitRecord> visits, ColorScheme cs) {
    final l = AppL10n.of(context);
    String dateLabel(DateTime d) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dDay = DateTime(d.year, d.month, d.day);
      final diff = today.difference(dDay).inDays;
      if (diff == 0) return l.profileToday;
      if (diff == 1) return l.profileYesterday;
      if (diff < 7) return l.profileAgoDays(diff);
      return l.profileMonthDay(d.month, d.day);
    }

    // 1) 라벨별로 묶음 (입력은 시간 내림차순 가정 → 순서 유지).
    final groups = <String, List<VisitRecord>>{};
    final order = <String>[];
    for (final v in visits) {
      final label = dateLabel(v.visitedAt);
      if (!groups.containsKey(label)) {
        order.add(label);
        groups[label] = [];
      }
      groups[label]!.add(v);
    }

    // 2) 그룹별로 헤더 + 카드 5개(또는 전체) + 더보기 버튼 렌더.
    final widgets = <Widget>[];
    for (int gi = 0; gi < order.length; gi++) {
      final label = order[gi];
      final groupVisits = groups[label]!;
      final expanded = _expandedTimelineGroups.contains(label);
      final showAll = expanded || groupVisits.length <= _kTimelineGroupLimit;
      final shown = showAll ? groupVisits : groupVisits.take(_kTimelineGroupLimit).toList();
      final hidden = groupVisits.length - shown.length;

      if (gi > 0) widgets.add(const SizedBox(height: 14));
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.primary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${groupVisits.length}',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ));
      for (final v in shown) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildVisitCard(v, cs),
        ));
      }
      // 5개 초과 그룹 → 더보기 / 접기 토글.
      if (groupVisits.length > _kTimelineGroupLimit) {
        widgets.add(
          _TimelineExpandToggle(
            expanded: expanded,
            hiddenCount: hidden,
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedTimelineGroups.remove(label);
                } else {
                  _expandedTimelineGroups.add(label);
                }
              });
            },
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildVisitCard(VisitRecord v, ColorScheme cs) {
    final timeStr =
        '${v.visitedAt.hour.toString().padLeft(2, '0')}:${v.visitedAt.minute.toString().padLeft(2, '0')}';
    final color = _categoryAccent(v.category);
    return GestureDetector(
      onTap: (v.lat != 0 && v.lng != 0)
          ? () => Navigator.pop(
              context, {'lat': v.lat, 'lng': v.lng, 'name': v.name})
          : null,
      child: AdaptiveSurfaceCard(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(
                _categoryIcon(v.category),
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(timeStr,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                      if (v.category.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text('·',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(width: 6),
                        Text(v.category,
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant)),
                      ],
                      if (v.visitCount > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppL10n.of(context).profileVisitTimes(v.visitCount),
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Color _categoryAccent(String cat) {
    if (cat.contains('맛') || cat.contains('식')) return Colors.orange;
    if (cat.contains('카페')) return const Color(0xFF795548);
    if (cat.contains('쇼')) return Colors.pink;
    if (cat.contains('관광') || cat.contains('명소')) return Colors.blue;
    if (cat.contains('문화') || cat.contains('전시')) return Colors.purple;
    if (cat.contains('자연') || cat.contains('공원')) return Colors.green;
    return Colors.blueAccent;
  }

  IconData _categoryIcon(String cat) {
    if (cat.contains('맛') || cat.contains('식')) return Icons.restaurant_rounded;
    if (cat.contains('카페')) return Icons.local_cafe_rounded;
    if (cat.contains('쇼')) return Icons.shopping_bag_rounded;
    if (cat.contains('관광') || cat.contains('명소')) {
      return Icons.travel_explore_rounded;
    }
    if (cat.contains('문화') || cat.contains('전시')) return Icons.museum_rounded;
    if (cat.contains('자연') || cat.contains('공원')) return Icons.park_rounded;
    return Icons.place_rounded;
  }

  Widget _buildPlaceCard(String name, String subtitle, IconData icon, Color iconColor, ColorScheme cs, {double? lat, double? lng}) {
    return GestureDetector(
      onTap: (lat != null && lng != null) ? () {
        Navigator.pop(context, {'lat': lat, 'lng': lng, 'name': name});
      } : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AdaptiveSurfaceCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: iconColor.withValues(alpha: 0.1)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              )),
              Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _editUsername() {
    final controller = TextEditingController(
      text: supabase.auth.currentUser?.userMetadata?['username'] ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) {
        final l = AppL10n.of(ctx);
        return AlertDialog(
          title: Text(l.profileEditName),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l.profileNewNameHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.commonCancel)),
            FilledButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;
                await supabase.auth.updateUser(UserAttributes(
                  data: {'username': newName},
                ));
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: Text(l.commonSave),
            ),
          ],
        );
      },
    );
  }

  // ─── Footer ───���─────────────────────────────��────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
            height: 1,
          ),
          const SizedBox(height: 20),
          Text(
            'Seoul Prism',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppL10n.of(context).profileTagline,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline Expand Toggle ────────────────────────────────────
// 한 날짜 그룹 5개 초과 시 카드 하단에 붙는 더보기 / 접기 버튼.

class _TimelineExpandToggle extends StatelessWidget {
  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;
  const _TimelineExpandToggle({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  expanded
                      ? AppL10n.of(context).profileCollapse
                      : AppL10n.of(context).profileMore,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                if (!expanded) ...[
                  const SizedBox(width: 6),
                  Text(
                    '+$hiddenCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: cs.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Timeline Map Preview ──────────────────────────────────────
// Mapbox Static Image API — 가벼운 평면 미리보기. 핀 자동 fit (auto).

class _TimelineMapPreview extends StatelessWidget {
  final List<VisitRecord> visits;
  final bool isDark;
  const _TimelineMapPreview({required this.visits, required this.isDark});

  String? _staticUrl(double width, double height, double dpr) {
    final pinned =
        visits.where((v) => v.lat != 0 && v.lng != 0).take(8).toList();
    if (pinned.isEmpty) return null;
    final markers = pinned
        .asMap()
        .entries
        .map((e) {
          final i = e.key;
          final v = e.value;
          final lng = v.lng.toStringAsFixed(5);
          final lat = v.lat.toStringAsFixed(5);
          // 최근(첫 핀) 은 주황, 나머지 파랑.
          final color = i == 0 ? 'fb6340' : '4a90d9';
          return 'pin-s+$color($lng,$lat)';
        })
        .join(',');
    // satellite-v9 — 라벨 0 개라 한/영 문제 없음. zoom 9 = 경기도 + 인천
    // 전체가 한 화면에 들어옴. 핀만 깔끔하게 강조.
    final center = pinned.first;
    final centerLng = center.lng.toStringAsFixed(5);
    final centerLat = center.lat.toStringAsFixed(5);
    const zoom = '9';
    const style = 'mapbox/satellite-v9';
    final w = width.round();
    final h = height.round();
    final retina = dpr >= 2 ? '@2x' : '';
    return 'https://api.mapbox.com/styles/v1/$style/static/$markers/'
        '$centerLng,$centerLat,$zoom/${w}x$h$retina'
        '?access_token=${ApiKeys.mapboxAccessToken}'
        '&attribution=false&logo=false';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: 180,
        color: cs.surfaceContainerHighest,
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final url =
                _staticUrl(constraints.maxWidth, constraints.maxHeight, dpr);
            if (url == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore_off_rounded,
                        size: 32, color: cs.onSurfaceVariant),
                    const SizedBox(height: 6),
                    Text(
                      AppL10n.of(context).profileEmptyMapPlaces,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, prog) {
                      if (prog == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.map_outlined,
                          size: 36,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                // 우상단 핀 개수 배지.
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppL10n.of(context).profileRecentPlaceCount(
                          visits.where((v) => v.lat != 0 && v.lng != 0).take(8).length),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
