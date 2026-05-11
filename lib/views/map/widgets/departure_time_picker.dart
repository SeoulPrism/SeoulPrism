import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

/// 출발 시각 선택 picker 결과.
/// [changed] = false 면 사용자가 취소 → 부모는 기존 값 유지.
/// [changed] = true 이면 [time] 으로 갱신 (null = "지금" = 현재 시각 기준).
class DepartureTimeResult {
  final bool changed;
  final DateTime? time;
  const DepartureTimeResult.cancelled() : changed = false, time = null;
  const DepartureTimeResult(this.time) : changed = true;
}

/// 출발 시각 변경 picker. 빠른 옵션(지금/30분 후/1시간 후) + 직접 지정.
/// [current] = 현재 설정값 (null = 현재 시각 기준).
/// iOS = CupertinoActionSheet, Android = M3 BottomSheet.
Future<DepartureTimeResult> showDepartureTimePicker(
  BuildContext context, {
  required DateTime? current,
}) async {
  if (Platform.isIOS) {
    return _showIOSPicker(context, current: current);
  }
  return _showAndroidPicker(context, current: current);
}

Future<DepartureTimeResult> _showIOSPicker(
  BuildContext context, {
  required DateTime? current,
}) async {
  DepartureTimeResult result = const DepartureTimeResult.cancelled();
  final l = AppL10n.of(context);
  await showCupertinoModalPopup(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(l.departureTimePickerTitle),
      message: current != null
          ? Text(l.departureTimePickerHint)
          : null,
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            result = const DepartureTimeResult(null);
            Navigator.pop(ctx);
          },
          child: Text(l.departureTimeNow),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            result = DepartureTimeResult(
              DateTime.now().add(const Duration(minutes: 30)),
            );
            Navigator.pop(ctx);
          },
          child: Text(l.departureTime30min),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            result = DepartureTimeResult(
              DateTime.now().add(const Duration(hours: 1)),
            );
            Navigator.pop(ctx);
          },
          child: Text(l.departureTime1hour),
        ),
        CupertinoActionSheetAction(
          onPressed: () async {
            Navigator.pop(ctx);
            if (!context.mounted) return;
            final picked = await _pickCustomTimeIOS(context, current: current);
            if (picked != null) result = DepartureTimeResult(picked);
          },
          child: Text(l.departureTimeCustom),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        isDefaultAction: true,
        child: Text(l.commonCancel),
      ),
    ),
  );
  return result;
}

Future<DepartureTimeResult> _showAndroidPicker(
  BuildContext context, {
  required DateTime? current,
}) async {
  DepartureTimeResult result = const DepartureTimeResult.cancelled();
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final l = AppL10n.of(ctx);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  l.departureTimePickerTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (current != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Text(
                    l.departureTimePickerHint,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ListTile(
                leading: Icon(Icons.flash_on_rounded, color: cs.primary),
                title: Text(l.departureTimeNow),
                onTap: () {
                  result = const DepartureTimeResult(null);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(Icons.av_timer_rounded, color: cs.primary),
                title: Text(l.departureTime30min),
                onTap: () {
                  result = DepartureTimeResult(
                    DateTime.now().add(const Duration(minutes: 30)),
                  );
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(Icons.schedule_rounded, color: cs.primary),
                title: Text(l.departureTime1hour),
                onTap: () {
                  result = DepartureTimeResult(
                    DateTime.now().add(const Duration(hours: 1)),
                  );
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_calendar_rounded, color: cs.primary),
                title: Text(l.departureTimeCustom),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!context.mounted) return;
                  final picked =
                      await _pickCustomTimeAndroid(context, current: current);
                  if (picked != null) result = DepartureTimeResult(picked);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
  return result;
}

Future<DateTime?> _pickCustomTimeIOS(
  BuildContext context, {
  required DateTime? current,
}) async {
  DateTime selected = current ?? DateTime.now();
  bool confirmed = false;
  await showCupertinoModalPopup(
    context: context,
    builder: (ctx) => Container(
      height: 280,
      color: CupertinoColors.systemBackground.resolveFrom(ctx),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: selected,
                minimumDate: DateTime.now().subtract(
                  const Duration(minutes: 1),
                ),
                onDateTimeChanged: (dt) => selected = dt,
              ),
            ),
            CupertinoButton(
              onPressed: () {
                confirmed = true;
                Navigator.pop(ctx);
              },
              child: Text(AppL10n.of(ctx).commonConfirm),
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ? selected : null;
}

Future<DateTime?> _pickCustomTimeAndroid(
  BuildContext context, {
  required DateTime? current,
}) async {
  final base = current ?? DateTime.now();
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: base,
    firstDate: DateTime.now().subtract(const Duration(minutes: 1)),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );
  if (pickedDate == null || !context.mounted) return null;
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(base),
  );
  if (pickedTime == null) return null;
  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}
