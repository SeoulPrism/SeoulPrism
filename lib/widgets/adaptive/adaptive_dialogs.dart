import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS: CupertinoAlertDialog
/// Android: Material 3 AlertDialog
/// [cancelText] 가 null 이면 cancel 버튼 없이 confirm 단일 버튼 (alert 패턴).
Future<void> showAdaptiveConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String? cancelText = '취소',
  required String confirmText,
  bool isDestructive = false,
  required VoidCallback onConfirm,
}) {
  // iOS Cupertino 다이얼로그는 Navigator.pop 후 즉시 onConfirm 을 부르면
  // dismiss 애니메이션 중에 setState/rebuild 가 일어나면서 KeyedSubtree
  // 같은 트리 재구성이 시각적으로 적용되지 않는 경우가 있다 (테마/언어 변경 후
  // restartApp 이 안 되는 증상). pop 이 commit 된 뒤 다음 frame 에 사용자
  // 콜백을 실행해 race 를 회피. Android Material 다이얼로그도 같은 패턴으로
  // 통일.
  void runAfterPop() {
    WidgetsBinding.instance.addPostFrameCallback((_) => onConfirm());
  }

  if (Platform.isIOS) {
    return showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelText != null)
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(cancelText),
            ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            isDefaultAction: cancelText == null,
            onPressed: () {
              Navigator.pop(context);
              runAfterPop();
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // Android: Material 3 AlertDialog
  final cs = Theme.of(context).colorScheme;

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      icon: isDestructive
          ? Icon(Icons.warning_rounded, color: cs.error)
          : null,
      title: Text(title),
      content: Text(content, style: const TextStyle(height: 1.5)),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText),
          ),
        if (isDestructive)
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              runAfterPop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: Text(confirmText),
          )
        else
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              runAfterPop();
            },
            child: Text(confirmText),
          ),
      ],
    ),
  );
}

/// iOS: CupertinoActionSheet
/// Android: Material 3 ModalBottomSheet
Future<void> showAdaptivePicker({
  required BuildContext context,
  required String title,
  required List<String> options,
  required String selected,
  required ValueChanged<String> onSelected,
}) {
  if (Platform.isIOS) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: options.map((option) {
          return CupertinoActionSheetAction(
            isDefaultAction: option == selected,
            onPressed: () {
              Navigator.pop(context);
              onSelected(option);
            },
            child: Text(option),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ),
    );
  }

  // Android: Material 3 BottomSheet
  final cs = Theme.of(context).colorScheme;

  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 타이틀
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1),
          // 옵션들
          ...options.map((option) {
            final isSelected = option == selected;
            return ListTile(
              leading: isSelected
                  ? Icon(Icons.check_rounded, color: cs.primary)
                  : const SizedBox(width: 24),
              title: Text(
                option,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? cs.primary : cs.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onSelected(option);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
