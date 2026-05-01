import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/api_keys.dart';

/// Gemini Live API 세션 상태
enum LiveSessionState {
  idle,
  connecting,
  listening,
  processing,
  speaking,
  idlePrompt,
  closing,
}

/// Function Calling 액션 타입
enum AiAction {
  navigateToStation,
  showStationInfo,
  createPlan,
  analyzeUrl,
  analyzeImage,
  searchPlace,
}

/// AI가 실행할 액션 데이터
class AiActionEvent {
  final AiAction action;
  final Map<String, dynamic> params;
  const AiActionEvent(this.action, this.params);
}

/// Gemini Live API WebSocket 서비스
class GeminiLiveService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _stateController = StreamController<LiveSessionState>.broadcast();
  final _transcriptController = StreamController<String>.broadcast();
  final _audioOutController = StreamController<Uint8List>.broadcast();
  final _actionController = StreamController<AiActionEvent>.broadcast();

  LiveSessionState _state = LiveSessionState.idle;
  Timer? _silenceTimer;
  bool _disposed = false;

  /// 현재 세션 상태 스트림
  Stream<LiveSessionState> get stateStream => _stateController.stream;
  LiveSessionState get state => _state;

  /// AI 응답 텍스트 (자막) 스트림
  Stream<String> get transcriptStream => _transcriptController.stream;

  /// AI 응답 오디오 스트림 (PCM 24kHz 16-bit mono)
  Stream<Uint8List> get audioOutStream => _audioOutController.stream;

  /// Function Calling 액션 스트림
  Stream<AiActionEvent> get actionStream => _actionController.stream;

  static const _wsUrl =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';

  /// Function declarations for tool use
  static final _toolDeclarations = {
    'functionDeclarations': [
      {
        'name': 'navigate_to_station',
        'description': '지도를 특정 지하철역으로 이동하고 해당 역을 선택합니다. 사용자가 역 위치를 물어보거나 특정 역으로 이동하고 싶을 때 사용합니다.',
        'parameters': {
          'type': 'object',
          'properties': {
            'stationName': {
              'type': 'string',
              'description': '지하철역명 (역 글자 제외, 예: "서울", "강남", "홍대입구")',
            },
          },
          'required': ['stationName'],
        },
      },
      {
        'name': 'show_station_info',
        'description': '특정 지하철역의 실시간 도착 정보를 표시합니다.',
        'parameters': {
          'type': 'object',
          'properties': {
            'stationName': {
              'type': 'string',
              'description': '지하철역명 (역 글자 제외)',
            },
          },
          'required': ['stationName'],
        },
      },
      {
        'name': 'analyze_url',
        'description': 'SNS URL(유튜브, 인스타그램, 틱톡 등)을 분석하여 서울 내 장소를 추출합니다. 사용자가 URL을 제공했을 때 사용합니다.',
        'parameters': {
          'type': 'object',
          'properties': {
            'url': {
              'type': 'string',
              'description': '분석할 URL',
            },
          },
          'required': ['url'],
        },
      },
      {
        'name': 'analyze_image',
        'description': '사용자가 제공한 이미지를 분석하여 장소를 파악합니다. 사용자가 사진을 보내겠다고 하거나 이미지를 통해 장소를 알고 싶어할 때 사용합니다.',
        'parameters': {
          'type': 'object',
          'properties': {
            'prompt': {
              'type': 'string',
              'description': '이미지 분석 시 추가 컨텍스트',
            },
          },
        },
      },
      {
        'name': 'create_plan',
        'description': '추출된 장소들로 하루 여행 일정을 생성합니다. 사용자가 일정/플랜/계획을 만들어달라고 할 때 사용합니다.',
        'parameters': {
          'type': 'object',
          'properties': {
            'style': {
              'type': 'string',
              'enum': ['efficient', 'leisurely', 'foodFocused'],
              'description': '일정 스타일: efficient(효율적), leisurely(여유로운), foodFocused(맛집 중심)',
            },
            'places': {
              'type': 'string',
              'description': '장소 목록 JSON 문자열 (이전 분석 결과)',
            },
          },
          'required': ['style'],
        },
      },
      {
        'name': 'search_place',
        'description': '서울 내 특정 장소나 카테고리를 검색합니다. 사용자가 맛집, 카페, 관광지 등을 물어볼 때 사용합니다.',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': '검색 쿼리 (예: "강남 맛집", "홍대 카페")',
            },
            'category': {
              'type': 'string',
              'enum': ['맛집', '카페', '관광', '쇼핑', '문화', '자연'],
              'description': '장소 카테고리',
            },
          },
          'required': ['query'],
        },
      },
    ],
  };

  /// System instruction for the live session
  static const _systemInstruction = '''
너는 SeoulPrism의 AI 여행 도우미야. 서울 지하철 기반 여행 플래닝을 도와줘.

역할:
- 사용자의 여행 관심사를 파악하고 서울 내 장소를 추천
- 유튜브/인스타그램/틱톡 URL이나 사진을 분석하여 장소 추출
- 효율적/여유로운/맛집 중심 일정 생성
- 지하철역 위치 안내 및 길찾기

성격:
- 친근하고 자연스러운 한국어 사용
- 간결하게 답변 (1-3문장)
- 적극적으로 도움 제안

규칙:
- 장소 추천 시 가장 가까운 지하철역 정보 포함
- URL이나 이미지가 필요하면 사용자에게 요청하고 해당 function 호출
- 지하철역 관련 질문은 navigate_to_station 또는 show_station_info 호출
- "서울역 어디야?" 같은 질문에는 navigate_to_station을 호출해서 지도로 보여줘
- 일정 생성 요청 시 create_plan function 호출
- 한 번에 하나의 function만 호출
''';

  /// 세션 시작
  Future<void> startSession() async {
    if (_state != LiveSessionState.idle) return;
    _setState(LiveSessionState.connecting);

    try {
      final uri = Uri.parse('$_wsUrl?key=${ApiKeys.geminiApiKey}');
      debugPrint('[GeminiLive] Connecting to: $uri');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      debugPrint('[GeminiLive] WebSocket connected');

      // 서버 메시지 수신
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // Setup 메시지 전송
      _sendSetup();
      // listening 전환은 setupComplete 수신 시 처리
    } catch (e) {
      debugPrint('[GeminiLive] Connection failed: $e');
      _setState(LiveSessionState.idle);
    }
  }

  /// Setup 메시지 (세션 초기화)
  /// 공식 문서: https://ai.google.dev/api/live
  /// 최상위 키 "setup" 안에 model, generationConfig, systemInstruction, tools
  void _sendSetup() {
    final setup = {
      'setup': {
        'model': 'models/gemini-2.5-flash-live-preview',
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {
                'voiceName': 'Kore',
              },
            },
          },
        },
        'systemInstruction': {
          'parts': [
            {'text': _systemInstruction},
          ],
        },
        'tools': [_toolDeclarations],
      },
    };

    final jsonStr = jsonEncode(setup);
    debugPrint('[GeminiLive] Setup sending: ${jsonStr.length} bytes');
    _channel?.sink.add(jsonStr);
  }

  /// 오디오 데이터 전송 (마이크 → Gemini)
  void sendAudio(Uint8List pcmData) {
    if (_channel == null || _state == LiveSessionState.idle) return;

    _resetSilenceTimer();

    final msg = {
      'realtimeInput': {
        'mediaChunks': [
          {
            'mimeType': 'audio/pcm;rate=16000',
            'data': base64Encode(pcmData),
          },
        ],
      },
    };

    _channel?.sink.add(jsonEncode(msg));
  }

  /// 텍스트 메시지 전송
  void sendText(String text) {
    if (_channel == null || _state == LiveSessionState.idle) return;

    _setState(LiveSessionState.processing);
    _resetSilenceTimer();

    final msg = {
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text},
            ],
          },
        ],
        'turnComplete': true,
      },
    };

    _channel?.sink.add(jsonEncode(msg));
  }

  /// 이미지 전송 (base64)
  void sendImage(Uint8List imageBytes, {String mimeType = 'image/jpeg'}) {
    if (_channel == null || _state == LiveSessionState.idle) return;

    _setState(LiveSessionState.processing);

    final msg = {
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Encode(imageBytes),
                },
              },
              {
                'text': '이 이미지를 분석해서 서울의 관련 장소를 찾아줘.',
              },
            ],
          },
        ],
        'turnComplete': true,
      },
    };

    _channel?.sink.add(jsonEncode(msg));
  }

  /// Function call 응답 전송
  void sendFunctionResponse(String functionName, Map<String, dynamic> result) {
    final msg = {
      'toolResponse': {
        'functionResponses': [
          {
            'name': functionName,
            'response': result,
          },
        ],
      },
    };

    _channel?.sink.add(jsonEncode(msg));
  }

  /// 서버 메시지 처리
  void _onMessage(dynamic data) {
    try {
      final dataStr = data as String;
      // 짧은 메시지는 전체 출력, 긴 메시지는 앞부분만
      if (dataStr.length < 500) {
        debugPrint('[GeminiLive] Received: $dataStr');
      } else {
        debugPrint('[GeminiLive] Received: ${dataStr.substring(0, 200)}... (${dataStr.length} bytes)');
      }

      final json = jsonDecode(dataStr) as Map<String, dynamic>;

      // Setup complete → listening 전환
      if (json.containsKey('setupComplete')) {
        debugPrint('[GeminiLive] ✓ Setup complete — ready to listen');
        _setState(LiveSessionState.listening);
        _startSilenceTimer();
        return;
      }

      // 에러 메시지 처리
      if (json.containsKey('error')) {
        debugPrint('[GeminiLive] ✗ Server error: ${json['error']}');
        return;
      }

      final serverContent = json['serverContent'] as Map<String, dynamic>?;
      if (serverContent != null) {
        _handleServerContent(serverContent);
        return;
      }

      final toolCall = json['toolCall'] as Map<String, dynamic>?;
      if (toolCall != null) {
        _handleToolCall(toolCall);
        return;
      }

      // 알 수 없는 메시지 타입
      debugPrint('[GeminiLive] Unknown message keys: ${json.keys.toList()}');
    } catch (e) {
      debugPrint('[GeminiLive] Message parse error: $e');
    }
  }

  /// 서버 콘텐츠 처리 (텍스트/오디오)
  void _handleServerContent(Map<String, dynamic> content) {
    final modelTurn = content['modelTurn'] as Map<String, dynamic>?;
    if (modelTurn != null) {
      final parts = modelTurn['parts'] as List<dynamic>?;
      if (parts != null) {
        for (final part in parts) {
          final partMap = part as Map<String, dynamic>;

          // 텍스트 응답
          if (partMap.containsKey('text')) {
            final text = partMap['text'] as String;
            _transcriptController.add(text);
            _setState(LiveSessionState.speaking);
          }

          // 오디오 응답
          if (partMap.containsKey('inlineData')) {
            final inlineData = partMap['inlineData'] as Map<String, dynamic>;
            final audioBase64 = inlineData['data'] as String?;
            if (audioBase64 != null) {
              final audioBytes = base64Decode(audioBase64);
              _audioOutController.add(Uint8List.fromList(audioBytes));
              _setState(LiveSessionState.speaking);
            }
          }
        }
      }
    }

    // 턴 완료
    final turnComplete = content['turnComplete'] as bool?;
    if (turnComplete == true) {
      _setState(LiveSessionState.listening);
      _startSilenceTimer();
    }
  }

  /// Tool Call (Function Calling) 처리
  void _handleToolCall(Map<String, dynamic> toolCall) {
    final functionCalls = toolCall['functionCalls'] as List<dynamic>?;
    if (functionCalls == null || functionCalls.isEmpty) return;

    for (final call in functionCalls) {
      final callMap = call as Map<String, dynamic>;
      final name = callMap['name'] as String;
      final args = callMap['args'] as Map<String, dynamic>? ?? {};

      debugPrint('[GeminiLive] Function call: $name($args)');

      AiAction? action;
      switch (name) {
        case 'navigate_to_station':
          action = AiAction.navigateToStation;
          break;
        case 'show_station_info':
          action = AiAction.showStationInfo;
          break;
        case 'analyze_url':
          action = AiAction.analyzeUrl;
          break;
        case 'analyze_image':
          action = AiAction.analyzeImage;
          break;
        case 'create_plan':
          action = AiAction.createPlan;
          break;
        case 'search_place':
          action = AiAction.searchPlace;
          break;
      }

      if (action != null) {
        _actionController.add(AiActionEvent(action, args));
      }
    }
  }

  /// 무음 타이머 (5초 무음 → idle prompt)
  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 8), () {
      if (_state == LiveSessionState.listening) {
        _setState(LiveSessionState.idlePrompt);
      }
    });
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    if (_state == LiveSessionState.idlePrompt) {
      _setState(LiveSessionState.listening);
    }
    _startSilenceTimer();
  }

  /// 세션 종료
  Future<void> endSession() async {
    if (_state == LiveSessionState.idle) return;
    _setState(LiveSessionState.closing);
    _silenceTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _setState(LiveSessionState.idle);
  }

  void _setState(LiveSessionState newState) {
    if (_disposed) return;
    _state = newState;
    _stateController.add(newState);
  }

  void _onError(dynamic error) {
    debugPrint('[GeminiLive] ✗ WebSocket error: $error');
    debugPrint('[GeminiLive] Error type: ${error.runtimeType}');
    endSession();
  }

  void _onDone() {
    final closeCode = _channel?.closeCode;
    final closeReason = _channel?.closeReason;
    debugPrint('[GeminiLive] WebSocket closed — code: $closeCode, reason: $closeReason');
    if (_state != LiveSessionState.idle) {
      _setState(LiveSessionState.idle);
    }
  }

  void dispose() {
    _disposed = true;
    _silenceTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _stateController.close();
    _transcriptController.close();
    _audioOutController.close();
    _actionController.close();
  }
}
