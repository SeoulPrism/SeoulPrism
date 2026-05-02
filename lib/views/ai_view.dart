import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_live_service.dart';
import '../services/gemini_service.dart';
import '../services/audio_service.dart';
import '../models/sns_content_models.dart';

/// 통합 AI 뷰 — Glow 애니메이션 + Gemini Live 음성 대화
class AiView extends StatefulWidget {
  final VoidCallback? onClose;
  final bool closing;
  final void Function(AiActionEvent action)? onAction;
  final void Function(String status)? onStatusChanged;

  const AiView({
    super.key,
    this.onClose,
    this.onStatusChanged,
    this.closing = false,
    this.onAction,
  });

  @override
  State<AiView> createState() => _AiViewState();
}

class _AiViewState extends State<AiView> with TickerProviderStateMixin {
  // ── Glow 애니메이션 ──
  late AnimationController _spreadController;
  late AnimationController _deformController;
  late List<AnimationController> _layerControllers;
  late List<List<double>> _layerCurrentStops;
  late List<List<double>> _layerFromStops;
  List<double> _targetStops = [0.0, 0.17, 0.33, 0.5, 0.67, 0.83, 1.0];
  Timer? _updateTimer;
  bool _dismissed = false;
  final _random = Random();
  static const _layerDurations = [500, 600, 800, 1000];

  // ── Gemini Live ──
  final GeminiLiveService _liveService = GeminiLiveService.instance;
  final AudioService _audioService = AudioService();
  LiveSessionState _sessionState = LiveSessionState.idle;
  String _accumulatedTranscript = '';  // 턴 동안 누적된 전체 텍스트
  double _audioLevel = 0.0;

  // ── UI 상태 ──
  bool _showTextInput = false;
  bool _textModeActive = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  // ── 장소 분석 결과 패널 ──
  bool _showPlacesPanel = false;
  List<ExtractedPlace> _extractedPlaces = [];
  bool _analyzingImage = false;

  // ── 스트림 구독 ──
  StreamSubscription? _stateSub;
  StreamSubscription? _transcriptSub;
  StreamSubscription? _audioOutSub;
  StreamSubscription? _actionSub;
  StreamSubscription? _audioInSub;
  StreamSubscription? _levelSub;
  StreamSubscription? _turnCompleteSub;

