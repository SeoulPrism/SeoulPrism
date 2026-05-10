import 'package:flutter/material.dart';

import '../services/onboarding_service.dart';
import '../widgets/adaptive/adaptive.dart';

/// 앱 short version. pubspec 의 version 과 일치 유지.
const String kAppVersion = '1.0.5';

/// What's New 시트 — 신규 버전 첫 진입 시 자동 표시.
/// 사용:
///   WhatsNewSheet.maybeShow(context);
class WhatsNewSheet extends StatelessWidget {
  const WhatsNewSheet({super.key});

  /// 마지막 본 버전이 [kAppVersion] 과 다르면 시트를 띄움.
  /// [forceShow] 가 true 면 항상 (설정 → 다시 보기 등).
  static Future<void> maybeShow(
    BuildContext context, {
    bool forceShow = false,
  }) async {
    final svc = OnboardingService.instance;
    if (!forceShow && svc.lastSeenWhatsNewVersion == kAppVersion) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const WhatsNewSheet(),
    );
    await svc.markWhatsNewSeen(kAppVersion);
  }

  static const _items = <_WhatsNewItem>[
    _WhatsNewItem('🎉', '같이 가기 모드',
        '친구방에서 공통 목적지 설정 — 멤버별 거리 실시간 표시'),
    _WhatsNewItem('💬', '1:1 DM',
        '친구 화면에서 메시지 버튼 → 친구방 없이 바로 대화'),
    _WhatsNewItem('🎙', '음성 메시지',
        '채팅 마이크 길게 눌러 녹음 — 손 떼면 전송'),
    _WhatsNewItem('📷', '사진 공유',
        '갤러리 사진을 채팅으로 — 탭하면 풀스크린'),
    _WhatsNewItem('🎵', 'Spotify 연동',
        '듣고 있는 곡을 친구에게 — 스포티파이 카드로 공유'),
    _WhatsNewItem('🏆', '점수 / 뱃지 / 랭킹',
        '친구 추가, 만남, 연속 출석 — 친구끼리 활동 비교'),
    _WhatsNewItem('🤝', '친구 추천',
        '친구의 친구 — 공통 친구 수 기반으로 자동 추천'),
    _WhatsNewItem('📍', '장소 공유 + 외부 길찾기',
        '채팅 카드 탭 → 지도 점프 / 길찾기 → 카카오·네이버 지도'),
    _WhatsNewItem('🔗', '방 초대 링크',
        '친구방 코드 옆 공유 버튼 — sms / 메신저로 한 번에 입장'),
    _WhatsNewItem('🔔', '알림 세분화',
        '친구 신청, 채팅, 만남 등 종류별로 켜고 끄기'),
    _WhatsNewItem('👥', '그룹별 위치 공개',
        '특정 친구 그룹에게만 내 위치 보이기'),
    _WhatsNewItem('📊', '활동 분석',
        '주간 활동 차트 + 최근 활동 타임라인'),
    _WhatsNewItem('📡', 'QR 친구 추가',
        '친구 코드 시트에 QR 표시 + 카메라로 스캔'),
    _WhatsNewItem('🛡', 'Crashlytics',
        'release 빌드의 충돌 자동 보고 (개발자만 확인)'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('v$kAppVersion',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: cs.onPrimary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('이번에 새로 들어온 것',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                    'Seoul Live 기능을 한 번에 모았어요. 친구와 더 자주 만나보세요.',
                    style:
                        TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final it = _items[i];
                    return AdaptiveSurfaceCard(
                      borderRadius: 14,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primaryContainer,
                            ),
                            alignment: Alignment.center,
                            child: Text(it.emoji,
                                style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.title,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: cs.onSurface)),
                                const SizedBox(height: 2),
                                Text(it.body,
                                    style: TextStyle(
                                        fontSize: 12,
                                        height: 1.35,
                                        color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: AdaptiveGlassButton(
                    label: '시작하기',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WhatsNewItem {
  final String emoji;
  final String title;
  final String body;
  const _WhatsNewItem(this.emoji, this.title, this.body);
}
