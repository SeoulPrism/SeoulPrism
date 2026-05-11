import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../services/favorites_service.dart';
import '../../../services/visit_history_service.dart';

/// 즐겨찾기 / 최근 방문 / 자주 방문 3탭 바텀 패널.
class SavedPanel extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(double lat, double lng, String name) onPlaceTap;
  const SavedPanel({super.key, required this.onClose, required this.onPlaceTap});
  @override
  State<SavedPanel> createState() => _SavedPanelState();
}

class _SavedPanelState extends State<SavedPanel> {
  int _tab = 0;
  bool get _isLightTheme => Theme.of(context).brightness == Brightness.light;
  Color get _tp => _isLightTheme
      ? Colors.black.withValues(alpha: 0.85)
      : Colors.white.withValues(alpha: 0.85);
  Color get _ts => _isLightTheme
      ? Colors.black.withValues(alpha: 0.55)
      : Colors.white.withValues(alpha: 0.45);
  Color get _tm => _isLightTheme
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.white.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final isM3 = Platform.isAndroid;
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _tm,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
          child: Row(
            children: [
              Text(
                l.savedPanelTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _tp,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: _ts),
                onPressed: widget.onClose,
                tooltip: l.commonClose,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: _tm.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _tabBtn(l.profileCategoryFavorites, 0),
                _tabBtn(l.profileCategoryRecent, 1),
                _tabBtn(l.profileCategoryFrequent, 2),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _tab == 0
              ? _buildFavorites()
              : _tab == 1
                  ? _buildRecent()
                  : _buildFrequent(),
        ),
      ],
    );

    if (isM3) {
      return Material(
        elevation: 6,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        color: cs.surfaceContainerHigh,
        surfaceTintColor: cs.surfaceTint,
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    final lp = _isLightTheme;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: lp
                  ? [
                      Colors.white.withValues(alpha: 0.70),
                      Colors.white.withValues(alpha: 0.75),
                      Colors.white.withValues(alpha: 0.85),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.50),
                      Colors.black.withValues(alpha: 0.65),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: lp
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.white24,
                width: 0.5,
              ),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final sel = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: sel ? _tp.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              color: sel ? _tp : _ts,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavorites() {
    final l = AppL10n.of(context);
    final items = FavoritesService.instance.favorites;
    if (items.isEmpty) {
      return Center(
        child: Text(l.savedEmptyFavorites, style: TextStyle(color: _tm)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final f = items[i];
        return _row(
          f.name,
          f.category,
          f.lat,
          f.lng,
          trailing: IconButton(
            icon: const Icon(Icons.favorite, size: 18, color: Colors.redAccent),
            onPressed: () async {
              await FavoritesService.instance.remove(f.name);
              setState(() {});
            },
            tooltip: l.savedRemoveFavoriteTooltip,
            visualDensity: VisualDensity.compact,
          ),
        );
      },
    );
  }

  Widget _buildRecent() {
    final l = AppL10n.of(context);
    final items = VisitHistoryService.instance.recentVisits;
    if (items.isEmpty) {
      return Center(
        child: Text(l.profileEmptyVisits, style: TextStyle(color: _tm)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final r = items[i];
        final ago = DateTime.now().difference(r.visitedAt);
        final s = ago.inDays > 0
            ? l.profileAgoDays(ago.inDays)
            : ago.inHours > 0
                ? l.profileAgoHours(ago.inHours)
                : l.profileAgoNow;
        return _row(
          r.name,
          r.category,
          r.lat,
          r.lng,
          trailing: Text(s, style: TextStyle(fontSize: 10, color: _tm)),
        );
      },
    );
  }

  Widget _buildFrequent() {
    final l = AppL10n.of(context);
    final items = VisitHistoryService.instance.frequentVisits;
    if (items.isEmpty) {
      return Center(
        child: Text(l.profileEmptyVisits, style: TextStyle(color: _tm)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final r = items[i];
        return _row(
          r.name,
          r.category,
          r.lat,
          r.lng,
          trailing: Text(
            l.profileVisitTimes(r.visitCount),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _ts,
            ),
          ),
        );
      },
    );
  }

  Widget _row(
    String name,
    String category,
    double lat,
    double lng, {
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: () => widget.onPlaceTap(lat, lng, name),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.place, size: 18, color: _ts),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _tp,
                    ),
                  ),
                  if (category.isNotEmpty)
                    Text(category, style: TextStyle(fontSize: 11, color: _ts)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
