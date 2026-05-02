import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';

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
  requestPhoto,
  addPlaces,
  removePlace,
  confirmPlan,
}

/// AI가 실행할 액션 데이터
class AiActionEvent {
  final AiAction action;
  final Map<String, dynamic> params;
  final String callId;
  const AiActionEvent(this.action, this.params, {this.callId = ''});
}

/// Gemini Live API 서비스 (firebase_ai 공식 SDK)
class GeminiLiveService {
  static GeminiLiveService? _instance;
  static GeminiLiveService get instance {
    _instance ??= GeminiLiveService._();
    return _instance!;
  }
  GeminiLiveService._();

  LiveSession? _session;
  LiveGenerativeModel? _liveModel;

  final _stateController = StreamController<LiveSessionState>.broadcast();
  final _transcriptController = StreamController<String>.broadcast();
  final _audioOutController = StreamController<Uint8List>.broadcast();
  final _actionController = StreamController<AiActionEvent>.broadcast();

  LiveSessionState _state = LiveSessionState.idle;
  Timer? _silenceTimer;
  bool _disposed = false;
  StreamController<bool>? _stopController;

  Stream<LiveSessionState> get stateStream => _stateController.stream;
  LiveSessionState get state => _state;
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<Uint8List> get audioOutStream => _audioOutController.stream;
  Stream<AiActionEvent> get actionStream => _actionController.stream;

  static const _systemInstruction = '''
너는 서울 여행 비서야. 이름은 "프리즘"이야. 사용자와 음성으로 자연스럽게 대화해.

성격:
- 20대 친구처럼 친근하고 밝게 대화해. 반말 사용.
- 짧고 자연스럽게 말해. 한 번에 1-2문장만.

할 수 있는 것:
- 서울 ���하철역 위치 안내: navigate_to_station 호출하면 지도가 그 역으로 이동해.
- 역 실시간 정보: show_station_info로 도착 정보 표시.
- 여행 일정 생성: create_plan으�� 하루 코스 만들기.
- 장소 추천: search_place로 맛집, 카페, 관광지 추천.
- URL 분석: analyze_url로 유튜브/인스타 링크에서 장소 ��출.
- 사진 요청: request_photo로 카메라/갤러리 UI 표시.
- 코스 추가: add_places로 현�� 코스에 장소 추가.
- 코스 삭제: remove_place로 특정 장소 제거.
- 코스 확정: confirm_plan으로 일정 생성.

코스 조절:
- 장소를 찾으면 "이 코스 어때? 수정하고 싶은 거 있어?" 물어봐.
- "카페 추가해줘" → add_places, "경복궁 빼줘" → remove_place, "확정해" → confirm_plan

규칙:
- 역 위치를 물어보면 바로 navigate_to_station 호출해.
- function 호��� 후에는 결과를 자연스럽게 음성으로 안내해.
- 사진 관련 말을 하면 request_photo 호출해.
- 한 번에 function 하나만 호출해.
''';

  /// 세션 시작
  Future<void> startSession() async {
    if (_state != LiveSessionState.idle) return;
    _setState(LiveSessionState.connecting);

    try {
      // LiveGenerativeModel 생성
      _liveModel = FirebaseAI.vertexAI().liveGenerativeModel(
        model: 'gemini-2.0-flash-live-001',
        systemInstruction: Content.text(_systemInstruction),
        liveGenerationConfig: LiveGenerationConfig(
          speechConfig: SpeechConfig(voiceName: 'Kore'),
          responseModalities: [ResponseModalities.audio],
        ),
        tools: [Tool.functionDeclarations(_functionDeclarations)],
      );

      // 세션 연결
      _session = await _liveModel!.connect();
      debugPrint('[GeminiLive] Session connected');

      // 메시지 수신 루프 시작
      _stopController = StreamController<bool>();
      unawaited(_processMessages());

      _setState(LiveSessionState.listening);
      _startSilenceTimer();
    } catch (e) {
      debugPrint('[GeminiLive] Connection failed: $e');
      _setState(LiveSessionState.idle);
    }
  }

  /// 오디오 스트림 전송 (마이크 → Gemini)
  Future<void> sendAudioStream(Stream<Uint8List> audioStream) async {
    if (_session == null) return;
    _resetSilenceTimer();

    final inlineDataStream = audioStream.map((data) {
      return InlineDataPart('audio/pcm', data);
    });

    try {
      await _session!.sendMediaStream(inlineDataStream);
    } catch (e) {
      debugPrint('[GeminiLive] sendMediaStream error: $e');
    }
  }

  /// 텍스트 전송
  Future<void> sendText(String text) async {
    if (_session == null) return;
    _setState(LiveSessionState.processing);
    _resetSilenceTimer();

    try {
      await _session!.send(input: Content.text(text), turnComplete: true);
    } catch (e) {
      debugPrint('[GeminiLive] sendText error: $e');
    }
  }

  /// Function call 응답 전송
  Future<void> sendFunctionResponse(String callId, String functionName, Map<String, dynamic> result) async {
    if (_session == null) return;
    try {
      await _session!.send(
        input: Content.functionResponse(functionName, result),
      );
    } catch (e) {
      debugPrint('[GeminiLive] sendFunctionResponse error: $e');
    }
  }

