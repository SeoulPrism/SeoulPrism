import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/api_keys.dart';
import '../services/recommendation_service.dart';

/// 추천 패널 — 아래에서 위로 슬라이드업 (설정 패널 스타일)
/// 네이버 지도 발견 탭 참고: 주변 인기 장소 + 전국 트렌드
class RecommendationPanel extends StatefulWidget {
  final VoidCallback onClose;

  const RecommendationPanel({super.key, required this.onClose});

  @override
  State<RecommendationPanel> createState() => _RecommendationPanelState();
}

class _RecommendationPanelState extends State<RecommendationPanel>
    with SingleTickerProviderStateMixin {
  final _service = RecommendationService.instance;

  List<RecommendedPlace> _nearbyPlaces = [];
  List<TrendItem> _trends = [];
  bool _loadingNearby = true;
  bool _loadingTrends = true;
  int _selectedTab = 0; // 0: 주변 인기, 1: 전국 트렌드
  String _currentArea = ''; // 현재 지역명 (예: 영등포구)

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCurrentArea();
  }

  Future<void> _loadData() async {
    _loadNearby();
    _loadTrends();
  }

  Future<void> _loadCurrentArea() async {
    try {
      final position = await _service.getCurrentPosition();
      final url =
          'https://api.mapbox.com/search/geocode/v6/reverse'
          '?longitude=${position.longitude}'
          '&latitude=${position.latitude}'
          '&language=ko'
          '&types=district,locality,place'
          '&access_token=${ApiKeys.mapboxAccessToken}';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          // district (구) 우선, 없으면 locality/place
          String area = '';
          for (final f in features) {
            final name = f['properties']?['name'] ?? '';
            final type = f['properties']?['feature_type'] ?? '';
            if (type == 'district' && name.toString().isNotEmpty) {
              area = name;
              break;
            }
            if (area.isEmpty && name.toString().isNotEmpty) {
              area = name;
            }
          }
          if (mounted && area.isNotEmpty) {
            setState(() => _currentArea = area);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadNearby() async {
    if (!mounted) return;
    setState(() => _loadingNearby = true);
    final places = await _service.getNearbyPopularPlaces();
    if (mounted) {
      setState(() {
        _nearbyPlaces = places;
        _loadingNearby = false;
      });
    }
  }

  Future<void> _loadTrends() async {
    if (!mounted) return;
    setState(() => _loadingTrends = true);
    final trends = await _service.getNationalTrends();
    if (mounted) {
      setState(() {
        _trends = trends;
        _loadingTrends = false;
      });
    }
  }

  /// 패널 내 텍스트 색상 — 설정 패널과 동일
  bool get _isLightTheme => Theme.of(context).brightness == Brightness.light;

  Color get _panelTextPrimary =>
      _isLightTheme ? Colors.black.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85);
  Color get _panelTextSecondary =>
      _isLightTheme ? Colors.black.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.45);
  Color get _panelTextMuted =>
      _isLightTheme ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isM3 = Platform.isAndroid;

    final content = Column(
      children: [
        // 드래그 핸들
        _buildHandle(),
        // 헤더
        _buildHeader(),
        // 세그먼트 탭
        _buildSegmentedTab(cs),
        const SizedBox(height: 8),
        // 컨텐츠 리스트
        Expanded(
          child: _selectedTab == 0
              ? _buildNearbyList(cs)
              : _buildTrendsList(cs),
        ),
      ],
    );

    // Android: M3 Material surface
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

    // iOS: 글라스모피즘 (설정 패널과 동일)
    final lightPanel = _isLightTheme;
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
              colors: lightPanel
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
                color: lightPanel
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

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: _panelTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentArea.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: _panelTextSecondary),
                      const SizedBox(width: 3),
                      Text(
                        _currentArea,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _panelTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                '추천',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _panelTextPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: _panelTextSecondary, size: 20),
            onPressed: () {
              _loadData();
              _loadCurrentArea();
            },
            tooltip: '새로고침',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.close, color: _panelTextSecondary, size: 20),
            onPressed: widget.onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTab(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: _panelTextMuted.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _buildTabButton('주변 인기 TOP 10', 0, cs),
            _buildTabButton('전국 트렌드', 1, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index, ColorScheme cs) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? _panelTextPrimary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _panelTextPrimary : _panelTextSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyList(ColorScheme cs) {
    if (_loadingNearby) {
      return Center(child: CircularProgressIndicator(color: _panelTextSecondary));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      itemCount: _nearbyPlaces.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final place = _nearbyPlaces[index];
        return _buildPlaceItem(place, cs);
      },
    );
  }

  Widget _buildPlaceItem(RecommendedPlace place, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _panelTextPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildRankBadge(place.rank, cs),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _panelTextPrimary,
                        ),
                      ),
                    ),
                    _buildCategoryChip(place.category, cs),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  place.description,
                  style: TextStyle(fontSize: 11, color: _panelTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildCongestionBadge(place.congestion, cs),
                    const SizedBox(width: 8),
                    Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade600),
                    const SizedBox(width: 2),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _panelTextPrimary),
                    ),
                    if (place.nearestStation != null) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.subway, size: 12, color: cs.primary),
                      const SizedBox(width: 2),
                      Text(
                        place.nearestStation!,
                        style: TextStyle(fontSize: 10, color: cs.primary),
                      ),
                    ],
                    if (place.distanceMeters != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatDistance(place.distanceMeters!),
                        style: TextStyle(fontSize: 10, color: _panelTextMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsList(ColorScheme cs) {
    if (_loadingTrends) {
      return Center(child: CircularProgressIndicator(color: _panelTextSecondary));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      itemCount: _trends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final trend = _trends[index];
        return _buildTrendItem(trend, cs);
      },
    );
  }

  Widget _buildTrendItem(TrendItem item, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _panelTextPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Column(
            children: [
              _buildRankBadge(item.rank, cs),
              const SizedBox(height: 3),
              _buildTrendIcon(item.trend),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _panelTextPrimary,
                        ),
                      ),
                    ),
                    _buildCategoryChip(item.category, cs),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 11, color: _panelTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: cs.primary),
                    const SizedBox(width: 2),
                    Text(
                      item.region,
                      style: TextStyle(fontSize: 10, color: cs.primary),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade600),
                    const SizedBox(width: 2),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _panelTextPrimary),
                    ),
                    if (item.searchCount > 0) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.search, size: 11, color: _panelTextMuted),
                      const SizedBox(width: 2),
                      Text(
                        _formatCount(item.searchCount),
                        style: TextStyle(fontSize: 10, color: _panelTextMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank, ColorScheme cs) {
    final isTop3 = rank <= 3;
    final colors = rank == 1
        ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
        : rank == 2
            ? [const Color(0xFFB8B8B8), const Color(0xFF8E8E8E)]
            : [const Color(0xFFCD7F32), const Color(0xFF8D6E63)];

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: isTop3 ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors) : null,
        color: isTop3 ? null : _panelTextMuted.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isTop3 ? Colors.white : _panelTextSecondary,
        ),
      ),
    );
  }

  Widget _buildTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return const Icon(Icons.trending_up, size: 14, color: Colors.redAccent);
      case 'down':
        return const Icon(Icons.trending_down, size: 14, color: Colors.blueAccent);
      case 'new':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text('N', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
        );
      default:
        return const Icon(Icons.trending_flat, size: 14, color: Colors.grey);
    }
  }

  Widget _buildCongestionBadge(String level, ColorScheme _) {
    Color color;
    switch (level) {
      case '여유':
        color = Colors.green;
        break;
      case '보통':
        color = Colors.amber;
        break;
      case '약간 붐빔':
        color = Colors.orange;
        break;
      case '붐빔':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        level,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildCategoryChip(String category, ColorScheme _) {
    final color = _categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case '맛집': return Colors.orange;
      case '카페': return const Color(0xFF795548);
      case '관광': return Colors.blue;
      case '쇼핑': return Colors.pink;
      case '문화': return Colors.purple;
      case '자연': return Colors.green;
      case '축제': return Colors.red;
      case '핫플레이스': return Colors.deepOrange;
      default: return Colors.grey;
    }
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)}km';
    return '${meters}m';
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}만';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}천';
    return '$count';
  }
}
