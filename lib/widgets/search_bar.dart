import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/recent_search_service.dart';
import '../services/directions_service.dart';
import '../data/river_bus_data.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'adaptive/adaptive.dart';
import '../data/seoul_subway_data.dart';
import '../models/subway_models.dart';
import '../models/bus_models.dart';
import '../services/path_finding_service.dart';
import '../services/place_search_service.dart';
import '../services/seoul_bus_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'app_badge.dart';
import 'bus_overlay.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 한글 초성 검색 유틸
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const List<String> _chosung = [
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
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
    'ㅏ',
    'ㅐ',
    'ㅑ',
    'ㅒ',
    'ㅓ',
    'ㅔ',
    'ㅕ',
    'ㅖ',
    'ㅗ',
    'ㅘ',
    'ㅙ',
    'ㅚ',
    'ㅛ',
    'ㅜ',
    'ㅝ',
    'ㅞ',
    'ㅟ',
    'ㅠ',
    'ㅡ',
    'ㅢ',
    'ㅣ',
  ];
  const jongsung = [
    '',
    'ㄱ',
    'ㄲ',
    'ㄳ',
    'ㄴ',
    'ㄵ',
    'ㄶ',
    'ㄷ',
    'ㄹ',
    'ㄺ',
    'ㄻ',
    'ㄼ',
    'ㄽ',
    'ㄾ',
    'ㄿ',
    'ㅀ',
    'ㅁ',
    'ㅂ',
    'ㅄ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ',
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
  if (_decomposeHangul(stationName).contains(_decomposeHangul(query)))
    return true;
  return false;
}

