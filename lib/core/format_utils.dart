/// 초 → "X시간 Y분" / "Y분" 표기.
String formatDuration(int sec) {
  final min = sec ~/ 60;
  final hr = min ~/ 60;
  return hr > 0 ? '${hr}시간 ${min % 60}분' : '$min분';
}

/// 원 → 천단위 콤마 표기 (예: 1234567 → "1,234,567").
String formatWon(int won) {
  return won.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}
