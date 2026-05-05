import 'dart:io';
import 'dart:ui';

import '../widgets/adaptive/adaptive.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../services/favorites_service.dart';
import '../services/visit_history_service.dart';
import 'notifications_view.dart';
import 'settings_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    '즐겨찾기',
    '최근 방문',
    '자주 방문',
  ];

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
    const isM3 = true;

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
          GestureDetector(
            onTap: _editUsername,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  supabase.auth.currentUser?.userMetadata?['username'] ?? '사용자',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit, size: 16, color: cs.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            supabase.auth.currentUser?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: cs.onSurfaceVariant,
            ),
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
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          final cs = Theme.of(context).colorScheme;
          const isM3 = true;

          if (isM3) {
            return FilterChip(
              selected: isSelected,
              label: Text(_categories[index]),
              onSelected: (_) => setState(() => _selectedCategoryIndex = index),
              showCheckmark: false,
            );
          }

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
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
                    _categories[index],
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

  Widget _buildCategoryContent() {
    final cs = Theme.of(context).colorScheme;

    List<Widget> items;
    if (_selectedCategoryIndex == 0) {
      final favs = FavoritesService.instance.favorites;
      items = favs.map((f) => _buildPlaceCard(f.name, f.category, Icons.favorite, Colors.redAccent, cs)).toList();
    } else if (_selectedCategoryIndex == 1) {
      final recent = VisitHistoryService.instance.recentVisits;
      items = recent.map((r) {
        final ago = DateTime.now().difference(r.visitedAt);
        final agoStr = ago.inDays > 0 ? '${ago.inDays}일 전' : ago.inHours > 0 ? '${ago.inHours}시간 전' : '방금';
        return _buildPlaceCard(r.name, agoStr, Icons.history, cs.primary, cs);
      }).toList();
    } else {
      final freq = VisitHistoryService.instance.frequentVisits;
      items = freq.map((r) => _buildPlaceCard(r.name, '${r.visitCount}회 방문', Icons.repeat, cs.tertiary, cs)).toList();
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AdaptiveSurfaceCard(
          borderRadius: 20,
          child: SizedBox(
            width: double.infinity,
            height: 120,
            child: Center(
              child: Text(
                _selectedCategoryIndex == 0 ? '즐겨찾기가 없습니다' : '방문 기록이 없습니다',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
            ),
        ),
      ),
    );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: items),
    );
  }

  // ─── Timeline Section ────────────────────────────────────────

  Widget _buildTimelineSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 타임라인',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // Map preview card
          AdaptiveGlassContainer.rect(
            cornerRadius: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withValues(alpha: 0.10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Simulated map grid
                      CustomPaint(
                        size: const Size(double.infinity, 180),
                        painter: _MapGridPainter(),
                      ),
                      Center(
                        child: Icon(
                          Icons.map_outlined,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Recent location items
          _buildLocationItem(
            icon: Icons.location_on_rounded,
            title: '최근 방문',
            subtitle: _recentVisitSummary(),
          ),
          const SizedBox(height: 10),
          _buildLocationItem(
            icon: Icons.access_time_rounded,
            title: '자주 방문',
            subtitle: _frequentVisitSummary(),
          ),
          const SizedBox(height: 10),
          _buildLocationItem(
            icon: Icons.favorite_rounded,
            title: '즐겨찾기',
            subtitle: '${FavoritesService.instance.favorites.length}개 저장됨',
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(String name, String subtitle, IconData icon, Color iconColor, ColorScheme cs) {
    return Padding(
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
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    const isM3 = true;

    return AdaptiveSurfaceCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isM3 ? cs.secondaryContainer : Colors.white.withValues(alpha: 0.10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isM3 ? cs.onSecondaryContainer : Colors.white.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isM3 ? cs.onSurface : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isM3 ? cs.onSurfaceVariant : Colors.white.withValues(alpha: 0.40),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isM3 ? cs.onSurfaceVariant : Colors.white.withValues(alpha: 0.30),
          ),
        ],
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
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('이름 변경'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '새 이름 입력',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
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
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  String _recentVisitSummary() {
    final recent = VisitHistoryService.instance.recentVisits;
    if (recent.isEmpty) return '방문 기록이 없습니다';
    return recent.take(2).map((r) => r.name).join(', ');
  }

  String _frequentVisitSummary() {
    final freq = VisitHistoryService.instance.frequentVisits;
    if (freq.isEmpty) return '방문 기록이 없습니다';
    return freq.take(2).map((r) => '${r.name}(${r.visitCount}회)').join(', ');
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
            '서울의 모든 순간을 담다',
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

// ─── Map Grid Painter ──────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
