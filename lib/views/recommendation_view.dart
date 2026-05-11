import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/api_keys.dart';
import '../data/travel_styles.dart';
import '../services/environment_service.dart';
import '../services/place_search_service.dart';
import '../services/recommendation_service.dart';
import '../services/seoul_tourism_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 추천 탭 종류. 핫플(서울 실시간 인구) 은 데이터 신뢰성 문제로 삭제.
enum _RecommendTab {
  forYou, // 당신의 무드 — 튜토리얼에서 고른 스타일 기반
  food, // 맛집 — 카카오 FD6
  cafe, // 카페 — 카카오 CE7
  shopping, // 쇼핑·핫스팟 — 카카오 MT1+CT1
  outdoor, // 공원·야경 — 카카오 AT4
  events, // 문화·이벤트 — 서울 문화행사 API
}

/// "당신의 무드" 칩 라벨 — 사용자가 고른 스타일에 따라 동적.
String _forYouLabel() {
  final s = travelStyleByKey(
    SettingsService.instance.getString(kTravelStylePrefKey),
  );
  if (s == null || s.key == 'mixed') return '✨ 너만의';
  return '${s.emoji} ${s.title.replaceAll(' 여행', '')}';
}

extension on _RecommendTab {
  String get label => switch (this) {
        _RecommendTab.forYou => _forYouLabel(),
        _RecommendTab.food => '🍜 맛집',
        _RecommendTab.cafe => '☕️ 카페',
        _RecommendTab.shopping => '🛍 쇼핑',
        _RecommendTab.outdoor => '🌳 공원·야경',
        _RecommendTab.events => '🎭 문화',
      };
}

/// 추천 패널 — 아래에서 위로 슬라이드업 (설정 패널 스타일)
/// 네이버 지도 발견 탭 참고: 주변 인기 장소 + 전국 트렌드
class RecommendationPanel extends StatefulWidget {
  final VoidCallback onClose;
  /// 장소 탭 → 우리 지도에서 그 장소 선택. null 이면 카카오 URL 폴백.
  final void Function(PlaceSearchResult place)? onPlaceTap;

  const RecommendationPanel({
    super.key,
    required this.onClose,
    this.onPlaceTap,
  });

  @override
  State<RecommendationPanel> createState() => _RecommendationPanelState();
}

