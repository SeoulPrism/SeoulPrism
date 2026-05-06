/// 서울 열린데이터광장 CSV → seoul_bus_data.dart 변환 스크립트
///
/// 표준 입력 (둘 다 EUC-KR 또는 UTF-8):
///   tools/csv/  안에 다음 중 하나의 형태:
///   (A) 노선별 경유 정류소 단일 CSV  (예: "서울시 버스 노선 정보 조회.csv")
///       — ROUTE_ID, 노선명, 순번, NODE_ID, ARS_ID, 정류소명, X좌표, Y좌표
///   (B) routes.csv + stops.csv 분리 CSV (헤더 자동 매핑)
///
/// 사용법:
///   dart run tools/build_bus_data_from_csv.dart                  # tools/csv 자동 스캔
///   dart run tools/build_bus_data_from_csv.dart --stops PATH     # 단일 파일 명시
///   dart run tools/build_bus_data_from_csv.dart --routes A --stops B
///
/// 출력: lib/data/seoul_bus_data.dart (덮어쓰기)
///
/// ws.bus.go.kr API 와 달리 호출 한도 없고 일괄 다운로드라 정확.

import 'dart:convert';
import 'dart:io';

const String defaultCsvDir = 'tools/csv';
const String outputFile = 'lib/data/seoul_bus_data.dart';

// 헤더 키워드 → 표준 필드명. 한글/영문 혼재 대응.
// 매핑 우선순위는 리스트 앞쪽이 강함.
// 한국 공공데이터 관행: X좌표 = 경도(lng), Y좌표 = 위도(lat).
const Map<String, List<String>> _routeHeaderHints = {
  'routeId': ['route_id', 'routeid', '노선id', 'busrouteid', '노선번호id'],
  'routeName': ['노선명', 'route_name', 'busroutenm', 'routename', '노선번호', '노선'],
  // routeType / 기점 / 종점은 노선별경유정류소 데이터엔 없을 수 있음 → 추정 폴백.
  'routeType': ['노선유형', '노선타입', 'route_type', 'routetype', '유형'],
  'startStation': ['기점', '기점명', 'ststationnm', '기점정류소'],
  'endStation': ['종점', '종점명', 'edstationnm', '종점정류소'],
};

const Map<String, List<String>> _stopHeaderHints = {
  'routeId': ['route_id', 'routeid', '노선id', 'busrouteid'],
  'seq': ['순번', '순서', 'seq', 'sequence', '정류소순번'],
  'stopId': ['node_id', 'nodeid', 'stop_id', 'stopid', 'stid', '정류소id'],
  'arsId': ['ars_id', 'arsid', '정류소번호', '정류소고유번호'],
  'stopName': ['정류소명', 'stop_name', 'stopname', 'stationnm', '정류장명'],
  // 한국 표준: X = 경도, Y = 위도. lat/lng 라벨도 함께 인식.
  'lat': ['y좌표', 'y_coord', 'gpsy', 'tmy', 'posy', '위도', 'lat', 'latitude'],
  'lng': ['x좌표', 'x_coord', 'gpsx', 'tmx', 'posx', '경도', 'lng', 'lon', 'longitude'],
};

// 일부 필드는 없어도 됨 (있으면 사용, 없으면 추정/기본값).
const Set<String> _optionalRouteFields = {'routeType', 'startStation', 'endStation'};
const Set<String> _optionalStopFields = {'arsId'};

