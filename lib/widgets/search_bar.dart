import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/recent_search_service.dart';
import '../services/recent_route_service.dart';
import '../services/directions_service.dart';
import '../data/river_bus_data.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'adaptive/adaptive.dart';
import 'search_bar/glass_search_field.dart';
import 'search_bar/recent_routes_panel.dart';
import 'search_bar/search_tiles.dart';
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
  /// 외부에서 길찾기 모드 진입 + 출발지 설정.
  /// 도착지가 비어 있으면 도착지 입력 대기 (네이버 지도 동작).
  void enterNavWithDeparture(String name, {double? lat, double? lng}) {
    setState(() {
      _isNavMode = true;
      _cancelSearch();
      _depStation = name;
      _depCtrl.text = name;
      _depLat = lat;
      _depLng = lng;
      _arrStation = null;
      _arrCtrl.clear();
      _arrLat = null;
      _arrLng = null;
      _pathResult = null;
      _allRoutes = {};
    });
    _navCtrl.forward();
    widget.onNavModeChanged?.call(true);
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

  /// 외부에서 길찾기 모드 진입 + 출발/도착 페어 직접 설정 → 즉시 길찾기.
  /// 위젯/Control 에서 "마지막 길찾기 다시 시작" 같은 진입에 사용.
  void enterNavWithPair(
    String departure,
    String arrival, {
    double? depLat,
    double? depLng,
    double? arrLat,
    double? arrLng,
  }) {
    setState(() {
      _isNavMode = true;
      _cancelSearch();
      _depStation = departure;
      _depCtrl.text = departure;
      _depLat = depLat;
      _depLng = depLng;
      _arrStation = arrival;
      _arrCtrl.text = arrival;
      _arrLat = arrLat;
      _arrLng = arrLng;
      _pathResult = null;
      _allRoutes = {};
    });
    _navCtrl.forward();
    widget.onNavModeChanged?.call(true);
    _findPath();
  }

  /// 외부에서 길찾기 모드 진입 + 도착지 설정.
  /// 출발지를 '내 위치'로 자동 채우고 좌표 받자마자 길찾기 즉시 시작 (네이버 지도 동작).
  void enterNavWithArrival(String name, {double? lat, double? lng}) {
    setState(() {
      _isNavMode = true;
      _cancelSearch();
      _depStation = '내 위치';
      _depCtrl.text = '내 위치';
      _depLat = null;
      _depLng = null;
      _arrStation = name;
      _arrCtrl.text = name;
      _arrLat = lat;
      _arrLng = lng;
      _pathResult = null;
      _allRoutes = {};
    });
    _navCtrl.forward();
    widget.onNavModeChanged?.call(true);
    // 위치 좌표 확보 후 자동 길찾기. _setCurrentLocationForField 가 autoFind=true 면
    // _depStation/_arrStation 모두 채워져 있을 때 _findPath 호출.
    _setCurrentLocationForField(_NavField.departure, autoFind: true);
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
  PathResult? _pathResult;
  Map<PathSearchType, PathResult> _allRoutes = {};
  bool _isPathLoading = false;
  final PathFindingService _pathService = PathFindingService();

  // 애니메이션
  late AnimationController _expandCtrl;
  late AnimationController _navCtrl;
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
    _navCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
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
    if (selected != null) {
      widget.onRouteFound?.call(selected);
      // 최근 길찾기 페어 저장. '내 위치' 출발은 매번 좌표가 다르므로 페어로 의미 없어 제외.
      if (_depStation != '내 위치' && _arrStation != '내 위치') {
        RecentRouteService.instance.record(
          departure: _depStation!,
          arrival: _arrStation!,
          depLat: _depLat,
          depLng: _depLng,
          arrLat: _arrLat,
          arrLng: _arrLng,
        );
      }
    }
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
                  )
                else if (_pathResult == null &&
                    !_isPathLoading &&
                    RecentRouteService.instance.routes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _kHPadding),
                    child: _buildRecentRoutesPanel(),
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
    return GlassSearchField(
      controller: _searchController,
      focusNode: _searchFocus,
      height: _kBarHeight,
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

  Widget _buildRecentRoutesPanel() {
    return RecentRoutesPanel(
      routes: RecentRouteService.instance.routes.take(5).toList(),
      radius: _kBarRadius,
      onSelect: _selectRecentRoute,
      onRemove: (r) async {
        await RecentRouteService.instance.remove(r.departure, r.arrival);
        if (mounted) setState(() {});
      },
    );
  }

  void _selectRecentRoute(RecentRoute r) {
    setState(() {
      _depStation = r.departure;
      _depCtrl.text = r.departure;
      _depLat = r.depLat;
      _depLng = r.depLng;
      _arrStation = r.arrival;
      _arrCtrl.text = r.arrival;
      _arrLat = r.arrLat;
      _arrLng = r.arrLng;
    });
    _findPath();
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
            return CurrentLocationTile(
              onTap: () => _setCurrentLocationForField(_activeField),
            );
          }
          final stationIndex = i - currentLocationCount;
          if (stationIndex < _navResults.length) {
            return StationTile(
              result: _navResults[stationIndex],
              onSelect: _selectNav,
            );
          }
          final place = _navPlaceResults[stationIndex - _navResults.length];
          return PlaceTile(
            place: place,
            onTap: () => _selectNavPlace(place),
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
            return StationTile(
              result: _searchResults[i],
              onSelect: _selectSearch,
            );
          }
          final busIdx = i - _searchResults.length;
          if (busIdx < busCount) {
            final route = _busResults[busIdx];
            return BusTile(route: route, onTap: () => _selectBus(route));
          }
          final p = _placeResults[i - _searchResults.length - busCount];
          return PlaceTile(place: p, onTap: () => _selectPlace(p));
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






}

enum _NavField { departure, arrival }

