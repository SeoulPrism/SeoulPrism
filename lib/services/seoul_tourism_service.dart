import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_keys.dart';

/// 서울 문화행사 정보 (열린데이터광장 culturalEventInfo).
class CulturalEvent {
  final String title;
  final String category; // CODENAME (전시/미술, 공연, 축제 등)
  final String guName; // 자치구
  final String place;
  final DateTime? startDate;
  final DateTime? endDate;
  final String fee; // 'USE_FEE'
  final bool isFree;
  final String? imageUrl;
  final String? homepageUrl;
  final String? orgLink;
  final double? lat;
  final double? lng;

  const CulturalEvent({
    required this.title,
    required this.category,
    required this.guName,
    required this.place,
    this.startDate,
    this.endDate,
    this.fee = '',
    this.isFree = false,
    this.imageUrl,
    this.homepageUrl,
    this.orgLink,
    this.lat,
    this.lng,
  });

  /// 이벤트가 현재 진행 중인지 (today ∈ [start, end]).
  bool get isOngoing {
    final now = DateTime.now();
    final s = startDate;
    final e = endDate;
    if (s == null || e == null) return false;
    final today = DateTime(now.year, now.month, now.day);
    final sd = DateTime(s.year, s.month, s.day);
    final ed = DateTime(e.year, e.month, e.day);
    return !today.isBefore(sd) && !today.isAfter(ed);
  }

  /// '~ MM/DD' 또는 'MM/DD ~ MM/DD' 짧은 표기.
  String get shortDate {
    final s = startDate;
    final e = endDate;
    if (s == null && e == null) return '';
    String fmt(DateTime d) =>
        '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    if (s != null && e != null) {
      if (s.year == e.year && s.month == e.month && s.day == e.day) {
        return fmt(s);
      }
      return '${fmt(s)} ~ ${fmt(e)}';
    }
    return fmt(s ?? e!);
  }
}

/// 서울 관광/문화 데이터 서비스.
/// 현재는 culturalEventInfo (문화행사) 만 사용. 추후 관광지 API 추가 가능.
class SeoulTourismService {
  static SeoulTourismService? _instance;
  SeoulTourismService._();
  static SeoulTourismService get instance =>
      _instance ??= SeoulTourismService._();

  static const _baseUrl = 'http://openapi.seoul.go.kr:8088';

  // 간단한 메모리 캐시 (탭 전환 시 재요청 방지). 30분 TTL.
  List<CulturalEvent>? _cachedEvents;
  DateTime? _cachedAt;
  static const _ttl = Duration(minutes: 30);

  /// 서울 문화행사 — 진행 중인 행사를 우선 정렬해 반환.
  /// API 가 날짜순이 아니라 등록순이라, 받은 뒤 직접 정렬.
  Future<List<CulturalEvent>> getEvents({
    int limit = 30,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedEvents != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _ttl) {
      return _cachedEvents!.take(limit).toList();
    }

    try {
      final key = ApiKeys.seoulApiKey;
      if (key.isEmpty) return const [];

      // limit 보다 넉넉히 가져와서 진행 중 우선 필터.
      final fetch = (limit * 3).clamp(30, 100);
      final url = '$_baseUrl/$key/json/culturalEventInfo/1/$fetch/';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return _cachedEvents ?? const [];

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final rows = data['culturalEventInfo']?['row'] as List?;
      if (rows == null) return _cachedEvents ?? const [];

      final all = rows
          .map((e) => _parse(e as Map<String, dynamic>))
          .where((e) => e != null)
          .cast<CulturalEvent>()
          .toList();

      // 진행 중 → 다가오는 순 → 종료된 순.
      final now = DateTime.now();
      all.sort((a, b) {
        final aOn = a.isOngoing;
        final bOn = b.isOngoing;
        if (aOn != bOn) return aOn ? -1 : 1;
        final aStart = a.startDate ?? now;
        final bStart = b.startDate ?? now;
        return aStart.compareTo(bStart);
      });

      _cachedEvents = all;
      _cachedAt = DateTime.now();
      return all.take(limit).toList();
    } catch (e) {
      debugPrint('[SeoulTourismService] 행사 로드 실패: $e');
      return _cachedEvents ?? const [];
    }
  }

  CulturalEvent? _parse(Map<String, dynamic> r) {
    final title = (r['TITLE'] ?? '').toString().trim();
    if (title.isEmpty) return null;
    return CulturalEvent(
      title: title,
      category: (r['CODENAME'] ?? '문화').toString(),
      guName: (r['GUNAME'] ?? '').toString(),
      place: (r['PLACE'] ?? '').toString(),
      startDate: _parseDate(r['STRTDATE']),
      endDate: _parseDate(r['END_DATE']),
      fee: (r['USE_FEE'] ?? '').toString(),
      isFree: (r['IS_FREE'] ?? '').toString().contains('무료'),
      imageUrl: _emptyToNull(r['MAIN_IMG']),
      homepageUrl: _emptyToNull(r['HMPG_ADDR']),
      orgLink: _emptyToNull(r['ORG_LINK']),
      lat: double.tryParse((r['LAT'] ?? '').toString()),
      lng: double.tryParse((r['LOT'] ?? '').toString()),
    );
  }

  static String? _emptyToNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    // '2026-08-13 00:00:00.0' 또는 '2026-08-13' 둘 다 처리.
    try {
      return DateTime.parse(s.replaceFirst(' ', 'T').split('.').first);
    } catch (_) {
      return null;
    }
  }
}
