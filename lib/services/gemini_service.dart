import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_keys.dart';
import '../models/sns_content_models.dart';
import '../data/seoul_subway_data.dart';
import '../models/subway_models.dart';

class GeminiService {
  static GeminiService? _instance;
  GeminiService._();

  static GeminiService get instance {
    _instance ??= GeminiService._();
    return _instance!;
  }

  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static const _systemPrompt = '''
당신은 서울 여행 플래너 AI입니다. SNS 콘텐츠를 분석하여 서울의 장소, 활동, 분위기를 추출합니다.

다음 SNS 콘텐츠를 분석하고 아래 JSON 형식으로만 응답하세요 (다른 텍스트 없이 순수 JSON만):

{
  "places": [
    {
      "name": "장소명 (한국어)",
      "nameEn": "Place name (English)",
      "category": "맛집|카페|관광|쇼핑|문화|자연",
      "activity": "구체적 활동 (예: 빈대떡 먹기, 한복 체험)",
      "mood": "분위기 키워드",
      "description": "한 줄 설명",
      "estimatedMinutes": 소요시간(분 단위 숫자),
      "nearestStation": "가장 가까운 지하철역명 (역 글자 제외)"
    }
  ],
  "overallMood": "전체 분위기 한 줄 요약",
  "keywords": ["키워드1", "키워드2", "키워드3"]
}

규칙:
- 장소는 모두 서울 내 실제 존재하는 곳이어야 합니다
- nearestStation은 서울 지하철 역명만 사용합니다 (예: "광화문", "종로3가")
- 이미지에서 장소를 인식할 수 없으면 텍스트/URL 기반으로 추정합니다
- 3~8개 장소를 추출합니다
- 카테고리는 반드시 맛집, 카페, 관광, 쇼핑, 문화, 자연 중 하나입니다
''';

  /// SNS 콘텐츠 분석
  Future<SnsAnalysisResult> analyzeContent(SnsContent content) async {
    if (ApiKeys.geminiApiKey.isEmpty) {
      throw Exception('Gemini API 키가 설정되지 않았습니다');
    }

    final parts = <Map<String, dynamic>>[];

    // 이미지 추가 (base64)
    for (final path in content.imagePaths) {
      final bytes = await _readAndResize(path);
      if (bytes != null) {
        parts.add({
          'inlineData': {
            'mimeType': 'image/jpeg',
            'data': base64Encode(bytes),
          },
        });
      }
    }

    // 텍스트 구성
    final textParts = <String>[];
    if (content.text.isNotEmpty) {
      textParts.add('사용자 텍스트: ${content.text}');
    }
    if (content.url.isNotEmpty) {
      textParts.add('SNS URL: ${content.url}');
    }
    if (textParts.isEmpty && content.imagePaths.isNotEmpty) {
      textParts.add('이 이미지들을 분석하여 서울의 관련 장소를 추천해주세요.');
    }

    parts.add({'text': textParts.join('\n')});

    // API 호출
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [{'text': _systemPrompt}],
      },
      'contents': [
        {'parts': parts},
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
      },
    });

    final uri = Uri.parse('$_baseUrl?key=${ApiKeys.geminiApiKey}');
    late http.Response response;

    // 429 자동 재시도 (최대 2회)
    for (int attempt = 0; attempt < 3; attempt++) {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 429 && attempt < 2) {
        debugPrint('[Gemini] 429 Too Many Requests — ${attempt + 1}회 재시도 (25초 대기)');
        await Future.delayed(const Duration(seconds: 25));
        continue;
      }
      break;
    }

    if (response.statusCode != 200) {
      debugPrint('[Gemini] Error ${response.statusCode}: ${response.body}');
      throw Exception('Gemini API 오류 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractText(json);
    debugPrint('[Gemini] Response: $text');

    return _parseResult(text);
  }

  /// Mapbox Geocoding으로 좌표 확보
  Future<ExtractedPlace> geocodePlace(ExtractedPlace place) async {
    if (place.hasCoordinates) return place;

    // 1. 역 이름으로 대략적 좌표 추정
    if (place.nearestStation != null) {
      final station = SeoulSubwayData.findStation(place.nearestStation!);
      if (station != null) {
        return place.copyWith(lat: station.lat, lng: station.lng);
      }
    }

    // 2. Mapbox Geocoding API
    try {
      final query = Uri.encodeComponent('${place.name} 서울');
      final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json'
          '?proximity=126.978,37.5665&country=kr&limit=1'
          '&access_token=${ApiKeys.mapboxAccessToken}';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final features = json['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final coords = features[0]['center'] as List;
          final lng = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();

          // 가장 가까운 역 찾기
          final nearest = _findNearestStation(lat, lng);

          return place.copyWith(
            lat: lat,
            lng: lng,
            nearestStation: place.nearestStation ?? nearest?.name,
          );
        }
      }
    } catch (e) {
      debugPrint('[Gemini] Geocoding 실패: $e');
    }

    return place;
  }

  /// 모든 장소에 좌표 부여
  Future<List<ExtractedPlace>> geocodeAll(List<ExtractedPlace> places) async {
    final results = <ExtractedPlace>[];
    for (final place in places) {
      results.add(await geocodePlace(place));
    }
    return results;
  }

  // ── Private helpers ──

  String _extractText(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return '{}';
    final content = candidates[0]['content'] as Map<String, dynamic>?;
    if (content == null) return '{}';
    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return '{}';
    return parts[0]['text'] as String? ?? '{}';
  }

  SnsAnalysisResult _parseResult(String text) {
    // JSON 블록 추출 (```json ... ``` 또는 순수 JSON)
    var jsonStr = text.trim();
    final jsonMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(jsonStr);
    if (jsonMatch != null) {
      jsonStr = jsonMatch.group(1)!.trim();
    }

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final placesJson = json['places'] as List? ?? [];
      final places = placesJson
          .map((p) => ExtractedPlace.fromJson(p as Map<String, dynamic>))
          .toList();

      return SnsAnalysisResult(
        places: places,
        overallMood: json['overallMood'] as String? ?? '',
        keywords: (json['keywords'] as List?)
            ?.map((k) => k.toString())
            .toList() ?? [],
      );
    } catch (e) {
      debugPrint('[Gemini] JSON 파싱 실패: $e');
      return const SnsAnalysisResult(places: []);
    }
  }

  Future<Uint8List?> _readAndResize(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      // 2MB 이상이면 품질 조정 필요하지만 Gemini가 자체 처리
      // 10MB 이상은 건너뜀
      if (bytes.length > 10 * 1024 * 1024) return null;
      return bytes;
    } catch (e) {
      debugPrint('[Gemini] 이미지 읽기 실패: $e');
      return null;
    }
  }

  StationInfo? _findNearestStation(double lat, double lng) {
    StationInfo? best;
    double bestDist = double.infinity;

    for (final entry in SeoulSubwayData.lineIdToApiName.entries) {
      for (final station in SeoulSubwayData.getLineStations(entry.key)) {
        final dLat = station.lat - lat;
        final dLng = station.lng - lng;
        final dist = dLat * dLat + dLng * dLng;
        if (dist < bestDist) {
          bestDist = dist;
          best = station;
        }
      }
    }
    return best;
  }
}
