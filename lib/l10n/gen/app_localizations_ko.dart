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

  @override
  String chatSendFailed(String error) {
    return '전송 실패: $error';
  }

  @override
  String get chatRoomDestSet => '🎯 방 목적지로 설정됨';

  @override
  String chatActionFailed(String error) {
    return '실패: $error';
  }

  @override
  String get chatMapAppUnavailable => '지도 앱을 열 수 없어요';

  @override
  String get chatMicPermissionRequired => '마이크 권한이 필요해요';

  @override
  String chatRecordStartFailed(String error) {
    return '녹음 시작 실패: $error';
  }

  @override
  String get chatRecordTooShort => '너무 짧아요 — 길게 눌러 녹음';

  @override
  String chatRecordStopFailed(String error) {
    return '녹음 종료 실패: $error';
  }

  @override
  String chatPhotoSendFailed(String error) {
    return '사진 전송 실패: $error';
  }

  @override
  String get chatSpotifyClientIdMissing =>
      'Spotify 설정 필요 — 개발자가 SPOTIFY_CLIENT_ID 를 추가해야 해요';

  @override
  String get chatSpotifyAuthRetryHint => 'Spotify 인증 후 다시 눌러주세요';

  @override
  String chatSpotifyAuthFailed(String error) {
    return 'Spotify 연결 실패: $error';
  }

  @override
  String get chatMyLocation => '내 위치';

  @override
  String get chatLocationUnavailable => '위치를 가져올 수 없어요';

  @override
  String get chatDefaultRoomName => '친구방';

  @override
  String chatMembersInRoom(int count) {
    return '$count 명 참여 중';
  }

  @override
  String get chatRecordingHint => '녹음 중... 손 떼면 전송 / 위로 드래그 시 취소';

  @override
  String get chatRecordingPlaceholder => '🎙 녹음 중';

  @override
  String get chatMessageHint => '메시지 입력';

  @override
  String get chatActionMap => '지도';

  @override
  String get chatActionDirections => '길찾기';

  @override
  String get chatActionRoomDest => '🎯 방 목적지로';

  @override
  String chatVoiceLabel(int seconds) {
    return '${seconds}s 음성';
  }

  @override
  String chatPlaybackFailed(String error) {
    return '재생 실패: $error';
  }

  @override
  String chatEmptyTitleNamed(String roomName) {
    return '$roomName 방이 시작됐어요';
  }

  @override
  String get chatEmptyTitleDefault => '친구방이 시작됐어요';

  @override
  String get chatEmptyBody => '여기서 친구들과 만나서 인사하고, 위치도 공유하고,\n같이 갈 곳도 정해보세요.';

  @override
  String get chatStart => '대화 시작';

  @override
  String get chatReport => '이 메시지 신고';

  @override
  String chatBlockDialogTitle(String nickname) {
    return '$nickname 차단';
  }

  @override
  String get chatBlockDialogBody => '차단하면 같은 방에서 즉시 강퇴되고 메시지도 보이지 않아요.';

  @override
  String get chatBlockConfirm => '차단';

  @override
  String get chatUnknownUser => '사용자';

  @override
  String get spotifyOpenInApp => 'Spotify 에서 열기';

  @override
  String spotifyShareFailed(String error) {
    return '공유 실패: $error';
  }

  @override
  String get spotifyNoTrack => '재생 중인 곡이 없어요';

  @override
  String get dmAccessDenied => '대화에 접근할 수 없어요';

  @override
  String dmSendFailed(String error) {
    return '전송 실패: $error';
  }

  @override
  String get dmDefaultPeer => '친구';

  @override
  String get dmEmptyHint => '첫 메시지를 보내보세요';

  @override
  String get dmMessageHint => '메시지';

  @override
  String get friendCodeLengthError => '8자리 코드를 입력해주세요.';

  @override
  String get friendCodeNotFound => '코드와 일치하는 사용자를 찾을 수 없어요.';

  @override
  String friendRequestSent(String nickname) {
    return '$nickname 님에게 친구 신청을 보냈어요.';
  }

  @override
  String get friendShareSubject => 'Seoul Live 친구 추가';

  @override
  String friendShareBody(String nickname, String code) {
    return '$nickname 님이 Seoul Live 친구 코드를 보냈어요!\n\n코드: $code\n바로 추가: com.seoul.prism://friend/$code';
  }

  @override
  String get friendShareCopied => '공유 텍스트를 복사했어요';

  @override
  String get friendCodeTitle => '친구 코드';

  @override
  String get friendCodeSubtitle => '내 코드를 공유하거나, 친구 코드로 추가하세요.';

  @override
  String get friendMyCode => '내 친구 코드';

  @override
  String get friendCodeCopied => '코드 복사됨';

  @override
  String get friendQrHint => '친구가 카메라로 스캔하면 바로 추가돼요';

  @override
  String get friendShareButton => '공유하기';

  @override
  String get friendAddByCodeTitle => '친구 코드로 친구 추가';

  @override
  String get friendAddByCodeHint => '받은 8글자 코드를 입력하거나 QR 을 스캔하세요';

  @override
  String get friendCodePlaceholder => '예: AB12CD34';

  @override
  String get friendSendRequest => '친구 신청 보내기';

  @override
  String peerFriendCode(String code) {
    return '친구 코드 $code';
  }

  @override
  String get peerOwnPin => '나의 핀이에요';

  @override
  String get peerReport => '신고';

  @override
  String peerBlockDialogTitle(String nickname) {
    return '$nickname 차단';
  }

  @override
  String get peerBlockDialogBody => '차단하면 같은 방에서 강퇴되고 메시지/핀이 보이지 않아요.';

  @override
  String get peerBlockConfirm => '차단';

  @override
  String get peerBlock => '차단';

  @override
  String get peerIsFriend => '친구입니다 ✓';

  @override
  String get peerCancelRequest => '신청 취소';

  @override
  String peerRequestCanceled(String nickname) {
    return '$nickname 에게 보낸 신청 취소함';
  }

  @override
  String get peerAcceptRequest => '친구 신청 수락';

  @override
  String peerNowFriend(String nickname) {
    return '$nickname 와 친구가 됐어요';
  }

  @override
  String peerCanRequestInDays(int days) {
    return '$days일 후 재신청 가능';
  }

  @override
  String peerCanRequestInHours(int hours) {
    return '$hours시간 후 재신청 가능';
  }

  @override
  String get peerSendRequest => '친구 신청 보내기';

  @override
  String peerRequestSent(String nickname) {
    return '$nickname 에게 신청을 보냈어요';
  }

  @override
  String peerDistanceMeters(int meters) {
    return '${meters}m 거리';
  }

  @override
  String peerDistanceKm(String km) {
    return '${km}km 거리';
  }

  @override
  String get spotifyRoomRequired => '친구방에 입장한 뒤 다시 시도해주세요';

  @override
  String get spotifyShareSuccess => '🎵 친구방에 공유했어요';

  @override
  String get spotifyDisconnectTitle => 'Spotify 연결 해제';

  @override
  String get spotifyDisconnectBody => '저장된 토큰을 삭제하고 친구에게 곡 공유가 중단돼요.';

  @override
  String get spotifyDisconnectConfirm => '해제';

  @override
  String get spotifyDisconnected => 'Spotify 해제됨';

  @override
  String get spotifyAuthRetryHint => 'Spotify 인증 후 자동으로 돌아와요';

  @override
  String spotifyConnectFailed(String error) {
    return '연결 실패: $error';
  }

  @override
  String get spotifyClientIdMissing => '개발자 SPOTIFY_CLIENT_ID 미설정';

  @override
  String get spotifyTokenExpired => '연결이 만료됐어요. 다시 로그인해주세요.';

  @override
  String get spotifyReconnect => 'Spotify 다시 연결';

  @override
  String get spotifyConnect => 'Spotify 연결';

  @override
  String get spotifyConnectDescription =>
      '연결하면 친구방 채팅에 듣고 있는 곡을\n공유할 수 있고, 친구도 내가 듣는 곡을 봐요.';

  @override
  String get spotifyLoginButton => 'Spotify 로 로그인';

  @override
  String get spotifyShareToRoom => '친구방에 공유';

  @override
  String get spotifyDisconnect => '연결 해제';

  @override
  String get spotifyConnectedNoTrack => 'Spotify 연결됨 (재생 없음)';

  @override
  String get spotifyNowPlaying => '지금 듣는 곡';

  @override
  String get departureTimePickerTitle => '출발 시각';

  @override
  String get departureTimePickerHint => '지정된 시각 기준으로 도착 시각이 계산됩니다.';

  @override
  String get departureTimeNow => '지금';

  @override
  String get departureTime30min => '30분 후';

  @override
  String get departureTime1hour => '1시간 후';

  @override
  String get departureTimeCustom => '직접 지정';

  @override
  String get placeActionDepart => '출발';

  @override
  String get placeActionArrive => '도착';

  @override
  String get placeActionInfo => '정보';

  @override
  String get placeDetailTapHint => '탭하여 사진·리뷰·영업시간 보기';

  @override
  String get savedPanelTitle => '저장';

  @override
  String get savedEmptyFavorites => '저장한 장소가 없습니다';

  @override
  String get savedRemoveFavoriteTooltip => '즐겨찾기 해제';

  @override
  String get travelThemeTitle => '테마 추천';

  @override
  String get travelThemeSubtitle => '탭 한 번으로 코스 자동 생성';

  @override
  String get travelTitle => '여행';

  @override
  String get travelSubtitle => '경복궁부터 한강 야경까지, 하루 코스를 짜드려요';

  @override
  String get travelEventsTitle => '이번 주 이벤트';

  @override
  String get travelEventsSubtitle => '서울에서 진행 중인 문화행사';

  @override
  String travelEventsCount(int count) {
    return '$count개';
  }

  @override
  String get travelEventsLoadError => '행사 정보를 불러오지 못했어요. 아래로 당겨서 다시 시도해 주세요.';

  @override
  String get travelAiTitle => 'AI 가 일정을 짜드려요';

  @override
  String get travelAiSubtitle => '시간 · 날씨 · 동선 자동 고려';

  @override
  String get travelFromSavedTitle => '저장한 장소로 만들기';

  @override
  String get travelFromSavedSubtitle => '즐겨찾기 + 방문 기록 기반 동선';

  @override
  String get travelYourTheme => '당신의 테마';

  @override
  String get travelStartWithMood => '이 무드로 코스 시작';

  @override
  String get travelEventBadgeOngoing => '진행 중';

  @override
  String get travelEventBadgeFree => '무료';

  @override
  String travelThemeStops(int count) {
    return '$count곳';
  }

  @override
  String get travelMoodAnalyzing => '곡 분위기 분석 중...';

  @override
  String get travelMoodExcited => '신나는 분위기엔';

  @override
  String get travelMoodToday => '오늘 같은 날엔';

  @override
  String get travelMoodIntense => '강렬한 비트엔';

  @override
  String get travelMoodCalm => '차분한 분위기엔';

  @override
  String get travelTodayMoodLabel => '오늘의 분위기';

  @override
  String get notificationsTitle => '알림';

  @override
  String get notificationsEmptyTitle => '알림이 없습니다';

  @override
  String get notificationsEmptySubtitle => '새로운 소식이 있으면 여기에 표시됩니다';
}
