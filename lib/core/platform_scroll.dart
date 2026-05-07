import 'dart:io';
import 'package:flutter/material.dart';

/// 플랫폼 기본 스크롤 물리.
/// iOS — 리퀴드 글라스 정책에 맞춰 Bouncing(반동) + AlwaysScrollable 로 짧은 컨텐츠도 탄성 유지.
/// Android — Material 3 정책. Clamping(스크롤 끝에서 정지, 글로우 인디케이터 활용).
ScrollPhysics platformScrollPhysics() {
  if (Platform.isIOS) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
  return const ClampingScrollPhysics();
}
