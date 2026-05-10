import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS: 원형 체크 (CupertinoIcons.checkmark_circle_fill)
/// Android: Material 3 Checkbox
///
/// 동의 화면처럼 라벨 옆에 큰 체크 영역이 필요할 때 사용.
class AdaptiveCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AdaptiveCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (Platform.isIOS) {
      return GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            value
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            color: value ? cs.primary : cs.onSurfaceVariant,
            size: 26,
          ),
        ),
      );
    }
    return Checkbox(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
    );
  }
}
