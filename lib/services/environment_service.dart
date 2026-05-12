import '../core/debug_log.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

/// 서울 좌표
const double _seoulLat = 37.5665;
const double _seoulLng = 126.9780;

/// 날씨 상태
enum WeatherCondition {
  clear,    // 맑음
  cloudy,   // 흐림
  rain,     // 비
  snow,     // 눈
  fog,      // 안개
  drizzle,  // 이슬비
  thunderstorm, // 뇌우
}

/// 시간대
enum DayPhase {
  night,  // 밤
  dawn,   // 새벽/일출
  day,    // 낮
  dusk,   // 황혼/일몰
}

/// 환경 데이터 (시간 + 날씨)
class EnvironmentData {
  final DayPhase timeOfDay;
  final String lightPreset; // Mapbox: day, night, dawn, dusk
  final WeatherCondition weather;
  final double temperature; // 섭씨
  final double cloudCover;  // 0~100%
  final double visibility;  // km
  final double windSpeed;   // km/h
  final double precipitation; // mm
  final String weatherDescription;
  final IconData weatherIcon;
  final DateTime sunrise;
  final DateTime sunset;

  const EnvironmentData({
    required this.timeOfDay,
    required this.lightPreset,
    required this.weather,
    required this.temperature,
    required this.cloudCover,
    required this.visibility,
    required this.windSpeed,
    required this.precipitation,
    required this.weatherDescription,
    required this.weatherIcon,
    required this.sunrise,
    required this.sunset,
  });
}

/// 실시간 환경 서비스 (시간 + 날씨)
/// - 서울 일출/일몰 자동 계산 (SunCalc 알고리즘)
/// - Open-Meteo API로 실시간 날씨 (무료, API 키 불필요)
class EnvironmentService {
  static final EnvironmentService _inst = EnvironmentService._();
  static EnvironmentService get instance => _inst;
  EnvironmentService._();

  Timer? _timer;
  EnvironmentData? _current;
  VoidCallback? onUpdated;

  // ── 마지막 API fetch 결과 캐시 (override 즉시 재적용용) ──
  // _update() 가 raw 값을 여기에 저장해두면, weatherOverride 변경 시
  // API 재호출 없이 _rebuildFromCache() 로 _current 만 다시 만들 수 있음.
  WeatherCondition _rawWeather = WeatherCondition.clear;
  double _rawTemp = 20.0;
  double _rawCloud = 0.0;
  double _rawVis = 10.0;
  double _rawWind = 0.0;
  double _rawPrecip = 0.0;
  String _rawDesc = '맑음';
  IconData _rawIcon = Icons.wb_sunny;

  EnvironmentData? get current => _current;

  /// 서비스 시작 (즉시 1회 + 5분 주기)
  Future<void> start() async {
    await _update();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _update());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();

  Future<void> _update() async {
    try {
      final weatherData = await _fetchWeather();
      if (weatherData != null) {
        _rawWeather = weatherData['condition'] as WeatherCondition;
        _rawTemp = weatherData['temperature'] as double;
        _rawCloud = weatherData['cloudCover'] as double;
        _rawVis = weatherData['visibility'] as double;
        _rawWind = weatherData['windSpeed'] as double;
        _rawPrecip = weatherData['precipitation'] as double;
        _rawDesc = weatherData['description'] as String;
        _rawIcon = weatherData['icon'] as IconData;
      }
    } catch (e) {
      DebugLog.log('[EnvironmentService] 날씨 fetch 실패: $e');
    }

    _rebuildFromCache();
  }

  /// 캐시된 raw 값 + 현재 SettingsService.weatherOverride 로 _current 재빌드.
  /// API 재호출 없이 즉시 반영 — 설정 화면에서 날씨 픽 시 사용.
  void _rebuildFromCache() {
    final now = DateTime.now();
    final sunrise = _calcSunrise(now, _seoulLat, _seoulLng);
    final sunset = _calcSunset(now, _seoulLat, _seoulLng);
    final tod = _getDayPhase(now, sunrise, sunset);
    final lightPreset = _toLightPreset(tod);

    final override = SettingsService.instance.weatherOverride;
    final WeatherCondition weather;
    final String desc;
    final IconData icon;
    if (override == 'auto') {
      weather = _rawWeather;
      desc = _rawDesc;
      icon = _rawIcon;
    } else {
      weather = _conditionFromCode(override);
      final wd = _descIconForCondition(weather);
      desc = wd.$1;
      icon = wd.$2;
    }

    _current = EnvironmentData(
      timeOfDay: tod,
      lightPreset: lightPreset,
      weather: weather,
      temperature: _rawTemp,
      cloudCover: _rawCloud,
      visibility: _rawVis,
      windSpeed: _rawWind,
      precipitation: _rawPrecip,
      weatherDescription: desc,
      weatherIcon: icon,
      sunrise: sunrise,
      sunset: sunset,
    );

    onUpdated?.call();
  }

