import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/device_profile_service.dart';

/// 디바이스 프로필 자동 적용 후 잠깐 표시되는 토스트 ("플래그십 · 60fps · 폴링 1000ms 최적화 적용").
class ProfileToast extends StatelessWidget {
  final bool visible;
  const ProfileToast({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    final dp = DeviceProfileService.instance;
    final tierLabel = switch (dp.profile.tier) {
      DeviceTier.flagship => '플래그십',
      DeviceTier.high => '상위',
      DeviceTier.mid => '중급',
      DeviceTier.low => '저사양',
    };

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 80,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          opacity: visible ? 1.0 : 0.0,
          child: Center(
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: Text(
                    '${dp.rawModel} · $tierLabel\n'
                    '${dp.profile.animFps}fps · 폴링 ${dp.profile.naverPollMs}ms 최적화 적용',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// AI 상태 바 (그라데이션 배경 + 타이핑 텍스트).
class AiStatusBar extends StatelessWidget {
  final String aiStatus;
  const AiStatusBar({super.key, required this.aiStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFBC82F3).withValues(alpha: 0.2),
            const Color(0xFF8D9FFF).withValues(alpha: 0.15),
            const Color(0xFFF5B9EA).withValues(alpha: 0.1),
          ],
        ),
        border: Border(
          top: BorderSide(color: const Color(0xFFBC82F3).withValues(alpha: 0.4)),
        ),
      ),
      child: _AiStatusText(text: aiStatus),
    );
  }
}

/// AI 상태 텍스트 (타이핑 효과).
class _AiStatusText extends StatefulWidget {
  final String text;
  const _AiStatusText({required this.text});

  @override
  State<_AiStatusText> createState() => _AiStatusTextState();
}

class _AiStatusTextState extends State<_AiStatusText> {
  String _fullText = '';
  String _displayed = '';
  Timer? _timer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping(widget.text);
  }

  @override
  void didUpdateWidget(_AiStatusText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      if (widget.text.isEmpty) {
        _timer?.cancel();
        setState(() {
          _fullText = '';
          _displayed = '';
          _charIndex = 0;
        });
      } else if (widget.text.length > _fullText.length &&
          widget.text.startsWith(_fullText)) {
        _fullText = widget.text;
        _continueTyping();
      } else {
        _startTyping(widget.text);
      }
    }
  }

  void _startTyping(String target) {
    _timer?.cancel();
    _fullText = target;
    _displayed = '';
    _charIndex = 0;
    _continueTyping();
  }

  void _continueTyping() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted || _charIndex >= _fullText.length) {
        t.cancel();
        return;
      }
      _charIndex++;
      setState(() => _displayed = _fullText.substring(0, _charIndex));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayed.isEmpty) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 60),
      child: SingleChildScrollView(
        reverse: true,
        child: Text(
          _displayed,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
