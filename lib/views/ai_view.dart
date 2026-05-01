import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_live_service.dart';
import '../services/audio_service.dart';

/// 통합 AI 뷰 — Glow 애니메이션 + Gemini Live 음성 대화
class AiView extends StatefulWidget {
  final VoidCallback? onClose;
  final bool closing;
  final void Function(AiActionEvent action)? onAction;

  const AiView({
    super.key,
    this.onClose,
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
  final GeminiLiveService _liveService = GeminiLiveService();
  final AudioService _audioService = AudioService();
  LiveSessionState _sessionState = LiveSessionState.idle;
  String _transcript = '';
  double _audioLevel = 0.0;

  // ── UI 상태 ──
  bool _showTextInput = false;
  bool _textModeActive = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  // ── 스트림 구독 ──
  StreamSubscription? _stateSub;
  StreamSubscription? _transcriptSub;
  StreamSubscription? _audioOutSub;
  StreamSubscription? _actionSub;
  StreamSubscription? _audioInSub;
  StreamSubscription? _levelSub;

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
    });

    _transcriptSub = _liveService.transcriptStream.listen((text) {
      if (!mounted) return;
      setState(() => _transcript = text);
    });

    _audioOutSub = _liveService.audioOutStream.listen((audio) {
      _audioService.playPcmAudio(audio);
    });

    _actionSub = _liveService.actionStream.listen((action) {
      widget.onAction?.call(action);
      // Function call에 대한 응답 전송
      _liveService.sendFunctionResponse(
        _actionToFunctionName(action.action),
        {'status': 'success', 'message': '액션이 실행되었습니다.'},
      );
    });

    // 오디오 레벨 구독 (Glow 반응용)
    _levelSub = _audioService.levelStream.listen((level) {
      if (!mounted) return;
      setState(() => _audioLevel = level);
    });

    // 세션 시작
    await _liveService.startSession();

    // 마이크 시작
    final micStarted = await _audioService.startRecording();
    if (micStarted) {
      _audioInSub = _audioService.audioInStream.listen((pcmData) {
        _liveService.sendAudio(pcmData);
      });
    }
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
    _liveService.dispose();
    _audioService.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
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

  // ── 이미지 첨부 ──
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 2048);
    if (picked == null) return;

    final bytes = await File(picked.path).readAsBytes();
    _liveService.sendImage(bytes);
    setState(() => _transcript = '이미지 분석 중...');
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

        // 3. AI 응답 자막 (중앙)
        if (_transcript.isNotEmpty)
          Positioned(
            left: 32,
            right: 32,
            top: MediaQuery.of(context).size.height * 0.35,
            child: _buildTranscript(),
          ),

        // 4. 무음 시 텍스트 전환 프롬프트
        if (_sessionState == LiveSessionState.idlePrompt && !_textModeActive)
          _buildIdlePrompt(),

        // 5. 텍스트 입력 필드 (슬라이드 업)
        _buildTextInputOverlay(),

        // 6. 하단 액션 버튼
        if (!_showTextInput)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 80,
            left: 0,
            right: 0,
            child: _buildActionButtons(),
          ),
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
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
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

  /// AI 응답 자막
  Widget _buildTranscript() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _transcript.isNotEmpty ? 1.0 : 0.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          _transcript,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  /// 무음 시 텍스트 전환 프롬프트
  Widget _buildIdlePrompt() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 160,
      left: 40,
      right: 40,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '현재 말을 못하는 상황인가요?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showTextInputField,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    '텍스트로 대화하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
