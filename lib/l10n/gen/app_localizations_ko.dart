// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppL10nKo extends AppL10n {
  AppL10nKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Seoul Vista';

  @override
  String get commonCancel => '취소';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonOk => '확인';

  @override
  String get commonSave => '저장';

  @override
  String get commonClose => '닫기';

  @override
  String get commonLater => '나중에';

  @override
  String get settingsAppLanguageTitle => '언어';

  @override
  String get languageSystem => '시스템 설정';

  @override
  String get languageKo => '한국어';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageChangedTitle => '언어가 변경되었어요';

  @override
  String get languageChangedBody => '새 언어를 완전히 적용하려면 앱을 재시작해야 해요. 지금 재시작할까요?';

  @override
  String get languageRestartNow => '재시작';

  @override
  String get languageRestartLater => '나중에';

  @override
  String get routeUnitHour => '시간';

  @override
  String get routeUnitMin => '분';

  @override
  String routeTransfersCount(int count) {
    return '환승 $count회';
  }

  @override
  String get routeDeparture => '출발';

  @override
  String get routeArrival => '도착';

  @override
  String get routeTransfer => '환승';

  @override
  String routeTransferDetail(String line, int min) {
    return '$line · $min분';
  }

  @override
  String routeBoardLine(String line) {
    return '$line 승차';
  }

  @override
  String routeSegmentBus(String from, String to, int count, int min) {
    return '$from → $to · $count개 정류장 · $min분';
  }

  @override
  String routeSegmentTrain(String from, String to, int count, int min) {
    return '$from → $to · $count개 역 · $min분';
  }

  @override
  String routeSegmentShort(String from, int min) {
    return '$from · $min분';
  }

  @override
  String get routeShowStops => '정류장 보기 ▼';

  @override
  String get routeCollapse => '접기 ▲';

  @override
  String get snsTitle => 'AI 플랜';

  @override
  String get snsSubtitle => 'SNS 콘텐츠로 서울 하루 플랜 만들기';

  @override
  String get snsSectionPhotos => '사진';

  @override
  String get snsSectionDescription => '설명';

  @override
  String get snsSectionLink => 'SNS 링크';

  @override
  String get snsTextHint => '가고 싶은 곳, 하고 싶은 것을 적어주세요';

  @override
  String get snsUrlHint => 'Instagram, TikTok URL';

  @override
  String get snsAnalyzeButton => '분석하기';

  @override
  String snsAnalyzeError(String error) {
    return '분석 실패: $error';
  }

  @override
  String get snsImageGallery => '갤러리';

  @override
  String get snsImageCamera => '카메라';

  @override
  String get dayPlanTitle => '하루 플랜';

  @override
  String get dayPlanNavigateAll => '전체 길찾기';

  @override
  String dayPlanTransitSummary(int min) {
    return '🚇 $min분';
  }

  @override
  String dayPlanTransfersSummary(int count) {
    return '🔄 $count회';
  }

  @override
  String dayPlanStyleStats(int count, int min) {
    return '$count곳 · $min분';
  }

  @override
  String get dayPlanNavigateStop => '길찾기';

  @override
  String get whatsNewClose => '닫기';

  @override
  String get whatsNewSkip => '건너뛰기';

  @override
  String get whatsNewStart => '시작하기';

  @override
  String get whatsNewNext => '다음';

  @override
  String whatsNewPage1Title(String version) {
    return 'v$version — 다시 만나서 반가워요';
  }

  @override
  String get whatsNewPage1Body =>
      '이번엔 여행이 더 너답게 바뀌었어요.\n여행 무드부터 친구·기록까지\n14개의 새 기능을 만나보세요.';

  @override
  String get whatsNewPage2Title => '당신의 여행 무드';

  @override
  String get whatsNewPage2Body =>
      '쉬어가기·놀기·역사·섞어서 중 하나를 고르면\nAI 톤, 추천 코스, 여행 탭이\n그 무드에 맞춰 바뀌어요.';

  @override
  String get whatsNewPage3Title => '같이 가기';

  @override
  String get whatsNewPage3Body =>
      '친구방에서 공통 목적지를 정하면\n멤버별 거리가 실시간으로 보여요.\n맵에는 주황 핀이 자동으로.';

  @override
  String get whatsNewPage4Title => '1:1 DM + 음성/사진';

  @override
  String get whatsNewPage4Body =>
      '친구방 없이 친구와 바로 대화.\n🎙 마이크 길게 눌러 음성, 📷 갤러리에서 사진,\n📍 위치까지 한 채팅에서.';

  @override
  String get whatsNewPage5Title => 'Spotify 공유';

  @override
  String get whatsNewPage5Body =>
      '내가 듣는 곡을 친구에게.\n채팅에 🎵 누르면 지금 재생 중인\nSpotify 트랙이 카드로 공유돼요.';

  @override
  String get whatsNewPage6Title => '친구 늘리기';

  @override
  String get whatsNewPage6Body =>
      '친구 화면에 \"친구의 친구\" 추천,\nQR 코드로 즉시 추가,\n방 초대 링크로 한 번에 입장.';

  @override
  String get whatsNewPage7Title => '활동이 점수가 돼요';

  @override
  String get whatsNewPage7Body =>
      '친구 추가, 만남, 연속 출석으로 점수와 뱃지.\n친구끼리 랭킹으로 비교하고,\n주간 활동 차트로 돌아보세요.';

  @override
  String get whatsNewPage8Title => '내 마음대로';

  @override
  String get whatsNewPage8Body =>
      '알림은 종류별로 켜고 끄고,\n내 위치는 특정 그룹에게만.\n안전과 프라이버시는 본인이.';

  @override
  String get profileCategoryFavorites => '즐겨찾기';

  @override
  String get profileCategoryRecent => '최근 방문';

  @override
  String get profileCategoryFrequent => '자주 방문';

  @override
  String get profileGuestName => '게스트';

  @override
  String get profileDefaultName => '사용자';

  @override
  String get profileSyncCta => '정식 로그인하면 다른 기기에서도 동기화돼요';

  @override
  String profileAgoDays(int days) {
    return '$days일 전';
  }

  @override
  String profileAgoHours(int hours) {
    return '$hours시간 전';
  }

  @override
  String get profileAgoNow => '방금';

  @override
  String profileVisitCount(int count) {
    return '$count회 방문';
  }

  @override
  String get profileEmptyFavorites => '즐겨찾기가 없습니다';

  @override
  String get profileEmptyVisits => '방문 기록이 없습니다';

  @override
  String get profileCollapse => '접기';

  @override
  String profileMoreCount(int count) {
    return '$count개 더 보기';
  }

  @override
  String get profileLiveShareBeta => '친구와 위치/채팅 실시간 공유 (베타)';

  @override
  String get profileTimeline => '내 타임라인';

  @override
  String profilePlaceCount(int count) {
    return '$count곳';
  }

  @override
  String get profileEmptyVisitsCta => '방문 기록이 없어요. 장소를 탐색하고 길찾기를 해보세요.';

  @override
  String get profileToday => '오늘';

  @override
  String get profileYesterday => '어제';

  @override
  String profileMonthDay(int month, int day) {
    return '$month월 $day일';
  }

  @override
  String profileVisitTimes(int count) {
    return '$count회';
  }

  @override
  String get profileEditName => '이름 변경';

  @override
  String get profileNewNameHint => '새 이름 입력';

  @override
  String get profileTagline => '서울의 모든 순간을 담다';

  @override
  String get profileMore => '더보기';

  @override
  String get profileEmptyMapPlaces => '방문지가 쌓이면 여기 지도에 표시돼요';

  @override
  String profileRecentPlaceCount(int count) {
    return '최근 $count곳';
  }
}