  /// 외부에서 호출 — weatherOverride 가 바뀐 직후 즉시 _current 갱신.
  void applyOverrideNow() => _rebuildFromCache();

  static WeatherCondition _conditionFromCode(String code) {
    switch (code) {
      case 'clear': return WeatherCondition.clear;
      case 'cloudy': return WeatherCondition.cloudy;
      case 'rain': return WeatherCondition.rain;
      case 'drizzle': return WeatherCondition.drizzle;
      case 'snow': return WeatherCondition.snow;
      case 'fog': return WeatherCondition.fog;
      case 'thunderstorm': return WeatherCondition.thunderstorm;
      default: return WeatherCondition.clear;
    }
  }

  static (String, IconData) _descIconForCondition(WeatherCondition c) {
    switch (c) {
      case WeatherCondition.clear: return ('맑음', Icons.wb_sunny);
      case WeatherCondition.cloudy: return ('흐림', Icons.cloud);
      case WeatherCondition.rain: return ('비', Icons.water_drop);
      case WeatherCondition.drizzle: return ('이슬비', Icons.grain);
      case WeatherCondition.snow: return ('눈', Icons.ac_unit);
      case WeatherCondition.fog: return ('안개', Icons.foggy);
      case WeatherCondition.thunderstorm: return ('뇌우', Icons.flash_on);
    }
  }

  // ── 일출/일몰 계산 (간이 SunCalc) ──

  static DateTime _calcSunrise(DateTime date, double lat, double lng) {
    return _calcSunEvent(date, lat, lng, isSunrise: true);
  }

  static DateTime _calcSunset(DateTime date, double lat, double lng) {
    return _calcSunEvent(date, lat, lng, isSunrise: false);
  }

  static DateTime _calcSunEvent(DateTime date, double lat, double lng, {required bool isSunrise}) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final zenith = 90.833; // 공식 일출/일몰 천정각

    // 시간 근사 (6=일출, 18=일몰)
    final approxTime = dayOfYear + ((isSunrise ? 6 : 18) - lng / 15) / 24;

    // 태양 평균 이상 (anomaly)
    final meanAnomaly = 0.9856 * approxTime - 3.289;
    final meanAnomalyRad = meanAnomaly * pi / 180;

    // 태양 경도
    var sunLng = meanAnomaly + 1.916 * sin(meanAnomalyRad) +
        0.020 * sin(2 * meanAnomalyRad) + 282.634;
    sunLng = sunLng % 360;
    final sunLngRad = sunLng * pi / 180;

    // 적경 (RA)
    var ra = atan(0.91764 * tan(sunLngRad)) * 180 / pi;
    final lQuadrant = (sunLng / 90).floor() * 90;
    final raQuadrant = (ra / 90).floor() * 90;
    ra += lQuadrant - raQuadrant;
    ra /= 15; // 시간으로 변환

    // 적위 (Declination)
    final sinDec = 0.39782 * sin(sunLngRad);
    final cosDec = cos(asin(sinDec));

    // 시간각
    final latRad = lat * pi / 180;
    final zenithRad = zenith * pi / 180;
    final cosH = (cos(zenithRad) - sinDec * sin(latRad)) / (cosDec * cos(latRad));

    if (cosH > 1 || cosH < -1) {
      // 극야/백야 — 기본값 반환
      return DateTime(date.year, date.month, date.day, isSunrise ? 6 : 18);
    }

    double h;
    if (isSunrise) {
      h = (360 - acos(cosH) * 180 / pi) / 15;
    } else {
      h = acos(cosH) * 180 / pi / 15;
    }

    final localTime = h + ra - 0.06571 * approxTime - 6.622;
    var utcTime = localTime - lng / 15;
    utcTime = utcTime % 24;

    // UTC → KST (+9)
    var kstTime = utcTime + 9;
    kstTime = kstTime % 24;

    final hour = kstTime.floor();
    final minute = ((kstTime - hour) * 60).round();

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// 현재 시간 → DayPhase
  static DayPhase _getDayPhase(DateTime now, DateTime sunrise, DateTime sunset) {
    final dawnStart = sunrise.subtract(const Duration(minutes: 30));
    final dawnEnd = sunrise.add(const Duration(minutes: 30));
    final duskStart = sunset.subtract(const Duration(minutes: 30));
    final duskEnd = sunset.add(const Duration(minutes: 30));

    if (now.isAfter(dawnStart) && now.isBefore(dawnEnd)) return DayPhase.dawn;
    if (now.isAfter(dawnEnd) && now.isBefore(duskStart)) return DayPhase.day;
    if (now.isAfter(duskStart) && now.isBefore(duskEnd)) return DayPhase.dusk;
    return DayPhase.night;
  }

