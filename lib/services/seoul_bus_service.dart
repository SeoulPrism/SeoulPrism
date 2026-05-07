import '../core/debug_log.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../core/api_keys.dart';
import '../models/bus_models.dart';

/// 서울시 버스 공공데이터 API 연동 서비스
/// data.go.kr 서울특별시 버스정보 API 사용
/// - 버스위치정보조회: http://ws.bus.go.kr/api/rest/buspos
/// - 버스도착정보조회: http://ws.bus.go.kr/api/rest/arrive
/// - 노선정보조회: http://ws.bus.go.kr/api/rest/busRouteInfo
/// - 정류소정보조회: http://ws.bus.go.kr/api/rest/stationinfo
class SeoulBusService {
  static final SeoulBusService instance = SeoulBusService._();
  SeoulBusService._();

  static const String _baseBusPos = 'http://ws.bus.go.kr/api/rest/buspos';
  static const String _baseArrive = 'http://ws.bus.go.kr/api/rest/arrive';
  static const String _baseRoute = 'http://ws.bus.go.kr/api/rest/busRouteInfo';
  static const String _baseStation = 'http://ws.bus.go.kr/api/rest/stationinfo';

  String get _serviceKey => ApiKeys.dataGoKrApiKey;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // API 호출 예산 관리 (일일 1,000건 제한)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static const int dailyLimit = 1000;
  int _callCount = 0;
  DateTime _countResetDate = DateTime.now();
  String? lastApiError;

  int get callCount {
    _resetIfNewDay();
    return _callCount;
  }

  int get remainingCalls => (dailyLimit - callCount).clamp(0, dailyLimit);

  void _resetIfNewDay() {
    final now = DateTime.now();
    if (now.day != _countResetDate.day ||
        now.month != _countResetDate.month ||
        now.year != _countResetDate.year) {
      _callCount = 0;
      _countResetDate = now;
      DebugLog.log('[SeoulBusAPI] 🔄 일일 호출 카운터 리셋');
    }
  }

