import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_keys.dart';

/// OpenSky Network API + 인천공항 여객기 스케줄 기반 항공기 서비스
class FlightService {
  static final FlightService instance = FlightService._();
  FlightService._();

  // ── OpenSky (실시간 위치) ──
  static const String _openSkyUrl =
      'https://opensky-network.org/api/states/all';
  static const double _lamin = 37.1;
  static const double _lomin = 126.1;
  static const double _lamax = 37.85;
  static const double _lomax = 127.5;

  // ── 인천공항 여객기 스케줄 ──
  static const String _icnBaseUrl =
      'https://apis.data.go.kr/B551177/StatusOfPassengerFlightsDeOdp';
  String get _icnServiceKey => ApiKeys.dataGoKrApiKey;

  // OAuth2 토큰
  String? _accessToken;
  DateTime? _tokenExpiry;

  // Rate limit 백오프
  DateTime? _rateLimitedUntil;

  // 스케줄 캐시
  List<IcnFlightSchedule> _departureSchedules = [];
  List<IcnFlightSchedule> _arrivalSchedules = [];
  DateTime? _lastScheduleFetch;

  /// OAuth2 토큰 발급/갱신
  Future<void> _ensureToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(
          _tokenExpiry!.subtract(const Duration(seconds: 30)),
        )) {
      return; // 아직 유효
    }
    try {
      final resp = await http
          .post(
            Uri.parse(
              'https://opensky-network.org/auth/realms/opensky/protocol/openid-connect/token',
            ),
            body: {
              'client_id': ApiKeys.openSkyClientId,
              'client_secret': ApiKeys.openSkyClientSecret,
              'grant_type': 'client_credentials',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int? ?? 300;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        debugPrint('[FlightAPI] ✅ OAuth2 토큰 발급 (${expiresIn}s)');
      }
    } catch (e) {
      // 토큰 실패해도 anonymous로 진행
      debugPrint('[FlightAPI] ⚠️ OAuth2 토큰 실패 (anonymous 모드): $e');
    }
  }

  /// 서울 영공 실시간 항공기 위치 조회 (OpenSky)
  Future<List<FlightPosition>> fetchFlights() async {
    // 스케줄도 주기적으로 갱신 (5분마다)
    if (_lastScheduleFetch == null ||
        DateTime.now().difference(_lastScheduleFetch!).inMinutes > 5) {
      _fetchSchedules(); // fire-and-forget
    }

    // 429 백오프 중이면 스킵
    if (_rateLimitedUntil != null &&
        DateTime.now().isBefore(_rateLimitedUntil!)) {
      return [];
    }
    _rateLimitedUntil = null;

    // OAuth2 토큰 갱신
    await _ensureToken();

    final url =
        '$_openSkyUrl?lamin=$_lamin&lomin=$_lomin&lamax=$_lamax&lomax=$_lomax';

    try {
      final headers = <String, String>{};
      if (_accessToken != null) {
        headers['Authorization'] = 'Bearer $_accessToken';
      }
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final states = data['states'] as List?;
        if (states == null || states.isEmpty) return [];

        final flights = <FlightPosition>[];
        for (final s in states) {
          if (s is! List || s.length < 12) continue;
          final lat = (s[6] as num?)?.toDouble();
          final lng = (s[5] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          flights.add(
            FlightPosition(
              icao24: (s[0] as String?) ?? '',
              callsign: ((s[1] as String?) ?? '').trim(),
              lat: lat,
              lng: lng,
              altitude: (s[7] as num?)?.toDouble() ?? 0,
              velocity: (s[9] as num?)?.toDouble() ?? 0,
              heading: (s[10] as num?)?.toDouble() ?? 0,
              verticalRate: (s[11] as num?)?.toDouble() ?? 0,
              onGround: (s[8] as bool?) ?? false,
              originCountry: (s[2] as String?) ?? '',
            ),
          );
        }

        return flights;
      } else if (response.statusCode == 429) {
        if (_rateLimitedUntil == null) {
          debugPrint('[FlightAPI] ⚠️ Rate limited → 5분 대기');
        }
        _rateLimitedUntil = DateTime.now().add(const Duration(minutes: 5));
        return [];
      }
      return [];
    } on TimeoutException {
      debugPrint('[FlightAPI] ⏱️ 요청 시간 초과');
      return [];
    } catch (e) {
      debugPrint('[FlightAPI] ❌ 오류: $e');
      return [];
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 인천공항 여객기 스케줄 (이착륙 시뮬레이션용)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 현재 시간 ±30분 출발/도착 스케줄 가져오기
  Future<void> _fetchSchedules() async {
    _lastScheduleFetch = DateTime.now();
    final now = DateTime.now();
    final fromTime =
        '${(now.hour * 100 + now.minute - 30).clamp(0, 2359).toString().padLeft(4, '0')}';
    final toTime =
        '${(now.hour * 100 + now.minute + 30).clamp(0, 2359).toString().padLeft(4, '0')}';

    try {
      // 출발편
      final depUrl =
          '$_icnBaseUrl/getPassengerDeparturesDeOdp'
          '?serviceKey=$_icnServiceKey&pageNo=1&numOfRows=30&type=json'
          '&from_time=$fromTime&to_time=$toTime';
      final depResp = await http
          .get(Uri.parse(depUrl))
          .timeout(const Duration(seconds: 10));
      if (depResp.statusCode == 200) {
        final data = jsonDecode(depResp.body);
        final items = data['response']?['body']?['items'] as List? ?? [];
        _departureSchedules = items
            .map((e) => IcnFlightSchedule.fromJson(e, true))
            .toList();
        debugPrint('[FlightAPI] ✅ 인천 출발 스케줄: ${_departureSchedules.length}편');
      }

      // 도착편
      final arrUrl =
          '$_icnBaseUrl/getPassengerArrivalsDeOdp'
          '?serviceKey=$_icnServiceKey&pageNo=1&numOfRows=30&type=json'
          '&from_time=$fromTime&to_time=$toTime';
      final arrResp = await http
          .get(Uri.parse(arrUrl))
          .timeout(const Duration(seconds: 10));
      if (arrResp.statusCode == 200) {
        final data = jsonDecode(arrResp.body);
        final items = data['response']?['body']?['items'] as List? ?? [];
        _arrivalSchedules = items
            .map((e) => IcnFlightSchedule.fromJson(e, false))
            .toList();
        debugPrint('[FlightAPI] ✅ 인천 도착 스케줄: ${_arrivalSchedules.length}편');
      }
    } catch (e) {
      debugPrint('[FlightAPI] ⚠️ 인천공항 스케줄 조회 실패: $e');
    }
  }

  /// 스케줄 기반 이착륙 시뮬레이션 비행기 생성
  /// OpenSky에 안 잡히는 공항 근처 비행기를 보충
  List<FlightPosition> getSimulatedAirportFlights() {
    final now = DateTime.now();
    final currentMin = now.hour * 60 + now.minute;
    final flights = <FlightPosition>[];

    // 인천공항 활주로 (15L 방향)
    const icnLat = 37.4602;
    const icnLng = 126.4407;
    const runwayHeading = 150.0; // 15L/33R

    for (final sched in _departureSchedules) {
      final diff = currentMin - sched.scheduledMinute;
      // 출발 예정 시각 -2분 ~ +5분 사이면 이륙 시뮬레이션
      if (diff >= -2 && diff <= 5) {
        final t = ((diff + 2) / 7).clamp(0.0, 1.0);
        final pos = _simulateDeparture(icnLat, icnLng, runwayHeading, t, sched);
        if (pos != null) flights.add(pos);
      }
    }

    for (final sched in _arrivalSchedules) {
      final diff = currentMin - sched.scheduledMinute;
      // 도착 예정 시각 -5분 ~ +2분 사이면 착륙 시뮬레이션
      if (diff >= -5 && diff <= 2) {
        final t = ((diff + 5) / 7).clamp(0.0, 1.0);
        final pos = _simulateArrival(icnLat, icnLng, runwayHeading, t, sched);
        if (pos != null) flights.add(pos);
      }
    }

    return flights;
  }

  FlightPosition? _simulateDeparture(
    double apLat,
    double apLng,
    double heading,
    double t,
    IcnFlightSchedule sched,
  ) {
    final rad = heading * 3.14159265 / 180.0;
    final cosH = cos(rad);
    final sinH = sin(rad);

    double lat, lng, alt, vRate;
    if (t < 0.3) {
      // 활주로 가속
      final d = t / 0.3 * 1000;
      lat = apLat + d * cosH / 111320;
      lng = apLng + d * sinH / 88000;
      alt = 0;
      vRate = 0;
    } else {
      // 이륙 상승
      final ct = (t - 0.3) / 0.7;
      final d = 1000 + ct * 8000;
      alt = ct * 2000;
      vRate = 15.0;
      lat = apLat + d * cosH / 111320;
      lng = apLng + d * sinH / 88000;
    }

    return FlightPosition(
      icao24: 'sim_dep_${sched.flightId}',
      callsign: sched.flightId,
      lat: lat,
      lng: lng,
      altitude: alt,
      velocity: t < 0.3 ? 50 + t * 200 : 200,
      heading: heading,
      verticalRate: vRate,
      onGround: t < 0.3,
      originCountry: 'Republic of Korea',
    );
  }

  FlightPosition? _simulateArrival(
    double apLat,
    double apLng,
    double heading,
    double t,
    IcnFlightSchedule sched,
  ) {
    // 반대 방향에서 접근
    final appHeading = (heading + 180) % 360;
    final appRad = appHeading * 3.14159265 / 180.0;
    final cosH = cos(appRad);
    final sinH = sin(appRad);
    final landHeading = heading; // 착륙은 활주로 방향

    double lat, lng, alt, vRate;
    if (t < 0.7) {
      // 접근 (ILS 글라이드)
      final d = (1 - t / 0.7) * 10000;
      alt = (1 - t / 0.7) * 1000;
      vRate = -5.0;
      lat = apLat + d * cosH / 111320;
      lng = apLng + d * sinH / 88000;
    } else {
      // 착지 감속
      final gt = (t - 0.7) / 0.3;
      final landRad = landHeading * 3.14159265 / 180.0;
      final d = gt * 800;
      alt = 0;
      vRate = 0;
      lat = apLat + d * cos(landRad) / 111320;
      lng = apLng + d * sin(landRad) / 88000;
    }

    return FlightPosition(
      icao24: 'sim_arr_${sched.flightId}',
      callsign: sched.flightId,
      lat: lat,
      lng: lng,
      altitude: alt,
      velocity: t < 0.7 ? 250 - t * 150 : 80 - (t - 0.7) * 200,
      heading: t < 0.7 ? (appHeading + 180) % 360 : landHeading,
      verticalRate: vRate,
      onGround: t >= 0.7,
      originCountry: 'Republic of Korea',
    );
  }
}

/// 항공기 위치 데이터
class FlightPosition {
  final String icao24; // ICAO 24-bit 고유 주소
  final String callsign; // 콜사인 (예: KAL1822, AAR8956)
  final double lat;
  final double lng;
  final double altitude; // 기압 고도 (m)
  final double velocity; // 대지 속도 (m/s)
  final double heading; // 방향 (도, 북=0 시계방향)
  final double verticalRate; // 수직 속도 (m/s, +상승 -하강)
  final bool onGround; // 지상 여부
  final String originCountry;

  FlightPosition({
    required this.icao24,
    required this.callsign,
    required this.lat,
    required this.lng,
    required this.altitude,
    required this.velocity,
    required this.heading,
    required this.verticalRate,
    required this.onGround,
    required this.originCountry,
  });

  /// 고도 기반 비행 단계 판별
  String get phase {
    if (onGround) return '지상';
    if (altitude < 1000) return '이착륙';
    if (verticalRate > 2) return '상승';
    if (verticalRate < -2) return '하강';
    return '순항';
  }

  /// 항공사 추정 (콜사인 앞 3글자)
  String get airline {
    if (callsign.length < 3) return callsign;
    final code = callsign.substring(0, 3);
    return _airlineNames[code] ?? code;
  }

  static const Map<String, String> _airlineNames = {
    'KAL': '대한항공',
    'AAR': '아시아나',
    'JNA': '진에어',
    'JJA': '제주항공',
    'TWB': '티웨이',
    'ABL': '에어부산',
    'ASV': '에어서울',
    'EOK': '이스타',
    'ACA': '에어캐나다',
    'CPA': '캐세이퍼시픽',
    'CES': '중국동방항공',
    'CSN': '중국남방항공',
    'ANA': '전일본공수',
    'JAL': '일본항공',
    'UAL': '유나이티드',
    'DAL': '델타',
    'AAL': '아메리칸',
    'DLH': '루프트한자',
    'SIA': '싱가포르항공',
    'THA': '타이항공',
    'EVA': '에바항공',
    'FDX': 'FedEx',
    'UPS': 'UPS',
  };
}

/// 인천공항 여객기 스케줄
class IcnFlightSchedule {
  final String flightId; // 편명 (KE901 등)
  final String airline; // 항공사명
  final String airport; // 출발지/도착지 공항명
  final int scheduledMinute; // 예정 시각 (분 단위, 0~1440)
  final bool isDeparture;
  final String? remark; // 운항 상태

  IcnFlightSchedule({
    required this.flightId,
    required this.airline,
    required this.airport,
    required this.scheduledMinute,
    required this.isDeparture,
    this.remark,
  });

  factory IcnFlightSchedule.fromJson(
    Map<String, dynamic> json,
    bool departure,
  ) {
    final timeStr = (json['scheduleDateTime'] ?? '000000000000').toString();
    // YYYYMMDDHHMM → 분으로 변환
    int minute = 0;
    if (timeStr.length >= 12) {
      final h = int.tryParse(timeStr.substring(8, 10)) ?? 0;
      final m = int.tryParse(timeStr.substring(10, 12)) ?? 0;
      minute = h * 60 + m;
    }

    return IcnFlightSchedule(
      flightId: (json['flightId'] ?? '').toString().trim(),
      airline: (json['airline'] ?? '').toString(),
      airport: (json['airport'] ?? '').toString(),
      scheduledMinute: minute,
      isDeparture: departure,
      remark: json['remark']?.toString(),
    );
  }
}
