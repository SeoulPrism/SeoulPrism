import 'dart:io';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';

/// iOS: CNSegmentedControl (네이티브 UISegmentedControl)
/// Android: Material 3 SegmentedButton
///
/// 아이콘 + 라벨 동시 노출 시 SegmentedButton 의 icon 슬롯 활용.
class AdaptiveSegmented<T> extends StatelessWidget {
  final List<AdaptiveSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  const AdaptiveSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      final idx = segments.indexWhere((s) => s.value == selected);
      return CNSegmentedControl(
        labels: segments.map((s) => s.label).toList(),
        selectedIndex: idx < 0 ? 0 : idx,
        onValueChanged: (i) => onSelected(segments[i].value),
      );
    }

    return SegmentedButton<T>(
      segments: segments
          .map((s) => ButtonSegment<T>(
                value: s.value,
                label: Text(s.label),
                icon: s.icon != null ? Icon(s.icon) : null,
              ))
          .toList(),
      selected: {selected},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onSelected(set.first);
      },
      showSelectedIcon: false,
    );
  }
}

class AdaptiveSegment<T> {
  final T value;
  final String label;
  final IconData? icon;
  const AdaptiveSegment({required this.value, required this.label, this.icon});
}