class _RecommendationPanelState extends State<RecommendationPanel>
    with SingleTickerProviderStateMixin {
  final _service = RecommendationService.instance;
  final _tourism = SeoulTourismService.instance;
  final _placeSearch = PlaceSearchService.instance;

  List<CulturalEvent> _events = [];
  final Map<_RecommendTab, List<PlaceSearchResult>> _placeCache = {};
  final Map<_RecommendTab, bool> _loadingTab = {};
  bool _loadingEvents = true;
  _RecommendTab _selectedTab = _RecommendTab.food;
  String _currentArea = ''; // 현재 지역명 (예: 영등포구)

  @override
  void initState() {
    super.initState();
    // 첫 진입 탭 (food) 미리 로드 + 이벤트 백그라운드 로드.
    _loadPlaceTab(_RecommendTab.food);
    _loadEvents();
    _loadCurrentArea();
  }


  Future<void> _loadPlaceTab(_RecommendTab tab, {bool force = false}) async {
    if (!force && _placeCache.containsKey(tab)) return;
    if (mounted) setState(() => _loadingTab[tab] = true);
    final pos = await _service.getCurrentPosition();
    // 무드 탭은 사용자 스타일에서 카테고리 코드 가져옴. 없으면 기본 인기 카테고리.
    final forYouCodes = travelStyleByKey(
          SettingsService.instance.getString(kTravelStylePrefKey),
        )?.recommendKakaoCodes ??
        ['FD6', 'CE7'];
    final codes = switch (tab) {
      _RecommendTab.forYou => forYouCodes,
      _RecommendTab.food => ['FD6'],
      _RecommendTab.cafe => ['CE7'],
      _RecommendTab.shopping => ['MT1', 'CT1'],
      _RecommendTab.outdoor => ['AT4'],
      _ => <String>[],
    };
    if (codes.isEmpty) return;
    final results = await _placeSearch.fetchByCategoryCodes(
      codes,
      pos.latitude,
      pos.longitude,
      radius: 1500,
      sizePerCode: 15,
    );
    if (!mounted) return;
    setState(() {
      _placeCache[tab] = results;
      _loadingTab[tab] = false;
    });
  }

  void _onTabChanged(_RecommendTab tab) {
    setState(() => _selectedTab = tab);
    if (tab != _RecommendTab.events) {
      // 무드 탭은 사용자 스타일이 변할 수 있으므로 항상 force=true 로 새로 가져옴.
      _loadPlaceTab(tab, force: tab == _RecommendTab.forYou);
    }
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

  // 패널 내 텍스트 색상 — travel_panel 과 동일 토큰.
  bool get _isLightTheme => Theme.of(context).brightness == Brightness.light;

  Color get _panelTextPrimary {
    final cs = Theme.of(context).colorScheme;
    return Platform.isAndroid
        ? cs.onSurface
        : (_isLightTheme ? const Color(0xFF1C1C1E) : Colors.white);
  }

  Color get _panelTextSecondary {
    final cs = Theme.of(context).colorScheme;
    return Platform.isAndroid
        ? cs.onSurfaceVariant
        : (_isLightTheme
            ? const Color(0xFF6E6E73)
            : Colors.white.withValues(alpha: 0.55));
  }

  Color get _panelTextMuted => _panelTextSecondary.withValues(alpha: 0.6);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isM3 = Platform.isAndroid;
    final isLight = _isLightTheme;

    final content = Column(
      children: [
        // 드래그 핸들 (travel_panel 과 동일 spec)
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _panelTextMuted.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        // 헤더 + chip 바 + 리스트가 한 CustomScrollView 안에서 같이 스크롤
        // → travel_panel 과 동일한 UX (위로 스와이프 시 제목까지 따라 올라감).
        Expanded(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _buildChipBar(cs)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ..._buildBodySlivers(cs),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 24,
                ),
              ),
            ],
          ),
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

    // iOS: 글라스 + 그라데이션 (travel_panel 과 동일)
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
              colors: isLight
                  ? [
                      Colors.white.withValues(alpha: 0.70),
                      Colors.white.withValues(alpha: 0.78),
                      Colors.white.withValues(alpha: 0.88),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.52),
                      Colors.black.withValues(alpha: 0.68),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: (isLight ? Colors.black : Colors.white)
                    .withValues(alpha: 0.10),
                width: 0.5,
              ),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '추천',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _panelTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentArea.isNotEmpty
                      ? '$_currentArea 근처에서 지금 인기있는 곳'
                      : '지금 가까이서 인기있는 곳',
                  style: AppTypography.bodySm.copyWith(
                    color: _panelTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon:
                Icon(Icons.refresh, color: _panelTextSecondary, size: 20),
            onPressed: () {
              _loadCurrentArea();
              switch (_selectedTab) {
                case _RecommendTab.events:
                  _loadEvents(force: true);
                case _RecommendTab.forYou:
                case _RecommendTab.food:
                case _RecommendTab.cafe:
                case _RecommendTab.shopping:
                case _RecommendTab.outdoor:
                  _loadPlaceTab(_selectedTab, force: true);
              }
            },
            tooltip: '새로고침',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.close, color: _panelTextSecondary, size: 20),
            onPressed: widget.onClose,
            tooltip: '닫기',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildChipBar(ColorScheme cs) {
    final isM3 = Platform.isAndroid;
    final isLight = _isLightTheme;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _RecommendTab.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tab = _RecommendTab.values[i];
          final selected = _selectedTab == tab;
          // 선택 = accent 색, 비선택 = surface 톤.
          final selectedBg = AppColors.accent;
          final unselectedBg = isM3
              ? cs.surfaceContainerHighest
              : (isLight
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.08));
          return GestureDetector(
            onTap: () => _onTabChanged(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? selectedBg : unselectedBg,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : _panelTextPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 현재 탭의 본문 — 항상 sliver 리스트로 반환해 헤더/chip 과 함께 스크롤.
  List<Widget> _buildBodySlivers(ColorScheme cs) {
    switch (_selectedTab) {
      case _RecommendTab.events:
        return _buildEventsSlivers(cs);
      case _RecommendTab.forYou:
      case _RecommendTab.food:
      case _RecommendTab.cafe:
      case _RecommendTab.shopping:
      case _RecommendTab.outdoor:
        return _buildPlaceSlivers(_selectedTab, cs);
    }
  }

  Widget _centerStateSliver(Widget child) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: child),
    );
  }

  /// 데이터 도착 전 스켈레톤 — 실제 타일과 동일한 모양으로 6장 렌더 후
  /// pulse 애니메이션. CircularProgress 보다 컨텐츠 위치가 시각적으로 안정.
  Widget _skeletonListSliver({int count = 6}) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList.separated(
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => _SkeletonTile(
          bg: _tileBg(),
          border: _tileBorder(),
          shimmer: _isLightTheme
              ? Colors.black.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
    );
  }

  List<Widget> _buildPlaceSlivers(_RecommendTab tab, ColorScheme cs) {
    final loading = _loadingTab[tab] ?? !_placeCache.containsKey(tab);
    final places = _placeCache[tab] ?? const <PlaceSearchResult>[];
    if (loading) {
      return [_skeletonListSliver()];
    }
    if (places.isEmpty) {
      return [
        _centerStateSliver(
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '주변에 결과가 없어요.\n잠시 후 다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: _panelTextSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
      ];
    }

    final ranked = _applyTimeWeatherRanking(tab, places);
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverList.separated(
          itemCount: ranked.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildKakaoPlaceItem(ranked[i], i + 1, cs),
        ),
      ),
    ];
  }

  /// travel_panel 의 _EventTile 과 동일한 surface 톤.
  Color _tileBg() {
    final cs = Theme.of(context).colorScheme;
    if (Platform.isAndroid) {
      return cs.surfaceContainerHighest.withValues(alpha: 0.6);
    }
    return _isLightTheme
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.05);
  }

  Color _tileBorder() {
    return (_isLightTheme ? Colors.black : Colors.white)
        .withValues(alpha: 0.05);
  }

  /// 시간대/날씨로 카테고리 가중치 — 같은 카테고리 안에서 우선순위 살짝 띄움.
  /// 정렬 안정성 위해 매 항목 점수 부여 후 stable sort.
  List<PlaceSearchResult> _applyTimeWeatherRanking(
    _RecommendTab tab,
    List<PlaceSearchResult> input,
  ) {
    final hour = DateTime.now().hour;
    final weather = EnvironmentService.instance.current?.weather;
    final isRainy = weather == WeatherCondition.rain ||
        weather == WeatherCondition.drizzle ||
        weather == WeatherCondition.thunderstorm ||
        weather == WeatherCondition.snow;
    final isEvening = hour >= 18 || hour <= 5;

    int boost(PlaceSearchResult p) {
      final cat = p.category;
      switch (tab) {
        case _RecommendTab.food:
          // 식사 시간대 음식점 살짝 ↑.
          final isMeal = (hour >= 11 && hour <= 14) ||
              (hour >= 17 && hour <= 20);
          if (isMeal) return 3;
          return 0;
        case _RecommendTab.cafe:
          // 오후 카페 시간 (12~17) 살짝 ↑.
          if (hour >= 12 && hour <= 17) return 3;
          return 0;
        case _RecommendTab.outdoor:
          // 공원/관광지 — 비 오면 페널티, 저녁이면 야경 가산.
          if (isRainy) return -10;
          if (isEvening) return 5;
          return 0;
        case _RecommendTab.shopping:
          if (isRainy && cat.contains('문화')) return 5;
          return 0;
        default:
          return 0;
      }
    }

    final indexed = List.generate(
      input.length,
      (i) => MapEntry(i, input[i]),
    );
    indexed.sort((a, b) {
      final ba = boost(a.value);
      final bb = boost(b.value);
      if (ba != bb) return bb.compareTo(ba);
      return a.key.compareTo(b.key); // 원래 거리 순서 유지
    });
    return indexed.map((e) => e.value).toList();
  }

  Widget _buildKakaoPlaceItem(
    PlaceSearchResult place,
    int rank,
    ColorScheme cs,
  ) {
    final shortCat = _shortCategoryFromKakao(place.category);
    final dist = int.tryParse(place.distance ?? '');
    return InkWell(
      onTap: () {
        // 우리 지도에 장소 표시 콜백이 있으면 그걸로 (외부 카카오맵 X).
        // 없으면 카카오 URL 폴백.
        if (widget.onPlaceTap != null) {
          widget.onPlaceTap!(place);
        } else {
          _openPlaceUrl(place.placeUrl);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _tileBg(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _tileBorder(), width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 컬러 정적 placeholder (사진 fetch 안 함 — 탭 전환 멈춤
            // 문제 + 사진 품질 들쭉날쭉한 문제 때문에 결국 안 쓰기로).
            _PlaceThumbnail(
              fallbackColor: _categoryColor(shortCat),
              fallbackIcon: _categoryIconFromShort(shortCat),
              fallbackEmoji: _categoryEmoji(shortCat),
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
                          place.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _panelTextPrimary,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildCategoryChip(shortCat, cs),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (place.address.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: _panelTextSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            place.address,
                            style: AppTypography.caption
                                .copyWith(color: _panelTextSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tag_rounded,
                              size: 12, color: _panelTextMuted),
                          const SizedBox(width: 2),
                          Text(
                            '$rank위',
                            style: AppTypography.caption.copyWith(
                              color: _panelTextMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (dist != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_walk,
                                size: 12, color: cs.primary),
                            const SizedBox(width: 2),
                            Text(
                              _formatDistance(dist),
                              style: AppTypography.caption.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      if (place.phone != null && place.phone!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone,
                                size: 11, color: _panelTextMuted),
                            const SizedBox(width: 3),
                            Text(
                              place.phone!,
                              style: AppTypography.caption
                                  .copyWith(color: _panelTextMuted),
                            ),
                          ],
                        ),
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

  String _categoryEmoji(String shortCat) {
    switch (shortCat) {
      case '맛집':
        return '🍜';
      case '카페':
        return '☕️';
      case '쇼핑':
        return '🛍';
      case '관광':
        return '📸';
      case '문화':
        return '🎭';
      case '자연':
        return '🌳';
      case '핫플레이스':
        return '🔥';
      case '숙박':
        return '🏨';
      default:
        return '📍';
    }
  }

  IconData _categoryIconFromShort(String shortCat) {
    switch (shortCat) {
      case '맛집':
        return Icons.restaurant_rounded;
      case '카페':
        return Icons.local_cafe_rounded;
      case '쇼핑':
        return Icons.shopping_bag_rounded;
      case '관광':
        return Icons.travel_explore_rounded;
      case '문화':
        return Icons.museum_rounded;
      case '자연':
        return Icons.park_rounded;
      case '핫플레이스':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Future<void> _openPlaceUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _shortCategoryFromKakao(String full) {
    if (full.contains('음식')) return '맛집';
    if (full.contains('카페')) return '카페';
    if (full.contains('마트') || full.contains('백화점')) return '쇼핑';
    if (full.contains('관광')) return '관광';
    if (full.contains('문화')) return '문화';
    if (full.contains('숙박')) return '숙박';
    return full.isEmpty ? '장소' : full;
  }

  List<Widget> _buildEventsSlivers(ColorScheme cs) {
    if (_loadingEvents) {
      return [_skeletonListSliver()];
    }
    if (_events.isEmpty) {
      return [
        _centerStateSliver(
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '문화행사 정보를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: _panelTextSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverList.separated(
          itemCount: _events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _buildEventItem(_events[index], cs),
        ),
      ),
    ];
  }

  Widget _buildEventItem(CulturalEvent event, ColorScheme cs) {
    final shortCategory = _shortCategory(event.category);
    return InkWell(
      onTap: () => _openEventLink(event),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _tileBg(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _tileBorder(), width: 0.5),
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

/// 장소 썸네일 — 카테고리 컬러 그라데이션 + 아이콘 + 이모지.
class _PlaceThumbnail extends StatelessWidget {
  final Color fallbackColor;
  final IconData fallbackIcon;
  final String fallbackEmoji;
  const _PlaceThumbnail({
    required this.fallbackColor,
    required this.fallbackIcon,
    required this.fallbackEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            fallbackColor.withValues(alpha: 0.32),
            fallbackColor.withValues(alpha: 0.14),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: fallbackColor.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(child: Icon(fallbackIcon, size: 30, color: fallbackColor)),
          Positioned(
            top: 4,
            right: 4,
            child: Text(fallbackEmoji, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

/// 데이터 도착 전에 보여주는 빈 타일 — 실제 _buildKakaoPlaceItem 의 박스
/// 형태(72px 썸네일 + 2줄 텍스트 + 메타) 그대로, alpha 펄스 애니메이션.
class _SkeletonTile extends StatefulWidget {
  final Color bg;
  final Color border;
  final Color shimmer;
  const _SkeletonTile({
    required this.bg,
    required this.border,
    required this.shimmer,
  });

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // alpha 0.45 ↔ 1.0 펄스
        final t = 0.45 + 0.55 * _ctrl.value;
        final c = widget.shimmer.withValues(alpha: widget.shimmer.a * t);
        Widget bar(double w, double h) => Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(4),
              ),
            );
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.border, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(double.infinity, 14),
                    const SizedBox(height: 8),
                    bar(140, 11),
                    const SizedBox(height: 12),
                    Row(children: [bar(40, 10), const SizedBox(width: 8), bar(56, 10)]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