class StationSearchResult {
  final StationInfo station;
  final String lineId;
  final String lineName;
  final Color lineColor;
  // 같은 이름의 역이 등장하는 모든 노선 ID (자기 노선 포함, 자기 노선이 첫 번째).
  // transferLines 데이터가 노선별로 비대칭하게 정의돼 있어도 누락 없이 환승역을 표현하기 위함.
  final List<String> allLineIds;
  const StationSearchResult({
    required this.station,
    required this.lineId,
    required this.lineName,
    required this.lineColor,
    this.allLineIds = const [],
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 검색바 + 길찾기
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// 네이버 지도 스타일 상수
const double _kBarHeight = 48.0; // 검색바 높이 (네이버 지도 동일)
const double _kBarExpandedHeight = 52.0;
const double _kProfileSize = 48.0; // 프로필 버튼 크기
const double _kBarRadius = 14.0; // 모서리 반경
const double _kHPadding = 14.0; // 좌우 패딩

class UnifiedSearchBar extends StatefulWidget {
  final void Function(String stationName) onStationSelected;
  final void Function(PlaceSearchResult place)? onPlaceSelected;
  final void Function(BusRouteInfo route)? onBusSelected;
  final void Function(RiverBusStop stop)? onRiverBusStopSelected;
  final void Function(PathResult route)? onRouteFound;
  final void Function(PathResult route)? onRouteDetailRequested;
  final void Function(DirectionsResult result)? onDirectionsFound;
  final void Function(bool isNavMode)? onNavModeChanged;
  final void Function(bool isFocused)? onFocusChanged;
  final VoidCallback? onProfileTap;

  const UnifiedSearchBar({
    super.key,
    required this.onStationSelected,
    this.onPlaceSelected,
    this.onBusSelected,
    this.onRiverBusStopSelected,
    this.onRouteFound,
    this.onRouteDetailRequested,
    this.onDirectionsFound,
    this.onNavModeChanged,
    this.onFocusChanged,
    this.onProfileTap,
  });

  @override
  UnifiedSearchBarState createState() => UnifiedSearchBarState();
}

class UnifiedSearchBarState extends State<UnifiedSearchBar>
    with TickerProviderStateMixin {
  /// 외부에서 길찾기 모드 진입 + 출발지 설정
  void enterNavWithDeparture(String name) {
    _enterNav();
    setState(() {
      _depStation = name;
      _depCtrl.text = name;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _arrFocus.requestFocus();
    });
  }

  /// 외부에서 검색 실행
  void performSearch(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
    _searchFocus.requestFocus();
  }

  /// 외부에서 길찾기 모드 진입 + 도착지 설정
  void enterNavWithArrival(String name) {
    _enterNav();
    setState(() {
      _arrStation = name;
      _arrCtrl.text = name;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _depFocus.requestFocus();
    });
  }

  // 검색
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<StationSearchResult> _searchResults = [];
  List<PlaceSearchResult> _placeResults = [];
  List<BusRouteInfo> _busResults = [];
  bool _isSearching = false;
  bool _isFocused = false;
  Timer? _placeSearchDebounce;
  final PlaceSearchService _placeService = PlaceSearchService.instance;
  final SeoulBusService _busService = SeoulBusService.instance;

  // 길찾기
  bool _isNavMode = false;
  final TextEditingController _depCtrl = TextEditingController();
  final TextEditingController _arrCtrl = TextEditingController();
  final FocusNode _depFocus = FocusNode();
  final FocusNode _arrFocus = FocusNode();
  String? _depStation;
  String? _arrStation;
  double? _depLat, _depLng; // 장소 좌표 (역이 아닐 때)
  double? _arrLat, _arrLng;
  List<StationSearchResult> _navResults = [];
  bool _isNavSearching = false;
  bool _showCurrentLocationResult = false;
  _NavField _activeField = _NavField.departure;

  // 경로 — 3개 타입 동시 조회
  PathSearchType _searchType = PathSearchType.duration;

  // 교통수단 모드
  int _transportMode = 0; // 0: 대중교통, 1: 도보, 2: 자전거, 3: 자동차
  DirectionsResult? _directionsResult;
  bool _directionsLoading = false;
  PathResult? _pathResult;
  Map<PathSearchType, PathResult> _allRoutes = {};
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

    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _navCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _navAnim = CurvedAnimation(
      parent: _navCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _dropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _dropAnim = CurvedAnimation(parent: _dropCtrl, curve: Curves.easeOutCubic);

    _searchFocus.addListener(_onSearchFocusChanged);
    _depFocus.addListener(() {
      if (_depFocus.hasFocus)
        setState(() => _activeField = _NavField.departure);
    });
    _arrFocus.addListener(() {
      if (_arrFocus.hasFocus) setState(() => _activeField = _NavField.arrival);
    });
  }

  void _buildCache() {
    // 1단계: 역명별로 등장하는 모든 노선 ID 수집.
    // 노선 데이터의 transferLines 가 비대칭으로 누락된 경우에도, 역이 등장하는 노선 자체를 합집합으로 잡아 환승역을 정확히 식별한다.
    final lineIdsByName = <String, Set<String>>{};
    for (final e in SubwayColors.lineColors.entries) {
      for (final s in SeoulSubwayData.getLineStations(e.key)) {
        final set = lineIdsByName.putIfAbsent(s.name, () => <String>{});
        set.add(e.key);
        // transferLines 도 함께 합쳐 누락된 노선 ID 까지 보강.
        for (final tl in s.transferLines) {
          if (SubwayColors.lineColors.containsKey(tl)) set.add(tl);
        }
      }
    }

    final list = <StationSearchResult>[];
    final seen = <String>{};
    for (final e in SubwayColors.lineColors.entries) {
      final ln = SubwayColors.lineNames[e.key] ?? e.key;
      for (final s in SeoulSubwayData.getLineStations(e.key)) {
        if (seen.add(s.name)) {
          final ids = lineIdsByName[s.name] ?? <String>{e.key};
          // 자기 노선이 맨 앞에 오도록 정렬 (단일 노선 색이 우선 표시되도록).
          final ordered = <String>[
            e.key,
            ...ids.where((id) => id != e.key),
          ];
          list.add(
            StationSearchResult(
              station: s,
              lineId: e.key,
              lineName: ln,
              lineColor: e.value,
              allLineIds: ordered,
            ),
          );
        }
      }
    }
    // 한강버스 선착장 추가 (활성 노선의 선착장만)
    final activeStopIds = <String>{};
    for (final route in RiverBusData.routes) {
      if (route.isActive) activeStopIds.addAll(route.stopIds);
    }
    for (final stop in RiverBusData.stops) {
      if (!activeStopIds.contains(stop.id)) continue;
      final name = '한강버스 ${stop.name} 선착장';
      if (seen.add(name)) {
        list.add(
          StationSearchResult(
            station: StationInfo(
              id: stop.id,
              name: name,
              lat: stop.lat,
              lng: stop.lng,
              transferLines: [],
              isUnderground: false,
            ),
            lineId: 'river',
            lineName: '한강버스',
            lineColor: const Color(0xFF00ACC1),
            allLineIds: const ['river'],
          ),
        );
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
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      _dropCtrl.reverse();
    }
  }

  List<StationSearchResult> _search(String q) {
    if (q.trim().isEmpty) return [];
    final matched = _allStations
        .where((r) => _matchesQuery(r.station.name, q.trim()))
        .toList();
    // 한강버스 선착장을 상위에 표시 (정확 매칭 우선)
    matched.sort((a, b) {
      final aExact = a.station.name.startsWith(q.trim()) ? 0 : 1;
      final bExact = b.station.name.startsWith(q.trim()) ? 0 : 1;
      return aExact.compareTo(bExact);
    });
    return matched.take(15).toList();
  }

  // ── 일반 검색 ──
  void _onSearchChanged(String q) {
    // 지하철역 로컬 검색 (즉시)
    final r = _search(q);
    setState(() {
      _searchResults = r;
      _isSearching = q.isNotEmpty;
    });

    if (q.isEmpty) {
      _dropCtrl.reverse();
      setState(() => _placeResults = []);
      return;
    }

    // 결과 있으면 드롭다운 열기
    if (r.isNotEmpty) {
      _dropCtrl.forward(from: _dropCtrl.value > 0 ? _dropCtrl.value : 0);
    }

    // 장소 + 버스 검색 (타이핑마다 즉시 호출)
    _placeSearchDebounce?.cancel();
    if (q.trim().length >= 2) {
      _searchPlacesAndBus(q);
    } else {
      setState(() {
        _placeResults = [];
        _busResults = [];
      });
    }
  }

  Future<void> _searchPlacesAndBus(String q) async {
    final futures = await Future.wait([
      _placeService.search(q),
      _busService.searchRoutes(q.trim()),
    ]);
    if (mounted && _searchController.text == q) {
      // 카카오 결과에서 로컬 매핑에 이미 있는 지하철역/한강버스 제거
      final kakaoPlaces = _filterDuplicatePlaces(
        futures[0] as List<PlaceSearchResult>,
      );

      setState(() {
        _placeResults = kakaoPlaces;
        _busResults = futures[1] as List<BusRouteInfo>;
      });
      if (_placeResults.isNotEmpty || _busResults.isNotEmpty) {
        _dropCtrl.forward(from: _dropCtrl.value > 0 ? _dropCtrl.value : 0);
      }
    }
  }

  void _selectSearch(StationSearchResult r) {
    RecentSearchService.instance.add(r.station.name);
    _searchController.clear();
    _searchFocus.unfocus();
    _dropCtrl.reverse();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _placeResults = [];
      _busResults = [];
    });

    // 한강버스 선착장이면 전용 콜백
    if (r.lineId == 'river') {
      final stop = RiverBusData.findStop(r.station.id);
      if (stop != null) {
        widget.onRiverBusStopSelected?.call(stop);
        return;
      }
    }
    widget.onStationSelected(r.station.name);
  }

  void _selectPlace(PlaceSearchResult place) {
    RecentSearchService.instance.add(place.name);
    _searchController.clear();
    _searchFocus.unfocus();
    _dropCtrl.reverse();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _placeResults = [];
      _busResults = [];
    });

    // 한강버스 선착장이면 전용 콜백
    if (place.category == '한강버스') {
      final stop = RiverBusData.stops.firstWhere(
        (s) => place.name.contains(s.name),
        orElse: () => RiverBusData.stops.first,
      );
      widget.onRiverBusStopSelected?.call(stop);
    } else {
      widget.onPlaceSelected?.call(place);
    }
  }

