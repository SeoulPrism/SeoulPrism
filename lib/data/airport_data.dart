import 'dart:math';

/// 미니도쿄3D coordinates.json 동일 패턴 공항 시뮬레이션
/// - 경로: [lat, lng, alt] 웨이포인트 배열
/// - 고도: 0(활주로) ~ 1000m(순항)
/// - 활주로 양끝 alt=0, 유도로 없음
/// - 항상 일정 수 비행기가 각 단계에 분포
class AirportData {
  // ── 인천공항 경로 (미니도쿄 airways 동일 구조) ──
  // 핵심: 이륙 시 활주로 연장선에서 서서히 상승 (수직이륙 방지)
  static const _icnRoutes = <String, List<List<double>>>{
    // 33R 출발
    'ICN.33R.Dep': [
      [37.456385, 126.464699, 0],   // 활주로 start
      [37.470, 126.452, 0],         // 활주로 중간 (가속)
      [37.483922, 126.440194, 0],   // 활주로 end (이륙점)
      [37.490, 126.434, 5],         // 바퀴 뜸
      [37.497, 126.428, 15],        // 1km 상승 시작
      [37.508, 126.415, 50],        // 3km
      [37.525, 126.398, 150],       // 6km
      [37.550, 126.375, 350],       // 10km
      [37.590, 126.340, 650],       // 17km
      [37.640, 126.300, 1000],      // 25km
    ],
    // 33R 도착
    'ICN.33R.Arr': [
      [37.360, 126.560, 1000],      // 25km
      [37.390, 126.530, 650],       // 17km
      [37.410, 126.510, 350],       // 10km
      [37.425, 126.495, 150],       // 6km
      [37.440, 126.480, 50],        // 3km
      [37.449, 126.472, 15],        // 1km
      [37.453, 126.468, 5],         // 500m
      [37.456385, 126.464699, 0],   // 터치다운!
      [37.470, 126.452, 0],         // 감속
      [37.483922, 126.440194, 0],   // 활주로 끝
    ],
    // 33L 출발
    'ICN.33L.Dep': [
      [37.454277, 126.460825, 0],
      [37.468, 126.448, 0],
      [37.481761, 126.436391, 0],
      [37.488, 126.430, 5],
      [37.495, 126.424, 15],
      [37.505, 126.412, 50],
      [37.522, 126.395, 150],
      [37.548, 126.372, 350],
      [37.585, 126.338, 650],
      [37.635, 126.295, 1000],
    ],
    // 33L 도착
    'ICN.33L.Arr': [
      [37.355, 126.555, 1000],
      [37.385, 126.525, 650],
      [37.408, 126.503, 350],
      [37.422, 126.490, 150],
      [37.435, 126.478, 50],
      [37.445, 126.468, 15],
      [37.450, 126.464, 5],
      [37.454277, 126.460825, 0],
      [37.468, 126.448, 0],
      [37.481761, 126.436391, 0],
    ],
  };

  // ── 김포공항 경로 ──
  static const _gmpRoutes = <String, List<List<double>>>{
    // 32R 출발
    'GMP.32R.Dep': [
      [37.547746, 126.807115, 0],
      [37.559, 126.793, 0],
      [37.570700, 126.778313, 0],
      [37.576, 126.772, 5],
      [37.582, 126.765, 15],
      [37.590, 126.755, 50],
      [37.605, 126.738, 150],
      [37.625, 126.715, 350],
      [37.660, 126.675, 650],
      [37.700, 126.620, 1000],
    ],
    // 32R 도착
    'GMP.32R.Arr': [
      [37.470, 126.880, 1000],
      [37.495, 126.858, 650],
      [37.510, 126.843, 350],
      [37.522, 126.832, 150],
      [37.535, 126.820, 50],
      [37.541, 126.814, 15],
      [37.544, 126.810, 5],
      [37.547746, 126.807115, 0],
      [37.559, 126.793, 0],
      [37.570700, 126.778313, 0],
    ],
    // 32L 출발
    'GMP.32L.Dep': [
      [37.548004, 126.801011, 0],
      [37.558, 126.788, 0],
      [37.568399, 126.775424, 0],
      [37.574, 126.769, 5],
      [37.580, 126.762, 15],
      [37.588, 126.750, 50],
      [37.603, 126.733, 150],
      [37.623, 126.710, 350],
      [37.658, 126.670, 650],
      [37.698, 126.615, 1000],
    ],
    // 32L 도착
    'GMP.32L.Arr': [
      [37.468, 126.875, 1000],
      [37.493, 126.853, 650],
      [37.508, 126.838, 350],
      [37.520, 126.827, 150],
      [37.533, 126.815, 50],
      [37.540, 126.808, 15],
      [37.544, 126.804, 5],
      [37.548004, 126.801011, 0],
      [37.558, 126.788, 0],
      [37.568399, 126.775424, 0],
    ],
  };

  /// 모든 경로
  static Map<String, List<List<double>>> get allRoutes => {
    ..._icnRoutes,
    ..._gmpRoutes,
  };

  /// 경로 이름 목록
  static List<String> get routeNames => allRoutes.keys.toList();