  // ── Glow 상태 반응 파라미터 ──
  double _glowSpeedMultiplier = 1.0;
  double _glowStrokeBoost = 0.0;
  double _glowBrightnessMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _initGlowAnimations();
    _initLiveSession();
  }

  void _initGlowAnimations() {
    _spreadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _deformController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    final initialStops = [0.0, 0.17, 0.33, 0.5, 0.67, 0.83, 1.0];
    _layerCurrentStops = List.generate(4, (_) => List.from(initialStops));
    _layerFromStops = List.generate(4, (_) => List.from(initialStops));

    _layerControllers = List.generate(4, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _layerDurations[i]),
      );
      ctrl.addListener(() => _interpolateLayer(i));
      return ctrl;
    });

    _updateTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      _generateNewTarget();
    });

    _spreadController.forward();
    _generateNewTarget();
  }

  Future<void> _initLiveSession() async {
    // 상태 스트림 구독
    _stateSub = _liveService.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _sessionState = state;
        _updateGlowForState(state);
      });
      // speaking 시작 시 누적 리셋
      if (state == LiveSessionState.speaking) {
        _accumulatedTranscript = '';
      }
      // listening 전환 시 15초 후 자막 클리어
      if (state == LiveSessionState.listening) {
        Future.delayed(const Duration(seconds: 15), () {
          if (mounted && _sessionState == LiveSessionState.listening) {
            widget.onStatusChanged?.call('');
          }
        });
      }
    });

    _transcriptSub = _liveService.transcriptStream.listen((text) {
      if (!mounted) return;
      // 텍스트 누적 (조각조각 오므로)
      _accumulatedTranscript += text;
      widget.onStatusChanged?.call(_accumulatedTranscript);
    });

    _audioOutSub = _liveService.audioBase64Stream.listen((base64) {
      // 첫 오디오 청크에서만 마이크 중지
      if (_audioService.isRecording) {
        _audioService.stopRecording();
        _audioInSub?.cancel();
      }
      _audioService.bufferBase64(base64);
    });

    _actionSub = _liveService.actionStream.listen((action) {
      if (action.action == AiAction.requestPhoto) {
        _handlePhotoRequest(action.params['source'] as String? ?? 'both');
      } else if (action.action == AiAction.searchPlace) {
        _handleSearchPlace(action);
      } else if (action.action == AiAction.createPlan) {
        _handleCreatePlan(action);
      } else {
        widget.onAction?.call(action);
      }
      // Function response 전송 (callId 포함)
      final response = _buildFunctionResponse(action);
      _liveService.sendFunctionResponse(
        action.callId,
        _actionToFunctionName(action.action),
        response,
      );
    });

    // generationComplete 시: 전체 오디오 재생 → 마이크 재시작
    _turnCompleteSub = _liveService.turnCompleteStream.listen((_) async {
      await _audioService.flushAndPlay();

      // 재생 완료 후 마이크 재시작
      final micRestarted = await _audioService.startRecording();
      if (micRestarted) {
        _audioInSub = _audioService.audioInStream.listen((pcmData) {
          _liveService.sendAudio(pcmData, hasVoice: _audioLevel > 0.02);
        });
      }
      _liveService.onPlaybackDone();
    });

    // 오디오 레벨 구독 (Glow 반응용)
    _levelSub = _audioService.levelStream.listen((level) {
      if (!mounted) return;
      setState(() => _audioLevel = level);
    });

    // 세션이 이미 연결됐으면 스킵
    if (_liveService.state == LiveSessionState.idle) {
      await _liveService.startSession();
    }

    // 마이크 시작
    final micStarted = await _audioService.startRecording();
    if (micStarted) {
      _audioInSub = _audioService.audioInStream.listen((pcmData) {
        _liveService.sendAudio(pcmData);
      });
    }

    // AI 인사 트리거
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _liveService.sendText('[system] User opened AI mode. Greet briefly in Korean.');
      }
    });
  }

  String _actionToFunctionName(AiAction action) {
    switch (action) {
      case AiAction.navigateToStation:
        return 'navigate_to_station';
      case AiAction.showStationInfo:
        return 'show_station_info';
      case AiAction.analyzeUrl:
        return 'analyze_url';
      case AiAction.analyzeImage:
        return 'analyze_image';
      case AiAction.createPlan:
        return 'create_plan';
      case AiAction.searchPlace:
        return 'search_place';
      case AiAction.requestPhoto:
        return 'request_photo';
    }
  }

  /// Function call별 의미있는 응답 생성
  Map<String, dynamic> _buildFunctionResponse(AiActionEvent action) {
    switch (action.action) {
      case AiAction.navigateToStation:
        final name = action.params['stationName'] as String? ?? '';
        return {
          'status': 'success',
          'message': '$name역으로 지도를 이동했습니다. 사용자에게 해당 역에 대해 안내해주세요.',
        };
      case AiAction.showStationInfo:
        final name = action.params['stationName'] as String? ?? '';
        return {
          'status': 'success',
          'message': '$name역의 실시간 도착 정보를 표시했습니다.',
        };
      case AiAction.analyzeUrl:
        return {
          'status': 'processing',
          'message': 'URL을 분석 중입니다. 결과가 나오면 지도에 표시됩니다. 사용자에게 잠시 기다리라고 안내해주세요.',
        };
      case AiAction.analyzeImage:
        return {
          'status': 'success',
          'message': '이미지가 이미 대화에 포함되어 있습니다. 이미지를 직접 분석하여 서울의 관련 장소를 찾아 사용자에게 안내해주세요. function을 다시 호출하지 마세요.',
        };
      case AiAction.createPlan:
        return {
          'status': 'processing',
          'message': '일정을 생성 중입니다. 사용자에게 잠시 기다리라고 안내해주세요.',
        };
      case AiAction.searchPlace:
        final query = action.params['query'] as String? ?? '';
        return {
          'status': 'success',
          'message': '"$query" 검색 결과를 사용자에게 직접 추천해주세요. 가장 가까운 지하철역 정보도 포함해주세요.',
        };
      case AiAction.requestPhoto:
        return {
          'status': 'success',
          'message': '사진 선택 UI를 표시했습니다. 사용자가 사진을 선택하면 분석 결과를 알려드릴게요. 사용자에게 사진을 선택해달라고 안내해주세요.',
        };
    }
  }

  /// 세션 상태에 따른 Glow 파라미터 조정
  void _updateGlowForState(LiveSessionState state) {
    switch (state) {
      case LiveSessionState.connecting:
        _glowSpeedMultiplier = 1.5;
        _glowStrokeBoost = 0.0;
        _glowBrightnessMultiplier = 0.7;
        break;
      case LiveSessionState.listening:
        _glowSpeedMultiplier = 1.0;
        _glowStrokeBoost = 0.0;
        _glowBrightnessMultiplier = 1.0;
        break;
      case LiveSessionState.processing:
        _glowSpeedMultiplier = 2.0;
        _glowStrokeBoost = 1.0;
        _glowBrightnessMultiplier = 1.2;
        break;
      case LiveSessionState.speaking:
        _glowSpeedMultiplier = 1.3;
        _glowStrokeBoost = _audioLevel * 4.5;
        _glowBrightnessMultiplier = 1.0 + _audioLevel * 0.3;
        break;
      case LiveSessionState.idlePrompt:
        _glowSpeedMultiplier = 0.6;
        _glowStrokeBoost = 0.0;
        _glowBrightnessMultiplier = 0.7;
        break;
      default:
        _glowSpeedMultiplier = 1.0;
        _glowStrokeBoost = 0.0;
        _glowBrightnessMultiplier = 1.0;
    }

    // 타이머 주기 조정
    _updateTimer?.cancel();
    final interval = (400 / _glowSpeedMultiplier).round();
    _updateTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      _generateNewTarget();
    });
  }

  void _generateNewTarget() {
    final positions = List.generate(5, (_) => _random.nextDouble() * 0.9 + 0.05);
    positions.sort();
    _targetStops = [0.0, ...positions, 1.0];

    for (int i = 0; i < 4; i++) {
      _layerFromStops[i] = List.from(_layerCurrentStops[i]);
      _layerControllers[i].forward(from: 0.0);
    }
  }

  void _interpolateLayer(int layerIndex) {
    if (!mounted) return;
    final t = Curves.easeInOut.transform(_layerControllers[layerIndex].value);
    final from = _layerFromStops[layerIndex];
    final newStops = List.generate(7, (i) {
      return from[i] + (_targetStops[i] - from[i]) * t;
    });
    setState(() {
      _layerCurrentStops[layerIndex] = newStops;
    });
  }

  @override
  void didUpdateWidget(AiView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.closing && !oldWidget.closing) {
      _dismiss();
    }
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _updateTimer?.cancel();
    _liveService.endSession();
    _audioService.stopRecording();
    _spreadController.reverse().then((_) {
      widget.onClose?.call();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _spreadController.dispose();
    _deformController.dispose();
    for (final c in _layerControllers) {
      c.dispose();
    }
    _stateSub?.cancel();
    _transcriptSub?.cancel();
    _audioOutSub?.cancel();
    _actionSub?.cancel();
    _audioInSub?.cancel();
    _levelSub?.cancel();
    _turnCompleteSub?.cancel();
    _liveService.endSession();
    _audioService.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }




  // -- Create plan → 장소가 이미 있으면 바로 플랜 생성, 없으면 검색 후 패널 --
  Future<void> _handleCreatePlan(AiActionEvent action) async {
    if (_extractedPlaces.isNotEmpty) {
      // 이미 장소가 있으면 바로 플랜 생성
      _generatePlanFromPlaces();
      return;
    }

    // 장소가 없으면 AI가 보낸 places 문자열이나 style로 검색
    final placesStr = action.params['places'] as String?;
    final query = placesStr ?? '서울 여행 추천 코스';

    widget.onStatusChanged?.call('코스 검�� 중...');

    try {
      final content = SnsContent(imagePaths: [], text: query, url: '');
      final result = await GeminiService.instance.analyzeContent(content);
      if (!mounted) return;

      if (result.places.isNotEmpty) {
        final geoPlaces = await GeminiService.instance.geocodeAll(result.places);
        if (!mounted) return;
        setState(() {
          _extractedPlaces = geoPlaces;
          _showPlacesPanel = true;
        });
        widget.onStatusChanged?.call('${geoPlaces.length}개 장소를 찾았어요! 아래에서 확인하세요.');
      }
    } catch (e) {
      debugPrint('[AiView] Create plan error: $e');
    }
  }

  // -- Search place → GeminiService 분석 → 장소 패널 표시 --
  Future<void> _handleSearchPlace(AiActionEvent action) async {
    final query = action.params['query'] as String? ?? '';
    if (query.isEmpty) return;

    widget.onStatusChanged?.call('$query 검색 중...');

    try {
      final content = SnsContent(imagePaths: [], text: query, url: '');
      final result = await GeminiService.instance.analyzeContent(content);
      if (!mounted) return;

      if (result.places.isNotEmpty) {
        final geoPlaces = await GeminiService.instance.geocodeAll(result.places);
        if (!mounted) return;
        setState(() {
          _extractedPlaces = geoPlaces;
          _showPlacesPanel = true;
        });
      }
    } catch (e) {
      debugPrint('[AiView] Search place error: $e');
    }
  }

  // -- Photo request handling --
  bool _showPhotoOptions = false;

  void _handlePhotoRequest(String source) {
    if (source == 'camera') {
      _pickImage(ImageSource.camera);
    } else if (source == 'gallery') {
      _pickImage(ImageSource.gallery);
    } else {
      setState(() => _showPhotoOptions = true);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _showPhotoOptions = false);

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 2048);
    if (picked == null) return;

    setState(() => _analyzingImage = true);
    widget.onStatusChanged?.call('이미지 분석 중...');

    try {
      final content = SnsContent(imagePaths: [picked.path], text: '', url: '');
      final result = await GeminiService.instance.analyzeContent(content);

      if (!mounted) return;

      if (result.places.isNotEmpty) {
        final geoPlaces = await GeminiService.instance.geocodeAll(result.places);
        if (!mounted) return;
        setState(() {
          _extractedPlaces = geoPlaces;
          _showPlacesPanel = true;
          _analyzingImage = false;
        });

        _liveService.sendText(
          'Image analysis found ${geoPlaces.length} places: '
          '${geoPlaces.map((p) => "${p.name}(${p.category})").join(", ")}. '
          'Tell the user about these places briefly in Korean.',
        );
      } else {
        setState(() => _analyzingImage = false);
        widget.onStatusChanged?.call('장소를 찾지 못했어요.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzingImage = false);
      widget.onStatusChanged?.call('분석 오류: $e');
      debugPrint('[AiView] Image analysis error: $e');
    }
  }

  // ── 텍스트 입력 ──
  void _showTextInputField() {
    setState(() {
      _showTextInput = true;
      _textModeActive = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _textFocusNode.requestFocus();
    });
  }

  void _hideTextInputField() {
    _textFocusNode.unfocus();
    setState(() => _showTextInput = false);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _textModeActive = false);
    });
  }

  void _submitText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _liveService.sendText(text);
    _textController.clear();
    _hideTextInputField();
  }


  void _removePlace(int index) {
    setState(() {
      _extractedPlaces.removeAt(index);
      if (_extractedPlaces.isEmpty) _showPlacesPanel = false;
    });
  }

  bool _loadingMorePlaces = false;

  Future<void> _requestMorePlaces() async {
    if (_loadingMorePlaces) return;
    setState(() => _loadingMorePlaces = true);
    widget.onStatusChanged?.call('추가 장소 검색 중...');

    try {
      final existing = _extractedPlaces.map((p) => p.name).join(', ');
      final content = SnsContent(
        imagePaths: [],
        text: '서울 여행 추천 장소를 더 알려줘. 기존: $existing. 이것들과 다른 새로운 장소 3~5개를 추천해줘.',
        url: '',
      );
      final result = await GeminiService.instance.analyzeContent(content);
      if (!mounted) return;

      if (result.places.isNotEmpty) {
        final geoPlaces = await GeminiService.instance.geocodeAll(result.places);
        if (!mounted) return;
        setState(() {
          _extractedPlaces.addAll(geoPlaces);
          _loadingMorePlaces = false;
        });
        widget.onStatusChanged?.call('${geoPlaces.length}개 장소를 추가했어요!');
      } else {
        setState(() => _loadingMorePlaces = false);
        widget.onStatusChanged?.call('추가 장소를 찾지 못했어요.');
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMorePlaces = false);
      debugPrint('[AiView] Request more places error: $e');
    }
  }

  void _generatePlanFromPlaces() {
    if (_extractedPlaces.isEmpty) return;
    // onAction으로 플랜 생성 요청
    widget.onAction?.call(AiActionEvent(
      AiAction.createPlan,
      {
        'style': 'efficient',
        'extractedPlaces': _extractedPlaces,
      },
    ));
    setState(() => _showPlacesPanel = false);

    _liveService.sendText(
      '사용자가 ${_extractedPlaces.length}개 장소로 일정 생성을 요청했습니다. '
      '효율적인 경로로 일정을 만들었다고 안내해주세요.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Glow 애니메이션 (배경)
        AnimatedBuilder(
          animation: Listenable.merge([
            _spreadController,
            _deformController,
            ..._layerControllers,
          ]),
          builder: (context, _) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Glow 영역 탭 시 텍스트 입력 닫기
                if (_showTextInput) _hideTextInputField();
              },
              child: CustomPaint(
                painter: _AiGlowPainter(
                  layerStops: _layerCurrentStops,
                  spreadProgress: _spreadController.value,
                  deformPhase: _deformController.value * 2 * pi,
                  strokeBoost: _glowStrokeBoost,
                  brightnessMultiplier: _glowBrightnessMultiplier,
                ),
                size: Size.infinite,
              ),
            );
          },
        ),

        // 2. 상태 인디케이터 (상단 중앙)
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: _buildStateIndicator(),
        ),

        // 3. DEBUG: AI thinking 텍스트 (중앙)
        if (_accumulatedTranscript.contains('[thinking]'))
          Positioned(
            left: 24,
            right: 24,
            top: MediaQuery.of(context).padding.top + 70,
            bottom: MediaQuery.of(context).size.height * 0.45,
            child: SingleChildScrollView(
              reverse: true,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFBC82F3).withValues(alpha: 0.12),
                      const Color(0xFF8D9FFF).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC686FF).withValues(alpha: 0.2)),
                ),
                child: Text(
                  _accumulatedTranscript,
                  style: TextStyle(
                    color: const Color(0xFFF5B9EA).withValues(alpha: 0.9),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),

        // 4. 무음 시 텍스트 입력 전환 (5초 후 자동)
        // 항상 표시 (테스트용) — 나중에 idlePrompt 조건 복원
        if (!_showPlacesPanel && !_showPhotoOptions)
          _buildIdlePrompt(),

        // 5. 분석 중 로딩 인디케이터
        if (_analyzingImage)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.45,
            left: 0,
            right: 0,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
          ),

        // 6. 사진 선택 인라인 위젯
        if (_showPhotoOptions)
          Positioned(
            left: 40,
            right: 40,
            top: MediaQuery.of(context).size.height * 0.38,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => Transform.scale(
                scale: 0.8 + 0.2 * v,
                child: Opacity(opacity: v, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFBC82F3).withValues(alpha: 0.2),
                      const Color(0xFF8D9FFF).withValues(alpha: 0.15),
                      const Color(0xFFF5B9EA).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBC82F3).withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBC82F3).withValues(alpha: 0.15),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '사진을 선택해주세요',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(ImageSource.camera),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFBC82F3), Color(0xFF8D9FFF)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('촬영', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickImage(ImageSource.gallery),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF5B9EA).withValues(alpha: 0.25),
                                    const Color(0xFFFF6778).withValues(alpha: 0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF5B9EA).withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('갤러리', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 7. 장소 분석 결과 패널 (슬라이드 업)
        _buildPlacesPanel(),

        // 8. 텍스트 입력 필드 (슬라이드 업)
        _buildTextInputOverlay(),
      ],
    );
  }

  /// 상태 표시 인디케이터
  Widget _buildStateIndicator() {
    String label;
    IconData icon;
    Color color;

    switch (_sessionState) {
      case LiveSessionState.connecting:
        label = '연결 중...';
        icon = Icons.wifi;
        color = Colors.orangeAccent;
        break;
      case LiveSessionState.listening:
        label = '듣고 있어요';
        icon = Icons.mic;
        color = Colors.greenAccent;
        break;
      case LiveSessionState.processing:
        label = '생각 중...';
        icon = Icons.auto_awesome;
        color = Colors.purpleAccent;
        break;
      case LiveSessionState.speaking:
        label = '말하는 중';
        icon = Icons.volume_up;
        color = Colors.blueAccent;
        break;
      case LiveSessionState.idlePrompt:
        label = '대기 중';
        icon = Icons.pause_circle_outline;
        color = Colors.white54;
        break;
      default:
        label = '준비 중';
        icon = Icons.hourglass_empty;
        color = Colors.white38;
    }

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(label),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFBC82F3).withValues(alpha: 0.25),
                const Color(0xFF8D9FFF).withValues(alpha: 0.25),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFBC82F3).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// 무음 시 텍스트 전환 프롬프트
  Widget _buildIdlePrompt() {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomOffset = keyboardHeight > 0
        ? keyboardHeight + 12
        : MediaQuery.of(context).padding.bottom + 75;

    return Positioned(
      bottom: bottomOffset,
      left: 20,
      right: 20,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (keyboardHeight == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '말을 할 수 없나요?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFBC82F3).withValues(alpha: 0.45),
                    const Color(0xFF8D9FFF).withValues(alpha: 0.40),
                    const Color(0xFFF5B9EA).withValues(alpha: 0.35),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFBC82F3).withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFBC82F3).withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: '메시지 입력...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _submitText(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _submitText,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFBC82F3), Color(0xFF8D9FFF)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 텍스트 입력 오버레이 (슬라이드 업/다운)
  Widget _buildTextInputOverlay() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: _showTextInput ? Curves.easeOutCubic : Curves.easeInCubic,
      bottom: _showTextInput
          ? MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16
          : -100,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _showTextInput ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _textFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  ),
                  onSubmitted: (_) => _submitText(),
                ),
              ),
              GestureDetector(
                onTap: _submitText,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBC82F3).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 하단 액션 버튼 (카메라, 갤러리, 텍스트)
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _actionButton(
          icon: Icons.camera_alt_rounded,
          label: '카메라',
          onTap: () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(width: 24),
        _actionButton(
          icon: Icons.photo_library_rounded,
          label: '갤러리',
          onTap: () => _pickImage(ImageSource.gallery),
        ),
        const SizedBox(width: 24),
        _actionButton(
          icon: Icons.keyboard_rounded,
          label: '텍스트',
          onTap: _showTextInputField,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── 장소 분석 결과 패널 (슬라이드 업) ──
  Widget _buildPlacesPanel() {
    final panelHeight = MediaQuery.of(context).size.height * 0.50;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: _showPlacesPanel ? Curves.easeOutCubic : Curves.easeInCubic,
      bottom: _showPlacesPanel ? 0 : -panelHeight - 50,
      left: 0,
      right: 0,
      height: panelHeight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _showPlacesPanel ? 1.0 : 0.0,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.dy > 200) {
              setState(() => _showPlacesPanel = false);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Column(
              children: [
                // 드래그 핸들
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                // 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        '발견된 장소 (${_extractedPlaces.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _showPlacesPanel = false),
                        child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.6), size: 22),
                      ),
                    ],
                  ),
                ),
                // 장소 리스트
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    itemCount: _extractedPlaces.length,
                    itemBuilder: (context, index) => _buildPlaceCard(index),
                  ),
                ),
                // 코스 추가 + 일정 만들기 버튼
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad + 12),
                  child: Row(
                    children: [
                      // 코스 추가 버튼
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _loadingMorePlaces ? null : _requestMorePlaces,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFF5B9EA).withValues(alpha: 0.3),
                                  const Color(0xFFFF6778).withValues(alpha: 0.25),
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFFF5B9EA).withValues(alpha: 0.5),
                              ),
                            ),
                            child: _loadingMorePlaces
                              ? const Center(
                                  child: SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      '코스 추가',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 일정 만들기 버튼
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: _generatePlanFromPlaces,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFBC82F3), Color(0xFF8D9FFF)],
                              ),
                            ),
                            child: Text(
                              '일정 만들기 (${_extractedPlaces.length}곳)',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(int index) {
    final place = _extractedPlaces[index];
    final color = _categoryColor(place.category);
    final icon = _categoryIcon(place.category);

    return Dismissible(
      key: ValueKey('${place.name}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removePlace(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.red.withValues(alpha: 0.2),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: color.withValues(alpha: 0.2),
                        ),
                        child: Text(
                          place.category,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.activity,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  if (place.nearestStation != null)
                    Text(
                      '${place.nearestStation}역 · ${place.estimatedMinutes}분',
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    return switch (category) {
      '맛집' => Colors.orange,
      '카페' => Colors.brown,
      '관광' => Colors.blue,
      '쇼핑' => Colors.pink,
      '문화' => Colors.purple,
      '자연' => Colors.green,
      _ => const Color(0xFFBC82F3),
    };
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      '맛집' => Icons.restaurant,
      '카페' => Icons.coffee,
      '관광' => Icons.photo_camera,
      '쇼핑' => Icons.shopping_bag,
      '문화' => Icons.museum,
      '자연' => Icons.park,
      _ => Icons.place,
    };
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Glow Painter (상태 반응형 — strokeBoost, brightnessMultiplier)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _AiGlowPainter extends CustomPainter {
  final List<List<double>> layerStops;
  final double spreadProgress;
  final double deformPhase;
  final double strokeBoost;
  final double brightnessMultiplier;

  _AiGlowPainter({
    required this.layerStops,
    required this.spreadProgress,
    required this.deformPhase,
    this.strokeBoost = 0.0,
    this.brightnessMultiplier = 1.0,
  });

  static const _baseColors = [
    Color(0xFFBC82F3),
    Color(0xFFF5B9EA),
    Color(0xFF8D9FFF),
    Color(0xFFFF6778),
    Color(0xFFFFBA71),
    Color(0xFFC686FF),
    Color(0xFFBC82F3),
  ];

  static const _baseLayerParams = [
    [3.5, 0.0],
    [10.0, 6.0],
    [18.0, 15.0],
    [28.0, 30.0],
  ];

  List<Color> get _colors {
    if (brightnessMultiplier == 1.0) return _baseColors;
    return _baseColors.map((c) {
      final hsv = HSVColor.fromColor(c);
      return hsv
          .withValue((hsv.value * brightnessMultiplier).clamp(0, 1))
          .withSaturation((hsv.saturation * (2 - brightnessMultiplier)).clamp(0, 1))
          .toColor();
    }).toList();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (spreadProgress <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final borderPath = _createDeformedPath(size);

    if (spreadProgress < 1.0) {
      _drawPartial(canvas, size, borderPath, rect);
    } else {
      _drawFull(canvas, borderPath, rect);
    }
  }

  Path _createDeformedPath(Size size, [Offset origin = Offset.zero]) {
    const r = 44.0;
    const segments = 512;
    const amplitude = 1.5;

    final path = Path();

    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final basePoint = _pointOnRoundedRect(size, r, t);

      final dx = amplitude * sin(deformPhase + t * 4 * pi) * cos(_normalAngle(size, r, t));
      final dy = amplitude * sin(deformPhase + t * 4 * pi) * sin(_normalAngle(size, r, t));

      final point = Offset(origin.dx + basePoint.dx + dx, origin.dy + basePoint.dy + dy);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  Offset _pointOnRoundedRect(Size size, double r, double t) {
    final w = size.width;
    final h = size.height;

    final straight = 2 * (w - 2 * r) + 2 * (h - 2 * r);
    final curved = 2 * pi * r;
    final total = straight + curved;

    var dist = t * total;

    final topLen = w - 2 * r;
    if (dist < topLen) return Offset(r + dist, 0);
    dist -= topLen;

    final cornerLen = pi * r / 2;
    if (dist < cornerLen) {
      final angle = -pi / 2 + dist / r;
      return Offset(w - r + r * cos(angle), r + r * sin(angle));
    }
    dist -= cornerLen;

    final rightLen = h - 2 * r;
    if (dist < rightLen) return Offset(w, r + dist);
    dist -= rightLen;

    if (dist < cornerLen) {
      final angle = 0.0 + dist / r;
      return Offset(w - r + r * cos(angle), h - r + r * sin(angle));
    }
    dist -= cornerLen;

    if (dist < topLen) return Offset(w - r - dist, h);
    dist -= topLen;

    if (dist < cornerLen) {
      final angle = pi / 2 + dist / r;
      return Offset(r + r * cos(angle), h - r + r * sin(angle));
    }
    dist -= cornerLen;

    if (dist < rightLen) return Offset(0, h - r - dist);
    dist -= rightLen;

    if (dist < cornerLen) {
      final angle = pi + dist / r;
      return Offset(r + r * cos(angle), r + r * sin(angle));
    }

    return Offset(r, 0);
  }

  double _normalAngle(Size size, double r, double t) {
    final w = size.width;
    final h = size.height;
    final straight = 2 * (w - 2 * r) + 2 * (h - 2 * r);
    final curved = 2 * pi * r;
    final total = straight + curved;
    var dist = t * total;

    final topLen = w - 2 * r;
    if (dist < topLen) return -pi / 2;
    dist -= topLen;

    final cornerLen = pi * r / 2;
    if (dist < cornerLen) return -pi / 2 + dist / r;
    dist -= cornerLen;

    final rightLen = h - 2 * r;
    if (dist < rightLen) return 0;
    dist -= rightLen;

    if (dist < cornerLen) return dist / r;
    dist -= cornerLen;

    if (dist < topLen) return pi / 2;
    dist -= topLen;

    if (dist < cornerLen) return pi / 2 + dist / r;
    dist -= cornerLen;

    if (dist < rightLen) return pi;
    dist -= rightLen;

    if (dist < cornerLen) return pi + dist / r;

    return -pi / 2;
  }

  void _drawFull(Canvas canvas, Path borderPath, Rect rect) {
    final colors = _colors;
    for (int i = 3; i >= 0; i--) {
      final params = _baseLayerParams[i];
      final gradient = SweepGradient(
        center: Alignment.center,
        colors: colors,
        stops: layerStops[i],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = params[0] + strokeBoost
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (params[1] > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, params[1]);
      }

      canvas.drawPath(borderPath, paint);
    }
  }

  void _drawPartial(Canvas canvas, Size size, Path fullPath, Rect rect) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(44),
    );
    final metricsPath = Path()..addRRect(rrect);
    final metrics = metricsPath.computeMetrics().first;
    final totalLength = metrics.length;

    final originRight = totalLength * 0.25;
    final originLeft = totalLength * 0.75;
    final halfSpread = totalLength * 0.25 * spreadProgress;

    Path extractWrapped(double start, double end) {
      final p = Path();
      if (start < 0) {
        p.addPath(metrics.extractPath(totalLength + start, totalLength), Offset.zero);
        p.addPath(metrics.extractPath(0, end), Offset.zero);
      } else if (end > totalLength) {
        p.addPath(metrics.extractPath(start, totalLength), Offset.zero);
        p.addPath(metrics.extractPath(0, end - totalLength), Offset.zero);
      } else {
        p.addPath(metrics.extractPath(start, end), Offset.zero);
      }
      return p;
    }

    final visiblePath = Path();
    visiblePath.addPath(extractWrapped(originRight - halfSpread, originRight + halfSpread), Offset.zero);
    visiblePath.addPath(extractWrapped(originLeft - halfSpread, originLeft + halfSpread), Offset.zero);

    final colors = _colors;
    for (int i = 3; i >= 0; i--) {
      final params = _baseLayerParams[i];
      final gradient = SweepGradient(
        center: Alignment.center,
        colors: colors,
        stops: layerStops[i],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = params[0] + strokeBoost
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (params[1] > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, params[1]);
      }

      canvas.drawPath(visiblePath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AiGlowPainter oldDelegate) => true;
}