  void _selectBus(BusRouteInfo route) {
    RecentSearchService.instance.add(route.busRouteNm);
    _searchController.clear();
    _searchFocus.unfocus();
    _dropCtrl.reverse();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _placeResults = [];
      _busResults = [];
    });
    widget.onBusSelected?.call(route);
  }

  void _cancelSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    _dropCtrl.reverse();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _placeResults = [];
      _busResults = [];
    });
  }

  // ── 길찾기 ──
  void _enterNav() {
    setState(() {
      _isNavMode = true;
      _cancelSearch();
      // 출발지를 내 위치로 기본 설정
      _depStation = '내 위치';
      _depCtrl.text = '내 위치';
      _depLat = null;
      _depLng = null;
    });
    _setCurrentLocationForField(_NavField.departure, autoFind: false);
    _navCtrl.forward();
    widget.onNavModeChanged?.call(true);
    // 도착지 포커스
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _arrFocus.requestFocus();
    });
  }

  void _exitNav() {
    widget.onNavModeChanged?.call(false);
    _navCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _isNavMode = false;
        _depStation = null;
        _arrStation = null;
        _depCtrl.clear();
        _arrCtrl.clear();
        _depLat = null;
        _depLng = null;
        _arrLat = null;
        _arrLng = null;
        _navResults = [];
        _isNavSearching = false;
        _showCurrentLocationResult = false;
        _pathResult = null;
      });
    });
  }

  List<PlaceSearchResult> _navPlaceResults = [];

  void _onNavSearch(String q) {
    final query = q.trim();
    final r = _search(q);
    final showCurrentLocation = _isCurrentLocationQuery(query);
    setState(() {
      _navResults = r;
      _isNavSearching = query.isNotEmpty;
      _showCurrentLocationResult = showCurrentLocation;
      _navPlaceResults = [];
    });

    // 장소도 검색
    if (query.length >= 2) {
      _placeService.search(q).then((places) {
        if (mounted &&
            ((_activeField == _NavField.departure
                    ? _depCtrl.text
                    : _arrCtrl.text) ==
                q)) {
          setState(() => _navPlaceResults = _filterDuplicatePlaces(places));
        }
      });
    }
  }

  bool _isCurrentLocationQuery(String q) {
    if (q.isEmpty) return false;
    final compact = q.replaceAll(' ', '').toLowerCase();
    return '내위치'.contains(compact) ||
        '현재위치'.contains(compact) ||
        compact == 'location' ||
        compact == 'currentlocation';
  }

  List<PlaceSearchResult> _filterDuplicatePlaces(
    List<PlaceSearchResult> places,
  ) {
    return places.where((p) {
      final isSubwayCategory =
          p.category.contains('지하철') ||
          p.category.contains('전철') ||
          p.category.contains('교통') ||
          p.category == '지하철역';
      final cleanName = p.name
          .replaceAll(
            RegExp(
              r'(GTX-?\w+|공항철도|경의중앙선|신분당선|경춘선|경강선|수인분당선|서해선|인천[12]호선|의정부경전철|용인경전철|김포골드라인|신림선|우이신설선|동해선|수도권\d+호선)\s*',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'\s*\d+호선.*'), '')
          .replaceAll(RegExp(r'\s*역\s*$'), '')
          .replaceAll(RegExp(r'역\s*$'), '')
          .replaceAll(' ', '')
          .trim();
      final isExactMatch = _allStations.any((s) {
        final localName = s.station.name.replaceAll(' ', '');
        final localBase = localName
            .replaceAll(RegExp(r'역$'), '')
            .replaceAll(RegExp(r'\(.*\)'), '');
        return localName == cleanName ||
            localBase == cleanName ||
            localName == '${cleanName}역' ||
            localBase == cleanName.replaceAll(RegExp(r'\(.*\)'), '');
      });
      if (isSubwayCategory && isExactMatch) return false;
      if (RegExp(r'^.+역$').hasMatch(p.name.trim()) && isExactMatch) {
        return false;
      }
      if (p.name.contains('선착장') || p.name.contains('한강버스')) {
        return !RiverBusData.stops.any((s) => p.name.contains(s.name));
      }
      return true;
    }).toList();
  }

  void _selectNav(StationSearchResult r) {
    setState(() {
      if (_activeField == _NavField.departure) {
        _depStation = r.station.name;
        _depCtrl.text = r.station.name;
        _depFocus.unfocus();
        _depLat = null;
        _depLng = null; // 역이므로 좌표 불필요
        if (_arrStation == null)
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _arrFocus.requestFocus();
          });
      } else {
        _arrStation = r.station.name;
        _arrCtrl.text = r.station.name;
        _arrFocus.unfocus();
        _arrLat = null;
        _arrLng = null;
      }
      _navResults = [];
      _isNavSearching = false;
      _showCurrentLocationResult = false;
    });
    if (_depStation != null && _arrStation != null) _findPath();
  }

  void _swapStations() {
    setState(() {
      final t = _depStation;
      _depStation = _arrStation;
      _arrStation = t;
      final tLat = _depLat;
      final tLng = _depLng;
      _depLat = _arrLat;
      _depLng = _arrLng;
      _arrLat = tLat;
      _arrLng = tLng;
      _depCtrl.text = _depStation ?? '';
      _arrCtrl.text = _arrStation ?? '';
    });
    if (_depStation != null && _arrStation != null) _findPath();
  }

  Future<void> _findPath() async {
    if (_depStation == null || _arrStation == null) return;
    await _ensureCurrentLocationCoords();
    if (_depStation == null || _arrStation == null) return;
    setState(() {
      _isPathLoading = true;
      _pathResult = null;
      _allRoutes = {};
    });

    final results = await Future.wait([
      _pathService.findPath(
        departure: _depStation!,
        arrival: _arrStation!,
        searchType: PathSearchType.duration,
        departureLat: _depLat,
        departureLng: _depLng,
        arrivalLat: _arrLat,
        arrivalLng: _arrLng,
      ),
      _pathService.findPath(
        departure: _depStation!,
        arrival: _arrStation!,
        searchType: PathSearchType.distance,
        departureLat: _depLat,
        departureLng: _depLng,
        arrivalLat: _arrLat,
        arrivalLng: _arrLng,
      ),
      _pathService.findPath(
        departure: _depStation!,
        arrival: _arrStation!,
        searchType: PathSearchType.transfer,
        departureLat: _depLat,
        departureLng: _depLng,
        arrivalLat: _arrLat,
        arrivalLng: _arrLng,
      ),
    ]);

    if (!mounted) return;

    final routes = <PathSearchType, PathResult>{};
    if (results[0] != null) routes[PathSearchType.duration] = results[0]!;
    if (results[1] != null) routes[PathSearchType.distance] = results[1]!;
    if (results[2] != null) routes[PathSearchType.transfer] = results[2]!;

    final seen = <int>{};
    final deduped = <PathSearchType, PathResult>{};
    for (final entry in routes.entries) {
      if (seen.add(entry.value.totalTimeSec)) {
        deduped[entry.key] = entry.value;
      }
    }

    final selected = deduped[_searchType] ?? deduped.values.firstOrNull;
    setState(() {
      _allRoutes = deduped;
      _pathResult = selected;
      _isPathLoading = false;
    });
    if (selected != null) widget.onRouteFound?.call(selected);
  }

  Future<void> _ensureCurrentLocationCoords() async {
    if (_depStation == '내 위치' && (_depLat == null || _depLng == null)) {
      await _setCurrentLocationForField(_NavField.departure, autoFind: false);
    }
    if (_arrStation == '내 위치' && (_arrLat == null || _arrLng == null)) {
      await _setCurrentLocationForField(_NavField.arrival, autoFind: false);
    }
  }

  Future<void> _setCurrentLocationForField(
    _NavField field, {
    bool autoFind = true,
  }) async {
    try {
      final pos = await PlaceSearchService.instance.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        if (field == _NavField.departure) {
          _depStation = '내 위치';
          _depCtrl.text = '내 위치';
          _depLat = pos.latitude;
          _depLng = pos.longitude;
          _depFocus.unfocus();
        } else {
          _arrStation = '내 위치';
          _arrCtrl.text = '내 위치';
          _arrLat = pos.latitude;
          _arrLng = pos.longitude;
          _arrFocus.unfocus();
        }
        _navResults = [];
        _navPlaceResults = [];
        _isNavSearching = false;
        _showCurrentLocationResult = false;
      });
      if (autoFind && _depStation != null && _arrStation != null) {
        _findPath();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (field == _NavField.departure) {
          _depStation = null;
          _depCtrl.clear();
        } else {
          _arrStation = null;
          _arrCtrl.clear();
        }
      });
    }
  }

  void _setTransportMode(int mode) {
    setState(() => _transportMode = mode);
    if (mode == 0) {
      // 대중교통 — 기존 지하철 길찾기
      if (_depStation != null && _arrStation != null) _findPath();
    } else {
      // 도보/자전거/자동차 — Directions API
      _findDirections(mode);
    }
  }

  Future<void> _findDirections(int mode) async {
    if (_depStation == null || _arrStation == null) return;
    setState(() {
      _directionsLoading = true;
      _directionsResult = null;
    });

    // 이름 → 좌표
    final fromCoord = await _resolveCoord(_depStation!);
    final toCoord = await _resolveCoord(_arrStation!);
    if (fromCoord == null || toCoord == null) {
      setState(() => _directionsLoading = false);
      return;
    }

    DirectionsResult? result;
    final ds = DirectionsService.instance;
    if (mode == 1) {
      result = await ds.getWalkingRoute(
        fromCoord[0],
        fromCoord[1],
        toCoord[0],
        toCoord[1],
      );
    } else if (mode == 2) {
      // 미사용
    } else if (mode == 3) {
      result = await ds.getDrivingRoute(
        fromCoord[0],
        fromCoord[1],
        toCoord[0],
        toCoord[1],
      );
    }

    if (mounted) {
      setState(() {
        _directionsResult = result;
        _directionsLoading = false;
      });
      if (result != null) widget.onDirectionsFound?.call(result);
    }
  }

  Future<List<double>?> _resolveCoord(String name) async {
    // "내 위치"
    if (name == '내 위치') {
      try {
        final pos = await PlaceSearchService.instance.getCurrentPosition();
        return [pos.latitude, pos.longitude];
      } catch (_) {
        return null;
      }
    }
    // 지하철역
    final station = _allStations
        .where((s) => s.station.name == name || s.station.name.contains(name))
        .firstOrNull;
    if (station != null) return [station.station.lat, station.station.lng];
    // 카카오 검색
    final places = await PlaceSearchService.instance.search(name);
    if (places.isNotEmpty) return [places.first.lat, places.first.lng];
    return null;
  }

  @override
  void dispose() {
    _placeSearchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _depCtrl.dispose();
    _arrCtrl.dispose();
    _depFocus.dispose();
    _arrFocus.dispose();
    _expandCtrl.dispose();
    _navCtrl.dispose();
    _dropCtrl.dispose();
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
          if (_isSearching &&
              (_searchResults.isNotEmpty ||
                  _placeResults.isNotEmpty ||
                  _busResults.isNotEmpty))
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
                child: _buildCombinedDropdown(),
              ),
            )
          else if (_isFocused &&
              !_isSearching &&
              RecentSearchService.instance.items.isNotEmpty)
            Positioned(
              top: top + AppSpacing.sm + _kBarHeight + AppSpacing.sm,
              left: _kHPadding,
              right: _kHPadding,
              child: _buildRecentSearchDropdown(),
            ),
        ],

        // ── 길찾기 모드 ──
        if (_isNavMode)
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // 경로 결과 있으면 컴팩트 헤더, 없으면 편집 헤더
                _pathResult != null &&
                        !_depFocus.hasFocus &&
                        !_arrFocus.hasFocus
                    ? _buildCompactNavHeader()
                    : _buildNavHeader(),
                if (_isNavSearching &&
                    (_showCurrentLocationResult ||
                        _navResults.isNotEmpty ||
                        _navPlaceResults.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _kHPadding),
                    child: _buildNavCombinedDropdown(),
                  ),
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
      onSubmitted: () {
        if (_searchResults.isNotEmpty) _selectSearch(_searchResults.first);
      },
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

  /// 경로 결과 있을 때 — [←] [소요시간]
  Widget _buildCompactNavHeader() {
    final chipData = <({PathSearchType type, String label, String time})>[];
    for (final entry in _allRoutes.entries) {
      final label = switch (entry.key) {
        PathSearchType.duration => '최적',
        PathSearchType.distance => '최단',
        PathSearchType.transfer => '최소환승',
      };
      chipData.add((
        type: entry.key,
        label: label,
        time: entry.value.totalTimeFormatted,
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(_kHPadding, 8, 0, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            AdaptiveGlassIconButton(
              icon: CupertinoIcons.back,
              iconSize: 18,
              size: 40,
              onPressed: () {
                setState(() {
                  _pathResult = null;
                  _allRoutes = {};
                });
                _depFocus.requestFocus();
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: _kHPadding),
                itemCount: chipData.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final chip = chipData[i];
                  final selected = chip.type == _searchType;
                  return _buildRouteChip(
                    label: chip.label,
                    time: chip.time,
                    selected: selected,
                    onTap: () => _selectRoute(chip.type),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectRoute(PathSearchType type) {
    final route = _allRoutes[type];
    if (route == null) return;
    setState(() {
      _searchType = type;
      _pathResult = route;
    });
    widget.onRouteFound?.call(route);
  }

  Widget _buildRouteChip({
    required String label,
    required String time,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    if (Platform.isIOS) {
      return CNButton(
        label: '$label  |  $time',
        onPressed: onTap,
        tint: textColor,
        config: CNButtonConfig(
          style: selected ? CNButtonStyle.prominentGlass : CNButtonStyle.glass,
          minHeight: 40,
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: selected
          ? FilledButton.tonal(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                foregroundColor: textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: AppTypography.bodySm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text('$label  |  $time'),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: textColor.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: AppTypography.bodySm,
              ),
              child: Text('$label  |  $time'),
            ),
    );
  }

  Widget _buildNavHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(_kHPadding, 8, _kHPadding, 0),
      child: AdaptiveGlassContainer.rect(
        cornerRadius: _kBarRadius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // 출발/도착 레일
                  Column(
                    children: [
                      Container(
                        width: AppSpacing.md,
                        height: AppSpacing.md,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.success,
                            width: 2.5,
                          ),
                        ),
                      ),
                      Container(
                        width: 1.5,
                        height: AppSpacing.xl,
                        color: AppColors.borderSubtle,
                      ),
                      Icon(
                        Icons.place,
                        size: AppSpacing.lg,
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      children: [
                        _buildNavField(_depCtrl, _depFocus, '출발지'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildNavField(_arrCtrl, _arrFocus, '도착지'),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    children: [
                      _circleButton(
                        CupertinoIcons.arrow_up_arrow_down,
                        _swapStations,
                        '출발지·도착지 교환',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _circleButton(CupertinoIcons.xmark, _exitNav, '길찾기 닫기'),
                    ],
                  ),
                ],
              ),
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

  Widget _buildNavField(
    TextEditingController ctrl,
    FocusNode focus,
    String hint,
  ) {
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
          color: isM3
              ? cs.onSurfaceVariant.withValues(alpha: 0.6)
              : navPlaceholder,
          fontSize: 14,
        ),
        style: AppTypography.bodyMd.copyWith(
          color: isM3 ? cs.onSurface : navTextColor,
        ),
        decoration: BoxDecoration(
          color: isM3
              ? cs.surfaceContainerHighest
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(
            isM3 ? 12.0 : AppSpacing.radiusMd,
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: isM3 ? 12 : 0,
        ),
        onChanged: _onNavSearch,
        onSubmitted: (_) {
          if (_showCurrentLocationResult) {
            _setCurrentLocationForField(_activeField);
          } else if (_navResults.isNotEmpty) {
            _selectNav(_navResults.first);
          }
        },
      ),
    );
  }

  Widget _buildDirectionsResult(DirectionsResult r) {
    final modeIcon = switch (r.mode) {
      TravelMode.walking => Icons.directions_walk,
      TravelMode.driving => Icons.directions_car,
      TravelMode.transit => Icons.directions_transit,
    };
    final modeName = switch (r.mode) {
      TravelMode.walking => '도보',
      TravelMode.driving => '자동차',
      TravelMode.transit => '대중교통',
    };
    final min = r.durationSec ~/ 60;
    final hr = min ~/ 60;
    final timeStr = hr > 0 ? '${hr}시간 ${min % 60}분' : '${min}분';

    return _resultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(modeIcon, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: AppTypography.displayLg.copyWith(fontSize: 20),
              ),
              const Spacer(),
              Text(
                '${r.distanceKm.toStringAsFixed(1)}km',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$modeName 경로',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (r.fare != null) ...[
            const SizedBox(height: 4),
            Text(
              '예상 택시비 약 ${_formatWon(r.fare!)}',
              style: AppTypography.bodySm.copyWith(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }

  String _formatWon(int won) {
    if (won >= 10000) return '${(won / 10000).toStringAsFixed(1)}만원';
    return '${won.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
  }

  Widget _buildTransportModeTabs() {
    const modes = [
      (Icons.directions_transit, '대중교통'),
      (Icons.directions_walk, '도보'),
      (Icons.directions_bike, '자전거'),
      (Icons.directions_car, '자동차'),
    ];
    final cs = Theme.of(context).colorScheme;
    final isM3 = Platform.isAndroid;

    return Row(
      children: List.generate(modes.length, (i) {
        final selected = _transportMode == i;
        final color = selected
            ? cs.primary
            : (isM3 ? cs.onSurfaceVariant : AppColors.textSecondary);
        return Expanded(
          child: GestureDetector(
            onTap: () => _setTransportMode(i),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: selected
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: cs.primary, width: 2),
                      ),
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(modes[i].$1, size: 18, color: color),
                  const SizedBox(height: 2),
                  Text(
                    modes[i].$2,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 경로 결과
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildRouteResult() {
    // 로딩
    if (_isPathLoading || _directionsLoading) {
      return _resultCard(
        child: Column(
          children: [
            Platform.isAndroid
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const CupertinoActivityIndicator(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '경로 검색 중...',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    // 도보/자전거/자동차 결과
    if (_transportMode != 0) {
      if (_directionsResult == null) {
        return _resultCard(
          child: Text(
            '경로를 찾을 수 없습니다',
            style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled),
            textAlign: TextAlign.center,
          ),
        );
      }
      return _buildDirectionsResult(_directionsResult!);
    }

    if (_pathResult == null) {
      return _resultCard(
        child: Text(
          '경로를 찾을 수 없습니다',
          style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled),
          textAlign: TextAlign.center,
        ),
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
      child: GestureDetector(
        onTap: () => widget.onRouteDetailRequested?.call(r),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_kHPadding, 6, _kHPadding, 0),
          child: _overlayCard(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.42,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 요약
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        r.totalTimeFormatted,
                        style: AppTypography.displayLg,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      if (r.transferCount > 0)
                        _badge('환승 ${r.transferCount}회', AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      _badge(
                        '${r.totalDistanceKm.toStringAsFixed(1)}km',
                        AppColors.textDisabled,
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${r.segments.length}개 구간',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                          if (r.isLocal)
                            Text(
                              '로컬 계산',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
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
                    itemBuilder: (_, i) =>
                        _buildSegTile(r.segments[i], i, r.segments.length),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kHPadding,
        AppSpacing.sm,
        _kHPadding,
        0,
      ),
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSpacing.xxl,
            child: Column(
              children: [
                if (i > 0)
                  Container(
                    width: 2,
                    height: AppSpacing.sm,
                    color: c.withValues(alpha: 0.4),
                  ),
                Container(
                  width: AppSpacing.md,
                  height: AppSpacing.md,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: seg.isTransfer ? Colors.transparent : c,
                    border: Border.all(color: c, width: 2),
                  ),
                  child: seg.isTransfer
                      ? Icon(
                          Icons.swap_vert,
                          size: AppSpacing.sm,
                          color: AppColors.textSecondary,
                        )
                      : null,
                ),
                if (i < total - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: c.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                      ),
                      child: Text(
                        seg.lineName,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (seg.travelTimeSec > 0)
                      Text(
                        '${(seg.travelTimeSec / 60).ceil()}분',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    if (seg.distanceKm > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${seg.distanceKm.toStringAsFixed(1)}km',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (seg.stations.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    seg.stations.join(' → '),
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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

  Widget _buildDropdown(
    List<StationSearchResult> results,
    void Function(StationSearchResult) onSelect,
  ) {
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
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 48,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, indent: 48, color: AppColors.divider),
            itemBuilder: (_, i) => _buildTile(results[i], onSelect),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
    StationSearchResult r,
    void Function(StationSearchResult) onSelect,
  ) {
    // 환승역 판정은 allLineIds (등장하는 모든 노선 ID 합집합) 기반.
    // 비어있을 수도 있는 const 기본값 호환: 비면 자기 노선만 사용.
    final lineIds = r.allLineIds.isEmpty ? <String>[r.lineId] : r.allLineIds;
    final allColors = <Color>[];
    for (final id in lineIds) {
      final c = SubwayColors.lineColors[id];
      if (c != null && !allColors.contains(c)) allColors.add(c);
    }
    if (allColors.isEmpty) allColors.add(r.lineColor);
    final hasTrf = allColors.length > 1;

    return GestureDetector(
      onTap: () => onSelect(r),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: allColors.length > 1
                    ? LinearGradient(
                        colors: allColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: allColors.length == 1 ? r.lineColor : null,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.subway, size: 15, color: Colors.white),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.station.name,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasTrf)
                    Text(
                      lineIds
                          .map((id) => SubwayColors.lineNames[id] ?? id)
                          .join(' · '),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                ],
              ),
            ),
            if (hasTrf)
              ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(colors: allColors).createShader(bounds),
                child: const Text(
                  '지하철',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Text(
                r.lineName,
                style: AppTypography.bodySm.copyWith(color: r.lineColor),
              ),
          ],
        ),
      ),
    );
  }

  String _shortLine(String n) {
    if (n.endsWith('호선')) return n.replaceAll('호선', '');
    return n.length > 2 ? n.substring(0, 2) : n;
  }

  void _selectNavPlace(PlaceSearchResult place) {
    setState(() {
      if (_activeField == _NavField.departure) {
        _depStation = place.name;
        _depCtrl.text = place.name;
        _depFocus.unfocus();
        _depLat = place.lat;
        _depLng = place.lng;
        if (_arrStation == null)
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _arrFocus.requestFocus();
          });
      } else {
        _arrStation = place.name;
        _arrCtrl.text = place.name;
        _arrFocus.unfocus();
        _arrLat = place.lat;
        _arrLng = place.lng;
      }
      _navResults = [];
      _isNavSearching = false;
      _showCurrentLocationResult = false;
      _navPlaceResults = [];
    });
    if (_depStation != null && _arrStation != null) _findPath();
  }

  Widget _buildNavCombinedDropdown() {
    final isM3 = Platform.isAndroid;
    final currentLocationCount = _showCurrentLocationResult ? 1 : 0;
    final totalCount =
        currentLocationCount + _navResults.length + _navPlaceResults.length;

    Widget buildList() {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        shrinkWrap: true,
        itemCount: totalCount,
        separatorBuilder: (_, i) {
          if (i == currentLocationCount + _navResults.length - 1 &&
              _navPlaceResults.isNotEmpty) {
            return Divider(
              height: 16,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
              color: isM3
                  ? Theme.of(context).colorScheme.outlineVariant
                  : AppColors.divider,
            );
          }
          return Divider(
            height: 1,
            indent: 48,
            color: isM3
                ? Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5)
                : AppColors.divider,
          );
        },
        itemBuilder: (_, i) {
          if (_showCurrentLocationResult && i == 0) {
            return _buildCurrentLocationTile();
          }
          final stationIndex = i - currentLocationCount;
          if (stationIndex < _navResults.length) {
            return _buildTile(_navResults[stationIndex], _selectNav);
          }
          final place = _navPlaceResults[stationIndex - _navResults.length];
          return _buildPlaceTileWith(place, () => _selectNavPlace(place));
        },
      );
    }

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
          child: buildList(),
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: buildList(),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationTile() {
    return InkWell(
      onTap: () => _setCurrentLocationForField(_activeField),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.my_location,
                size: 16,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                '내 위치',
                style: AppTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 최근 검색 드롭다운 ──
  Widget _buildRecentSearchDropdown() {
    final isM3 = Platform.isAndroid;
    final recent = RecentSearchService.instance.items;

    Widget buildList() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
            child: Row(
              children: [
                Text(
                  '최근 검색',
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await RecentSearchService.instance.clear();
                    setState(() {});
                  },
                  child: Text(
                    '전체 삭제',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          ...recent
              .take(8)
              .map(
                (q) => GestureDetector(
                  onTap: () {
                    _searchController.text = q;
                    _onSearchChanged(q);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 16,
                          color: AppColors.textDisabled,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(q, style: AppTypography.bodyMd)),
                        GestureDetector(
                          onTap: () async {
                            await RecentSearchService.instance.remove(q);
                            setState(() {});
                          },
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 6),
        ],
      );
    }

    if (isM3) {
      final cs = Theme.of(context).colorScheme;
      return Material(
        elevation: 3,
        shadowColor: cs.shadow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(_kBarRadius),
        color: cs.surfaceContainer,
        surfaceTintColor: cs.surfaceTint,
        clipBehavior: Clip.antiAlias,
        child: buildList(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_kBarRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: AppColors.glassDropOpacity),
            borderRadius: BorderRadius.circular(_kBarRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: buildList(),
        ),
      ),
    );
  }

  // ── 통합 검색 드롭다운 (지하철 + 버스 + 장소) ──
  Widget _buildCombinedDropdown() {
    final isM3 = Platform.isAndroid;
    final busCount = _busResults.take(5).length; // 버스는 최대 5개
    final totalCount = _searchResults.length + busCount + _placeResults.length;

    Widget buildList() {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        shrinkWrap: true,
        itemCount: totalCount,
        separatorBuilder: (_, i) {
          // 섹션 경계에 두꺼운 구분선
          final stationEnd = _searchResults.length - 1;
          final busEnd = _searchResults.length + busCount - 1;
          if ((i == stationEnd && (busCount > 0 || _placeResults.isNotEmpty)) ||
              (i == busEnd && _placeResults.isNotEmpty)) {
            return Divider(
              height: 16,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
              color: isM3
                  ? Theme.of(context).colorScheme.outlineVariant
                  : AppColors.divider,
            );
          }
          return Divider(
            height: 1,
            indent: 48,
            color: isM3
                ? Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5)
                : AppColors.divider,
          );
        },
        itemBuilder: (_, i) {
          if (i < _searchResults.length) {
            return _buildTile(_searchResults[i], _selectSearch);
          }
          final busIdx = i - _searchResults.length;
          if (busIdx < busCount) {
            return _buildBusTile(_busResults[busIdx]);
          }
          return _buildPlaceTile(
            _placeResults[i - _searchResults.length - busCount],
          );
        },
      );
    }

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
          constraints: const BoxConstraints(maxHeight: 350),
          child: buildList(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_kBarRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 350),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: AppColors.glassDropOpacity),
            borderRadius: BorderRadius.circular(_kBarRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: buildList(),
        ),
      ),
    );
  }

  Widget _buildBusTile(BusRouteInfo route) {
    final color = BusColors.fromRouteType(route.routeType);
    final typeName = _busTypeName(route.routeType);

    return GestureDetector(
      onTap: () => _selectBus(route),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(Icons.directions_bus, size: 15, color: color),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.busRouteNm,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (route.stStationNm.isNotEmpty ||
                      route.edStationNm.isNotEmpty)
                    Text(
                      '${route.stStationNm} → ${route.edStationNm}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDisabled,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(typeName, style: AppTypography.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  String _busTypeName(int type) {
    switch (type) {
      case 3:
        return '간선';
      case 4:
        return '지선';
      case 5:
        return '순환';
      case 6:
        return '광역';
      case 7:
        return '인천';
      case 8:
        return '경기';
      default:
        return '버스';
    }
  }

  Widget _buildPlaceTile(PlaceSearchResult place) {
    return _buildPlaceTileWith(place, () => _selectPlace(place));
  }

  Widget _buildPlaceTileWith(PlaceSearchResult place, VoidCallback onTap) {
    final icon = _placeIcon(place.category);
    final color = _placeColor(place.category);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, size: 15, color: color)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (place.address.isNotEmpty)
                    Text(
                      place.address,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textDisabled,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              place.category,
              style: AppTypography.caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  IconData _placeIcon(String category) {
    switch (category) {
      case '음식점':
        return Icons.restaurant;
      case '카페':
        return Icons.local_cafe;
      case '공원':
        return Icons.park;
      case '쇼핑':
        return Icons.shopping_bag;
      case '의료':
        return Icons.local_hospital;
      case '교육':
        return Icons.school;
      case '숙박':
        return Icons.hotel;
      case '금융':
        return Icons.account_balance;
      case '교통':
        return Icons.directions_transit;
      case '주소':
        return Icons.pin_drop;
      case '도시':
        return Icons.location_city;
      case '동네':
        return Icons.holiday_village;
      case '도로':
        return Icons.edit_road;
      default:
        return Icons.place;
    }
  }

  Color _placeColor(String category) {
    switch (category) {
      case '음식점':
        return Colors.orange;
      case '카페':
        return const Color(0xFF795548);
      case '공원':
        return Colors.green;
      case '쇼핑':
        return Colors.pink;
      case '의료':
        return Colors.red;
      case '교육':
        return Colors.indigo;
      case '숙박':
        return Colors.purple;
      case '금융':
        return Colors.teal;
      case '교통':
        return Colors.blue;
      case '주소':
        return Colors.blueGrey;
      case '도시':
        return Colors.deepPurple;
      case '동네':
        return Colors.amber;
      case '도로':
        return Colors.grey;
      default:
        return Colors.blueAccent;
    }
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
    const placeholderColor = Color(0xFF8E8E93);

    final glassBar = SizedBox(
      height: _kBarHeight,
      child: AdaptiveGlassContainer.capsule(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Icon(CupertinoIcons.search, size: 20, color: placeholderColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AdaptiveSearchField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  placeholder: '장소, 버스, 지하철 검색',
                  placeholderStyle: TextStyle(
                    color: placeholderColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
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
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 20,
                          color: placeholderColor,
                        ),
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
