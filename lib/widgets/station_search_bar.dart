import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'adaptive/adaptive.dart';
import '../data/seoul_subway_data.dart';
import '../models/subway_models.dart';
import '../services/path_finding_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'app_badge.dart';


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 한글 초성 검색 유틸
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const List<String> _chosung = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ',
  'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

String _getChosung(String text) {
  final buffer = StringBuffer();
  for (final c in text.runes) {
    if (c >= 0xAC00 && c <= 0xD7A3) {
      buffer.write(_chosung[((c - 0xAC00) / 588).floor()]);
    } else {
      buffer.writeCharCode(c);
    }
  }
  return buffer.toString();
}

/// 한글 자모 분해 (초성+중성+종성 → 낱자 나열)
String _decomposeHangul(String text) {
  const jungsung = [
    'ㅏ','ㅐ','ㅑ','ㅒ','ㅓ','ㅔ','ㅕ','ㅖ','ㅗ','ㅘ','ㅙ','ㅚ',
    'ㅛ','ㅜ','ㅝ','ㅞ','ㅟ','ㅠ','ㅡ','ㅢ','ㅣ',
  ];
  const jongsung = [
    '','ㄱ','ㄲ','ㄳ','ㄴ','ㄵ','ㄶ','ㄷ','ㄹ','ㄺ','ㄻ','ㄼ',
    'ㄽ','ㄾ','ㄿ','ㅀ','ㅁ','ㅂ','ㅄ','ㅅ','ㅆ','ㅇ','ㅈ','ㅉ',
    'ㅊ','ㅋ','ㅌ','ㅍ','ㅎ',
  ];
  final buf = StringBuffer();
  for (final c in text.runes) {
    if (c >= 0xAC00 && c <= 0xD7A3) {
      final offset = c - 0xAC00;
      buf.write(_chosung[offset ~/ 588]);
      buf.write(jungsung[(offset % 588) ~/ 28]);
      final jong = offset % 28;
      if (jong > 0) buf.write(jongsung[jong]);
    } else {
      buf.writeCharCode(c);
    }
  }
  return buf.toString();
}

bool _matchesQuery(String stationName, String query) {
  // 1. 직접 포함
  if (stationName.contains(query)) return true;
  // 2. 초성 매칭 (ㅈㄹ → 종로)
  if (_getChosung(stationName).contains(query)) return true;
  // 3. 자모 분해 매칭 (한글 입력 중간 상태 대응: "종로3ㄱ" → "종로3가" 매칭)
  if (_decomposeHangul(stationName).contains(_decomposeHangul(query))) return true;
  return false;
}