  void _incrementCallCount() {
    _resetIfNewDay();
    _callCount++;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 1. 실시간 버스 위치 (getBusPosByRtidList)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 특정 노선의 실시간 버스 위치 조회
  Future<List<BusPosition>> fetchBusPositions(String busRouteId) async {
    if (_serviceKey.isEmpty) {
      DebugLog.log('[SeoulBusAPI] ⚠️ DATA_GO_KR_API_KEY가 설정되지 않음');
      return [];
    }
    if (remainingCalls <= 0) {
      DebugLog.log('[SeoulBusAPI] 🚫 일일 호출 한도 소진');
      return [];
    }

    final url = '$_baseBusPos/getBusPosByRtid'
        '?serviceKey=$_serviceKey'
        '&busRouteId=$busRouteId';

    try {
      _incrementCallCount();
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final items = _parseXmlItems(response.body, 'itemList');
        final positions = items.map((e) => BusPosition.fromXml(e)).toList();
        DebugLog.log('[SeoulBusAPI] ✅ 노선 $busRouteId: ${positions.length}대 버스 (남은: $remainingCalls)');
        return positions;
      } else {
        DebugLog.log('[SeoulBusAPI] ❌ HTTP ${response.statusCode}');
        return [];
      }
    } on TimeoutException {
      DebugLog.log('[SeoulBusAPI] ⏱️ 버스위치 요청 시간 초과');
      return [];
    } catch (e) {
      DebugLog.log('[SeoulBusAPI] ❌ 버스위치 오류: $e');
      return [];
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 2. 버스 도착 정보 (getArrInfoByRouteAll)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 특정 노선의 전체 정류소 도착정보 조회
  Future<List<BusArrivalInfo>> fetchArrivalsByRoute(String busRouteId) async {
    if (_serviceKey.isEmpty) return [];
    if (remainingCalls <= 0) return [];

    final url = '$_baseArrive/getArrInfoByRouteAll'
        '?serviceKey=$_serviceKey'
        '&busRouteId=$busRouteId';

    try {
      _incrementCallCount();
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final items = _parseXmlItems(response.body, 'itemList');
        final arrivals = items.map((e) => BusArrivalInfo.fromXml(e)).toList();
        DebugLog.log('[SeoulBusAPI] ✅ 도착정보 $busRouteId: ${arrivals.length}개 정류소');
        return arrivals;
      }
      return [];
    } on TimeoutException {
      DebugLog.log('[SeoulBusAPI] ⏱️ 도착정보 시간 초과');
      return [];
    } catch (e) {
      DebugLog.log('[SeoulBusAPI] ❌ 도착정보 오류: $e');
      return [];
    }
  }

  /// 특정 정류소 + 노선의 도착정보 조회
  Future<BusArrivalInfo?> fetchArrivalByRouteAndStation(
    String busRouteId,
    String stId,
    int ord,
  ) async {
    if (_serviceKey.isEmpty) return null;
    if (remainingCalls <= 0) return null;

    final url = '$_baseArrive/getArrInfoByRoute'
        '?serviceKey=$_serviceKey'
        '&busRouteId=$busRouteId'
        '&stId=$stId'
        '&ord=$ord';

    try {
      _incrementCallCount();
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final items = _parseXmlItems(response.body, 'itemList');
        if (items.isNotEmpty) {
          return BusArrivalInfo.fromXml(items.first);
        }
      }
      return null;
    } catch (e) {
      DebugLog.log('[SeoulBusAPI] ❌ 정류소 도착정보 오류: $e');
      return null;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3. 노선 정보 (getBusRouteList / getStaionByRoute)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 노선명으로 검색
  Future<List<BusRouteInfo>> searchRoutes(String keyword) async {
    if (_serviceKey.isEmpty) return [];
    if (remainingCalls <= 0) return [];

    final url = '$_baseRoute/getBusRouteList'
        '?serviceKey=$_serviceKey'
        '&strSrch=${Uri.encodeComponent(keyword)}';

    try {
      _incrementCallCount();
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final items = _parseXmlItems(response.body, 'itemList');
        final routes = items.map((e) => BusRouteInfo.fromXml(e)).toList();
        DebugLog.log('[SeoulBusAPI] ✅ 노선 검색 "$keyword": ${routes.length}개');
        return routes;
      }
      return [];
    } catch (e) {
      DebugLog.log('[SeoulBusAPI] ❌ 노선 검색 오류: $e');
      return [];
    }
  }

  /// 노선의 정류소 목록 (경로 좌표 포함)
  Future<List<BusRouteStation>> fetchRouteStations(String busRouteId) async {
    if (_serviceKey.isEmpty) return [];
    if (remainingCalls <= 0) return [];

    final url = '$_baseRoute/getStaionByRoute'
        '?serviceKey=$_serviceKey'
        '&busRouteId=$busRouteId';

    try {
      _incrementCallCount();
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final items = _parseXmlItems(response.body, 'itemList');
        final stations = items.map((e) => BusRouteStation.fromXml(e)).toList();
        stations.sort((a, b) => a.seq.compareTo(b.seq));
        DebugLog.log('[SeoulBusAPI] ✅ 노선정류소 $busRouteId: ${stations.length}개');
        return stations;
      }
      return [];
    } catch (e) {
      DebugLog.log('[SeoulBusAPI] ❌ 노선정류소 오류: $e');
      return [];
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 4. 정류소 정보 (getStationByName / getStationByUid)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 정류소명으로 검색
  Future<List<BusStationInfo>> searchStations(String name) async {
    if (_serviceKey.isEmpty) return [];
    if (remainingCalls <= 0) return [];

    final url = '$_baseStation/getStationByName'
        '?serviceKey=$_serviceKey'
        '&stSrch=${Uri.encodeComponent(name)}';

    try {
      _incrementCallCount();
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final items = _parseXmlItems(response.body, 'itemList');
        final stations = items.map((e) => BusStationInfo.fromXml(e)).toList();
        DebugLog.log('[SeoulBusAPI] ✅ 정류소 검색 "$name": ${stations.length}개');
        return stations;
      }
      return [];
    } catch (e) {
      DebugLog.log('[SeoulBusAPI] ❌ 정류소 검색 오류: $e');
      return [];
    }
  }

  /// 정류소 고유번호(arsId)로 조회
  Future<BusStationInfo?> fetchStationByArsId(String arsId) async {
    if (_serviceKey.isEmpty) return null;
    if (remainingCalls <= 0) return null;

    final url = '$_baseStation/getStationByUid'
        '?serviceKey=$_serviceKey'
        '&arsId=$arsId';

    try {
      _incrementCallCount();
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final items = _parseXmlItems(response.body, 'itemList');
        if (items.isNotEmpty) {
          return BusStationInfo.fromXml(items.first);
        }
      }
      return null;
    } catch (e) {
      DebugLog.log('[SeoulBusAPI] ❌ 정류소 조회 오류: $e');
      return null;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // XML 파서 유틸리티
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// XML 응답에서 itemList 요소들을 파싱하여 Map 리스트로 반환
  List<Map<String, String>> _parseXmlItems(String body, String itemTag) {
    try {
      final document = xml.XmlDocument.parse(body);
      final items = document.findAllElements(itemTag);
      return items.map((item) {
        final fields = <String, String>{};
        for (final child in item.children) {
          if (child is xml.XmlElement) {
            fields[child.name.local] = child.innerText;
          }
        }
        return fields;
      }).toList();
    } catch (e) {
      // XML 파싱 실패 시 에러 코드 확인
      DebugLog.log('[SeoulBusAPI] ⚠️ XML 파싱 실패: $e');
      DebugLog.log('[SeoulBusAPI] 응답 본문(200자): ${body.substring(0, body.length.clamp(0, 200))}');
      return [];
    }
  }
}
