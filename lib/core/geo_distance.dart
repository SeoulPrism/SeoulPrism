import 'dart:math';

/// 두 좌표 간 거리(미터). Haversine.
double distanceMeters(double aLat, double aLng, double bLat, double bLng) {
  const earthRadius = 6371000.0;
  final dLat = (bLat - aLat) * pi / 180;
  final dLng = (bLng - aLng) * pi / 180;
  final lat1 = aLat * pi / 180;
  final lat2 = bLat * pi / 180;
  final h =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * earthRadius * atan2(sqrt(h), sqrt(1 - h));
}

/// 한 좌표에서 polyline 까지 최소 거리 (미터). [coords] = [[lat, lng], ...].
double distanceToPolylineMeters(
  double lat,
  double lng,
  List<List<double>> coords,
) {
  var best = double.infinity;
  for (int i = 0; i < coords.length - 1; i++) {
    best = min(
      best,
      distanceToSegmentMeters(lat, lng, coords[i], coords[i + 1]),
    );
  }
  return best;
}

/// 한 좌표에서 한 선분까지 최소 거리 (미터). 평면 근사 (서울 위도 기준 정확).
double distanceToSegmentMeters(
  double lat,
  double lng,
  List<double> a,
  List<double> b,
) {
  final latScale = 111320.0;
  final lngScale = 111320.0 * cos(lat * pi / 180);
  final px = lng * lngScale;
  final py = lat * latScale;
  final ax = a[1] * lngScale;
  final ay = a[0] * latScale;
  final bx = b[1] * lngScale;
  final by = b[0] * latScale;
  final dx = bx - ax;
  final dy = by - ay;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) return sqrt(pow(px - ax, 2) + pow(py - ay, 2));
  final t = (((px - ax) * dx + (py - ay) * dy) / len2).clamp(0.0, 1.0);
  final cx = ax + dx * t;
  final cy = ay + dy * t;
  return sqrt(pow(px - cx, 2) + pow(py - cy, 2));
}

/// 서비스 가능한 영역 — 수도권 (서울/인천/경기 + 공항).
/// 이 박스를 벗어난 좌표로는 길찾기를 시도하지 않음 (시뮬레이터 SF 좌표 등 방어).
const double serviceMinLat = 36.7;
const double serviceMaxLat = 38.0;
const double serviceMinLng = 126.3;
const double serviceMaxLng = 127.8;

bool isInServiceArea(double lat, double lng) {
  return lat >= serviceMinLat &&
      lat <= serviceMaxLat &&
      lng >= serviceMinLng &&
      lng <= serviceMaxLng;
}

/// 두 좌표 사이 방위각 (북=0, 시계방향).
double bearingBetween(double aLat, double aLng, double bLat, double bLng) {
  final lat1 = aLat * pi / 180;
  final lat2 = bLat * pi / 180;
  final dLng = (bLng - aLng) * pi / 180;
  final y = sin(dLng) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
  return (atan2(y, x) * 180 / pi + 360) % 360;
}
