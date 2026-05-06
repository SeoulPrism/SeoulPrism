/// 서울시 버스 노선별 정류소 데이터 수집 스크립트
/// 사용법: dart run tools/fetch_bus_data.dart
///
/// ws.bus.go.kr API를 사용하여 모든 버스 노선의 정류소 정보를 수집하고
/// tools/bus_data_cache.json에 저장합니다.
/// 이어서 실행 가능 (이미 수집된 노선은 스킵)
///
/// 수집 완료 후: dart run tools/generate_bus_dart.dart 로 dart 파일 생성

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:seoulprism/core/api_keys.dart';

const String baseRoute = 'http://ws.bus.go.kr/api/rest/busRouteInfo';
const String cacheFile = 'tools/bus_data_cache.json';
const int maxCallsPerRun = 950; // 안전 마진

int callCount = 0;

Future<void> main() async {
  print('━━━ 서울시 버스 데이터 수집 스크립트 ━━━');
  final serviceKey =
      Platform.environment['SEOUL_BUS_API_KEY'] ?? ApiKeys.dataGoKrApiKey;

  // 캐시 로드
  Map<String, dynamic> cache = {};
  final file = File(cacheFile);
  if (file.existsSync()) {
    final decoded = jsonDecode(file.readAsStringSync());
    cache = Map<String, dynamic>.from(decoded as Map);
    print('📂 캐시 로드: ${(cache['routes'] as Map?)?.length ?? 0}개 노선 수집됨');
  } else {
    cache = {'routeList': <dynamic>[], 'routes': <String, dynamic>{}};
  }

  final routeList = cache['routeList'] as List;
  final routes = Map<String, dynamic>.from((cache['routes'] as Map?) ?? {});

  // Step 1: 노선 목록 수집
  if (routeList.isEmpty) {
    print('\n🔍 Step 1: 노선 목록 수집...');
    final allRoutes = await _fetchAllRoutes(serviceKey);
    if (allRoutes.isEmpty) {
      print('   ❌ 노선 목록을 못 받았습니다. API 키/활용승인 상태를 확인하세요.');
      return;
    }
    routeList.addAll(allRoutes);
    cache['routeList'] = routeList;
    _saveCache(cache);
    print('   ✅ ${routeList.length}개 노선 발견');
  } else {
    print('\n📋 노선 목록: ${routeList.length}개 (캐시)');
  }

  // Step 2: 각 노선의 정류소 수집
  print('\n🚌 Step 2: 노선별 정류소 수집...');
  int fetched = 0;
  int skipped = 0;

  for (final route in routeList) {
    final routeId = route['busRouteId'] as String;

    if (routes.containsKey(routeId)) {
      skipped++;
      continue;
    }

    if (callCount >= maxCallsPerRun) {
      print('\n⚠️  일일 한도 도달 ($callCount건). 다시 실행하면 이어서 수집합니다.');
      break;
    }

    final stations = await _fetchRouteStations(serviceKey, routeId);
    if (stations.isNotEmpty) {
      routes[routeId] = {'info': route, 'stations': stations};
      fetched++;

      if (fetched % 10 == 0) {
        _saveCache(cache);
        print('   📥 $fetched개 완료 (총 ${routes.length}/${routeList.length})');
      }
    }

    // Rate limiting: 100ms 간격
    await Future.delayed(const Duration(milliseconds: 100));
  }

  cache['routes'] = routes;
  _saveCache(cache);

  print('\n━━━ 결과 ━━━');
  print('  수집된 노선: ${routes.length}/${routeList.length}');
  print('  이번 실행: $fetched개 신규, $skipped개 스킵');
  print('  API 호출: $callCount건');

  if (routes.length == routeList.length) {
    print('\n🎉 전체 수집 완료! dart run tools/generate_bus_dart.dart 실행하세요.');
  }
}

