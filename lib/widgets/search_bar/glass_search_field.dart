import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../adaptive/adaptive.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

/// 리퀴드 글라스 검색 필드. 부모 setState 시 리빌드 차단을 위해 별도 위젯으로 분리.
class GlassSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;
  final VoidCallback? onProfileTap;
  final double height;

  const GlassSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    this.onProfileTap,
    this.height = 48.0,
  });

  @override
  State<GlassSearchField> createState() => _GlassSearchFieldState();
}

class _GlassSearchFieldState extends State<GlassSearchField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 250),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode.hasFocus) {
      _pressCtrl.forward().then((_) {
        if (mounted) _pressCtrl.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFFB0B0B0);
    const placeholderColor = Color(0xFF8E8E93);

    final glassBar = SizedBox(
      height: widget.height,
      child: AdaptiveGlassContainer.capsule(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Icon(CupertinoIcons.search, size: 20, color: placeholderColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AdaptiveSearchField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  placeholder: '장소, 버스, 지하철 검색',
                  placeholderStyle: TextStyle(
                    color: placeholderColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  style: AppTypography.bodyMd.copyWith(color: textColor),
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (_, value, __) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return Semantics(
                    label: '검색어 지우기',
                    button: true,
                    child: GestureDetector(
                      onTap: widget.onClear,
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 20,
                          color: placeholderColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _pressCtrl,
      builder: (context, child) {
        final t = _pressCtrl.value;
        return Transform.scale(
          scale: 1.0 - (t * 0.03),
          child: Opacity(opacity: 1.0 - (t * 0.08), child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        behavior: HitTestBehavior.translucent,
        child: glassBar,
      ),
    );
  }
}
