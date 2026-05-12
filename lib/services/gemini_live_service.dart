import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../data/ai_languages.dart';
import '../data/travel_styles.dart';
import 'settings_service.dart';

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
  // v2 액션
  findRoute,          // 길찾기 (출발, 도착)
  toggleSatellite,    // 위성지도 토글
  addFavorite,        // 즐겨찾기 추가/제거
  openRecommendation, // 추천 탭 열기
  openSaved,          // 저장 탭 열기
  moveToLocation,     // 특정 좌표로 이동
  // v3 액션 (Seoul Live / 여행 / Spotify 등 신규 기능)
  applyTheme,         // 큐레이션 테마 코스 적용 (kTravelThemes)
  planFromSaved,      // 즐겨찾기/방문기록으로 코스 자동 생성
  openTravel,         // 여행 패널 열기
  openMultiplayer,    // Seoul Live 허브 열기
  openSpotify,        // Spotify 뷰 열기
  setLiveVisibility,  // Seoul Live 위치 공유 모드 변경 (ghost / normal)
  toggleLayer,        // 지도 레이어 토글 (지하철·버스·한강버스·항공·역)
  closePanel,         // 현재 열린 패널 (여행/추천/저장) 닫고 지도로 복귀
  setWeatherExpanded, // 날씨 위젯 펼치기 / 접기
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
  final _interruptedController = StreamController<void>.broadcast();

  LiveSessionState _state = LiveSessionState.idle;
  Timer? _silenceTimer;
  bool _disposed = false;
  StreamController<bool>? _stopController;
  AiLanguage _currentLanguage = aiLanguageByCode(kDefaultAiLanguage);

  /// 현재 활성 언어 (세션 시작 시점에 결정).
  AiLanguage get currentLanguage => _currentLanguage;

  Stream<LiveSessionState> get stateStream => _stateController.stream;
  LiveSessionState get state => _state;
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<Uint8List> get audioOutStream => _audioOutController.stream;
  Stream<AiActionEvent> get actionStream => _actionController.stream;
  Stream<void> get interruptedStream => _interruptedController.stream;

  /// 베이스 프롬프트 (현재 언어) + 사용자 무드 (튜토리얼에서 고른 여행 스타일) 합본.
  /// 매 세션 시작마다 호출 — 언어/무드 변경 시 다음 세션에 반영.
  String _buildSystemInstruction(AiLanguage lang) {
    final base = lang.basePrompt;
    final styleKey = SettingsService.instance.getString(kTravelStylePrefKey);
    final style = travelStyleByKey(styleKey);
    if (style == null || style.aiPersona.isEmpty) {
      return base;
    }
    final moodHeader = switch (lang.code) {
      'ko' => '== 사용자 무드 ==',
      'ja' => '== ユーザーのムード ==',
      _ => '== User mood ==',
    };
    return '$base\n$moodHeader\n${style.aiPersona}\n';
  }

  /// 세션 시작
  Future<void> startSession() async {
    // closing 에서 stuck 된 경우에도 강제로 idle 로 떨어뜨려서 재시작 가능하게.
    if (_state == LiveSessionState.closing) {
      _setState(LiveSessionState.idle);
    }
    if (_state != LiveSessionState.idle) return;
    _setState(LiveSessionState.connecting);

    try {
      _currentLanguage = aiLanguageByCode(
        SettingsService.instance.aiLanguage,
      );
      // LiveGenerativeModel 생성 (언어별 voice + system prompt)
      _liveModel = FirebaseAI.vertexAI(location: 'us-central1').liveGenerativeModel(
        model: 'gemini-live-2.5-flash-native-audio',
        systemInstruction: Content.text(_buildSystemInstruction(_currentLanguage)),
        liveGenerationConfig: LiveGenerationConfig(
          speechConfig: SpeechConfig(voiceName: _currentLanguage.voiceName),
          responseModalities: [ResponseModalities.audio],
        ),
        tools: [Tool.functionDeclarations(_functionDeclarations)],
      );

      // 세션 연결
      _session = await _liveModel!.connect();
      debugPrint('[GeminiLive] Session connected (lang=${_currentLanguage.code})');

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

  /// 인사 트리거 — 현재 언어에 맞는 user-turn 프롬프트를 model 에게 보낸다.
  Future<void> sendGreeting() async {
    await sendText(_currentLanguage.greetTrigger);
  }

  /// 오디오 스트림 전송 (마이크 → Gemini).
  /// 호출자가 16kHz PCM16 mono 를 보낸다고 가정한다 (record 설정과 매칭).
  Future<void> sendAudioStream(Stream<Uint8List> audioStream) async {
    if (_session == null) return;
    _resetSilenceTimer();

    // Live API 스펙: audio/pcm 에 sample rate 명시.
    final inlineDataStream = audioStream.map((data) {
      return InlineDataPart('audio/pcm;rate=16000', data);
    });

    try {
      await _session!.sendMediaStream(inlineDataStream);
    } catch (e) {
      // 세션 종료 / 마이크 stream close 시 정상 종료로 취급.
      final msg = e.toString();
      if (!msg.contains('Cannot add event') &&
          !msg.contains('WebSocket Closed')) {
        debugPrint('[GeminiLive] sendMediaStream error: $e');
      }
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

  /// Function call 응답 전송. [callId] 는 Gemini 가 함수 호출 시 발급한 id —
  /// 같은 id 로 응답해야 Live API 가 그 호출과 매칭한다.
  Future<void> sendFunctionResponse(
    String callId,
    String functionName,
    Map<String, dynamic> result,
  ) async {
    if (_session == null) return;
    try {
      final content = Content(
        'function',
        [FunctionResponse(functionName, result, id: callId.isEmpty ? null : callId)],
      );
      await _session!.send(input: content);
    } catch (e) {
      debugPrint('[GeminiLive] sendFunctionResponse error: $e');
    }
  }

  /// 메시지 수신 루프 (공식 예제 패턴). _session 이 null 이거나 stop 신호가 오면 빠짐.
  Future<void> _processMessages() async {
    bool shouldContinue = true;
    _stopController?.stream.listen((stop) {
      if (stop) shouldContinue = false;
    });

    while (shouldContinue && _session != null) {
      final session = _session;
      if (session == null) break;
      try {
        await for (final response in session.receive()) {
          if (_session == null) break;
          _handleResponse(response);
        }
      } catch (e) {
        // 1006 = WebSocket 정상 종료 (idle timeout). 그 외 에러는 로깅만.
        final msg = e.toString();
        if (!msg.contains('1006') && !msg.contains('WebSocket Closed')) {
          debugPrint('[GeminiLive] Receive error: $e');
        }
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
    } else if (message is LiveServerToolCallCancellation) {
      // 취소된 function call — 아직 별도 UI 처리 없음.
      debugPrint('[GeminiLive] Tool call cancelled: ${message.functionIds}');
    }
  }

  /// 콘텐츠 처리 (텍스트 + 오디오)
  void _handleContent(LiveServerContent content) {
    // interrupted — 사용자가 끼어들어서 model 발화가 중단됨.
    // 큐된 audio chunk 를 flush 해서 잘린 음성이 계속 재생되지 않게 한다.
    if (content.interrupted == true) {
      debugPrint('[GeminiLive] Interrupted');
      _interruptedController.add(null);
      _setState(LiveSessionState.listening);
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
        // v2
        case 'find_route': action = AiAction.findRoute; break;
        case 'toggle_satellite': action = AiAction.toggleSatellite; break;
        case 'add_favorite': action = AiAction.addFavorite; break;
        case 'open_recommendation': action = AiAction.openRecommendation; break;
        case 'open_saved': action = AiAction.openSaved; break;
        case 'move_to_location': action = AiAction.moveToLocation; break;
        // v3
        case 'apply_theme': action = AiAction.applyTheme; break;
        case 'plan_from_saved': action = AiAction.planFromSaved; break;
        case 'open_travel': action = AiAction.openTravel; break;
        case 'open_multiplayer': action = AiAction.openMultiplayer; break;
        case 'open_spotify': action = AiAction.openSpotify; break;
        case 'set_live_visibility': action = AiAction.setLiveVisibility; break;
        case 'toggle_layer': action = AiAction.toggleLayer; break;
        case 'close_panel': action = AiAction.closePanel; break;
        case 'set_weather_expanded': action = AiAction.setWeatherExpanded; break;
      }

      if (action != null) {
        _actionController.add(AiActionEvent(
          action,
          Map<String, dynamic>.from(call.args),
          // Live API 매칭용 — Gemini 가 발급한 id 그대로 응답에 다시 넣어야 함.
          callId: call.id ?? '',
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

    // ── v2 ──
    FunctionDeclaration('find_route', '특정 장소까지 길찾기 시작',
      parameters: {
        'to': Schema.string(description: '도착지 이름 (예: "강남역", "광화문")'),
        'from': Schema.string(description: '출발지 (없으면 현재 위치)', nullable: true),
      }),
    FunctionDeclaration('toggle_satellite', '위성지도 켜기/끄기 토글', parameters: {}),
    FunctionDeclaration('add_favorite', '장소를 즐겨찾기에 추가/제거 (토글)',
      parameters: {
        'placeName': Schema.string(description: '장소 이름. 비우면 현재 선택된 장소', nullable: true),
      }),
    FunctionDeclaration('open_recommendation', '추천 탭 열기', parameters: {}),
    FunctionDeclaration('open_saved', '저장한 장소 탭 열기', parameters: {}),
    FunctionDeclaration('move_to_location', '지도를 특정 좌표로 이동',
      parameters: {
        'lat': Schema.number(description: '위도'),
        'lng': Schema.number(description: '경도'),
      }),

    // ── v3 ──
    FunctionDeclaration('apply_theme', '큐레이션 테마 코스를 지도에 표시',
      parameters: {
        'theme_id': Schema.enumString(
          enumValues: ['foodie_day', 'hangang_wind', 'palace_walk', 'cafe_hop',
                       'kpop', 'night_view', 'family_kids', 'rainy_indoor'],
          description: '테마 id',
        ),
      }),
    FunctionDeclaration('plan_from_saved', '사용자의 즐겨찾기/방문기록으로 자동 코스 생성', parameters: {}),
    FunctionDeclaration('open_travel', '여행 패널 열기 (테마 카드 보기)', parameters: {}),
    FunctionDeclaration('open_multiplayer', 'Seoul Live (친구 위치 공유) 허브 열기', parameters: {}),
    FunctionDeclaration('open_spotify', 'Spotify 친구 곡 뷰 열기', parameters: {}),
    FunctionDeclaration('set_live_visibility', 'Seoul Live 위치 공유 모드 변경',
      parameters: {
        'visibility': Schema.enumString(
          enumValues: ['normal', 'ghost'],
          description: 'normal=친구에게 위치 보임, ghost=숨김',
        ),
      }),
    FunctionDeclaration('toggle_layer',
      '지도 레이어 표시/숨김 토글 (지하철 노선·열차·역·버스·한강버스·항공)',
      parameters: {
        'layer': Schema.enumString(
          enumValues: ['subway', 'trains', 'stations', 'buses', 'river_bus', 'flights'],
          description: '레이어 종류',
        ),
        'enable': Schema.boolean(
          description: 'true=켜기, false=끄기. 비우면 현재 상태에서 토글',
          nullable: true,
        ),
      }),
    FunctionDeclaration('close_panel',
      '현재 열린 패널 (여행/추천/저장) 닫고 지도로 복귀',
      parameters: {}),
    FunctionDeclaration('set_weather_expanded',
      '날씨 위젯 펼치기/접기 (펼치면 주간 예보 표시)',
      parameters: {
        'expanded': Schema.boolean(
          description: 'true=펼침, false=접음',
        ),
      }),
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

  /// 세션 종료. 어디서 throw 돼도 항상 idle 로 떨어뜨려서 다음 startSession 가능하게.
  Future<void> endSession() async {
    if (_state == LiveSessionState.idle) return;
    _setState(LiveSessionState.closing);
    _silenceTimer?.cancel();
    try {
      _stopController?.add(true);
      await _stopController?.close();
      await _session?.close();
    } catch (e) {
      debugPrint('[GeminiLive] endSession error (suppressed): $e');
    } finally {
      _stopController = null;
      _session = null;
      _setState(LiveSessionState.idle);
    }
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