void main(List<String> args) {
  final argMap = _parseArgs(args);
  final routesPath = argMap['routes'];
  var stopsPath = argMap['stops'];

  // 인자 미지정 시 tools/csv 디렉터리 자동 스캔.
  if (routesPath == null && stopsPath == null) {
    final scan = _scanCsvDir(defaultCsvDir);
    if (scan == null) {
      stderr.writeln('❌ $defaultCsvDir 에 CSV 가 없습니다. routes.csv / stops.csv 또는 노선별 정류소 CSV 1개 두세요.');
      exit(1);
    }
    stopsPath = scan;
  }

  print('━━━ 서울시 버스 데이터 CSV → Dart 변환 ━━━');
  // 단일 CSV 모드: routes 미지정이면 stops CSV 를 양쪽 모두에 사용.
  // 노선별 경유 정류소 CSV 한 개로도 노선명까지 추출 가능.
  final routesFile = File(routesPath ?? stopsPath!);
  final stopsFile = File(stopsPath!);
  if (!routesFile.existsSync()) {
    stderr.writeln('❌ ${routesFile.path} 없음.');
    exit(1);
  }
  if (!stopsFile.existsSync()) {
    stderr.writeln('❌ ${stopsFile.path} 없음.');
    exit(1);
  }

  final singleMode = routesFile.path == stopsFile.path;
  print('  routes: ${routesFile.path}');
  print('  stops:  ${stopsFile.path}${singleMode ? "  (단일 CSV 모드)" : ""}');

  final routes = _loadRoutes(routesFile);
  print('  📋 노선 메타 ${routes.length}개 로드');
  final stopsByRoute = _loadStopsByRoute(stopsFile);
  print('  🚏 노선당 정류소 시퀀스 ${stopsByRoute.length}개 로드');

  // 정류소 좌표 0/0 인 항목 제거, seq 순 정렬.
  for (final list in stopsByRoute.values) {
    list.removeWhere((s) => s.lat == 0 || s.lng == 0);
    list.sort((a, b) => a.seq.compareTo(b.seq));
  }
  stopsByRoute.removeWhere((_, list) => list.isEmpty);

  // routeType / 기점 / 종점이 비어있으면 추정 폴백.
  for (final r in routes.values) {
    if (r.type == 0) r.type = _inferRouteType(r.name);
    final stops = stopsByRoute[r.id];
    if (stops != null && stops.isNotEmpty) {
      if (r.start.isEmpty) r.start = stops.first.name;
      if (r.end.isEmpty) r.end = stops.last.name;
    }
  }

  // 정류소만 있고 노선 메타가 없는 경우는 거의 없겠으나 안전망.
  routes.removeWhere((id, _) => !stopsByRoute.containsKey(id));

  print('  ✅ 유효 노선 ${routes.length}개 → 출력 시작');
  _writeDart(routes, stopsByRoute);
  print('  📦 $outputFile 생성 완료');
}

/// tools/csv 안에 가장 큰(=노선별 정류소일 가능성 높음) CSV 한 개를 선택.
String? _scanCsvDir(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return null;
  final csvs = d
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.csv'))
      .toList();
  if (csvs.isEmpty) return null;
  // 행수가 가장 많은 CSV 를 노선별 경유 정류소 데이터로 가정.
  csvs.sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
  return csvs.first.path;
}

class _Route {
  final String id;
  String name;
  int type;
  String start;
  String end;
  _Route(this.id, this.name, this.type, this.start, this.end);
}

class _Stop {
  final int seq;
  final String id;
  final String name;
  final double lat;
  final double lng;
  _Stop(this.seq, this.id, this.name, this.lat, this.lng);
}

/// EUC-KR/UTF-8 자동 감지 후 라인 분리.
/// EUC-KR 디코드는 utf8 외 코덱이 dart:convert 에 없으므로,
/// BOM 검사 + UTF-8 시도 → 실패하면 latin1 으로 raw bytes → CP949 매핑 테이블 적용.
List<String> _readLines(File file) {
  final bytes = file.readAsBytesSync();
  // UTF-8 BOM
  if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
    return const LineSplitter().convert(utf8.decode(bytes.sublist(3)));
  }
  // UTF-8 시도
  try {
    return const LineSplitter().convert(utf8.decode(bytes, allowMalformed: false));
  } catch (_) {
    // UTF-8 실패 → EUC-KR/CP949 가정. iconv 명령으로 변환.
    final tmp = File('${file.path}.utf8.tmp');
    final result = Process.runSync('iconv', ['-f', 'CP949', '-t', 'UTF-8', file.path]);
    if (result.exitCode != 0) {
      stderr.writeln('❌ EUC-KR/CP949 디코드 실패. iconv 가 설치돼 있어야 합니다.');
      stderr.writeln(result.stderr);
      exit(3);
    }
    tmp.writeAsStringSync(result.stdout as String);
    final lines = const LineSplitter().convert(result.stdout as String);
    if (tmp.existsSync()) tmp.deleteSync();
    return lines;
  }
}

/// 노선명으로 routeType 추정 (서울시 버스 명명 규칙).
/// 공식 코드: 1=공항, 2=마을, 3=간선, 4=지선, 5=순환, 6=광역, 13=동행, 14=한강, 15=심야.
int _inferRouteType(String name) {
  final n = name.trim();
  if (n.isEmpty) return 0;
  // 심야: N15, N16, N31 ...
  if (RegExp(r'^N\d').hasMatch(n)) return 15;
  // 한강버스 (이 데이터셋엔 보통 없으나 안전).
  if (n.contains('한강')) return 14;
  // 한글 + 숫자: 마을 (서초15, 동작01 등).
  if (RegExp(r'^[가-힣]').hasMatch(n)) return 2;
  // 순수 숫자 분류.
  final digitsOnly = RegExp(r'^\d+$').hasMatch(n);
  if (!digitsOnly) return 0; // 모르는 패턴
  final num = int.tryParse(n) ?? 0;
  // 두 자리 이하: 순환 (01, 02, 03 등).
  if (n.length <= 2) return 5;
  // 4자리: 6XXX 일부는 공항 (6001, 6002), 나머지는 광역(8XXX, 9XXX) 또는 지선.
  if (n.length == 4) {
    final first = num ~/ 1000;
    if (first == 9) return 6; // 9xxx 광역
    if (first == 8) return 6; // 8xxx 광역 (직행좌석)
    if (first == 6) {
      // 6001~6030 부근은 공항버스. 그 외 6xxx 지선.
      if (num >= 6001 && num <= 6030) return 1;
      return 4;
    }
    return 4; // 4xxx, 5xxx, 7xxx 지선
  }
  // 3자리: 간선.
  if (n.length == 3) return 3;
  return 0;
}