/// 모든 노선 목록 수집 (간선3xx, 지선5xxx/6xxx/7xxx, 순환 등)
Future<List<Map<String, dynamic>>> _fetchAllRoutes(String serviceKey) async {
  final results = <Map<String, dynamic>>[];
  final seen = <String>{};

  // 간선버스: 1xx~9xx, 지선: 마을버스 제외한 서울시내
  // getBusRouteList에 빈 검색어는 안됨 → 숫자/문자 prefix로 검색
  final searchTerms = [
    // 간선 (100~900번대)
    ...List.generate(9, (i) => '${i + 1}'),
    // N버스 (심야)
    'N',
    // 공항
    '60',
    // 광역
    'M',
    // 지선/마을은 숫자로 이미 커버됨
  ];

  for (final term in searchTerms) {
    if (callCount >= maxCallsPerRun) break;

    final url =
        '$baseRoute/getBusRouteList'
        '?serviceKey=$serviceKey'
        '&strSrch=${Uri.encodeComponent(term)}';

    try {
      callCount++;
      final response = await HttpClient()
          .getUrl(Uri.parse(url))
          .then((req) => req.close())
          .timeout(const Duration(seconds: 15));

      final body = await response.transform(utf8.decoder).join();
      _throwIfApiError(body);
      final items = _parseXmlItems(body);

      for (final item in items) {
        final id = item['busRouteId'] ?? '';
        if (id.isNotEmpty && !seen.contains(id)) {
          final routeType = int.tryParse(item['routeType'] ?? '0') ?? 0;
          // 서울시 버스만: 공항/마을/간선/지선/순환/광역/동행/한강/심야.
          if ({1, 2, 3, 4, 5, 6, 13, 14, 15}.contains(routeType)) {
            seen.add(id);
            results.add({
              'busRouteId': id,
              'busRouteNm': item['busRouteNm'] ?? '',
              'routeType': routeType,
              'stStationNm': item['stStationNm'] ?? '',
              'edStationNm': item['edStationNm'] ?? '',
              'term': int.tryParse(item['term'] ?? '') ?? 0,
            });
          }
        }
      }

      print('   검색 "$term": ${items.length}개 응답, 누적 ${results.length}개');
    } catch (e) {
      print('   ❌ 검색 "$term" 실패: $e');
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  return results;
}

/// 특정 노선의 정류소 목록 조회
Future<List<Map<String, dynamic>>> _fetchRouteStations(
  String serviceKey,
  String busRouteId,
) async {
  final url =
      '$baseRoute/getStaionByRoute'
      '?serviceKey=$serviceKey'
      '&busRouteId=$busRouteId';

  try {
    callCount++;
    final response = await HttpClient()
        .getUrl(Uri.parse(url))
        .then((req) => req.close())
        .timeout(const Duration(seconds: 15));

    final body = await response.transform(utf8.decoder).join();
    _throwIfApiError(body);
    final items = _parseXmlItems(body);

    final result = items.map((item) {
      return <String, dynamic>{
        'seq': int.tryParse(item['seq'] ?? '0') ?? 0,
        'stId': item['station'] ?? item['stId'] ?? '',
        'arsId': item['arsId'] ?? item['stationNo'] ?? '',
        'stNm': item['stationNm'] ?? item['stNm'] ?? '',
        'lat': double.tryParse(item['gpsY'] ?? '0') ?? 0.0,
        'lng': double.tryParse(item['gpsX'] ?? '0') ?? 0.0,
        'direction': item['direction'] ?? '',
      };
    }).toList();
    result.sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int));
    return result;
  } catch (e) {
    print('   ❌ 노선 $busRouteId 정류소 실패: $e');
    return [];
  }
}

/// XML 파싱
List<Map<String, String>> _parseXmlItems(String body) {
  final results = <Map<String, String>>[];

  // Simple XML parsing without xml package dependency
  final itemRegex = RegExp(r'<itemList>(.*?)</itemList>', dotAll: true);
  final fieldRegex = RegExp(r'<(\w+)>(.*?)</\1>');

  for (final match in itemRegex.allMatches(body)) {
    final itemXml = match.group(1) ?? '';
    final fields = <String, String>{};
    for (final field in fieldRegex.allMatches(itemXml)) {
      fields[field.group(1)!] = field.group(2)!;
    }
    if (fields.isNotEmpty) results.add(fields);
  }

  return results;
}

void _throwIfApiError(String body) {
  final code = RegExp(r'<headerCd>(.*?)</headerCd>').firstMatch(body)?.group(1);
  if (code == null || code == '0') return;
  final msg =
      RegExp(r'<headerMsg>(.*?)</headerMsg>').firstMatch(body)?.group(1) ??
      '알 수 없는 API 오류';
  throw StateError('서울시 버스 API 오류($code): $msg');
}

void _saveCache(Map<String, dynamic> cache) {
  File(
    cacheFile,
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(cache));
}
