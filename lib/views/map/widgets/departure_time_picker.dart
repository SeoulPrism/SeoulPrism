import 'package:flutter/cupertino.dart';

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
Future<DepartureTimeResult> showDepartureTimePicker(
  BuildContext context, {
  required DateTime? current,
}) async {
  DepartureTimeResult result = const DepartureTimeResult.cancelled();
  await showCupertinoModalPopup(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: const Text('출발 시각'),
      message: current != null
          ? const Text('지정된 시각 기준으로 도착 시각이 계산됩니다.')
          : null,
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            result = const DepartureTimeResult(null);
            Navigator.pop(ctx);
          },
          child: const Text('지금'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            result = DepartureTimeResult(
              DateTime.now().add(const Duration(minutes: 30)),
            );
            Navigator.pop(ctx);
          },
          child: const Text('30분 후'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            result = DepartureTimeResult(
              DateTime.now().add(const Duration(hours: 1)),
            );
            Navigator.pop(ctx);
          },
          child: const Text('1시간 후'),
        ),
        CupertinoActionSheetAction(
          onPressed: () async {
            Navigator.pop(ctx);
            final picked = await _pickCustomTime(context, current: current);
            if (picked != null) result = DepartureTimeResult(picked);
          },
          child: const Text('직접 지정'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        isDefaultAction: true,
        child: const Text('취소'),
      ),
    ),
  );
  return result;
}

Future<DateTime?> _pickCustomTime(
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
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ? selected : null;
}