  /// 메시지 수신 루프 (공식 예제 패턴)
  Future<void> _processMessages() async {
    bool shouldContinue = true;
    _stopController?.stream.listen((stop) {
      if (stop) shouldContinue = false;
    });

    while (shouldContinue) {
      try {
        await for (final response in _session!.receive()) {
          _handleResponse(response);
        }
      } catch (e) {
        debugPrint('[GeminiLive] Receive error: $e');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// 응답 처리
  void _handleResponse(LiveServerResponse response) {
    final message = response.message;

    if (message is LiveServerContent) {
      _handleContent(message);
    } else if (message is LiveServerToolCall && message.functionCalls != null) {
      _handleToolCall(message);
    }
  }

  /// 콘텐츠 처리 (텍스트 + 오디오)
  void _handleContent(LiveServerContent content) {
    // interrupted
    if (content.interrupted == true) {
      debugPrint('[GeminiLive] Interrupted');
      return;
    }

    // modelTurn (오디오/텍스트)
    final parts = content.modelTurn?.parts;
    if (parts != null) {
      for (final part in parts) {
        if (part is TextPart) {
          _transcriptController.add(part.text);
          if (_state != LiveSessionState.speaking) {
            _setState(LiveSessionState.speaking);
          }
        } else if (part is InlineDataPart) {
          if (part.mimeType.startsWith('audio')) {
            _audioOutController.add(part.bytes);
            if (_state != LiveSessionState.speaking) {
              _setState(LiveSessionState.speaking);
            }
            _silenceTimer?.cancel();
          }
        }
      }
    }

    // turnComplete
    if (content.turnComplete == true) {
      _setState(LiveSessionState.listening);
      _startSilenceTimer();
    }
  }

  /// Function Call 처리
  void _handleToolCall(LiveServerToolCall toolCall) {
    final functionCalls = toolCall.functionCalls!.toList();
    for (final call in functionCalls) {
      debugPrint('[GeminiLive] Function call: ${call.name}(${call.args})');

      AiAction? action;
      switch (call.name) {
        case 'navigate_to_station': action = AiAction.navigateToStation; break;
        case 'show_station_info': action = AiAction.showStationInfo; break;
        case 'analyze_url': action = AiAction.analyzeUrl; break;
        case 'analyze_image': action = AiAction.analyzeImage; break;
        case 'create_plan': action = AiAction.createPlan; break;
        case 'search_place': action = AiAction.searchPlace; break;
        case 'request_photo': action = AiAction.requestPhoto; break;
        case 'add_places': action = AiAction.addPlaces; break;
        case 'remove_place': action = AiAction.removePlace; break;
        case 'confirm_plan': action = AiAction.confirmPlan; break;
      }

      if (action != null) {
        _actionController.add(AiActionEvent(
          action,
          Map<String, dynamic>.from(call.args),
          callId: call.name,
        ));
      }
    }
  }

  /// Function declarations
  static final _functionDeclarations = [
    FunctionDeclaration('navigate_to_station', '지도를 특정 지하철역으로 이동',
      parameters: {'stationName': Schema.string(description: '지하철역명')}),
    FunctionDeclaration('show_station_info', '역의 실시간 도착 정보 표시',
      parameters: {'stationName': Schema.string(description: '지하철역명')}),
    FunctionDeclaration('analyze_url', 'SNS URL 분석하여 장소 추출',
      parameters: {'url': Schema.string(description: '분석할 URL')}),
    FunctionDeclaration('analyze_image', '이미지 분석하여 장소 파악',
      parameters: {'prompt': Schema.string(description: '��석 컨텍스트', nullable: true)}),
    FunctionDeclaration('create_plan', '여행 일정 생성',
      parameters: {
        'style': Schema.enumString(enumValues: ['efficient', 'leisurely', 'foodFocused'], description: '일정 스타일'),
        'places': Schema.string(description: '장소 목록', nullable: true),
      }),
    FunctionDeclaration('search_place', '서울 ��� 장소 검색',
      parameters: {
        'query': Schema.string(description: '검색 쿼리'),
        'category': Schema.enumString(enumValues: ['맛집', '카페', '관광', '쇼핑', '문화', '자연'], description: '카테고리', nullable: true),
      }),
    FunctionDeclaration('request_photo', '사용자에게 사진 요청',
      parameters: {'source': Schema.enumString(enumValues: ['camera', 'gallery', 'both'], description: '소스', nullable: true)}),
    FunctionDeclaration('add_places', '현재 코스에 장소 추가',
      parameters: {
        'query': Schema.string(description: '추가할 장소 검색 쿼리'),
        'category': Schema.enumString(enumValues: ['맛집', '카페', '관광', '쇼핑', '문화', '자연'], description: '카테고리', nullable: true),
      }),
    FunctionDeclaration('remove_place', '코스에서 장소 삭제',
      parameters: {'placeName': Schema.string(description: '삭제할 장소 이름')}),
    FunctionDeclaration('confirm_plan', '코스 확정하고 일정 생성',
      parameters: {'style': Schema.enumString(enumValues: ['efficient', 'leisurely', 'foodFocused'], description: '일정 스타일', nullable: true)}),
  ];

  /// 무음 타이머
  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 15), () {
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
    _stopController?.add(true);
    await _stopController?.close();
    await _session?.close();
    _session = null;
    _setState(LiveSessionState.idle);
  }

  void _setState(LiveSessionState newState) {
    if (_disposed) return;
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _disposed = true;
    endSession();
    _stateController.close();
    _transcriptController.close();
    _audioOutController.close();
    _actionController.close();
  }
}
