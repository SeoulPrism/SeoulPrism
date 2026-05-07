/// bus_data_cache.json → lib/data/seoul_bus_data.dart 변환 스크립트
/// 사용법: dart run tools/generate_bus_dart.dart
///
/// fetch_bus_data.dart로 수집한 데이터를 정적 Dart 파일로 변환합니다.

import 'dart:convert';
import 'dart:io';

const String cacheFile = 'tools/bus_data_cache.json';
const String outputFile = 'lib/data/seoul_bus_data.dart';

void main() {
  final file = File(cacheFile);
  if (!file.existsSync()) {
    print('❌ $cacheFile 가 없습니다. 먼저 fetch_bus_data.dart를 실행하세요.');
    exit(1);
  }

  final cache = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final routeList = cache['routeList'] as List;
  final routes = cache['routes'] as Map<String, dynamic>;

  print('📊 노선: ${routeList.length}개, 수집완료: ${routes.length}개');

  if (routes.length < routeList.length) {
    print('⚠️  아직 수집이 완료되지 않았습니다 (${routes.length}/${routeList.length})');
    print('   계속 생성하시겠습니까? (미수집 노선 제외)');
  }

  final buf = StringBuffer();

  // Header
  buf.writeln('/// 서울시 버스 노선별 정류소 오프라인 데이터');
  buf.writeln('/// 자동 생성 파일 — tools/generate_bus_dart.dart');
  buf.writeln('/// 생성일: ${DateTime.now().toIso8601String().substring(0, 10)}');
  buf.writeln('///');
  buf.writeln('/// 구조: BusRouteData (노선) → List<BusStopData> (정류소 순서)');
  buf.writeln();

  // Model classes
  buf.writeln('/// 버스 정류소 정적 데이터');
  buf.writeln('class BusStopData {');
  buf.writeln('  final int seq;');
  buf.writeln('  final String stId;');
  buf.writeln('  final String arsId;');
  buf.writeln('  final String name;');
  buf.writeln('  final double lat;');
  buf.writeln('  final double lng;');
  buf.writeln();
  buf.writeln('  const BusStopData({');
  buf.writeln('    required this.seq,');
  buf.writeln('    required this.stId,');
  buf.writeln('    required this.arsId,');
  buf.writeln('    required this.name,');
  buf.writeln('    required this.lat,');
  buf.writeln('    required this.lng,');
  buf.writeln('  });');
  buf.writeln('}');
  buf.writeln();

  // Route type enum comment
  buf.writeln('/// 노선 유형: 3=간선, 4=지선, 5=순환, 6=광역');
  buf.writeln('class BusRouteData {');
  buf.writeln('  final String routeId;');
  buf.writeln('  final String routeName;');
  buf.writeln('  final int routeType;');
  buf.writeln('  final String startStation;');
  buf.writeln('  final String endStation;');
  buf.writeln('  final List<BusStopData> stops;');
  buf.writeln();
  buf.writeln('  const BusRouteData({');
  buf.writeln('    required this.routeId,');
  buf.writeln('    required this.routeName,');
  buf.writeln('    required this.routeType,');
  buf.writeln('    required this.startStation,');
  buf.writeln('    required this.endStation,');
  buf.writeln('    required this.stops,');
  buf.writeln('  });');
  buf.writeln();
  buf.writeln("  String get routeTypeLabel => switch (routeType) {");
  buf.writeln("    3 => '간선',");
  buf.writeln("    4 => '지선',");
  buf.writeln("    5 => '순환',");
  buf.writeln("    6 => '광역',");
  buf.writeln("    _ => '기타',");
  buf.writeln("  };");
  buf.writeln('}');
  buf.writeln();

  // Main data class
  buf.writeln('class SeoulBusData {');
  buf.writeln('  SeoulBusData._();');
  buf.writeln();

  // Route name → route ID lookup
  buf.writeln('  /// 노선명 → 노선 ID 매핑');
  buf.writeln('  static final Map<String, String> routeNameToId = {');
  for (final entry in routes.entries) {
    final info = entry.value['info'] as Map<String, dynamic>;
    final name = info['busRouteNm'] as String;
    buf.writeln("    '$name': '${entry.key}',");
  }
  buf.writeln('  };');
  buf.writeln();

  // All routes list
  buf.writeln('  /// 전체 노선 목록');
  buf.writeln('  static final List<BusRouteData> allRoutes = [');

  // Sort by route name for readability
  final sortedEntries = routes.entries.toList()
    ..sort((a, b) {
      final aName = (a.value['info'] as Map)['busRouteNm'] as String;
      final bName = (b.value['info'] as Map)['busRouteNm'] as String;
      return aName.compareTo(bName);
    });

  for (final entry in sortedEntries) {
    final info = entry.value['info'] as Map<String, dynamic>;
    final stations = entry.value['stations'] as List;

    if (stations.isEmpty) continue;

    buf.writeln('    BusRouteData(');
    buf.writeln("      routeId: '${entry.key}',");
    buf.writeln("      routeName: '${_escape(info['busRouteNm'] as String)}',");
    buf.writeln("      routeType: ${info['routeType']},");
    buf.writeln("      startStation: '${_escape(info['stStationNm'] as String)}',");
    buf.writeln("      endStation: '${_escape(info['edStationNm'] as String)}',");
    buf.writeln('      stops: [');

    for (final st in stations) {
      final seq = st['seq'] ?? 0;
      final stId = st['stId'] ?? '';
      final arsId = st['arsId'] ?? '';
      final name = _escape(st['stNm'] as String? ?? '');
      final lat = st['lat'] ?? 0.0;
      final lng = st['lng'] ?? 0.0;

      if (lat == 0 || lng == 0) continue;

      buf.writeln("        BusStopData(seq: $seq, stId: '$stId', arsId: '$arsId', name: '$name', lat: $lat, lng: $lng),");
    }

    buf.writeln('      ],');
    buf.writeln('    ),');
  }

  buf.writeln('  ];');
  buf.writeln();

  // Helper methods
  buf.writeln('  /// 노선 ID로 검색');
  buf.writeln('  static BusRouteData? getRoute(String routeId) {');
  buf.writeln('    for (final r in allRoutes) {');
  buf.writeln('      if (r.routeId == routeId) return r;');
  buf.writeln('    }');
  buf.writeln('    return null;');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  /// 노선명으로 검색');
  buf.writeln('  static BusRouteData? getRouteByName(String name) {');
  buf.writeln('    final id = routeNameToId[name];');
  buf.writeln('    if (id == null) return null;');
  buf.writeln('    return getRoute(id);');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  /// 정류소명으로 해당 정류소를 지나는 노선 검색');
  buf.writeln('  static List<BusRouteData> getRoutesByStopName(String stopName) {');
  buf.writeln('    return allRoutes.where((r) =>');
  buf.writeln('      r.stops.any((s) => s.name == stopName)');
  buf.writeln('    ).toList();');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  /// 정류소 ID로 해당 정류소를 지나는 노선 검색');
  buf.writeln('  static List<BusRouteData> getRoutesByStopId(String stId) {');
  buf.writeln('    return allRoutes.where((r) =>');
  buf.writeln('      r.stops.any((s) => s.stId == stId)');
  buf.writeln('    ).toList();');
  buf.writeln('  }');
  buf.writeln('}');

  // Write file
  File(outputFile).writeAsStringSync(buf.toString());

  final fileSizeKB = File(outputFile).lengthSync() / 1024;
  print('✅ $outputFile 생성 완료 (${fileSizeKB.toStringAsFixed(0)} KB)');
  print('   노선: ${sortedEntries.length}개');

  // Stats
  int totalStops = 0;
  for (final entry in routes.values) {
    totalStops += (entry['stations'] as List).length;
  }
  print('   정류소 레코드: $totalStops개');
}

String _escape(String s) => s.replaceAll("'", "\\'").replaceAll(r'$', r'\$');
