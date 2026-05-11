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
  String get languageChangedTitle => '언어 저장됨';

  @override
  String get languageChangedBody =>
      '새 언어를 완전히 적용하려면 앱 전환기에서 앱을 위로 밀어 종료한 뒤 다시 열어주세요.';

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
  String get whatsNewPage9Title => '한 번에 길찾기';

  @override
  String get whatsNewPage9Body =>
      '지하철·버스·도보를 하나로.\n환승, 실시간 도착, 역 출구까지\n한 화면에서 다 보여요.';

  @override
  String get whatsNewPage10Title => '하루 플랜 자동 생성';

  @override
  String get whatsNewPage10Body =>
      '저장한 장소로 하루 코스를 짜드려요.\n효율 동선·여유 산책·맛집 중심,\n3가지 스타일로.';

  @override
  String get whatsNewPage11Title => '4개 언어 지원';

  @override
  String get whatsNewPage11Body =>
      '한국어·영어·일본어·중국어.\nAI 비서도 같은 언어로 답해요.\n기기 언어에 자동으로 맞춰져요.';

  @override
  String get whatsNewPage12Title => '말로 묻고 답 받기';

  @override
  String get whatsNewPage12Body =>
      'AI 비서랑 음성으로 자연스럽게.\n검색·길찾기·추천도 음성으로.\nGemini Live 가 듣고 바로 답해요.';

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

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionRealtime => '실시간 시각화';

  @override
  String get settingsLineSubway => '지하철 노선';

  @override
  String get settingsTrainPos => '지하철 열차 위치';

  @override
  String get settingsStations => '지하철 역';

  @override
  String get settingsBuses => '시내버스';

  @override
  String get settingsRiverBus => '한강버스';

  @override
  String get settingsFlights => '항공기';

  @override
  String get settingsSectionDataSource => '데이터 소스';

  @override
  String get settingsSubwayMode => '지하철 모드';

  @override
  String get settingsSubwayModeLive => '실시간';

  @override
  String get settingsSubwayModeDemo => '데모';

  @override
  String get settingsSeoulApi => '서울시 공공 API (60s)';

  @override
  String get settingsNaverApi => '네이버 API (5s 단위 보정)';

  @override
  String get settingsSectionLighting => '라이팅';

  @override
  String get settingsAutoLighting => '자동 (시간대 + 날씨)';

  @override
  String get settingsLightPreset => '라이트 프리셋';

  @override
  String get settingsLightAuto => '자동';

  @override
  String get settingsLightDawn => '새벽';

  @override
  String get settingsLightDay => '낮';

  @override
  String get settingsLightDusk => '저녁';

  @override
  String get settingsLightNight => '밤';

  @override
  String settingsCountValue(int count) {
    return '$count개';
  }

  @override
  String get settingsLabelFavorites => '즐겨찾기';

  @override
  String get settingsLabelVisits => '방문 기록';

  @override
  String get settingsLabelRecentSearches => '최근 검색';

  @override
  String get settingsAiAssistantLanguage => 'AI 비서 언어';

  @override
  String get settingsThemeMode => '화면 테마';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsThemeChangedTitle => '테마 저장됨';

  @override
  String settingsThemeChangedBody(String theme) {
    return '$theme 모드를 완전히 적용하려면 앱 전환기에서 앱을 위로 밀어 종료한 뒤 다시 열어주세요.';
  }

  @override
  String get settingsRestartConfirm => '확인';

  @override
  String get settingsMapHome => '지도 홈 시작';

  @override
  String get settingsMapHomeDefault => '기본';

  @override
  String get settingsMapHomeMyLocation => '내 위치';

  @override
  String get settingsMapHomeRecent => '최근 검색';

  @override
  String get settingsKeepScreenOn => '화면 자동 잠금 안 함';

  @override
  String get settingsAutoRotate => '화면 방향 자동 회전';

  @override
  String get settingsAlwaysMyLocation => '길찾기 출발지를 항상 내위치로';

  @override
  String get settingsClearHistory => '사용 기록 전체 삭제';

  @override
  String get settingsClearSearchHistory => '최근 검색 기록 삭제';

  @override
  String get settingsConvertAccount => '정식 계정으로 전환';

  @override
  String get settingsEditNameItem => '이름 변경';

  @override
  String get settingsChangePassword => '비밀번호 변경';

  @override
  String get settingsLogout => '로그아웃';

  @override
  String get settingsDeleteAccount => '회원 탈퇴';

  @override
  String get settingsMapDataLabel => '지도 표시 및 데이터';

  @override
  String get settingsSectionDeveloper => '개발자';

  @override
  String get settingsDebugLogs => '디버그 로그 출력';

  @override
  String get settingsResetTutorial => '튜토리얼 다시 보기';

  @override
  String get settingsReplayWhatsNew => '새 기능 다시 보기';

  @override
  String get settingsWhatsNewToast => '다음 앱 실행 시 새 기능 안내가 다시 나와요';

  @override
  String get settingsAppVersion => '앱 버전';

  @override
  String get settingsPrivacy => '개인정보처리방침';

  @override
  String get settingsCommunityGuidelines => '커뮤니티 가이드라인';

  @override
  String get settingsLicenses => '오픈소스 라이선스';

  @override
  String get settingsClearHistoryTitle => '사용 기록 삭제';

  @override
  String get settingsClearHistoryBody => '모든 사용 기록이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.';

  @override
  String get commonDelete => '삭제';

  @override
  String get settingsClearedHistoryToast => '모든 사용 기록이 삭제되었습니다';

  @override
  String get settingsClearSearchTitle => '검색 기록 삭제';

  @override
  String get settingsClearSearchBody => '최근 검색 기록이 모두 삭제됩니다.';

  @override
  String get settingsClearedSearchToast => '검색 기록이 삭제되었습니다';

  @override
  String get settingsEditNameDialogTitle => '이름 변경';

  @override
  String get settingsEditNameDialogBody => '변경할 이름을 입력해주세요.';

  @override
  String get settingsEditNameConfirm => '변경';

  @override
  String get settingsNewNameDialogTitle => '새 이름';

  @override
  String get settingsChangePasswordTitle => '비밀번호 변경';

  @override
  String settingsChangePasswordBody(String email) {
    return '$email 으로 비밀번호 재설정 링크를 보냅니다.';
  }

  @override
  String get settingsSendButton => '발송';

  @override
  String get settingsPasswordResetSent => '재설정 이메일이 발송되었습니다';

  @override
  String get settingsLogoutTitle => '로그아웃';

  @override
  String get settingsLogoutBody => '로그아웃 하시겠습니까?';

  @override
  String get settingsLogoutConfirm => '로그아웃';

  @override
  String get settingsDeleteAccountTitle => '회원 탈퇴';

  @override
  String get settingsDeleteAccountBody =>
      '계정과 모든 데이터가 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.';

  @override
  String get settingsDeleteAccountConfirm => '탈퇴';

  @override
  String get settingsDeleteError => '탈퇴 처리 중 오류가 발생했습니다';

  @override
  String get settingsResetTutorialTitle => '튜토리얼 다시 보기';

  @override
  String get settingsResetTutorialBody =>
      '저장된 진행 상태를 지우고 다음 앱 실행 시 튜토리얼을 처음부터 보여드려요.';

  @override
  String get settingsResetTutorialConfirm => '다시 보기';

  @override
  String get settingsMapDisplayTitle => '지도 표시 및 데이터';

  @override
  String get settingsSectionMapDisplay => '지도 표시';

  @override
  String get aiStatusSearchingCourse => '코스 검색 중...';

  @override
  String aiPlacesFound(int count) {
    return '$count개 장소를 찾았어요! 아래에서 확인하세요.';
  }

  @override
  String get aiStatusFindingInfo => '정보 찾는 중...';

  @override
  String get aiStatusAnalyzingImage => '이미지 분석 중...';

  @override
  String get aiNoPlacesFound => '장소를 찾지 못했어요.';

  @override
  String aiAnalysisError(String error) {
    return '분석 오류: $error';
  }

  @override
  String get aiSelectPhotoHint => '사진을 선택해주세요';

  @override
  String get aiPhotoShoot => '촬영';

  @override
  String get aiStatusConnecting => '연결 중...';

  @override
  String get aiStatusListening => '듣고 있어요';

  @override
  String get aiStatusThinking => '생각 중...';

  @override
  String get aiStatusSpeaking => '말하는 중';

  @override
  String get aiStatusIdle => '대기 중';

  @override
  String get aiStatusReady => '준비 중';

  @override
  String aiFoundPlacesHeader(int count) {
    return '발견된 장소 ($count)';
  }

  @override
  String get aiVoiceCommandHint =>
      '\"카페 추가해줘\", \"경복궁 빼줘\", \"이걸로 확정해\" 등 말해보세요';

  @override
  String aiPlaceStationDistance(String station, int minutes) {
    return '$station역 · $minutes분';
  }

  @override
  String get aiDefaultSearch => '서울 여행 추천 코스';

  @override
  String get recommendTitle => '추천';

  @override
  String recommendSubtitleNearbyArea(String area) {
    return '$area 근처에서 지금 인기있는 곳';
  }

  @override
  String get recommendSubtitleNearbyDefault => '지금 가까이서 인기있는 곳';

  @override
  String get recommendRefresh => '새로고침';

  @override
  String get recommendNoResults => '주변에 결과가 없어요.\n잠시 후 다시 시도해 주세요.';

  @override
  String recommendRank(int rank) {
    return '$rank위';
  }

  @override
  String get recommendEventsLoadError =>
      '문화행사 정보를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.';

  @override
  String get recommendStatusUpcoming => '예정';

  @override
  String get recommendBadgePaid => '유료';

  @override
  String get recommendUniqueMood => '✨ 너만의';

  @override
  String get recommendTabFood => '🍜 맛집';

  @override
  String get recommendTabCafe => '☕️ 카페';

  @override
  String get recommendTabShopping => '🛍 쇼핑';

  @override
  String get recommendTabOutdoor => '🌳 공원·야경';

  @override
  String get recommendTabEvents => '🎭 문화';

  @override
  String get authTabSignUp => '회원가입';

  @override
  String get authTabSignIn => '로그인';

  @override
  String get authProcessing => '처리 중...';

  @override
  String get authSignIn => '로그인';

  @override
  String get authSignUp => '회원가입';

  @override
  String get authLabelEmail => '이메일';

  @override
  String get authHintEmail => '이메일을 입력해주세요';

  @override
  String get authLabelPassword => '비밀번호';

  @override
  String get authHintPassword => '비밀번호를 입력해주세요';

  @override
  String get authFindId => '아이디 찾기';

  @override
  String get authFindPassword => '비밀번호 찾기';

  @override
  String get authLabelUsername => '아이디';

  @override
  String get authHintUsername => '아이디를 입력해주세요';

  @override
  String get authLabelConfirmPassword => '비밀번호 확인';

  @override
  String get authHintConfirmPassword => '비밀번호를 다시 입력해주세요';

  @override
  String get authSnsLogin => 'SNS 계정으로 로그인';

  @override
  String get authGoogleAuthFailed => 'Google 인증에 실패했습니다';

  @override
  String get authGoogleSignInFailed => 'Google 로그인에 실패했습니다';

  @override
  String get authGuestSignInFailed => '게스트 로그인에 실패했습니다';

  @override
  String get authAppleAuthFailed => 'Apple 인증에 실패했습니다';

  @override
  String get authAppleSignInCanceled => 'Apple 로그인이 취소되었습니다';

  @override
  String get authAppleSignInFailed => 'Apple 로그인에 실패했습니다';

  @override
  String get authEmailAndPasswordRequired => '이메일과 비밀번호를 입력해주세요';

  @override
  String get authUsernameRequired => '아이디를 입력해주세요';

  @override
  String get authPasswordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get authPasswordTooShort => '비밀번호는 6자 이상이어야 합니다';

  @override
  String get authGenericError => '오류가 발생했습니다';

  @override
  String get authErrorInvalidCredentials => '이메일 또는 비밀번호가 올바르지 않습니다';

  @override
  String get authErrorEmailExists => '이미 가입된 이메일입니다';

  @override
  String get authErrorInvalidEmail => '올바른 이메일 형식을 입력해주세요';

  @override
  String get authErrorEmailNotConfirmed => '이메일 인증이 완료되지 않았습니다. 메일함을 확인해주세요.';

  @override
  String get authEmailConfirmRequiredTitle => '이메일 인증 필요';

  @override
  String authEmailConfirmRequiredBody(String email) {
    return '$email로 인증 메일을 보냈습니다.\n메일함을 확인하고 인증을 완료한 후 로그인해주세요.';
  }

  @override
  String get authFindIdResultTitle => '아이디 찾기 결과';

  @override
  String get authFindIdResultBefore => '회원님의 아이디는 ';

  @override
  String get authFindIdResultAfter => ' 입니다.';

  @override
  String get authFindIdEmailRequired => '이메일을 입력해주세요';

  @override
  String get authFindIdNotFound => '해당 이메일로 가입된 계정을 찾을 수 없습니다';

  @override
  String get authPasswordResetSent => '비밀번호 재설정 링크를 이메일로 보냈습니다';

  @override
  String get authFindIdFailed => '아이디 찾기에 실패했습니다';

  @override
  String get authEmailSendFailed => '이메일 전송에 실패했습니다';

  @override
  String get authFindIdTitle => '아이디 찾기';

  @override
  String get authFindPasswordTitle => '비밀번호 찾기';

  @override
  String get authFindIdBody => '가입 시 사용한 이메일을 입력하면\n아이디를 알려드립니다.';

  @override
  String get authFindPasswordBody => '이메일을 입력하면\n비밀번호 재설정 링크를 보내드립니다.';

  @override
  String get authFindIdEmailHint => '가입한 이메일을 입력해주세요';

  @override
  String get authFindIdSubmit => '아이디 찾기';

  @override
  String get authFindPasswordSubmit => '재설정 링크 받기';

  @override
  String get hubSettingsTooltip => '설정';

  @override
  String get hubAuthExploreSeoulTitle => '친구와 함께 서울을 탐험하기';

  @override
  String get hubAuthCreateProfileSubtitle => '닉네임과 핀을 만들어 시작하세요.';

  @override
  String get hubAuthCreateProfileButton => '프로필 만들기';

  @override
  String get hubPausedNotice => 'Seoul Live 일시정지 중 — 위치/알림 차단, 채팅은 가능';

  @override
  String get hubResumeButton => '재개';

  @override
  String get hubRoomTitle => '친구방';

  @override
  String get hubRoomEmpty => '새 방을 만들거나 코드로 입장';

  @override
  String hubRoomCurrent(String code) {
    return '입장 중 · 코드 $code';
  }

  @override
  String get hubFriendsTitle => '친구';

  @override
  String hubFriendsSubtitle(int count, int requests) {
    return '$count명 · 신청 $requests건';
  }

  @override
  String get hubDmSubtitle => '친구와 1:1 대화';

  @override
  String get hubFriendCodeTitle => '친구 코드';

  @override
  String hubFriendCodeSubtitle(String code) {
    return '내 코드 $code 공유 / 입력';
  }

  @override
  String get hubFriendGroupsTitle => '친구 그룹';

  @override
  String hubFriendGroupsSubtitle(int count) {
    return '$count개 그룹';
  }

  @override
  String get hubSpotifyConnectedNoPlayback => '연결됨 — 재생 없음';

  @override
  String get hubSpotifyShareSubtitle => '듣는 곡을 친구에게 공유';

  @override
  String get hubVisibilityGhost => '비공개 — 송신/수신 모두 X';

  @override
  String get hubVisibilityFriends => '친구방 — 같은 방 멤버에게만';

  @override
  String get hubVisibilityPublic => '전체 공개 — 모든 Seoul Live 사용자';

  @override
  String get hubActivityTitle => '내 활동';

  @override
  String get hubStatMeetups => '만남';

  @override
  String get hubStatFriends => '친구';

  @override
  String get hubStatStreak => '연속';

  @override
  String hubStatStreakValue(int days) {
    return '$days일';
  }

  @override
  String hubStatStreakBest(int days) {
    return '최고 $days';
  }

  @override
  String get hubBadgesEmptyHint => '첫 친구나 첫 만남으로 뱃지를 모아보세요';

  @override
  String get hubAgoJust => '방금';

  @override
  String hubAgoMin(int min) {
    return '$min분 전';
  }

  @override
  String hubAgoHour(int hour) {
    return '$hour시간 전';
  }

  @override
  String hubAgoDay(int day) {
    return '$day일 전';
  }

  @override
  String get hubRecentMeetupsTitle => '🎉 최근 만남';

  @override
  String hubRecentMeetupsCount(int count) {
    return '$count회';
  }

  @override
  String get roomCodeRequired => '6자리 코드를 입력해주세요.';

  @override
  String get roomLeaveTitle => '방 나가기';

  @override
  String get roomLeaveBody => '나가면 위치 공유와 채팅이 종료됩니다.';

  @override
  String get roomLeaveConfirm => '나가기';

  @override
  String get roomTitle => '친구방';

  @override
  String get roomDescription => '실시간으로 친구와 위치/채팅을 공유합니다.';

  @override
  String get roomCapacityNote => '방은 24시간 후 자동 만료, 정원 8명입니다.';

  @override
  String get roomCreateButton => '새 방 만들기';

  @override
  String get roomCodeEntryTitle => '초대 코드로 입장 (6자리)';

  @override
  String get roomJoinButton => '입장';

  @override
  String roomExpiresInMin(int min) {
    return '$min분 후 방이 만료돼요';
  }

  @override
  String get roomDefaultName => '이름 없는 친구방';

  @override
  String get roomInviteCode => '초대 코드';

  @override
  String get roomCodeCopied => '코드 복사됨';

  @override
  String roomExpiresInHours(int hour) {
    return '$hour시간 후 만료';
  }

  @override
  String roomMembers(int current, int max) {
    return '멤버 ($current/$max)';
  }

  @override
  String roomChatOpenWithUnread(int count) {
    return '채팅 열기 ($count)';
  }

  @override
  String get roomChatOpen => '채팅 열기';

  @override
  String get roomLeaveButton => '방 나가기';

  @override
  String get roomEditNameTitle => '방 이름 변경';

  @override
  String get roomEditNameBody => '친구방 멤버에게 표시되는 이름이에요';

  @override
  String get roomEditNamePlaceholder => '예: 광화문 모임';

  @override
  String roomGenericError(String error) {
    return '실패: $error';
  }

  @override
  String get roomShareSubject => 'Seoul Live 친구방 초대';

  @override
  String roomShareBody(String nickname, String code) {
    return '$nickname 님이 Seoul Live 친구방에 초대했어요!\n\n코드: $code\n바로 입장: com.seoul.prism://room/$code';
  }

  @override
  String get roomInviteTextCopied => '초대 텍스트 복사됨';

  @override
  String get roomRefreshCodeTitle => '초대 코드 갱신';

  @override
  String get roomRefreshCodeBody => '기존 코드는 즉시 무효화됩니다. 계속할까요?';

  @override
  String get roomRefreshCodeConfirm => '갱신';

  @override
  String get roomCodeRefreshed => '새 코드로 갱신됐어요';

  @override
  String roomKickTitle(String nickname) {
    return '$nickname 강퇴';
  }

  @override
  String get roomKickBody => '강퇴하면 즉시 방에서 내보내져요.';

  @override
  String get roomKickConfirm => '강퇴';

  @override
  String get roomKickFallbackName => '멤버';

  @override
  String roomNameMe(String name) {
    return '$name (나)';
  }

  @override
  String get roomMeetupBadge => '만남';

  @override
  String get roomKickTooltip => '강퇴';

  @override
  String get roomUnknownUser => '누군가';

  @override
  String roomDestTitle(String name) {
    return '🎯 같이 가기 — $name';
  }

  @override
  String roomDestSetBy(String name) {
    return '$name 님이 설정';
  }

  @override
  String get roomDestDefault => '목적지';

  @override
  String get roomDestViewMap => '지도에서 보기';

  @override
  String get roomDestClear => '목적지 해제';

  @override
  String get mpSettingsTitle => 'Seoul Live 설정';

  @override
  String get mpSectionMyStatus => '내 상태';

  @override
  String get mpPause => 'Seoul Live 일시정지';

  @override
  String get mpPauseHint =>
      '✓ 채팅 / 친구방 입장 / 친구 신청 — 가능\n✗ 위치 송신 / 만남 알림 / 핀 표시 — 차단\n데이터는 그대로 유지';

  @override
  String get mpSectionBattery => '배터리 모드';

  @override
  String get mpBatteryHint => '위치 송신 주기 — 정확할수록 배터리 소모';

  @override
  String get mpSectionNotifications => '알림';

  @override
  String mpNotificationsFail(String error) {
    return '실패: $error';
  }

  @override
  String get mpNotificationsHint => '시스템 알림 권한과 별개 — 여기서 끄면 푸시는 보내지지만 무음 처리.';

  @override
  String get mpSectionTutorial => '튜토리얼';

  @override
  String get mpReplayTutorial => 'Seoul Live 튜토리얼 다시 보기';

  @override
  String get mpTutorialToast => '다음 진입 시 튜토리얼이 다시 나와요';

  @override
  String get mpReplayWhatsNew => '새 기능 다시 보기';

  @override
  String mpReplayWhatsNewHint(String version) {
    return 'v$version 업데이트 내역';
  }

  @override
  String get mpSectionSafety => '안전';

  @override
  String get mpBlockList => '차단 목록';

  @override
  String get mpBlockListHint => '차단한 사용자 보기 / 해제';

  @override
  String get mpSectionConsent => '동의 및 데이터';

  @override
  String get mpRevokeConsent => '위치정보 동의 철회';

  @override
  String get mpRevokeConsentHint => '동의를 철회하면 멀티플레이가 비활성화되고 모든 데이터가 삭제돼요';

  @override
  String get mpDownloadMyData => '내 데이터 다운로드';

  @override
  String get mpDownloadMyDataHint => 'PIPA 데이터 이동권 — 이메일로 요청';

  @override
  String get mpDownloadMyDataToast =>
      'rush94434@gmail.com 으로 요청해주세요 (10일 이내 처리)';

  @override
  String get mpSectionOps => '운영팀';

  @override
  String get mpOpsMonitor => '운영 모니터';

  @override
  String get mpOpsMonitorHint => '일일 지표 · 어뷰즈 신호 · 신고 처리';

  @override
  String get mpSectionDanger => '위험 영역';

  @override
  String get mpLeaveSeoulLive => 'Seoul Live 탈퇴';

  @override
  String get mpLeaveSeoulLiveHint => '프로필·친구·방·채팅 등 멀티플레이 데이터 일괄 삭제';

  @override
  String get mpFootnote => '※ Seoul Vista 본 계정은 유지돼요. 멀티플레이 관련 데이터만 삭제됩니다.';

  @override
  String get mpRevokeDialogTitle => '동의 철회';

  @override
  String get mpRevokeDialogBody =>
      '위치정보 처리 동의를 철회하면 멀티플레이가 비활성화되고\n프로필·친구·방·채팅 데이터가 모두 삭제됩니다.\n계속할까요?';

  @override
  String get mpRevokeDialogConfirm => '철회';

  @override
  String get mpRevokedToast => '동의를 철회하고 데이터를 삭제했어요';

  @override
  String get mpLeaveDialogTitle => 'Seoul Live 탈퇴';

  @override
  String get mpLeaveDialogBody =>
      '모든 멀티플레이 데이터가 영구 삭제됩니다.\n다시 가입할 수 있지만 친구·방·채팅 기록은 복구되지 않아요.';

  @override
  String get mpLeaveConfirm => '탈퇴';

  @override
  String get mpLeftToast => 'Seoul Live 에서 탈퇴했어요';

  @override
  String get mpNotifCatFriendRequest => '친구 신청';

  @override
  String get mpNotifCatFriendAccept => '친구 수락';

  @override
  String get mpNotifCatRoomMessage => '채팅 메시지';

  @override
  String get mpNotifCatMeetup => '만남 감지';

  @override
  String get mpNotifCatDestination => '목적지 변경';

  @override
  String get mpNotifCatWelcome => '환영';

  @override
  String get panelSubway => '지하철';

  @override
  String get panelBus => '버스';

  @override
  String get panelFlights => '항공기';

  @override
  String get panelDisplay => '표시';

  @override
  String get panelLineFilter => '노선 필터';

  @override
  String get panelPerformance => '성능';

  @override
  String get panelLighting => '라이팅';

  @override
  String get panelInfo => '정보';

  @override
  String get panelDeveloper => '개발자';

  @override
  String get panelDemoRunning => 'DEMO 실행 중';

  @override
  String get panelLiveRunning => 'LIVE 실행 중';

  @override
  String get panelOff => '꺼짐';

  @override
  String get panelSwitchToLive => 'LIVE 모드로 전환';

  @override
  String get panelSwitchToDemo => 'DEMO 모드로 전환';

  @override
  String get panelSubwayOn => '지하철 켜기';

  @override
  String get panelSubwayOff => '지하철 끄기';

  @override
  String panelTrainCount(int count) {
    return '열차 $count대';
  }

  @override
  String panelLastUpdate(String time) {
    return '갱신 $time';
  }

  @override
  String panelBusActive(int count) {
    return '버스 $count대 표시 중';
  }

  @override
  String get panelSelectRoutes => '노선을 선택하세요';

  @override
  String get panelTurnAllOff => '전체 끄기';

  @override
  String get panelBusPosition => '버스 위치';

  @override
  String get panelHanRiverBus => '🚢 한강 한강버스';

  @override
  String get panelAddRoute => '노선 추가';

  @override
  String panelFlightCount(String mode, int count) {
    return '$mode $count대';
  }

  @override
  String get panelFlightFallback => '항공기';

  @override
  String get panelFlightLegendClimb => '상승';

  @override
  String get panelFlightLegendCruise => '순항';

  @override
  String get panelFlightLegendDescend => '하강';

  @override
  String get panelFlightLegendTakeoffLanding => '이착륙';

  @override
  String get panelRouteLines => '노선 경로';

  @override
  String get panelTrainPosition => '열차 위치';

  @override
  String get panelStationDisplay => '역 표시';

  @override
  String get panelSelectRoutesToShow => '표시할 노선 선택';

  @override
  String get panelAll => '전체';

  @override
  String get panelPresetHigh => '높음';

  @override
  String get panelPresetMedium => '보통';

  @override
  String get panelPresetLow => '낮음';

  @override
  String get panelFps => '프레임';

  @override
  String get panelNaverPolling => '네이버 폴링';

  @override
  String panelRenderInfo(String engine) {
    return '렌더링: $engine · GeoJSON 캐싱';
  }

  @override
  String get panelLightAuto => '자동';

  @override
  String get panelLightDay => '주간';

  @override
  String get panelLightNight => '야간';

  @override
  String get panelLightDawn => '새벽';

  @override
  String get panelLightDusk => '석양';

  @override
  String get panelTierFlagship => '플래그십';

  @override
  String get panelTierHigh => '상위';

  @override
  String get panelTierMid => '중급';

  @override
  String get panelTierLow => '저사양';

  @override
  String get panelMapEngine => '맵 엔진';

  @override
  String get panelDevice => '기기';

  @override
  String get panelPerfTier => '성능 등급';

  @override
  String get mapDisplay3D => '3D 건물 표시';

  @override
  String get mapDisplayPois => 'POI 아이콘 표시';

  @override
  String get mapDisplayWeather => '날씨 효과 (안개/비)';

  @override
  String get mapDisplayLiveSubway => '실시간 지하철';

  @override
  String get friendsGroupTooltip => '친구 그룹';

  @override
  String get friendsCodeTooltip => '친구 코드';

  @override
  String get friendsAddByNickname => '닉네임으로 친구 추가';

  @override
  String get friendsSearchPlaceholder => '닉네임 입력 후 검색';

  @override
  String get friendsSearching => '검색 중...';

  @override
  String get friendsSearch => '검색';

  @override
  String friendsNotFound(String query) {
    return '\"$query\" 와(과) 일치하는 사용자가 없어요';
  }

  @override
  String get friendsSearchHint => '닉네임은 정확히 일치해야 해요. 친구코드(8자리)도 시도해보세요.';

  @override
  String friendsReceivedRequests(int count) {
    return '받은 친구 신청 ($count)';
  }

  @override
  String get friendsAccept => '수락';

  @override
  String get friendsReject => '거절';

  @override
  String friendsMyFriends(int count) {
    return '내 친구 ($count)';
  }

  @override
  String get friendsEmpty => '아직 친구가 없어요. 닉네임으로 추가해보세요.';

  @override
  String get friendsCooldownTooltip => '거절당한 신청은 7일 후 다시 보낼 수 있어요';

  @override
  String friendsCooldownDays(int days) {
    return '$days일 후 재신청';
  }

  @override
  String friendsCooldownHours(int hours) {
    return '$hours시간 후';
  }

  @override
  String get friendsBadgeFriend => '친구';

  @override
  String get friendsBadgeRequested => '신청됨';

  @override
  String get friendsApply => '신청';

  @override
  String friendsSendingRequestHint(String nickname) {
    return '$nickname 님에게 친구 신청 — 수락하면 푸시 알림이 와요';
  }

  @override
  String friendsDmStartFailed(String error) {
    return 'DM 시작 실패: $error';
  }

  @override
  String get friendsUnfriend => '친구 해제';

  @override
  String get friendsReport => '신고';

  @override
  String get friendsBlock => '차단';

  @override
  String get friendsBlockDialogTitleFallback => '이 사용자 차단';

  @override
  String friendsBlockDialogTitle(String nickname) {
    return '$nickname 차단';
  }

  @override
  String get friendsBlockDialogBody => '차단하면 같은 방 입장이 불가능하고 메시지도 보이지 않습니다.';

  @override
  String get friendsBlockConfirm => '차단';

  @override
  String get friendsUnknown => '알 수 없음';

  @override
  String friendsRequestSent(String nickname) {
    return '$nickname 님에게 친구 신청 보냈어요';
  }

  @override
  String friendsFailure(String error) {
    return '실패: $error';
  }

  @override
  String get friendsSuggestionsTitle => '추천 친구 (친구의 친구)';

  @override
  String friendsMutualCount(int count) {
    return '공통 친구 $count명';
  }

  @override
  String get friendsAddShort => '추가';

  @override
  String get searchRouteNotFound => '경로를 찾지 못했어요. 출발지/도착지를 확인해 주세요.';

  @override
  String get searchLocationUnavailable =>
      '현재 위치를 가져올 수 없어요. 위치 권한과 GPS 를 확인해 주세요.';

  @override
  String get searchTabRoute => '길찾기';

  @override
  String get searchTabProfile => '프로필';

  @override
  String get searchPathTypeOptimal => '최적';

  @override
  String get searchPathTypeShortest => '최단';

  @override
  String get searchPathTypeMinTransfer => '최소환승';

  @override
  String get searchOutsideServiceTitle => '서비스 지역 밖이에요';

  @override
  String get searchOutsideServiceBody =>
      '현재 길찾기는 서울·인천·경기 수도권만 지원해요. 출발 또는 도착지를 수도권 안에서 다시 선택해주세요.';

  @override
  String get searchDepartureFieldHint => '출발지';

  @override
  String get searchArrivalFieldHint => '도착지';

  @override
  String get searchSwapDepArr => '출발지·도착지 교환';

  @override
  String get searchCloseTooltip => '길찾기 닫기';

  @override
  String get searchPlaceholder => '장소, 버스, 지하철 검색';

  @override
  String get searchClearLabel => '검색어 지우기';

  @override
  String get searchRecentTitle => '최근 검색';

  @override
  String get searchRecentClearAll => '전체 삭제';

  @override
  String get searchRecentRoutesTitle => '최근 길찾기';

  @override
  String get searchBusTypeTrunk => '간선';

  @override
  String get searchBusTypeBranch => '지선';

  @override
  String get searchBusTypeCircular => '순환';

  @override
  String get searchBusTypeMetro => '광역';

  @override
  String get searchBusTypeIncheon => '인천';

  @override
  String get searchBusTypeGyeonggi => '경기';

  @override
  String get searchBusTypeDefault => '버스';

  @override
  String get searchCatFood => '음식점';

  @override
  String get searchCatCafe => '카페';

  @override
  String get searchCatPark => '공원';

  @override
  String get searchCatShopping => '쇼핑';

  @override
  String get searchCatMedical => '의료';

  @override
  String get searchCatEducation => '교육';

  @override
  String get searchCatLodging => '숙박';

  @override
  String get searchCatFinance => '금융';

  @override
  String get searchCatTransit => '교통';

  @override
  String get searchCatAddress => '주소';

  @override
  String get searchCatCity => '도시';

  @override
  String get searchCatNeighborhood => '동네';

  @override
  String get searchCatRoad => '도로';

  @override
  String liveBadgePeerTrack(String nickname, String track) {
    return '$nickname 가 $track 듣고 있어요';
  }

  @override
  String liveBadgeSharing(int count) {
    return '$count명에게 위치 공유 중';
  }

  @override
  String get liveBadgeStopped => '위치 공유를 중지했어요';

  @override
  String get seoulLiveStartTitle => 'Seoul Live 시작';

  @override
  String get seoulLiveStartBody => '지도가 세계로 확장됐어요';

  @override
  String get seoulLiveStep2Title => '친구의 핀이 지도에 떠요';

  @override
  String get seoulLiveStep2Body =>
      '같은 친구방의 멤버가 핀(닉네임 + 이모지) 으로 실시간 표시돼요. 친구가 움직이면 핀도 같이 움직여요.';

  @override
  String get seoulLiveStep3Title => '친구방 코드로 모이기';

  @override
  String get seoulLiveStep3Body =>
      '프로필 → Seoul Live → 친구방에서 새 방을 만들거나 6자리 초대 코드로 입장하세요. 정원은 8명이에요.';

  @override
  String get seoulLiveStep4Title => '50m 이내면 만남 알림';

  @override
  String get seoulLiveStep4Body => '친구와 가까워지면 햅틱과 알림이 울려요. 채팅에도 자동으로 기록돼요.';

  @override
  String get seoulLiveStep5Title => '언제든 비공개 모드';

  @override
  String get seoulLiveStep5Body =>
      '상단의 \"위치 공유 중\" 배지를 탭하면 즉시 ghost 모드로 전환돼요. 친구방을 나가면 자동으로 송신이 멈춰요.';

  @override
  String get seoulLivePermTitle => '알림 받기';

  @override
  String get seoulLivePermBody =>
      '친구 신청 / 새 메시지 / 만남이 발생하면 푸시 알림으로 알려드려요. 아래 \"허용\" 버튼을 눌러 알림을 받아주세요.';

  @override
  String get seoulLivePermAllowed => '✓ 알림 권한 허용됨';

  @override
  String get seoulLivePermDenied => '거부됨 — 설정에서 직접 허용할 수 있어요';

  @override
  String get seoulLivePermRequesting => '요청 중...';

  @override
  String get seoulLivePermAllow => '알림 허용';

  @override
  String get roomMembersEmpty => '같이 있는 친구가 없어요';

  @override
  String roomMembersWithCount(int count) {
    return '같이 있는 친구 $count명';
  }

  @override
  String get roomMembersGhost => '비공개';

  @override
  String roomMembersNearbyHeader(int count) {
    return '주변 ${count}명 (500m 이내)';
  }

  @override
  String get roomMembersPublicSectionHeader => '전체 공개 사용자';

  @override
  String roomMembersSeeAllPublic(int count) {
    return '전체 보기 (${count}명)';
  }

  @override
  String get roomMembersHidePublic => '전체 숨기기';

  @override
  String liveBadgeSharingPublic(int count) {
    return '${count}명에게 공개 중';
  }

  @override
  String get roomMembersDisconnected => '연결 안됨';

  @override
  String get roomMembersRealtime => '실시간';

  @override
  String get roomMembersStale => '잠시 떨어짐';

  @override
  String get dmListAgoJust => '방금';

  @override
  String dmListAgoMin(int min) {
    return '$min분';
  }

  @override
  String dmListAgoHour(int hour) {
    return '$hour시간';
  }

  @override
  String dmListAgoDay(int day) {
    return '$day일';
  }

  @override
  String get dmListKindVoice => '🎙 음성';

  @override
  String get dmListKindImage => '🖼 사진';

  @override
  String get dmListKindPlace => '📍 장소';

  @override
  String get dmListKindSpotify => '🎵 노래';

  @override
  String get dmListEmpty => '아직 DM 이 없어요';

  @override
  String get dmListEmptyHint => '친구 화면에서 메시지 버튼을 눌러 시작';

  @override
  String get friendGroupsNewTitle => '새 그룹';

  @override
  String get friendGroupsNewTooltip => '새 그룹';

  @override
  String get friendGroupsEmpty => '아직 그룹이 없어요';

  @override
  String get friendGroupsEmptyHint => '상단 + 로 친구를 묶어 보세요';

  @override
  String get friendGroupsEmptyHintAlt => '우상단 + 버튼으로 그룹을 만들어 친구를 분류하세요.';

  @override
  String get friendGroupsNamePlaceholder => '예: 가족, 회사, 동호회';

  @override
  String get friendGroupsCreate => '만들기';

  @override
  String get friendGroupsCreated => '그룹 만들어졌어요';

  @override
  String friendGroupsFailure(String error) {
    return '실패: $error';
  }

  @override
  String friendGroupsDeleteTitle(String emoji, String name) {
    return '$emoji $name 삭제';
  }

  @override
  String get friendGroupsDeleteBody => '그룹을 삭제해요. 친구는 사라지지 않아요.';

  @override
  String get friendGroupsDelete => '삭제';

  @override
  String get friendGroupsName => '이름';

  @override
  String get friendGroupsIcon => '아이콘';

  @override
  String friendGroupsMemberCount(int count) {
    return '$count명';
  }

  @override
  String get friendGroupsNoFriendsPrompt => '친구를 먼저 추가하세요.';

  @override
  String get friendGroupsVisibilityHint => '그룹별 가시성 / 채팅에 활용돼요';

  @override
  String friendGroupsMembersTitle(String emoji, String name) {
    return '$emoji $name 멤버';
  }

  @override
  String get friendGroupsEditMembers => '멤버 편집';

  @override
  String get friendGroupsEmptyFriendsBox => '아직 친구가 없어요';

  @override
  String get loginRequiredTitle => '로그인이 필요해요';

  @override
  String get loginRequiredBody =>
      '멀티플레이는 정식 로그인 사용자만 이용할 수 있어요.\n게스트(익명) 계정은 30일 미사용 시 자동 삭제되어\n친구·방 정보가 사라질 수 있기 때문이에요.';

  @override
  String get loginRequiredCta => '로그인하기';

  @override
  String get reportReasonSpam => '스팸/광고';

  @override
  String get reportReasonHate => '욕설/혐오 표현';

  @override
  String get reportReasonSexual => '성적/불쾌한 콘텐츠';

  @override
  String get reportReasonHarass => '괴롭힘/스토킹';

  @override
  String get reportReasonFakeLocation => '가짜 위치/사칭';

  @override
  String get reportReasonMinorAbuse => '미성년자 보호 위반';

  @override
  String get reportReasonOther => '기타';

  @override
  String get reportSelectReason => '사유를 선택해주세요.';

  @override
  String get reportSubmitted => '신고가 접수됐어요. 24시간 내 검토됩니다.';

  @override
  String reportTitleUser(String label) {
    return '$label 신고';
  }

  @override
  String get reportTitleMessage => '메시지 신고';

  @override
  String get reportNote => '운영팀이 검토 후 24시간 이내에 조치합니다.';

  @override
  String get reportExtraPlaceholder => '추가 설명 (선택)';

  @override
  String get reportSubmit => '신고하기';

  @override
  String get reportSubmitting => '전송 중...';

  @override
  String get reportFallbackUser => '사용자';

  @override
  String get blockedUsersTitle => '차단 목록';

  @override
  String get blockedUsersEmpty => '차단한 사용자가 없어요';

  @override
  String blockedUsersUnblockTitle(String name) {
    return '$name 차단 해제';
  }

  @override
  String get blockedUsersUnblockBody => '차단을 해제하면 다시 만날 수 있고 메시지도 보입니다.';

  @override
  String get blockedUsersUnblockConfirm => '해제';

  @override
  String get activityTitle => '활동 분석';

  @override
  String get activityCatMeetup => '🎉 만남';

  @override
  String get activityCatFriend => '🤝 친구';

  @override
  String get activityCatRoomJoined => '🚪 방 입장';

  @override
  String get activityCatPlaceShared => '📍 장소 공유';

  @override
  String get activityCatDestination => '🎯 목적지';

  @override
  String get activityAgoJust => '방금';

  @override
  String activityAgoMin(int min) {
    return '$min분 전';
  }

  @override
  String activityAgoHour(int hour) {
    return '$hour시간 전';
  }

  @override
  String activityAgoDay(int day) {
    return '$day일 전';
  }

  @override
  String get activityRanking => '친구 랭킹';

  @override
  String get activityRecent => '최근 활동';

  @override
  String get activityEmpty => '아직 기록된 활동이 없어요';

  @override
  String activityCode(String code) {
    return '코드 $code';
  }

  @override
  String get activityThisWeek => '이번 주 활동';

  @override
  String activityTotalCount(int count) {
    return '총 $count건';
  }

  @override
  String get activityWeekdayMon => '월';

  @override
  String get activityWeekdayTue => '화';

  @override
  String get activityWeekdayWed => '수';

  @override
  String get activityWeekdayThu => '목';

  @override
  String get activityWeekdayFri => '금';

  @override
  String get activityWeekdaySat => '토';

  @override
  String get activityWeekdaySun => '일';

  @override
  String get peerNowPlayingBtnFriend => '친구입니다 ✓';

  @override
  String get peerNowPlayingBtnRequested => '신청 보냄';

  @override
  String get peerNowPlayingBtnAccept => '친구 신청 수락';

  @override
  String get peerNowPlayingBtnSendRequest => '친구 신청 보내기';

  @override
  String get peerNowPlayingOpenInSpotify => 'Spotify에서 듣기';

  @override
  String get mapNoLocationPermission =>
      '위치 권한이 없어서 친구가 내 핀을 못 봐요. 설정 → 위치 에서 허용해주세요.';

  @override
  String get mapLeftRoom => '친구방에서 나가졌어요';

  @override
  String mapShowOnMap(String name) {
    return '지도에서 \"$name\" 보기';
  }

  @override
  String mapBuildingInside(String name) {
    return '🏢 $name 안에 있어요';
  }

  @override
  String get mapLocationChecking => '위치 확인 중...';

  @override
  String get mapLocationPermissionDenied =>
      '위치 권한 거부됨 → iOS 설정 → Seoul Vista → 위치';

  @override
  String get mapLocationServiceOff => 'iOS 설정 → 개인정보 → 위치 서비스 가 꺼져있어요';

  @override
  String get mapMyLocationMoved => '내 위치로 이동했어요';

  @override
  String mapLocationFetchFailed(String error) {
    return '위치 가져오기 실패: $error';
  }

  @override
  String get mapMapAppUnavailable => '지도 앱을 열 수 없어요';

  @override
  String get mapTabRecommend => '추천';

  @override
  String get mapTabSave => '저장';

  @override
  String get mapTabMap => '지도';

  @override
  String get mapTabWorld => '세계';

  @override
  String get mapTabTrip => '여행';

  @override
  String get mapDirectionsRoadFetching => '자동차 경로 불러오는 중...';

  @override
  String get mapDirectionsWalkFetching => '도보 경로 불러오는 중...';

  @override
  String get mapNoCoords => '출발/도착 좌표를 찾을 수 없어요';

  @override
  String get mapDirectionsFailed => '경로를 불러오지 못했어요';

  @override
  String mapInsufficientSavedPlaces(int min) {
    return '장소가 더 필요해요 — 즐겨찾기/방문 기록 $min곳 이상이면 자동 생성돼요';
  }

  @override
  String get subwayPanelExpand => '패널 펼치기';

  @override
  String get subwayPanelCollapse => '패널 접기';

  @override
  String subwayPanelDelayedTrains(int count) {
    return '지연 열차 $count대';
  }

  @override
  String subwayPanelMinutes(int min) {
    return '$min분';
  }

  @override
  String subwayPanelOthersCount(int count) {
    return '외 $count대...';
  }

  @override
  String get subwayPanelOffTapToStart => 'OFF - 탭하여 시작';

  @override
  String get subwayPanelMode => '모드';

  @override
  String get subwayPanelDemoLabel => '데모 (API 미사용)';

  @override
  String get subwayPanelLiveLabel => '실시간';

  @override
  String get subwayPanelTrainsLabel => '열차 수';

  @override
  String subwayPanelTrainsValue(int count) {
    return '$count대';
  }

  @override
  String get subwayPanelUpdate => '갱신';

  @override
  String get subwayPanelToggleRoutes => '노선 경로';

  @override
  String get subwayPanelToggleTrains => '열차 위치';

  @override
  String get subwayPanelToggleStations => '역 표시';

  @override
  String get subwayPanelToggleCongestion => '혼잡도';

  @override
  String get subwayPanelRouteFilter => '노선 필터';

  @override
  String get subwayPanelAll => '전체';

  @override
  String get subwayPanelToggleOn => '지하철 시각화 켜기';

  @override
  String get subwayPanelToggleOff => '지하철 시각화 끄기';

  @override
  String get subwayPanelNoArrivalInfo => '도착 정보 없음';

  @override
  String subwayPanelTrainDirection(String destination, String type) {
    return '$destination행 $type';
  }

  @override
  String get subwayPanelCloseDetail => '열차 상세 닫기';

  @override
  String subwayPanelTrainNo(String no) {
    return '열차 #$no';
  }

  @override
  String subwayPanelDelayedBadge(int min) {
    return '$min분 지연';
  }

  @override
  String get subwayPanelLastTrainBadge => '막차';

  @override
  String subwayPanelTerminalDestination(String terminal) {
    return '$terminal행';
  }

  @override
  String get subwayPanelPrevStation => '이전역';

  @override
  String get subwayPanelDepartureStation => '출발역';

  @override
  String get subwayPanelCurrentStation => '현재역';

  @override
  String get subwayPanelNextStation => '다음역';

  @override
  String get subwayPanelStateArriving => '곧 도착';

  @override
  String get subwayPanelStateStopped => '정차중';

  @override
  String get subwayPanelStateDeparted => '출발';

  @override
  String get subwayPanelStateMoving => '이동중';

  @override
  String get subwayPanelStateOperating => '운행';

  @override
  String get subwayPanelDirInnerLoop => '내선 순환';

  @override
  String get subwayPanelDirOuterLoop => '외선 순환';

  @override
  String get subwayPanelDirUp => '상행';

  @override
  String get subwayPanelDirDown => '하행';

  @override
  String get subwayPanelTrainTypeExpress => '급행';

  @override
  String get subwayPanelTrainTypeSpecial => '특급';

  @override
  String get subwayPanelTrainTypeRegular => '보통';

  @override
  String get searchTileSubway => '지하철';

  @override
  String get profileEditNicknameInvalid => '닉네임은 1~20자로 입력해주세요.';

  @override
  String get profileEditBirthInvalid => '출생연도(YYYY) 를 정확히 입력해주세요.';

  @override
  String get profileEditAgeRestriction => '14세 미만은 멀티플레이를 이용할 수 없습니다.';

  @override
  String get profileEditTitle => '프로필 설정';

  @override
  String get profileEditSubtitle => '친구방에서 다른 사람에게 보여질 모습을 정해주세요.';

  @override
  String get profileEditNicknameLabel => '닉네임 (중복 허용)';

  @override
  String get profileEditNicknamePlaceholder => '예: 서울탐험가';

  @override
  String get profileEditBirthLabel => '출생연도 (만 14세 이상만 가입)';

  @override
  String get profileEditBirthPlaceholder => '예: 2000';

  @override
  String get profileEditAvatarLabel => '프로필 사진';

  @override
  String get profileEditAvatarTapHint => '탭하여 변경';

  @override
  String get profileEditAvatarChoose => '갤러리에서 선택';

  @override
  String get profileEditAvatarCamera => '카메라로 촬영';

  @override
  String get profileEditAvatarRemove => '현재 사진 삭제';

  @override
  String get profileEditAvatarUploading => '업로드 중...';

  @override
  String get profileEditAvatarRemoveConfirmTitle => '사진을 삭제할까요?';

  @override
  String get profileEditAvatarRemoveConfirmBody =>
      '프로필 사진이 사라지고 이모지로 다시 표시됩니다.';

  @override
  String get profileEditAvatarFailed => '사진 업로드에 실패했어요. 잠시 후 다시 시도해주세요.';

  @override
  String get profileEditEmojiLabel => '핀 이모지';

  @override
  String get profileEditColorLabel => '핀 색상';

  @override
  String get profileEditVisibilityLabel => '위치 공개 범위';

  @override
  String get profileEditVisibilityGhost => '비공개';

  @override
  String get profileEditVisibilityFriends => '친구방';

  @override
  String get profileEditVisibilityGroup => '그룹만';

  @override
  String get profileEditVisibilityPublic => '전체';

  @override
  String get profileEditSaving => '저장 중...';

  @override
  String get profileEditSave => '저장';

  @override
  String get profileEditPublicDialogTitle => '전체 공개로 전환';

  @override
  String get profileEditPublicDialogBody =>
      '내 위치가 모르는 사람을 포함한 모든 Seoul Live 사용자에게 실시간으로 보여집니다.\n\n• 부적절한 만남 / 스토킹 위험에 유의하세요\n• 언제든 비공개/친구방으로 되돌릴 수 있어요\n• 차단/신고는 친구 프로필 또는 채팅 메뉴에서';

  @override
  String get profileEditPublicDialogConfirm => '계속';

  @override
  String get profileEditVisibilityGhostDesc =>
      '위치를 보내지 않습니다. 다른 사람의 위치도 볼 수 없어요.';

  @override
  String get profileEditVisibilityFriendsDesc =>
      '친구방에 입장한 동안만 같은 방 멤버에게 위치가 보여요.';

  @override
  String get profileEditVisibilityGroupDesc =>
      '아래에서 선택한 그룹의 친구만 내 위치를 볼 수 있어요.';

  @override
  String get profileEditVisibilityPublicDesc =>
      '⚠️ Seoul Live 사용자 누구나 내 위치를 볼 수 있어요. 친구방에서도 동일하게 송신돼요.';

  @override
  String get profileEditNoGroups => '그룹이 없어요. 친구 → 그룹 에서 만들어주세요.';

  @override
  String get adminMonitorTitle => '운영 모니터';

  @override
  String get adminRefresh => '새로고침';

  @override
  String get adminTabMetrics => '지표';

  @override
  String get adminTabAbuse => '어뷰즈';

  @override
  String get adminTabReports => '신고';

  @override
  String get adminMetricAllProfiles => '전체 프로필';

  @override
  String get adminMetricActiveRooms => '활성 친구방';

  @override
  String get adminMetricTodayMeetups => '오늘 만남';

  @override
  String get adminMetricTodayBlocks => '오늘 차단';

  @override
  String get adminMetricTodayReports => '오늘 신고';

  @override
  String get adminNoSuspiciousSignals => '의심 신호 없음 (24시간 내 3건 이상 차단당한 사용자 X)';

  @override
  String adminRecentBlockCount(int count) {
    return '24h 내 $count명에게 차단됨';
  }

  @override
  String get adminReportStatusPending => '대기';

  @override
  String get adminReportStatusReviewed => '검토됨';

  @override
  String get adminReportStatusActioned => '조치됨';

  @override
  String get adminReportStatusDismissed => '기각';

  @override
  String get adminNoReports => '표시할 신고가 없어요';

  @override
  String get adminReportTypeMessage => '메시지 신고';

  @override
  String get adminReportTypeUser => '사용자 신고';

  @override
  String get adminReportActionReview => '검토';

  @override
  String get adminReportActionAction => '조치';

  @override
  String get adminReportActionDismiss => '기각';

  @override
  String adminAgoMin(int min) {
    return '$min분 전';
  }

  @override
  String adminAgoHour(int hour) {
    return '$hour시간 전';
  }

  @override
  String adminAgoDay(int day) {
    return '$day일 전';
  }

  @override
  String get liveDiagTitle => '실시간 진단';

  @override
  String get liveDiagMyId => '내 ID';

  @override
  String get liveDiagVisibility => '공개 범위';

  @override
  String get liveDiagRoom => '방';

  @override
  String get liveDiagPeers => '받는 peer';

  @override
  String liveDiagPeersValue(int count) {
    return '$count명';
  }

  @override
  String get liveDiagPresenceStatus => 'Presence 상태';

  @override
  String get liveDiagWorldStatus => 'World 상태';

  @override
  String get liveDiagLastSent => '마지막 송신';

  @override
  String get liveDiagSendError => '송신 오류';

  @override
  String get liveDiagGps => 'GPS';

  @override
  String get liveDiagPaused => '일시정지';

  @override
  String get liveDiagActivityFailCount => '활동기록 실패';

  @override
  String liveDiagActivityFailValue(int count) {
    return '$count회';
  }

  @override
  String get liveDiagLastActivityError => '최근 활동 오류';

  @override
  String get liveDiagFooter => '문제 있으면 이 화면 캡처해서 공유';

  @override
  String get liveDiagClose => '닫기';

  @override
  String get liveDiagNoProfile => '(프로필 없음)';

  @override
  String get liveDiagNone => '(없음)';

  @override
  String get liveDiagNotConnected => '(미연결)';

  @override
  String get liveDiagNotUsed => '(미사용)';

  @override
  String get liveDiagNotSent => '아직 송신 안함';

  @override
  String liveDiagSecondsAgo(int sec) {
    return '$sec초 전';
  }

  @override
  String liveDiagRoomLabel(String code, int count) {
    return '$code ($count명)';
  }

  @override
  String get liveDiagGpsHas => '있음';

  @override
  String get liveDiagGpsNo => '없음';

  @override
  String get mpConsentLocationDenied => '설정 > 위치 에서 위치 권한을 허용해주세요.';

  @override
  String get mpConsentTitle => '멀티플레이 시작 전 안내';

  @override
  String get mpConsentHeading => 'Seoul Live 동의';

  @override
  String get mpConsentBody =>
      '친구와 위치를 공유하기 위해 아래 항목에 동의가 필요해요. 각 항목은 별도로 동의/거부할 수 있고, 언제든 설정에서 철회할 수 있어요.';

  @override
  String get mpConsentItem1Title => '[필수] 프로필 정보 처리';

  @override
  String get mpConsentItem1Detail =>
      '닉네임, 핀 색상/이모지, 출생연도. 서비스 식별 및 14세 미만 가입 차단 목적. 계정 삭제 시까지 보유, 탈퇴 시 즉시 파기.';

  @override
  String get mpConsentItem2Title => '[필수] 위치정보 처리 (LBS법 §18)';

  @override
  String get mpConsentItem2Detail =>
      'GPS 좌표·이동 방향. 친구방 멤버 또는 (전체 공개 선택 시) 모든 Seoul Live 사용자에게 실시간 공유. 영구 저장 X — Realtime 채널 휘발 전송. 공개 범위는 프로필에서 비공개/친구방/전체 공개 중 언제든 변경 가능.';

  @override
  String get mpConsentItem3Title => '[필수] 위치기반서비스 이용약관';

  @override
  String get mpConsentItem3Detail => '방통위 신고 사업자가 제공. 14세 미만 이용 불가.';

  @override
  String get mpConsentItem3Link => '약관 전문 보기';

  @override
  String get mpConsentItem4Title => '[필수] 커뮤니티 가이드라인';

  @override
  String get mpConsentItem4Detail =>
      '혐오·괴롭힘·성적 콘텐츠·미성년자 학대 무관용. 신고된 콘텐츠는 24시간 이내에 검토되며, 위반자는 콘텐츠 삭제·정지·영구 차단될 수 있어요.';

  @override
  String get mpConsentItem4Link => '가이드라인 전문 보기';

  @override
  String get mpConsentDeclineNote => '거부해도 멀티플레이만 비활성화되고 나머지 기능은 정상 사용 가능해요.';

  @override
  String get mpConsentBackgroundNote =>
      '앱이 백그라운드로 가면 위치 공유는 자동 일시정지돼요 (배터리 보호).';

  @override
  String get mpConsentSubmit => '동의하고 시작';

  @override
  String get mpConsentLaterButton => '나중에';

  @override
  String get mpConsentSubmitBusy => '처리 중...';

  @override
  String get mpConsentLbsTermsBody =>
      '이 약관은 Seoul Vista 가 제공하는 Seoul Live(이하 \"서비스\")의 위치기반서비스 이용에 관한 사항을 정합니다.';

  @override
  String get optTitle => '내 기기에 맞춰';

  @override
  String get optSubtitle => '실시간 시각화는 GPU 부담이 커요.\n기기에 맞게 골라주세요.';

  @override
  String get optPresetHighTitle => '고품질';

  @override
  String get optPresetHighDetail => '60fps · 5초 갱신 · 안티얼라이어싱 ON';

  @override
  String get optPresetSmoothTitle => '부드러움';

  @override
  String get optPresetSmoothDetail => '30fps · 10초 갱신';

  @override
  String get optPresetBatteryTitle => '배터리 절약';

  @override
  String get optPresetBatteryDetail => '20fps · 30초 갱신 · 효과 OFF';

  @override
  String get optAdvancedTitle => '고급 — 표시할 레이어 선택';

  @override
  String get optLayerSubway => '지하철 (실시간 열차 위치)';

  @override
  String get optLayerSubwaySub => '서울 지하철 + 광역철도. GPU 부담이 가장 큼';

  @override
  String get optLayerBus => '시내버스';

  @override
  String get optLayerBusSub => '서울 + 경기 시내버스 실시간 위치';

  @override
  String get optLayerRiverBus => '한강버스';

  @override
  String get optLayerRiverBusSub => '한강 운항 선박';

  @override
  String get optLayerFlights => '항공기';

  @override
  String get optLayerFlightsSub => '인천공항 주변 실시간 항공기';

  @override
  String optDetectedTier(String tier) {
    return '$tier 등급으로 감지됨';
  }

  @override
  String get optRecommended => '권장';

  @override
  String get vehicleCongestion => '혼잡도';

  @override
  String get vehicleCongestionNone => '정보없음';

  @override
  String get vehicleCongestionFree => '여유';

  @override
  String get vehicleCongestionNormal => '보통';

  @override
  String get vehicleCongestionBusy => '혼잡';

  @override
  String get vehicleCongestionPacked => '매우혼잡';

  @override
  String get vehicleCongestionFull => '만차';

  @override
  String get vehicleStatus => '상태';

  @override
  String get vehicleStopped => '정차 중';

  @override
  String get vehicleRunning => '운행 중';

  @override
  String get vehicleSection => '구간';

  @override
  String vehicleSectionOrd(int ord) {
    return '$ord번째';
  }

  @override
  String get vehicleBusLowFloor => '저상버스';

  @override
  String get vehicleBusRegular => '일반버스';

  @override
  String get vehiclePhaseAscent => '상승';

  @override
  String get vehiclePhaseCruise => '순항';

  @override
  String get vehiclePhaseDescent => '하강';

  @override
  String get vehiclePhaseTakeoff => '이착륙';

  @override
  String get vehiclePhaseGround => '지상';

  @override
  String get vehicleAltitude => '고도';

  @override
  String get vehicleAltitudeOnGround => '지상';

  @override
  String get vehicleSpeed => '속도';

  @override
  String get vehicleHeading => '방향';

  @override
  String vehicleRiverBusRoute(String name) {
    return '한강버스 $name';
  }

  @override
  String get vehicleRiverDirNormal => '정방향';

  @override
  String get vehicleRiverDirReverse => '역방향';

  @override
  String get vehicleRiverPhaseStop => '정차';

  @override
  String get vehicleNext => '다음';

  @override
  String get vehicleProgress => '진행';

  @override
  String get deepLinkRoomLoginRequired => '정식 로그인 후 방에 입장할 수 있어요';

  @override
  String deepLinkRoomEntered(String code) {
    return '방 입장 — 코드 $code';
  }

  @override
  String deepLinkRoomFailure(String error) {
    return '방 입장 실패: $error';
  }

  @override
  String get snsAnalysisTitle => '분석 결과';

  @override
  String get snsAnalysisEmpty => '추출된 장소가 없습니다';

  @override
  String snsAnalysisCreatePlans(int count) {
    return '일정 만들기 ($count곳)';
  }

  @override
  String snsAnalysisPlanFailure(String error) {
    return '플랜 생성 실패: $error';
  }

  @override
  String snsAnalysisNearestStation(String station, int minutes) {
    return '📍 $station역 · $minutes분';
  }

  @override
  String get avatarMyPin => '나의 핀';

  @override
  String get avatarNoRoomHint => '친구방에 들어가면 친구들이 여기에 보여요';

  @override
  String get avatarNoRoomMembers => '아직 같이 있는 친구가 없어요';

  @override
  String avatarRoomMembersCount(int count) {
    return '같이 있는 친구 $count명';
  }

  @override
  String get avatarNoTrack => '지금 듣는 곡 없음';

  @override
  String get qrScanTitle => 'QR 스캔';

  @override
  String qrScanCameraError(String error) {
    return '카메라를 사용할 수 없어요\n$error';
  }

  @override
  String get qrScanHint => '친구 QR 을 프레임 안에 맞춰 주세요';

  @override
  String get buildingOccupantsFallbackName => '건물';

  @override
  String buildingOccupantsInside(int count) {
    return '$count명이 안에 있어요';
  }

  @override
  String get buildingOccupantsEmpty => '건물을 떠났어요';

  @override
  String buildingOccupantsListening(String name, String artist) {
    return '🎵 $name · $artist 듣는 중';
  }

  @override
  String get buildingOccupantsInBuilding => '🏢 건물 안에 있어요';

  @override
  String get weatherWeeklyLabel => '주간';

  @override
  String get weatherToday => '오늘';

  @override
  String get weatherDayMon => '월';

  @override
  String get weatherDayTue => '화';

  @override
  String get weatherDayWed => '수';

  @override
  String get weatherDayThu => '목';

  @override
  String get weatherDayFri => '금';

  @override
  String get weatherDaySat => '토';

  @override
  String get weatherDaySun => '일';

  @override
  String get locPermTitle => '위치 권한이 필요해요';

  @override
  String get locPermBody =>
      '현재 위치를 지도에 표시하고\n주변 정보 / 길찾기를 정확하게 안내하기 위해\n위치 권한이 필요해요.';

  @override
  String get locPermRequesting => '요청 중...';

  @override
  String get locPermRequest => '위치 권한 허용';

  @override
  String get locPermGranted => '✓ 위치 권한 허용됨';

  @override
  String get locPermDenied => '거부됨 — 설정에서 직접 허용할 수 있어요';

  @override
  String get locPermRetry => '다시 시도';

  @override
  String get groupEditorTitle => '친구 그룹';

  @override
  String get groupEditorNew => '새 그룹';

  @override
  String get groupEditorEmpty => '아직 그룹이 없어요';

  @override
  String get groupEditorEmptyHint => '우상단 + 버튼으로 그룹을 만들어 친구를 분류하세요.';

  @override
  String get groupEditorHelper => '그룹별 가시성 / 채팅에 활용돼요';

  @override
  String get groupEditorNamePlaceholder => '예: 가족, 회사, 동호회';

  @override
  String get groupEditorCreate => '만들기';

  @override
  String groupEditorFailure(String error) {
    return '실패: $error';
  }

  @override
  String groupEditorMemberCount(int count) {
    return '$count명';
  }

  @override
  String groupEditorDeleteTitle(String name) {
    return '$name 그룹 삭제';
  }

  @override
  String get groupEditorDeleteBody => '그룹만 삭제되고 친구는 유지돼요.';

  @override
  String get groupEditorDelete => '삭제';

  @override
  String get groupEditorAddFriendsHint => '친구를 먼저 추가하세요.';

  @override
  String get peerPinDestinationFallback => '목적지';

  @override
  String peerPinDestinationLabel(String name) {
    return '🎯 $name';
  }

  @override
  String get stationDetailCloseLabel => '역 상세 닫기';

  @override
  String get stationDetailDeparture => '출발';

  @override
  String get stationDetailArrival => '도착';

  @override
  String get stationDetailLiveArrivals => '실시간 출발 정보';

  @override
  String get stationDetailLoading => '조회 중...';

  @override
  String get stationDetailNoArrivals => '도착 정보 없음';

  @override
  String get stationDetailCrowdVery => '매우 혼잡';

  @override
  String get stationDetailCrowdBusy => '혼잡';

  @override
  String get stationDetailCrowdNormal => '보통';

  @override
  String get stationDetailCrowdFree => '여유';

  @override
  String stationDetailBoardingCount(String count) {
    return '승차 $count명';
  }

  @override
  String stationDetailAlightingCount(String count) {
    return '하차 $count명';
  }

  @override
  String stationDetailClosureCount(int count) {
    return '시설 폐쇄 $count건';
  }

  @override
  String get visitTimelineTitle => '내 발자국';

  @override
  String visitTimelineSummary(int count, String ago) {
    return '$count곳 · 가장 최근 $ago';
  }

  @override
  String get visitTimelineEmpty => '방문 기록이 없어요.';

  @override
  String get visitTimelineClose => '닫기';

  @override
  String visitTimelineExpand(int count) {
    return '$count곳 더 보기';
  }

  @override
  String get visitTimelineCollapse => '접기';

  @override
  String get visitTimelineDateToday => '오늘';

  @override
  String get visitTimelineDateYesterday => '어제';

  @override
  String visitTimelineDateDaysAgo(int days) {
    return '$days일 전';
  }

  @override
  String visitTimelineDateMonthDay(int month, int day) {
    return '$month/$day';
  }

  @override
  String get visitTimelineAgoNone => '없음';

  @override
  String visitTimelineAgoMin(int min) {
    return '$min분 전';
  }

  @override
  String visitTimelineAgoHour(int hour) {
    return '$hour시간 전';
  }

  @override
  String visitTimelineAgoDay(int day) {
    return '$day일 전';
  }

  @override
  String visitTimelineVisitCount(int count) {
    return '$count회';
  }

  @override
  String get permPageTitle => '권한 설정';

  @override
  String get permPageBody => '아래 권한을 한 번에 설정해두면\n앱을 쓰다가 멈추는 일이 없어요.';

  @override
  String get permPageFooter => '거부해도 앱은 동작해요. 해당 기능만 제한됨.';

  @override
  String get permPageRequesting => '요청 중...';

  @override
  String get permPageAllGranted => '✓ 모두 허용됨';

  @override
  String get permPageRequestAll => '한 번에 허용';

  @override
  String get permItemLocation => '위치';

  @override
  String get permItemLocationDesc => '지도에 내 위치 표시 + 친구방 실시간 공유';

  @override
  String get permItemNotification => '알림';

  @override
  String get permItemNotificationDesc => '친구 신청 / 채팅 / 만남 알림';

  @override
  String get permItemCamera => '카메라';

  @override
  String get permItemCameraDesc => '장소 사진 분석 + 친구 채팅 사진';

  @override
  String get permItemPhotos => '사진';

  @override
  String get permItemPhotosDesc => '갤러리 사진을 채팅에 공유';

  @override
  String get permItemMicrophone => '마이크';

  @override
  String get permItemMicrophoneDesc => 'AI 음성 대화 + 음성 메시지';

  @override
  String permTapToSettings(String desc) {
    return '$desc (탭하면 설정 열기)';
  }

  @override
  String get livingCityTitle => '서울이 살아 움직여요';

  @override
  String get livingCityBody => '아이콘을 누르면 카메라가 그 장면으로 날아가요.';

  @override
  String get livingCityVehSubway => '지하철';

  @override
  String get livingCityVehBus => '버스';

  @override
  String get livingCityVehRiverBus => '한강버스';

  @override
  String get livingCityVehFlight => '항공기';

  @override
  String get infoBarsTierFlagship => '플래그십';

  @override
  String get infoBarsTierHigh => '상위';

  @override
  String get infoBarsTierMid => '중급';

  @override
  String get infoBarsTierLow => '저사양';

  @override
  String infoBarsProfileToast(String model, String tier, int fps, int pollMs) {
    return '$model · $tier\n${fps}fps · 폴링 ${pollMs}ms 최적화 적용';
  }

  @override
  String get navBannerNext => '다음';

  @override
  String navBannerWalkTo(String station) {
    return '$station까지 도보';
  }

  @override
  String navBannerBoardAt(String station, String line) {
    return '$station에서 $line 승차';
  }

  @override
  String navBannerWalkDetail(int min) {
    return '$min분 이동';
  }

  @override
  String navBannerTransitDetail(String station, int min) {
    return '$station 방면 · $min분';
  }

  @override
  String get readyPageTitle => '준비됐어요';

  @override
  String get readyPageBody => '아래 시작 버튼을 누르면\n실시간 서울이 펼쳐져요.';

  @override
  String get welcomePageSubtitle => '서울을 새로운 시각으로';

  @override
  String get pathfindingPageTitle => '오늘은 어떤 여행?';

  @override
  String get pathfindingPageBody =>
      'AI 비서가 너의 무드에 맞춰 코스를 짜줄게.\n나중에 언제든 바꿀 수 있어.';

  @override
  String riverBusStopLabel(String name) {
    return '$name 선착장';
  }

  @override
  String get riverBusRouteEnded => '운항 종료';

  @override
  String riverBusNextTime(String time) {
    return '다음 $time';
  }

  @override
  String get riverBusMaintenance => '정비 중';

  @override
  String get riverBusDeparture => '출발';

  @override
  String get riverBusArrival => '도착';

  @override
  String get qualityPreviewDemoLabel => 'DEMO · 지하철';

  @override
  String get qualityPresetHigh => '고품질';

  @override
  String get qualityPresetMedium => '부드러움';

  @override
  String get qualityPresetLow => '배터리 절약';

  @override
  String get qualityPresetHighDetail => '60 fps · 효과 ON';

  @override
  String get qualityPresetMediumDetail => '30 fps · 효과 일부';

  @override
  String get qualityPresetLowDetail => '10 fps · 효과 OFF';
}
