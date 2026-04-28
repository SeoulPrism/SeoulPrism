import 'dart:ui';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';

import 'map_view.dart';
import 'route_search_view.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _tabIndex = 0;
  String? _routeQuery;

  // Settings state
  bool _darkMode = true;
  bool _highContrast = false;
  bool _showLabels = true;
  int _qualityPreset = 1; // 0=low, 1=medium, 2=high
  int _lightingPreset = 0; // 0=auto, 1=day, 2=night

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Stack(
      children: [
        Scaffold(
      extendBody: true,
      bottomNavigationBar: CNTabBar(
        items: const [
          CNTabBarItem(label: '지도', customIcon: Icons.map_rounded),
          CNTabBarItem(label: '설정', customIcon: Icons.settings_rounded),
        ],
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 3D 지도
          const Positioned.fill(child: MapView()),

          // Top bar (search + profile + weather)
          Positioned(
            top: mq.padding.top + 8,
            left: 16,
            right: 16,
            child: _ExpandableSearchBar(
              onSearch: (query) {
                setState(() => _routeQuery = query);
              },
              onProfileTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const ProfileView(),
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
          ),

          // Weather widget (top-left below top bar)
          Positioned(
            top: mq.padding.top + 64,
            left: 16,
            child: const _WeatherCapsule(),
          ),

          // Settings overlay (body 안 — extendBody로 탭바 뒤까지 확장)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _tabIndex == 1 ? 0 : -(mq.size.height * 0.65),
            child: Material(
              color: Colors.transparent,
              child: _buildSettingsPanel(mq),
            ),
          ),

        ],
      ),
    ),
        // Route search overlay (Scaffold 위)
        if (_routeQuery != null)
          Positioned.fill(
            child: RouteSearchOverlay(
              query: _routeQuery!,
              onClose: () => setState(() => _routeQuery = null),
            ),
          ),
      ],
    );
  }


  Widget _buildSettingsPanel(MediaQueryData mq) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: mq.size.height * 0.58,
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.20),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
                width: 0.5,
              ),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, mq.padding.bottom + 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  '설정',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 24),

                // Display section
                _buildSectionHeader('디스플레이'),
                const SizedBox(height: 12),
                _buildToggleRow(
                  icon: Icons.dark_mode_rounded,
                  label: '다크 모드',
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                ),
                const SizedBox(height: 8),
                _buildToggleRow(
                  icon: Icons.contrast_rounded,
                  label: '고대비 모드',
                  value: _highContrast,
                  onChanged: (v) => setState(() => _highContrast = v),
                ),
                const SizedBox(height: 8),
                _buildToggleRow(
                  icon: Icons.label_rounded,
                  label: '역 이름 표시',
                  value: _showLabels,
                  onChanged: (v) => setState(() => _showLabels = v),
                ),
                const SizedBox(height: 24),

                // Quality section
                _buildSectionHeader('품질'),
                const SizedBox(height: 12),
                _buildPresetRow(
                  options: const ['낮음', '보통', '높음'],
                  selected: _qualityPreset,
                  onSelect: (i) => setState(() => _qualityPreset = i),
                ),
                const SizedBox(height: 24),

                // Lighting section
                _buildSectionHeader('조명'),
                const SizedBox(height: 12),
                _buildPresetRow(
                  options: const ['자동', '주간', '야간'],
                  selected: _lightingPreset,
                  onSelect: (i) => setState(() => _lightingPreset = i),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.45),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.60),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CNSwitch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetRow({
    required List<String> options,
    required int selected,
    required ValueChanged<int> onSelect,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.5,
            ),
          ),
          child: Row(
            children: List.generate(options.length, (i) {
              final isSelected = i == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: isSelected
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 0.5,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        options[i],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.95)
                              : Colors.white.withValues(alpha: 0.40),
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}


// ─── Glass Search Bar ──────────────────────────────────────

class _ExpandableSearchBar extends StatefulWidget {
  const _ExpandableSearchBar({
    required this.onProfileTap,
    required this.onSearch,
  });

  final VoidCallback onProfileTap;
  final ValueChanged<String> onSearch;

  @override
  State<_ExpandableSearchBar> createState() => _ExpandableSearchBarState();
}

class _ExpandableSearchBarState extends State<_ExpandableSearchBar> {
  bool _expanded = false;
  final _searchController = CNSearchBarController();

  @override
  void initState() {
    super.initState();
    _searchController.onExpandChanged = () {
      if (mounted) setState(() => _expanded = _searchController.isExpanded);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _expanded
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CNButton.icon(
                    customIcon: Icons.more_horiz_rounded,
                    onPressed: () {},
                    config: const CNButtonConfig(
                      style: CNButtonStyle.glass,
                      customIconSize: 20,
                    ),
                  ),
                ),
        ),
        Expanded(
          child: CNSearchBar(
            placeholder: '지하철역 검색',
            expandable: true,
            collapsedWidth: 48,
            expandedHeight: 44,
            showCancelButton: true,
            cancelText: '취소',
            controller: _searchController,
            onExpandStateChanged: (expanded) {
              setState(() => _expanded = expanded);
            },
            onChanged: (text) {},
            onSubmitted: (text) {
              if (text.isNotEmpty) {
                widget.onSearch(text);
                _searchController.collapse();
              }
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _expanded
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: CNButton.icon(
                    customIcon: Icons.person_rounded,
                    onPressed: widget.onProfileTap,
                    config: const CNButtonConfig(
                      style: CNButtonStyle.glass,
                      customIconSize: 22,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Weather Capsule ───────────────────────────────────────

class _WeatherCapsule extends StatelessWidget {
  const _WeatherCapsule();

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_rounded,
                color: Colors.white.withValues(alpha: 0.50),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$hour:$minute',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '18°C',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