class StationSearchResult {
  final StationInfo station;
  final String lineId;
  final String lineName;
  final Color lineColor;
  const StationSearchResult({
    required this.station, required this.lineId,
    required this.lineName, required this.lineColor,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 검색바 + 길찾기
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// 네이버 지도 스타일 상수
const double _kBarHeight = 48.0;        // 검색바 높이 (네이버 지도 동일)
const double _kBarExpandedHeight = 52.0;
const double _kProfileSize = 48.0;      // 프로필 버튼 크기
const double _kBarRadius = 14.0;        // 모서리 반경
const double _kHPadding = 14.0;         // 좌우 패딩

class StationSearchBar extends StatefulWidget {
  final void Function(String stationName) onStationSelected;
  final void Function(PathResult route)? onRouteFound;
  final void Function(bool isNavMode)? onNavModeChanged;
  final void Function(bool isFocused)? onFocusChanged;
  final VoidCallback? onProfileTap;

  const StationSearchBar({
    super.key,
    required this.onStationSelected,
    this.onRouteFound,
    this.onNavModeChanged,
    this.onFocusChanged,
    this.onProfileTap,
  });

  @override
  State<StationSearchBar> createState() => _StationSearchBarState();
}

class _StationSearchBarState extends State<StationSearchBar>
    with TickerProviderStateMixin {
  // 검색
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<StationSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isFocused = false;

  // 길찾기
  bool _isNavMode = false;
  final TextEditingController _depCtrl = TextEditingController();
  final TextEditingController _arrCtrl = TextEditingController();
  final FocusNode _depFocus = FocusNode();
  final FocusNode _arrFocus = FocusNode();
  String? _depStation;
  String? _arrStation;
  List<StationSearchResult> _navResults = [];
  bool _isNavSearching = false;
  _NavField _activeField = _NavField.departure;

  // 경로
  PathSearchType _searchType = PathSearchType.duration;
  PathResult? _pathResult;
  bool _isPathLoading = false;
  final PathFindingService _pathService = PathFindingService();

  // 애니메이션
  late AnimationController _expandCtrl;
  late CurvedAnimation _expandAnim;
  late AnimationController _navCtrl;
  late CurvedAnimation _navAnim;
  late AnimationController _dropCtrl;
  late CurvedAnimation _dropAnim;

  late final List<StationSearchResult> _allStations;

  @override
  void initState() {
    super.initState();
    _buildCache();

    _expandCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

    _navCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _navAnim = CurvedAnimation(parent: _navCtrl, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

    _dropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _dropAnim = CurvedAnimation(parent: _dropCtrl, curve: Curves.easeOutCubic);

    _searchFocus.addListener(_onSearchFocusChanged);
    _depFocus.addListener(() { if (_depFocus.hasFocus) setState(() => _activeField = _NavField.departure); });
    _arrFocus.addListener(() { if (_arrFocus.hasFocus) setState(() => _activeField = _NavField.arrival); });
  }

  void _buildCache() {
    final list = <StationSearchResult>[];
    final seen = <String>{};
    for (final e in SubwayColors.lineColors.entries) {
      final ln = SubwayColors.lineNames[e.key] ?? e.key;
      for (final s in SeoulSubwayData.getLineStations(e.key)) {
        if (seen.add(s.name)) {
          list.add(StationSearchResult(station: s, lineId: e.key, lineName: ln, lineColor: e.value));
        }
      }
    }
    _allStations = list;
  }

  void _onSearchFocusChanged() {
    final f = _searchFocus.hasFocus;
    if (f == _isFocused) return;
    setState(() => _isFocused = f);
    f ? _expandCtrl.forward() : _expandCtrl.reverse();
    widget.onFocusChanged?.call(f);
    if (!f && _searchController.text.isEmpty) {
      setState(() { _isSearching = false; _searchResults = []; });
      _dropCtrl.reverse();
    }
  }

  List<StationSearchResult> _search(String q) {
    if (q.trim().isEmpty) return [];
    return _allStations.where((r) => _matchesQuery(r.station.name, q.trim())).take(15).toList();
  }

  // ── 일반 검색 ──
  void _onSearchChanged(String q) {
    final r = _search(q);
    setState(() { _searchResults = r; _isSearching = q.isNotEmpty; });
    // 텍스트가 있으면 드롭다운 유지 (결과 0개여도 닫지 않음 — 한글 IME 조합 중간 상태 대응)
    if (q.isNotEmpty && r.isNotEmpty) {
      _dropCtrl.forward(from: _dropCtrl.value > 0 ? _dropCtrl.value : 0);
    } else if (q.isEmpty) {
      _dropCtrl.reverse();
    }
  }

  void _selectSearch(StationSearchResult r) {
    _searchController.clear(); _searchFocus.unfocus(); _dropCtrl.reverse();
    setState(() { _isSearching = false; _searchResults = []; });
    widget.onStationSelected(r.station.name);
  }

  void _cancelSearch() {
    _searchController.clear(); _searchFocus.unfocus(); _dropCtrl.reverse();
    setState(() { _isSearching = false; _searchResults = []; });
  }

  // ── 길찾기 ──
  void _enterNav() {
    setState(() { _isNavMode = true; _cancelSearch(); });
    _navCtrl.forward();
    widget.onNavModeChanged?.call(true);
  }

  void _exitNav() {
    widget.onNavModeChanged?.call(false);
    _navCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _isNavMode = false; _depStation = null; _arrStation = null;
        _depCtrl.clear(); _arrCtrl.clear();
        _navResults = []; _isNavSearching = false; _pathResult = null;
      });
    });
  }