  static int _flightsPerHour(String code, int hour) {
    if (hour >= 1 && hour < 5) return 3;
    if (hour >= 6 && hour < 9) return code == 'ICN' ? 35 : 20;
    if (hour >= 9 && hour < 12) return code == 'ICN' ? 30 : 18;
    if (hour >= 12 && hour < 15) return code == 'ICN' ? 25 : 15;
    if (hour >= 15 && hour < 19) return code == 'ICN' ? 35 : 22;
    if (hour >= 19 && hour < 23) return code == 'ICN' ? 30 : 18;
    return 5;
  }

  /// 활성 비행기 — 항상 모든 경로에 비행기가 분포
  static List<SimulatedFlight> getActiveFlights() {
    final now = DateTime.now();
    final totalMs = now.minute * 60000.0 + now.second * 1000.0 + now.millisecond;
    final flights = <SimulatedFlight>[];
    final names = routeNames;

    // 각 경로마다 2~3대씩 (총 16~24대)
    for (int ri = 0; ri < names.length; ri++) {
      final routeName = names[ri];
      final route = allRoutes[routeName]!;
      final isICN = routeName.startsWith('ICN');
      final freq = _flightsPerHour(isICN ? 'ICN' : 'GMP', now.hour);
      final perRoute = (freq / (isICN ? 4 : 4) * 3 / 60).ceil().clamp(1, 3);

      for (int fi = 0; fi < perRoute; fi++) {
        // 각 비행기 위상: 3분(180초) 주기, 균등 분포
        const cyclMs = 180000.0; // 3분
        final offset = (ri * 30000.0 + fi * cyclMs / perRoute);
        final t = ((totalMs + offset) % cyclMs) / cyclMs;

        final flight = _interpolateRoute(route, t, routeName, fi);
        if (flight != null) flights.add(flight);
      }
    }

    return flights;
  }

  /// 경로 위 위치 보간 (미니도쿄 compute-fragment.glsl 동일)
  static SimulatedFlight? _interpolateRoute(
    List<List<double>> route, double t, String routeName, int idx,
  ) {
    if (route.length < 2) return null;

    // 누적 거리
    final dists = <double>[0];
    double total = 0;
    for (int i = 1; i < route.length; i++) {
      final dy = (route[i][0] - route[i-1][0]) * 111320;
      final dx = (route[i][1] - route[i-1][1]) * 88000;
      total += sqrt(dy * dy + dx * dx);
      dists.add(total);
    }
    if (total == 0) return null;

    // 미니도쿄: 가속 → 정속 → 감속
    const accT = 0.12, decT = 0.12;
    double progress;
    if (t < accT) {
      final a = t / accT;
      progress = a * a * accT * 0.5;
    } else if (t > 1 - decT) {
      final a = (1 - t) / decT;
      progress = 1 - a * a * decT * 0.5;
    } else {
      progress = accT * 0.5 + (t - accT);
    }
    progress = progress.clamp(0.0, 1.0);

    final targetDist = progress * total;

    // 구간 찾기
    int si = 0;
    for (int i = 1; i < dists.length; i++) {
      if (dists[i] >= targetDist) { si = i - 1; break; }
      si = i - 1;
    }
    si = si.clamp(0, route.length - 2);

    final segLen = dists[si + 1] - dists[si];
    final segT = segLen > 0 ? (targetDist - dists[si]) / segLen : 0.0;

    final from = route[si];
    final to = route[si + 1];
    final lat = from[0] + (to[0] - from[0]) * segT;
    final lng = from[1] + (to[1] - from[1]) * segT;
    final alt = from[2] + (to[2] - from[2]) * segT;

    final bdy = to[0] - from[0];
    final bdx = to[1] - from[1];
    final bearing = (bdy == 0 && bdx == 0) ? 0.0
        : (atan2(bdx * 88000, bdy * 111320) * 180 / pi + 360) % 360;

    final isDep = routeName.contains('Dep');
    String phase;
    if (isDep) {
      if (alt < 1) phase = '활주';
      else if (alt < 100) phase = '이륙';
      else phase = '상승';
    } else {
      if (alt > 300) phase = '접근';
      else if (alt > 10) phase = '최종접근';
      else if (alt > 0) phase = '착지';
      else phase = '감속';
    }

    final id = '${routeName}_$idx';
    return SimulatedFlight(
      id: id,
      callsign: _callsign(id),
      lat: lat, lng: lng, altitude: alt, bearing: bearing,
      isDeparture: isDep, phase: phase,
      airportCode: routeName.substring(0, 3),
    );
  }

  static String _callsign(String id) {
    const al = ['KAL', 'AAR', 'JNA', 'JJA', 'TWB', 'ABL', 'EVA', 'CPA', 'ANA', 'JAL'];
    return '${al[id.hashCode.abs() % al.length]}${(id.hashCode.abs() % 900) + 100}';
  }
}

class Airport {
  final String code, name;
  final List<Runway> runways;
  const Airport({required this.code, required this.name, required this.runways});
}

class Runway {
  final String name;
  final double startLat, startLng, endLat, endLng;
  const Runway({required this.name, required this.startLat, required this.startLng, required this.endLat, required this.endLng});
}

class SimulatedFlight {
  final String id, callsign, phase, airportCode;
  final double lat, lng, altitude, bearing;
  final bool isDeparture;
  SimulatedFlight({required this.id, required this.callsign, required this.lat, required this.lng, required this.altitude, required this.bearing, required this.isDeparture, required this.phase, required this.airportCode});
}