Map<String, _Route> _loadRoutes(File file) {
  final lines = _readLines(file);
  if (lines.isEmpty) return {};
  final header = _parseCsvLine(lines.first);
  final idx = _resolveHeader(header, _routeHeaderHints, _optionalRouteFields, file.path);

  final out = <String, _Route>{};
  for (int i = 1; i < lines.length; i++) {
    final fields = _parseCsvLine(lines[i]);
    if (fields.length < header.length) continue;
    final id = _at(fields, idx['routeId']);
    if (id.isEmpty) continue;
    if (out.containsKey(id)) continue; // 노선 메타는 dedup.
    final name = _at(fields, idx['routeName']);
    final typeRaw = _at(fields, idx['routeType']);
    final type = int.tryParse(typeRaw) ?? _typeFromLabel(typeRaw);
    out[id] = _Route(
      id,
      name,
      type,
      _at(fields, idx['startStation']),
      _at(fields, idx['endStation']),
    );
  }
  return out;
}

Map<String, List<_Stop>> _loadStopsByRoute(File file) {
  final lines = _readLines(file);
  if (lines.isEmpty) return {};
  final header = _parseCsvLine(lines.first);
  final idx = _resolveHeader(header, _stopHeaderHints, _optionalStopFields, file.path);

  final out = <String, List<_Stop>>{};
  for (int i = 1; i < lines.length; i++) {
    final fields = _parseCsvLine(lines[i]);
    if (fields.length < header.length) continue;
    final routeId = _at(fields, idx['routeId']);
    if (routeId.isEmpty) continue;
    final seq = int.tryParse(_at(fields, idx['seq'])) ?? 0;
    final stopId = _at(fields, idx['stopId']);
    final stopName = _at(fields, idx['stopName']);
    final lat = double.tryParse(_at(fields, idx['lat'])) ?? 0;
    final lng = double.tryParse(_at(fields, idx['lng'])) ?? 0;
    if (stopName.isEmpty) continue;
    out.putIfAbsent(routeId, () => []).add(_Stop(seq, stopId, stopName, lat, lng));
  }
  return out;
}

// 헤더 자동 매핑. 키워드 부분일치(소문자 비교, 공백 제거).
// optional 필드는 못 찾아도 -1 반환 (값 없을 때 추정 폴백).
Map<String, int> _resolveHeader(
  List<String> header,
  Map<String, List<String>> hints,
  Set<String> optionalFields,
  String fileLabel,
) {
  final norm = header
      .map((h) => h.replaceAll(' ', '').replaceAll('"', '').toLowerCase())
      .toList();
  final result = <String, int>{};
  hints.forEach((field, keys) {
    int found = -1;
    for (final k in keys) {
      final lk = k.toLowerCase().replaceAll(' ', '');
      for (int i = 0; i < norm.length; i++) {
        if (norm[i] == lk || norm[i].contains(lk)) {
          found = i;
          break;
        }
      }
      if (found >= 0) break;
    }
    if (found < 0) {
      if (optionalFields.contains(field)) {
        result[field] = -1;
        return;
      }
      stderr.writeln('⚠️  $fileLabel: 필수 컬럼 "$field" 매핑 실패.');
      stderr.writeln('   헤더: $header');
      stderr.writeln('   힌트 후보: $keys');
      exit(2);
    }
    result[field] = found;
  });
  return result;
}

String _at(List<String> fields, int? i) {
  if (i == null || i < 0 || i >= fields.length) return '';
  return fields[i].trim();
}

// 한글 라벨 → routeType 코드 (서울시 분류 따름).
int _typeFromLabel(String s) {
  final t = s.replaceAll(' ', '');
  if (t.contains('공항')) return 1;
  if (t.contains('마을')) return 2;
  if (t.contains('간선')) return 3;
  if (t.contains('지선')) return 4;
  if (t.contains('순환')) return 5;
  if (t.contains('광역')) return 6;
  if (t.contains('동행')) return 13;
  if (t.contains('한강')) return 14;
  if (t.contains('심야') || t.startsWith('N')) return 15;
  return 0;
}

