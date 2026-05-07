import 'package:flutter/widgets.dart';

/// 튜토리얼 페이지 1장 = (id, 위젯).
/// [id] 는 영구 저장되어 "본 페이지" 추적에 쓰이므로 절대 변경 금지.
/// 새 페이지 추가 시 새 [id] 만 부여 — 기존 사용자는 새 페이지만 보게 됨.
class OnboardingPage {
  final String id;
  final Widget body;
  const OnboardingPage({required this.id, required this.body});
}