  static String _toLightPreset(DayPhase tod) {
    switch (tod) {
      case DayPhase.dawn: return 'dawn';
      case DayPhase.day: return 'day';
      case DayPhase.dusk: return 'dusk';
      case DayPhase.night: return 'night';
    }
  }

  // ── Open-Meteo API ──

  Future<Map<String, dynamic>?> _fetchWeather() async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$_seoulLat&longitude=$_seoulLng'
      '&current=temperature_2m,weather_code,cloud_cover,visibility,wind_speed_10m,precipitation'
      '&timezone=Asia/Seoul',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body);
    final current = json['current'];
    if (current == null) return null;

    final code = current['weather_code'] as int? ?? 0;
    final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 20.0;
    final cloud = (current['cloud_cover'] as num?)?.toDouble() ?? 0.0;
    final vis = ((current['visibility'] as num?)?.toDouble() ?? 10000.0) / 1000.0; // m → km
    final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
    final precip = (current['precipitation'] as num?)?.toDouble() ?? 0.0;

    final parsed = _parseWeatherCode(code);
    return {
      'condition': parsed['condition'],
      'description': parsed['description'],
      'icon': parsed['icon'],
      'temperature': temp,
      'cloudCover': cloud,
      'visibility': vis,
      'windSpeed': wind,
      'precipitation': precip,
    };
  }

  /// WMO weather code → 상태/설명/아이콘
  static Map<String, dynamic> _parseWeatherCode(int code) {
    if (code == 0) {
      return {'condition': WeatherCondition.clear, 'description': '맑음', 'icon': Icons.wb_sunny};
    } else if (code <= 3) {
      return {'condition': WeatherCondition.cloudy, 'description': code == 1 ? '대체로 맑음' : code == 2 ? '구름 조금' : '흐림', 'icon': Icons.cloud};
    } else if (code <= 49) {
      return {'condition': WeatherCondition.fog, 'description': '안개', 'icon': Icons.foggy};
    } else if (code <= 59) {
      return {'condition': WeatherCondition.drizzle, 'description': '이슬비', 'icon': Icons.grain};
    } else if (code <= 69) {
      return {'condition': WeatherCondition.rain, 'description': '비', 'icon': Icons.water_drop};
    } else if (code <= 79) {
      return {'condition': WeatherCondition.snow, 'description': '눈', 'icon': Icons.ac_unit};
    } else if (code <= 84) {
      return {'condition': WeatherCondition.rain, 'description': '소나기', 'icon': Icons.thunderstorm};
    } else if (code <= 86) {
      return {'condition': WeatherCondition.snow, 'description': '눈보라', 'icon': Icons.ac_unit};
    } else if (code <= 99) {
      return {'condition': WeatherCondition.thunderstorm, 'description': '뇌우', 'icon': Icons.flash_on};
    }
    return {'condition': WeatherCondition.clear, 'description': '맑음', 'icon': Icons.wb_sunny};
  }

  /// 7일 예보 데이터
  Future<List<DailyForecast>> fetchWeeklyForecast() async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$_seoulLat&longitude=$_seoulLng'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min'
        '&timezone=Asia/Seoul',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body);
      final daily = json['daily'];
      if (daily == null) return [];

      final dates = (daily['time'] as List).cast<String>();
      final codes = (daily['weather_code'] as List).cast<int>();
      final maxTemps = (daily['temperature_2m_max'] as List);
      final minTemps = (daily['temperature_2m_min'] as List);

      final result = <DailyForecast>[];
      for (int i = 0; i < dates.length && i < 7; i++) {
        final w = _parseWeatherCode(codes[i]);
        result.add(DailyForecast(
          date: DateTime.parse(dates[i]),
          weatherIcon: w['icon'] as IconData,
          description: w['description'] as String,
          maxTemp: (maxTemps[i] as num).toDouble(),
          minTemp: (minTemps[i] as num).toDouble(),
        ));
      }
      return result;
    } catch (e) {
      DebugLog.log('[Environment] 주간예보 실패: $e');
      return [];
    }
  }
}

/// 일별 예보 데이터
class DailyForecast {
  final DateTime date;
  final IconData weatherIcon;
  final String description;
  final double maxTemp;
  final double minTemp;

  const DailyForecast({
    required this.date,
    required this.weatherIcon,
    required this.description,
    required this.maxTemp,
    required this.minTemp,
  });
}