// CSV 한 줄 파서. 큰따옴표 인용 + 콤마 이스케이프 처리.
List<String> _parseCsvLine(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  bool inQuote = false;
  for (int i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      if (inQuote && i + 1 < line.length && line[i + 1] == '"') {
        buf.write('"');
        i++;
      } else {
        inQuote = !inQuote;
      }
      continue;
    }
    if (ch == ',' && !inQuote) {
      out.add(buf.toString());
      buf.clear();
      continue;
    }
    buf.write(ch);
  }
  out.add(buf.toString());
  return out;
}

void _writeDart(Map<String, _Route> routes, Map<String, List<_Stop>> stopsByRoute) {
  final buf = StringBuffer();
  final today = DateTime.now().toIso8601String().substring(0, 10);

  buf.writeln('// 서울시 버스 노선별 정류소 오프라인 데이터');
  buf.writeln('// 자동 생성 파일 — tools/build_bus_data_from_csv.dart');
  buf.writeln('// 생성일: $today');
  buf.writeln('// 출처: 서울 열린데이터광장 CSV (공식 데이터)');
  buf.writeln();

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

  buf.writeln('/// 노선 유형: 1=공항, 2=마을, 3=간선, 4=지선, 5=순환, 6=광역, 13=동행, 14=한강, 15=심야');
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
  buf.writeln('  String get routeTypeLabel => switch (routeType) {');
  buf.writeln("    1 => '공항',");
  buf.writeln("    2 => '마을',");
  buf.writeln("    3 => '간선',");
  buf.writeln("    4 => '지선',");
  buf.writeln("    5 => '순환',");
  buf.writeln("    6 => '광역',");
  buf.writeln("    13 => '동행',");
  buf.writeln("    14 => '한강',");
  buf.writeln("    15 => '심야',");
  buf.writeln("    _ => '기타',");
  buf.writeln('  };');
  buf.writeln('}');
  buf.writeln();

  buf.writeln('class SeoulBusData {');
  buf.writeln('  SeoulBusData._();');
  buf.writeln();

  // routeNameToId
  buf.writeln('  /// 노선명 → 노선 ID 매핑');
  buf.writeln('  static final Map<String, String> routeNameToId = {');
  final sorted = routes.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  for (final r in sorted) {
    buf.writeln("    '${_esc(r.name)}': '${_esc(r.id)}',");
  }
  buf.writeln('  };');
  buf.writeln();

  // allRoutes
  buf.writeln('  /// 전체 노선 목록');
  buf.writeln('  static final List<BusRouteData> allRoutes = [');
  int totalStops = 0;
  for (final r in sorted) {
    final stops = stopsByRoute[r.id]!;
    if (stops.isEmpty) continue;
    totalStops += stops.length;
    buf.writeln('    BusRouteData(');
    buf.writeln("      routeId: '${_esc(r.id)}',");
    buf.writeln("      routeName: '${_esc(r.name)}',");
    buf.writeln('      routeType: ${r.type},');
    buf.writeln("      startStation: '${_esc(r.start)}',");
    buf.writeln("      endStation: '${_esc(r.end)}',");
    buf.writeln('      stops: [');
    for (final s in stops) {
      buf.writeln(
        "        BusStopData(seq: ${s.seq}, stId: '${_esc(s.id)}', arsId: '${_esc(s.id)}', name: '${_esc(s.name)}', lat: ${s.lat}, lng: ${s.lng}),",
      );
    }
    buf.writeln('      ],');
    buf.writeln('    ),');
  }
  buf.writeln('  ];');
  buf.writeln();

  // helpers
  buf.writeln('  static BusRouteData? getRoute(String routeId) {');
  buf.writeln('    for (final r in allRoutes) {');
  buf.writeln('      if (r.routeId == routeId) return r;');
  buf.writeln('    }');
  buf.writeln('    return null;');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  static BusRouteData? getRouteByName(String name) {');
  buf.writeln('    final id = routeNameToId[name];');
  buf.writeln('    if (id == null) return null;');
  buf.writeln('    return getRoute(id);');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  static List<BusRouteData> getRoutesByStopName(String stopName) {');
  buf.writeln('    return allRoutes.where((r) => r.stops.any((s) => s.name == stopName)).toList();');
  buf.writeln('  }');
  buf.writeln();
  buf.writeln('  static List<BusRouteData> getRoutesByStopId(String stId) {');
  buf.writeln('    return allRoutes.where((r) => r.stops.any((s) => s.stId == stId)).toList();');
  buf.writeln('  }');
  buf.writeln('}');

  File(outputFile).writeAsStringSync(buf.toString());
  print('  📊 노선 ${sorted.length}개, 정류소 레코드 $totalStops개');
}

String _esc(String s) => s.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$');

Map<String, String> _parseArgs(List<String> args) {
  final out = <String, String>{};
  for (int i = 0; i < args.length - 1; i++) {
    if (args[i].startsWith('--')) {
      out[args[i].substring(2)] = args[i + 1];
      i++;
    }
  }
  return out;
}
