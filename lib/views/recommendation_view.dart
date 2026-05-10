import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/api_keys.dart';
import '../services/recommendation_service.dart';
import '../services/seoul_tourism_service.dart';

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
  final _tourism = SeoulTourismService.instance;

  List<RecommendedPlace> _nearbyPlaces = [];
  List<CulturalEvent> _events = [];
  bool _loadingNearby = true;
  bool _loadingEvents = true;
  int _selectedTab = 0; // 0: 주변 인기, 1: 서울 이벤트
  String _currentArea = ''; // 현재 지역명 (예: 영등포구)

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCurrentArea();
  }

  Future<void> _loadData() async {
    _loadNearby();
    _loadEvents();
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

  Future<void> _loadEvents({bool force = false}) async {
    if (!mounted) return;
    setState(() => _loadingEvents = true);
    final events = await _tourism.getEvents(limit: 30, forceRefresh: force);
    if (mounted) {
      setState(() {
        _events = events;
        _loadingEvents = false;
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
              : _buildEventsList(cs),
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
              _loadNearby();
              _loadEvents(force: true);
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
            _buildTabButton('서울 이벤트', 1, cs),
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

  Widget _buildEventsList(ColorScheme cs) {
    if (_loadingEvents) {
      return Center(child: CircularProgressIndicator(color: _panelTextSecondary));
    }
    if (_events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '문화행사 정보를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _panelTextSecondary, height: 1.5),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      itemCount: _events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildEventItem(_events[index], cs);
      },
    );
  }

  Widget _buildEventItem(CulturalEvent event, ColorScheme cs) {
    final shortCategory = _shortCategory(event.category);
    return InkWell(
      onTap: () => _openEventLink(event),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _panelTextPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventThumbnail(event, cs),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _panelTextPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildCategoryChip(shortCategory, cs),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (event.place.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: cs.primary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            event.guName.isNotEmpty
                                ? '${event.guName} · ${event.place}'
                                : event.place,
                            style: TextStyle(fontSize: 11, color: _panelTextSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (event.isOngoing)
                        _buildStatusBadge('진행 중', Colors.green)
                      else if (event.startDate != null &&
                          event.startDate!.isAfter(DateTime.now()))
                        _buildStatusBadge('예정', Colors.blue),
                      if (event.shortDate.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.calendar_today_outlined,
                            size: 11, color: _panelTextMuted),
                        const SizedBox(width: 3),
                        Text(
                          event.shortDate,
                          style: TextStyle(fontSize: 10, color: _panelTextMuted),
                        ),
                      ],
                      const SizedBox(width: 8),
                      if (event.isFree)
                        _buildStatusBadge('무료', Colors.teal)
                      else
                        _buildStatusBadge('유료', Colors.deepOrange),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventThumbnail(CulturalEvent event, ColorScheme cs) {
    final color = _categoryColor(_shortCategory(event.category));
    final placeholder = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        _categoryIcon(event.category),
        size: 28,
        color: color,
      ),
    );
    final url = event.imageUrl;
    if (url == null || !url.startsWith('http')) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, prog) =>
            prog == null ? child : placeholder,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Future<void> _openEventLink(CulturalEvent event) async {
    final raw = event.homepageUrl ?? event.orgLink;
    if (raw == null) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// CODENAME 을 짧은 카테고리로 매핑.
  String _shortCategory(String codename) {
    if (codename.contains('전시') || codename.contains('미술')) return '문화';
    if (codename.contains('축제')) return '축제';
    if (codename.contains('콘서트') ||
        codename.contains('클래식') ||
        codename.contains('국악') ||
        codename.contains('대중')) return '문화';
    if (codename.contains('연극') || codename.contains('뮤지컬')) return '문화';
    if (codename.contains('영화')) return '문화';
    if (codename.contains('교육') || codename.contains('체험')) return '문화';
    return '문화';
  }

  IconData _categoryIcon(String codename) {
    if (codename.contains('전시') || codename.contains('미술')) {
      return Icons.palette_rounded;
    }
    if (codename.contains('축제')) return Icons.celebration_rounded;
    if (codename.contains('영화')) return Icons.movie_rounded;
    if (codename.contains('연극') || codename.contains('뮤지컬')) {
      return Icons.theater_comedy_rounded;
    }
    if (codename.contains('콘서트') ||
        codename.contains('클래식') ||
        codename.contains('국악') ||
        codename.contains('대중')) return Icons.music_note_rounded;
    return Icons.event_rounded;
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
}