  void _onNavSearch(String q) {
    final r = _search(q);
    setState(() { _navResults = r; _isNavSearching = q.isNotEmpty; });
  }

  void _selectNav(StationSearchResult r) {
    setState(() {
      if (_activeField == _NavField.departure) {
        _depStation = r.station.name; _depCtrl.text = r.station.name; _depFocus.unfocus();
        if (_arrStation == null) Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _arrFocus.requestFocus(); });
      } else {
        _arrStation = r.station.name; _arrCtrl.text = r.station.name; _arrFocus.unfocus();
      }
      _navResults = []; _isNavSearching = false;
    });
    if (_depStation != null && _arrStation != null) _findPath();
  }

  void _swapStations() {
    setState(() {
      final t = _depStation; _depStation = _arrStation; _arrStation = t;
      _depCtrl.text = _depStation ?? ''; _arrCtrl.text = _arrStation ?? '';
    });
    if (_depStation != null && _arrStation != null) _findPath();
  }

  Future<void> _findPath() async {
    if (_depStation == null || _arrStation == null) return;
    setState(() { _isPathLoading = true; _pathResult = null; });
    final r = await _pathService.findPath(departure: _depStation!, arrival: _arrStation!, searchType: _searchType);
    if (mounted) {
      setState(() { _pathResult = r; _isPathLoading = false; });
      if (r != null) widget.onRouteFound?.call(r);
    }
  }

  @override
  void dispose() {
    _searchController.dispose(); _searchFocus.dispose();
    _depCtrl.dispose(); _arrCtrl.dispose(); _depFocus.dispose(); _arrFocus.dispose();
    _expandCtrl.dispose(); _navCtrl.dispose(); _dropCtrl.dispose();
    super.dispose();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Build
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _dismissKeyboard() {
    _searchFocus.unfocus();
    _depFocus.unfocus();
    _arrFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final anyFocused = _isFocused || _depFocus.hasFocus || _arrFocus.hasFocus;

    return Stack(
      children: [
        // ── 일반 검색 모드 ──
        if (!_isNavMode) ...[
          Positioned(
            top: top + AppSpacing.sm,
            left: _kHPadding,
            right: _kHPadding,
            child: Row(
              children: [
                Expanded(child: _buildSearchBar()),
                const SizedBox(width: AppSpacing.sm),
                _buildNavButton(),
                const SizedBox(width: AppSpacing.sm),
                _buildProfile(),
              ],
            ),
          ),
          if (_isSearching && _searchResults.isNotEmpty)
            Positioned(
              top: top + AppSpacing.sm + _kBarHeight + AppSpacing.sm,
              left: _kHPadding,
              right: _kHPadding,
              child: AnimatedBuilder(
                animation: _dropAnim,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -6 * (1 - _dropAnim.value)),
                  child: Opacity(opacity: _dropAnim.value, child: child),
                ),
                child: _buildDropdown(_searchResults, _selectSearch),
              ),
            ),
        ],

        // ── 길찾기 모드 ──
        if (_isNavMode)
          Positioned(
            top: top,
            left: 0, right: 0,
            child: Column(
              children: [
                _buildNavHeader(),
                if (_isNavSearching && _navResults.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _kHPadding),
                    child: _buildDropdown(_navResults, _selectNav),
                  ),
                if (!_isNavSearching && _depStation != null && _arrStation != null)
                  _buildRouteResult(),
              ],
            ),
          ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 검색바 (네이버 지도 크기 + 리퀴드 글라스)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildSearchBar() {
    return _GlassSearchField(
      controller: _searchController,
      focusNode: _searchFocus,
      onChanged: _onSearchChanged,
      onSubmitted: () { if (_searchResults.isNotEmpty) _selectSearch(_searchResults.first); },
      onClear: _cancelSearch,
      onProfileTap: widget.onProfileTap,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 프로필 버튼 (리퀴드 글라스, 48×48)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildNavButton() {
    return Semantics(
      label: '길찾기',
      button: true,
      child: AdaptiveGlassIconButton(
        icon: CupertinoIcons.arrow_turn_down_right,
        onPressed: _enterNav,
        size: _kProfileSize,
        iconSize: 20,
      ),
    );
  }

  Widget _buildProfile() {
    return Semantics(
      label: '프로필',
      button: true,
      child: AdaptiveGlassIconButton(
        icon: CupertinoIcons.person_fill,
        onPressed: widget.onProfileTap ?? () {},
        size: _kProfileSize,
        iconSize: 22,
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 길찾기 모드
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildNavHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(_kHPadding, 8, _kHPadding, 0),
      child: AdaptiveGlassContainer.rect(
        cornerRadius: _kBarRadius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // 출발/도착 레일
                  Column(
                    children: [
                      Container(
                        width: AppSpacing.md, height: AppSpacing.md,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.success, width: 2.5),
                        ),
                      ),
                      Container(width: 1.5, height: AppSpacing.xl, color: AppColors.borderSubtle),
                      Icon(Icons.place, size: AppSpacing.lg, color: AppColors.danger),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      children: [
                        _buildNavField(_depCtrl, _depFocus, '출발역'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildNavField(_arrCtrl, _arrFocus, '도착역'),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    children: [
                      _circleButton(CupertinoIcons.arrow_up_arrow_down, _swapStations, '출발역·도착역 교환'),
                      const SizedBox(height: AppSpacing.sm),
                      _circleButton(CupertinoIcons.xmark, _exitNav, '길찾기 닫기'),
                    ],
                  ),
                ],
              ),
              if (_depStation != null && _arrStation != null) ...[
                const SizedBox(height: AppSpacing.md),
                _buildTypeTabs(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, String label) {
    return AppCircleButton(
      icon: icon,
      onTap: onTap,
      semanticLabel: label,
      size: AppSpacing.buttonLg,
      iconSize: 15,
    );
  }

  Widget _buildNavField(TextEditingController ctrl, FocusNode focus, String hint) {
    final isM3 = Platform.isAndroid;
    final cs = Theme.of(context).colorScheme;
    const navTextColor = Color(0xFFB0B0B0);
    const navPlaceholder = Color(0xFF8E8E93);

    return SizedBox(
      height: AppSpacing.inputHeight,
      child: AdaptiveTextField(
        controller: ctrl,
        focusNode: focus,
        placeholder: hint,
        placeholderStyle: TextStyle(
          color: isM3 ? cs.onSurfaceVariant.withValues(alpha: 0.6) : navPlaceholder,
          fontSize: 14,
        ),
        style: AppTypography.bodyMd.copyWith(
          color: isM3 ? cs.onSurface : navTextColor,
        ),
        decoration: BoxDecoration(
          color: isM3 ? cs.surfaceContainerHighest : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(isM3 ? 12.0 : AppSpacing.radiusMd),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: isM3 ? 12 : 0,
        ),
        onChanged: _onNavSearch,
        onSubmitted: (_) { if (_navResults.isNotEmpty) _selectNav(_navResults.first); },
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Row(
      children: PathSearchType.values.map((type) {
        final sel = _searchType == type;
        final label = switch (type) {
          PathSearchType.duration => '최소시간',
          PathSearchType.distance => '최단거리',
          PathSearchType.transfer => '최소환승',
        };
        final icon = switch (type) {
          PathSearchType.duration => CupertinoIcons.clock,
          PathSearchType.distance => CupertinoIcons.map,
          PathSearchType.transfer => CupertinoIcons.arrow_swap,
        };
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _searchType = type); _findPath(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 7),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: sel ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: sel ? Theme.of(context).colorScheme.primary : Colors.white12, width: sel ? 1.2 : 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 13, color: sel ? Theme.of(context).colorScheme.primary : AppColors.textTertiary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(label, style: AppTypography.bodySm.copyWith(
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    color: sel ? Theme.of(context).colorScheme.primary : AppColors.textTertiary,
                  )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 경로 결과
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildRouteResult() {
    if (_isPathLoading) {
      return _resultCard(
        child: Column(children: [
          Platform.isAndroid
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const CupertinoActivityIndicator(),
          const SizedBox(height: AppSpacing.sm),
          Text('경로 검색 중...', style: AppTypography.bodySm.copyWith(color: AppColors.textTertiary)),
        ]),
      );
    }

    if (_pathResult == null) {
      return _resultCard(
        child: Text('경로를 찾을 수 없습니다', style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled), textAlign: TextAlign.center),
      );
    }

    final r = _pathResult!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Transform.translate(
        offset: Offset(0, 10 * (1 - v)),
        child: Opacity(opacity: v, child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_kHPadding, 6, _kHPadding, 0),
        child: _overlayCard(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.42),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 요약
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                child: Row(
                  children: [
                    Text(r.totalTimeFormatted, style: AppTypography.displayLg),
                    const SizedBox(width: AppSpacing.md),
                    if (r.transferCount > 0) _badge('환승 ${r.transferCount}회', AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    _badge('${r.totalDistanceKm.toStringAsFixed(1)}km', AppColors.textDisabled),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${r.segments.length}개 구간', style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled)),
                        if (r.isLocal) Text('로컬 계산', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: r.segments.length,
                  itemBuilder: (_, i) => _buildSegTile(r.segments[i], i, r.segments.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kHPadding, AppSpacing.sm, _kHPadding, 0),
      child: _overlayCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(child: child),
      ),
    );
  }

  /// 지도 위 오버레이 카드 — iOS: 글라스, Android: M3 Surface
  Widget _overlayCard({
    required Widget child,
    BoxConstraints? constraints,
    EdgeInsets? padding,
  }) {
    if (Platform.isAndroid) {
      final cs = Theme.of(context).colorScheme;
      return Material(
        elevation: 3,
        shadowColor: cs.shadow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(_kBarRadius),
        color: cs.surfaceContainer,
        surfaceTintColor: cs.surfaceTint,
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: constraints,
          padding: padding,
          child: child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_kBarRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: constraints,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: AppColors.glassDropOpacity),
            borderRadius: BorderRadius.circular(_kBarRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _badge(String text, Color c) {
    return AppBadge(text: text, color: c, fontWeight: FontWeight.w600);
  }

  Widget _buildSegTile(PathSegment seg, int i, int total) {
    final c = SubwayColors.lineColors[seg.lineId] ?? Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSpacing.xxl,
            child: Column(children: [
              if (i > 0) Container(width: 2, height: AppSpacing.sm, color: c.withValues(alpha: 0.4)),
              Container(
                width: AppSpacing.md, height: AppSpacing.md,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: seg.isTransfer ? Colors.transparent : c,
                  border: Border.all(color: c, width: 2),
                ),
                child: seg.isTransfer ? Icon(Icons.swap_vert, size: AppSpacing.sm, color: AppColors.textSecondary) : null,
              ),
              if (i < total - 1) Container(width: 2, height: 28, color: c.withValues(alpha: 0.4)),
            ]),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(AppSpacing.xs)),
                    child: Text(seg.lineName, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (seg.travelTimeSec > 0) Text('${(seg.travelTimeSec / 60).ceil()}분', style: AppTypography.bodySm.copyWith(color: AppColors.textTertiary)),
                  if (seg.distanceKm > 0) ...[const SizedBox(width: AppSpacing.xs), Text('${seg.distanceKm.toStringAsFixed(1)}km', style: AppTypography.caption.copyWith(color: AppColors.textMuted))],
                ]),
                if (seg.stations.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(seg.stations.join(' → '), style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 드롭다운
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildDropdown(List<StationSearchResult> results, void Function(StationSearchResult) onSelect) {
    final isM3 = Platform.isAndroid;

    if (isM3) {
      final cs = Theme.of(context).colorScheme;
      return Material(
        elevation: 3,
        shadowColor: cs.shadow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(_kBarRadius),
        color: cs.surfaceContainer,
        surfaceTintColor: cs.surfaceTint,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 48, color: cs.outlineVariant.withValues(alpha: 0.5)),
            itemBuilder: (_, i) => _buildTile(results[i], onSelect),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_kBarRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: AppColors.glassDropOpacity),
            borderRadius: BorderRadius.circular(_kBarRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 48, color: AppColors.divider),
            itemBuilder: (_, i) => _buildTile(results[i], onSelect),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(StationSearchResult r, void Function(StationSearchResult) onSelect) {
    final hasTrf = r.station.transferLines.isNotEmpty;
    return GestureDetector(
      onTap: () => onSelect(r),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: r.lineColor, shape: BoxShape.circle),
            child: Center(child: Text(_shortLine(r.lineName), style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.station.name, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
              if (hasTrf) Text('환승: ${r.station.transferLines.map((id) => SubwayColors.lineNames[id] ?? id).join(', ')}', style: AppTypography.caption.copyWith(color: AppColors.textDisabled)),
            ]),
          ),
          Text(r.lineName, style: AppTypography.bodySm.copyWith(color: r.lineColor)),
        ]),
      ),
    );
  }

  String _shortLine(String n) {
    if (n.endsWith('호선')) return n.replaceAll('호선', '');
    return n.length > 2 ? n.substring(0, 2) : n;
  }
}

enum _NavField { departure, arrival }

/// 리퀴드 글라스 검색 필드 — 별도 위젯으로 분리하여 부모 setState 시 리빌드 차단
class _GlassSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;
  final VoidCallback? onProfileTap;

  const _GlassSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    this.onProfileTap,
  });

  @override
  State<_GlassSearchField> createState() => _GlassSearchFieldState();
}

class _GlassSearchFieldState extends State<_GlassSearchField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 250),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode.hasFocus) {
      _pressCtrl.forward().then((_) {
        if (mounted) _pressCtrl.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 리퀴드 글라스 위 텍스트: 밝은/어두운 배경 모두에서 보이는 중간 회색
    const textColor = Color(0xFFB0B0B0);
    const placeholderColor = Color(0xFF8E8E93);    // iOS systemGrey

    final glassBar = SizedBox(
      height: _kBarHeight,
      child: AdaptiveGlassContainer.capsule(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              const Icon(CupertinoIcons.search, size: 20, color: placeholderColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AdaptiveSearchField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  placeholder: '지하철역 검색',
                  placeholderStyle: const TextStyle(color: placeholderColor, fontSize: 14, fontWeight: FontWeight.w400),
                  style: AppTypography.bodyMd.copyWith(color: textColor),
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (_, value, __) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return Semantics(
                    label: '검색어 지우기',
                    button: true,
                    child: GestureDetector(
                      onTap: widget.onClear,
                      child: const Padding(
                        padding: EdgeInsets.only(left: AppSpacing.sm),
                        child: Icon(CupertinoIcons.xmark_circle_fill, size: 20, color: placeholderColor),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _pressCtrl,
      builder: (context, child) {
        final t = _pressCtrl.value;
        return Transform.scale(
          scale: 1.0 - (t * 0.03),
          child: Opacity(opacity: 1.0 - (t * 0.08), child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        behavior: HitTestBehavior.translucent,
        child: glassBar,
      ),
    );
  }
}
