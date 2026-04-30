import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS: CupertinoAlertDialog
/// Android: Material 3 AlertDialog
Future<void> showAdaptiveConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String cancelText = '취소',
  required String confirmText,
  bool isDestructive = false,
  required VoidCallback onConfirm,
}) {
  if (Platform.isIOS) {
    return showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText),
        ),
        if (isDestructive)
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
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
              onConfirm();
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
