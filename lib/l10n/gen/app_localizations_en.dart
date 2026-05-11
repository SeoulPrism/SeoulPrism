// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Seoul Vista';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonLater => 'Later';

  @override
  String get settingsAppLanguageTitle => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageKo => '한국어';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageChangedTitle => 'Language saved';

  @override
  String get languageChangedBody =>
      'To fully apply the new language, please close the app (swipe up from the app switcher) and reopen it.';

  @override
  String get routeUnitHour => 'h';

  @override
  String get routeUnitMin => 'min';

  @override
  String routeTransfersCount(int count) {
    return '$count transfers';
  }

  @override
  String get routeDeparture => 'Depart';

  @override
  String get routeArrival => 'Arrive';

  @override
  String get routeTransfer => 'Transfer';

  @override
  String routeTransferDetail(String line, int min) {
    return '$line · $min min';
  }

  @override
  String routeBoardLine(String line) {
    return 'Board $line';
  }

  @override
  String routeSegmentBus(String from, String to, int count, int min) {
    return '$from → $to · $count stops · $min min';
  }

  @override
  String routeSegmentTrain(String from, String to, int count, int min) {
    return '$from → $to · $count stations · $min min';
  }

  @override
  String routeSegmentShort(String from, int min) {
    return '$from · $min min';
  }

  @override
  String get routeShowStops => 'Show stops ▼';

  @override
  String get routeCollapse => 'Collapse ▲';

  @override
  String get snsTitle => 'AI Plan';

  @override
  String get snsSubtitle => 'Build a Seoul day plan from social posts';

  @override
  String get snsSectionPhotos => 'Photos';

  @override
  String get snsSectionDescription => 'Description';

  @override
  String get snsSectionLink => 'Social link';

  @override
  String get snsTextHint =>
      'Tell us where you\'d like to go and what you\'d like to do';

  @override
  String get snsUrlHint => 'Instagram, TikTok URL';

  @override
  String get snsAnalyzeButton => 'Analyze';

  @override
  String snsAnalyzeError(String error) {
    return 'Analysis failed: $error';
  }

  @override
  String get snsImageGallery => 'Gallery';

  @override
  String get snsImageCamera => 'Camera';

  @override
  String get dayPlanTitle => 'Day plan';

  @override
  String get dayPlanNavigateAll => 'Navigate all';

  @override
  String dayPlanTransitSummary(int min) {
    return '🚇 $min min';
  }

  @override
  String dayPlanTransfersSummary(int count) {
    return '🔄 $count';
  }

  @override
  String dayPlanStyleStats(int count, int min) {
    return '$count stops · $min min';
  }

  @override
  String get dayPlanNavigateStop => 'Navigate';

  @override
  String get whatsNewClose => 'Close';

  @override
  String get whatsNewSkip => 'Skip';

  @override
  String get whatsNewStart => 'Get started';

  @override
  String get whatsNewNext => 'Next';

  @override
  String whatsNewPage1Title(String version) {
    return 'v$version — Welcome back';
  }

  @override
  String get whatsNewPage1Body =>
      'Your trips just got more personal.\nFrom travel moods to friends and memories —\nmeet 14 new features.';

  @override
  String get whatsNewPage2Title => 'Your travel mood';

  @override
  String get whatsNewPage2Body =>
      'Pick from Relax · Play · History · Mix and\nthe AI tone, recommendations, and Trip tab\nshift to match.';

  @override
  String get whatsNewPage3Title => 'Go together';

  @override
  String get whatsNewPage3Body =>
      'Set a shared destination in a friend room.\nDistances for each member update live.\nAn orange pin lands on the map.';

  @override
  String get whatsNewPage4Title => '1:1 DMs + voice/photo';

  @override
  String get whatsNewPage4Body =>
      'Chat with a friend without a room.\n🎙 Long-press the mic for voice, 📷 pick a photo,\n📍 share a location — all in one chat.';

  @override
  String get whatsNewPage5Title => 'Spotify sharing';

  @override
  String get whatsNewPage5Body =>
      'Send what you\'re listening to.\nTap 🎵 in chat and your currently-playing\nSpotify track shares as a card.';

  @override
  String get whatsNewPage6Title => 'More friends';

  @override
  String get whatsNewPage6Body =>
      'Friend-of-friend suggestions,\nQR codes for instant adds,\nroom invite links for one-tap join.';

  @override
  String get whatsNewPage7Title => 'Activity becomes points';

  @override
  String get whatsNewPage7Body =>
      'Earn points and badges from adds, meetups, and streaks.\nCompare with friends in the ranking,\nand review your week on a chart.';

  @override
  String get whatsNewPage8Title => 'Your way';

  @override
  String get whatsNewPage8Body =>
      'Toggle notifications by type,\nshare your location with only certain groups.\nSafety and privacy stay with you.';

  @override
  String get whatsNewPage9Title => 'Routes, end to end';

  @override
  String get whatsNewPage9Body =>
      'Subway, bus, and walking — all in one.\nTransfers, live arrivals, and station exits\nshow up where you need them.';

  @override
  String get whatsNewPage10Title => 'Day plans, made for you';

  @override
  String get whatsNewPage10Body =>
      'Turn your saved places into a day.\nEfficient, leisurely, or food-focused —\npick a style and go.';

  @override
  String get whatsNewPage11Title => 'Speaks your language';

  @override
  String get whatsNewPage11Body =>
      'Korean, English, Japanese, Chinese.\nThe AI assistant replies in the same.\nIt follows your device language.';

  @override
  String get whatsNewPage12Title => 'Just ask out loud';

  @override
  String get whatsNewPage12Body =>
      'Talk to the AI naturally.\nSearch, navigate, get picks — by voice.\nGemini Live listens and answers live.';

  @override
  String get profileCategoryFavorites => 'Favorites';

  @override
  String get profileCategoryRecent => 'Recent';

  @override
  String get profileCategoryFrequent => 'Frequent';

  @override
  String get profileGuestName => 'Guest';

  @override
  String get profileDefaultName => 'User';

  @override
  String get profileSyncCta => 'Sign in to sync across devices';

  @override
  String profileAgoDays(int days) {
    return '${days}d ago';
  }

  @override
  String profileAgoHours(int hours) {
    return '${hours}h ago';
  }

  @override
  String get profileAgoNow => 'Just now';

  @override
  String profileVisitCount(int count) {
    return '$count visits';
  }

  @override
  String get profileEmptyFavorites => 'No favorites yet';

  @override
  String get profileEmptyVisits => 'No visits yet';

  @override
  String get profileCollapse => 'Collapse';

  @override
  String profileMoreCount(int count) {
    return '$count more';
  }

  @override
  String get profileLiveShareBeta => 'Real-time location & chat (Beta)';

  @override
  String get profileTimeline => 'My timeline';

  @override
  String profilePlaceCount(int count) {
    return '$count places';
  }

  @override
  String get profileEmptyVisitsCta =>
      'No visits yet. Explore places and try directions.';

  @override
  String get profileToday => 'Today';

  @override
  String get profileYesterday => 'Yesterday';

  @override
  String profileMonthDay(int month, int day) {
    return '$month/$day';
  }

  @override
  String profileVisitTimes(int count) {
    return '$count×';
  }

  @override
  String get profileEditName => 'Edit name';

  @override
  String get profileNewNameHint => 'Enter new name';

  @override
  String get profileTagline => 'Every moment in Seoul';

  @override
  String get profileMore => 'More';

  @override
  String get profileEmptyMapPlaces => 'Your visits will appear on this map';

  @override
  String profileRecentPlaceCount(int count) {
    return 'Last $count places';
  }

  @override
  String chatSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get chatRoomDestSet => '🎯 Set as room destination';

  @override
  String chatActionFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get chatMapAppUnavailable => 'Couldn\'t open the maps app';

  @override
  String get chatMicPermissionRequired => 'Microphone permission required';

  @override
  String chatRecordStartFailed(String error) {
    return 'Couldn\'t start recording: $error';
  }

  @override
  String get chatRecordTooShort => 'Too short — press and hold to record';

  @override
  String chatRecordStopFailed(String error) {
    return 'Couldn\'t stop recording: $error';
  }

  @override
  String chatPhotoSendFailed(String error) {
    return 'Couldn\'t send photo: $error';
  }

  @override
  String get chatSpotifyClientIdMissing =>
      'Spotify not set up — developer must add SPOTIFY_CLIENT_ID';

  @override
  String get chatSpotifyAuthRetryHint => 'Tap again after Spotify auth';

  @override
  String chatSpotifyAuthFailed(String error) {
    return 'Spotify connection failed: $error';
  }

  @override
  String get chatMyLocation => 'My location';

  @override
  String get chatLocationUnavailable => 'Couldn\'t fetch your location';

  @override
  String get chatDefaultRoomName => 'Friend room';

  @override
  String chatMembersInRoom(int count) {
    return '$count in the room';
  }

  @override
  String get chatRecordingHint =>
      'Recording… release to send, drag up to cancel';

  @override
  String get chatRecordingPlaceholder => '🎙 Recording';

  @override
  String get chatMessageHint => 'Type a message';

  @override
  String get chatActionMap => 'Map';

  @override
  String get chatActionDirections => 'Directions';

  @override
  String get chatActionRoomDest => '🎯 Room destination';

  @override
  String chatVoiceLabel(int seconds) {
    return '${seconds}s voice';
  }

  @override
  String chatPlaybackFailed(String error) {
    return 'Playback failed: $error';
  }

  @override
  String chatEmptyTitleNamed(String roomName) {
    return '$roomName has started';
  }

  @override
  String get chatEmptyTitleDefault => 'The friend room is on';

  @override
  String get chatEmptyBody =>
      'Say hi to your friends here, share your location,\nand plan where to go together.';

  @override
  String get chatStart => 'Start the chat';

  @override
  String get chatReport => 'Report this message';

  @override
  String chatBlockDialogTitle(String nickname) {
    return 'Block $nickname';
  }

  @override
  String get chatBlockDialogBody =>
      'Blocking removes them from the room and hides their messages.';

  @override
  String get chatBlockConfirm => 'Block';

  @override
  String get chatUnknownUser => 'User';

  @override
  String get spotifyOpenInApp => 'Open in Spotify';

  @override
  String spotifyShareFailed(String error) {
    return 'Share failed: $error';
  }

  @override
  String get spotifyNoTrack => 'Nothing playing right now';

  @override
  String get dmAccessDenied => 'Can\'t access this conversation';

  @override
  String dmSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get dmDefaultPeer => 'Friend';

  @override
  String get dmEmptyHint => 'Send the first message';

  @override
  String get dmMessageHint => 'Message';

  @override
  String get friendCodeLengthError => 'Please enter an 8-character code.';

  @override
  String get friendCodeNotFound => 'No user matches that code.';

  @override
  String friendRequestSent(String nickname) {
    return 'Friend request sent to $nickname.';
  }

  @override
  String get friendShareSubject => 'Add me on Seoul Live';

  @override
  String friendShareBody(String nickname, String code) {
    return '$nickname sent you a Seoul Live friend code!\n\nCode: $code\nAdd instantly: com.seoul.prism://friend/$code';
  }

  @override
  String get friendShareCopied => 'Share text copied';

  @override
  String get friendCodeTitle => 'Friend code';

  @override
  String get friendCodeSubtitle => 'Share your code, or add a friend\'s.';

  @override
  String get friendMyCode => 'My friend code';

  @override
  String get friendCodeCopied => 'Code copied';

  @override
  String get friendQrHint => 'Friends can scan with their camera to add you';

  @override
  String get friendShareButton => 'Share';

  @override
  String get friendAddByCodeTitle => 'Add a friend by code';

  @override
  String get friendAddByCodeHint => 'Enter an 8-character code or scan a QR';

  @override
  String get friendCodePlaceholder => 'e.g. AB12CD34';

  @override
  String get friendSendRequest => 'Send friend request';

  @override
  String peerFriendCode(String code) {
    return 'Friend code $code';
  }

  @override
  String get peerOwnPin => 'That\'s your own pin';

  @override
  String get peerReport => 'Report';

  @override
  String peerBlockDialogTitle(String nickname) {
    return 'Block $nickname';
  }

  @override
  String get peerBlockDialogBody =>
      'Blocking removes them from this room and hides their messages and pins.';

  @override
  String get peerBlockConfirm => 'Block';

  @override
  String get peerBlock => 'Block';

  @override
  String get peerIsFriend => 'Friends ✓';

  @override
  String get peerCancelRequest => 'Cancel request';

  @override
  String peerRequestCanceled(String nickname) {
    return 'Canceled the request to $nickname';
  }

  @override
  String get peerAcceptRequest => 'Accept friend request';

  @override
  String peerNowFriend(String nickname) {
    return 'You\'re now friends with $nickname';
  }

  @override
  String peerCanRequestInDays(int days) {
    return 'Can request again in ${days}d';
  }

  @override
  String peerCanRequestInHours(int hours) {
    return 'Can request again in ${hours}h';
  }

  @override
  String get peerSendRequest => 'Send friend request';

  @override
  String peerRequestSent(String nickname) {
    return 'Friend request sent to $nickname';
  }

  @override
  String peerDistanceMeters(int meters) {
    return '$meters m away';
  }

  @override
  String peerDistanceKm(String km) {
    return '$km km away';
  }

  @override
  String get spotifyRoomRequired => 'Join a friend room and try again';

  @override
  String get spotifyShareSuccess => '🎵 Shared with the room';

  @override
  String get spotifyDisconnectTitle => 'Disconnect Spotify';

  @override
  String get spotifyDisconnectBody =>
      'This deletes the saved token and stops sharing tracks with friends.';

  @override
  String get spotifyDisconnectConfirm => 'Disconnect';

  @override
  String get spotifyDisconnected => 'Spotify disconnected';

  @override
  String get spotifyAuthRetryHint =>
      'We\'ll return automatically after Spotify auth';

  @override
  String spotifyConnectFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get spotifyClientIdMissing =>
      'Developer hasn\'t set SPOTIFY_CLIENT_ID';

  @override
  String get spotifyTokenExpired => 'Connection expired. Please log in again.';

  @override
  String get spotifyReconnect => 'Reconnect Spotify';

  @override
  String get spotifyConnect => 'Connect Spotify';

  @override
  String get spotifyConnectDescription =>
      'Connect to share what you\'re listening to in friend rooms,\nand see what your friends are playing.';

  @override
  String get spotifyLoginButton => 'Log in with Spotify';

  @override
  String get spotifyShareToRoom => 'Share with room';

  @override
  String get spotifyDisconnect => 'Disconnect';

  @override
  String get spotifyConnectedNoTrack => 'Spotify connected (no playback)';

  @override
  String get spotifyNowPlaying => 'Now playing';

  @override
  String get departureTimePickerTitle => 'Departure time';

  @override
  String get departureTimePickerHint =>
      'Arrival time is calculated from this departure time.';

  @override
  String get departureTimeNow => 'Now';

  @override
  String get departureTime30min => 'In 30 min';

  @override
  String get departureTime1hour => 'In 1 hour';

  @override
  String get departureTimeCustom => 'Custom';

  @override
  String get placeActionDepart => 'Depart';

  @override
  String get placeActionArrive => 'Arrive';

  @override
  String get placeActionInfo => 'Info';

  @override
  String get placeDetailTapHint => 'Tap for photos · reviews · hours';

  @override
  String get savedPanelTitle => 'Saved';

  @override
  String get savedEmptyFavorites => 'No saved places yet';

  @override
  String get savedRemoveFavoriteTooltip => 'Remove from favorites';

  @override
  String get travelThemeTitle => 'Theme suggestions';

  @override
  String get travelThemeSubtitle => 'One tap to generate a course';

  @override
  String get travelTitle => 'Trip';

  @override
  String get travelSubtitle =>
      'From Gyeongbokgung to the Han River — we\'ll plan your day';

  @override
  String get travelEventsTitle => 'This week\'s events';

  @override
  String get travelEventsSubtitle => 'Cultural events happening in Seoul';

  @override
  String travelEventsCount(int count) {
    return '$count';
  }

  @override
  String get travelEventsLoadError =>
      'Couldn\'t load events. Pull down to retry.';

  @override
  String get travelAiTitle => 'AI plans your day';

  @override
  String get travelAiSubtitle => 'Considers time · weather · routes';

  @override
  String get travelFromSavedTitle => 'Build from saved places';

  @override
  String get travelFromSavedSubtitle =>
      'Course based on favorites + visit history';

  @override
  String get travelYourTheme => 'Your theme';

  @override
  String get travelStartWithMood => 'Start with this mood';

  @override
  String get travelEventBadgeOngoing => 'Live';

  @override
  String get travelEventBadgeFree => 'Free';

  @override
  String travelThemeStops(int count) {
    return '$count stops';
  }

  @override
  String get travelMoodAnalyzing => 'Analyzing track mood…';

  @override
  String get travelMoodExcited => 'For upbeat vibes,';

  @override
  String get travelMoodToday => 'On a day like today,';

  @override
  String get travelMoodIntense => 'For intense beats,';

  @override
  String get travelMoodCalm => 'For a calm mood,';

  @override
  String get travelTodayMoodLabel => 'Today\'s mood';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptySubtitle => 'New updates will appear here';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionRealtime => 'Real-time visualization';

  @override
  String get settingsLineSubway => 'Subway lines';

  @override
  String get settingsTrainPos => 'Subway trains';

  @override
  String get settingsStations => 'Subway stations';

  @override
  String get settingsBuses => 'City buses';

  @override
  String get settingsRiverBus => 'Han River bus';

  @override
  String get settingsFlights => 'Aircraft';

  @override
  String get settingsSectionDataSource => 'Data source';

  @override
  String get settingsSubwayMode => 'Subway mode';

  @override
  String get settingsSubwayModeLive => 'Live';

  @override
  String get settingsSubwayModeDemo => 'Demo';

  @override
  String get settingsSeoulApi => 'Seoul Open API (60s)';

  @override
  String get settingsNaverApi => 'Naver API (5s interp.)';

  @override
  String get settingsSectionLighting => 'Lighting';

  @override
  String get settingsAutoLighting => 'Auto (time + weather)';

  @override
  String get settingsLightPreset => 'Light preset';

  @override
  String get settingsLightAuto => 'Auto';

  @override
  String get settingsLightDawn => 'Dawn';

  @override
  String get settingsLightDay => 'Day';

  @override
  String get settingsLightDusk => 'Dusk';

  @override
  String get settingsLightNight => 'Night';

  @override
  String settingsCountValue(int count) {
    return '$count';
  }

  @override
  String get settingsLabelFavorites => 'Favorites';

  @override
  String get settingsLabelVisits => 'Visits';

  @override
  String get settingsLabelRecentSearches => 'Recent searches';

  @override
  String get settingsAiAssistantLanguage => 'AI assistant language';

  @override
  String get settingsThemeMode => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeChangedTitle => 'Theme saved';

  @override
  String settingsThemeChangedBody(String theme) {
    return 'To fully apply $theme mode, please close the app (swipe up from the app switcher) and reopen it.';
  }

  @override
  String get settingsRestartConfirm => 'OK';

  @override
  String get settingsMapHome => 'Map home start';

  @override
  String get settingsMapHomeDefault => 'Default';

  @override
  String get settingsMapHomeMyLocation => 'My location';

  @override
  String get settingsMapHomeRecent => 'Recent search';

  @override
  String get settingsKeepScreenOn => 'Keep screen on';

  @override
  String get settingsAutoRotate => 'Auto-rotate screen';

  @override
  String get settingsAlwaysMyLocation =>
      'Always start directions from my location';

  @override
  String get settingsClearHistory => 'Clear all usage history';

  @override
  String get settingsClearSearchHistory => 'Clear recent searches';

  @override
  String get settingsConvertAccount => 'Convert to full account';

  @override
  String get settingsEditNameItem => 'Edit name';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsMapDataLabel => 'Map display & data';

  @override
  String get settingsSectionDeveloper => 'Developer';

  @override
  String get settingsDebugLogs => 'Debug log output';

  @override
  String get settingsResetTutorial => 'Replay tutorial';

  @override
  String get settingsReplayWhatsNew => 'Replay What\'s New';

  @override
  String get settingsWhatsNewToast =>
      'What\'s New will be shown on next app launch';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String get settingsClearHistoryTitle => 'Clear usage history';

  @override
  String get settingsClearHistoryBody =>
      'All usage history will be deleted.\nThis cannot be undone.';

  @override
  String get commonDelete => 'Delete';

  @override
  String get settingsClearedHistoryToast =>
      'All usage history has been deleted';

  @override
  String get settingsClearSearchTitle => 'Clear search history';

  @override
  String get settingsClearSearchBody => 'All recent searches will be deleted.';

  @override
  String get settingsClearedSearchToast => 'Search history has been cleared';

  @override
  String get settingsEditNameDialogTitle => 'Edit name';

  @override
  String get settingsEditNameDialogBody => 'Enter a new name.';

  @override
  String get settingsEditNameConfirm => 'Change';

  @override
  String get settingsNewNameDialogTitle => 'New name';

  @override
  String get settingsChangePasswordTitle => 'Change password';

  @override
  String settingsChangePasswordBody(String email) {
    return 'We\'ll send the password reset link to $email.';
  }

  @override
  String get settingsSendButton => 'Send';

  @override
  String get settingsPasswordResetSent => 'Reset email has been sent';

  @override
  String get settingsLogoutTitle => 'Sign out';

  @override
  String get settingsLogoutBody => 'Sign out now?';

  @override
  String get settingsLogoutConfirm => 'Sign out';

  @override
  String get settingsDeleteAccountTitle => 'Delete account';

  @override
  String get settingsDeleteAccountBody =>
      'Your account and all data will be permanently deleted.\nThis cannot be undone.';

  @override
  String get settingsDeleteAccountConfirm => 'Delete';

  @override
  String get settingsDeleteError => 'An error occurred during account deletion';

  @override
  String get settingsResetTutorialTitle => 'Replay tutorial';

  @override
  String get settingsResetTutorialBody =>
      'Saved progress will be cleared and the tutorial will start over on next launch.';

  @override
  String get settingsResetTutorialConfirm => 'Replay';

  @override
  String get settingsMapDisplayTitle => 'Map display & data';

  @override
  String get settingsSectionMapDisplay => 'Map display';

  @override
  String get aiStatusSearchingCourse => 'Searching course…';

  @override
  String aiPlacesFound(int count) {
    return 'Found $count places! Check below.';
  }

  @override
  String get aiStatusFindingInfo => 'Looking it up…';

  @override
  String get aiStatusAnalyzingImage => 'Analyzing image…';

  @override
  String get aiNoPlacesFound => 'No places found.';

  @override
  String aiAnalysisError(String error) {
    return 'Analysis error: $error';
  }

  @override
  String get aiSelectPhotoHint => 'Please select a photo';

  @override
  String get aiPhotoShoot => 'Take photo';

  @override
  String get aiStatusConnecting => 'Connecting…';

  @override
  String get aiStatusListening => 'Listening';

  @override
  String get aiStatusThinking => 'Thinking…';

  @override
  String get aiStatusSpeaking => 'Speaking';

  @override
  String get aiStatusIdle => 'Idle';

  @override
  String get aiStatusReady => 'Ready';

  @override
  String aiFoundPlacesHeader(int count) {
    return 'Found places ($count)';
  }

  @override
  String get aiVoiceCommandHint =>
      '\"Add a cafe\", \"Remove Gyeongbokgung\", \"Confirm this\" — try it';

  @override
  String aiPlaceStationDistance(String station, int minutes) {
    return '$station stn · $minutes min';
  }

  @override
  String get aiDefaultSearch => 'Seoul travel recommendations';

  @override
  String get recommendTitle => 'Recommendations';

  @override
  String recommendSubtitleNearbyArea(String area) {
    return 'Popular near $area right now';
  }

  @override
  String get recommendSubtitleNearbyDefault => 'Popular nearby right now';

  @override
  String get recommendRefresh => 'Refresh';

  @override
  String get recommendNoResults => 'No results nearby.\nTry again later.';

  @override
  String recommendRank(int rank) {
    return '#$rank';
  }

  @override
  String get recommendEventsLoadError =>
      'Couldn\'t load cultural events.\nTry again later.';

  @override
  String get recommendStatusUpcoming => 'Upcoming';

  @override
  String get recommendBadgePaid => 'Paid';

  @override
  String get recommendUniqueMood => '✨ Your own';

  @override
  String get recommendTabFood => '🍜 Food';

  @override
  String get recommendTabCafe => '☕️ Café';

  @override
  String get recommendTabShopping => '🛍 Shopping';

  @override
  String get recommendTabOutdoor => '🌳 Parks · Night';

  @override
  String get recommendTabEvents => '🎭 Culture';

  @override
  String get authTabSignUp => 'Sign up';

  @override
  String get authTabSignIn => 'Sign in';

  @override
  String get authProcessing => 'Processing…';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authLabelEmail => 'Email';

  @override
  String get authHintEmail => 'Enter your email';

  @override
  String get authLabelPassword => 'Password';

  @override
  String get authHintPassword => 'Enter your password';

  @override
  String get authFindId => 'Find ID';

  @override
  String get authFindPassword => 'Find password';

  @override
  String get authLabelUsername => 'Username';

  @override
  String get authHintUsername => 'Enter your username';

  @override
  String get authLabelConfirmPassword => 'Confirm password';

  @override
  String get authHintConfirmPassword => 'Re-enter password';

  @override
  String get authSnsLogin => 'Sign in with social';

  @override
  String get authGoogleAuthFailed => 'Google authentication failed';

  @override
  String get authGoogleSignInFailed => 'Google sign-in failed';

  @override
  String get authGuestSignInFailed => 'Guest sign-in failed';

  @override
  String get authAppleAuthFailed => 'Apple authentication failed';

  @override
  String get authAppleSignInCanceled => 'Apple sign-in was canceled';

  @override
  String get authAppleSignInFailed => 'Apple sign-in failed';

  @override
  String get authEmailAndPasswordRequired => 'Please enter email and password';

  @override
  String get authUsernameRequired => 'Please enter a username';

  @override
  String get authPasswordMismatch => 'Passwords don\'t match';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get authGenericError => 'An error occurred';

  @override
  String get authErrorInvalidCredentials => 'Email or password is incorrect';

  @override
  String get authErrorEmailExists => 'This email is already registered';

  @override
  String get authErrorInvalidEmail => 'Please enter a valid email format';

  @override
  String get authErrorEmailNotConfirmed =>
      'Email verification not complete. Check your inbox.';

  @override
  String get authEmailConfirmRequiredTitle => 'Email verification required';

  @override
  String authEmailConfirmRequiredBody(String email) {
    return 'A verification email has been sent to $email.\nCheck your inbox, verify, and then sign in.';
  }

  @override
  String get authFindIdResultTitle => 'Find ID result';

  @override
  String get authFindIdResultBefore => 'Your username is ';

  @override
  String get authFindIdResultAfter => '.';

  @override
  String get authFindIdEmailRequired => 'Please enter an email';

  @override
  String get authFindIdNotFound => 'No account found for that email';

  @override
  String get authPasswordResetSent =>
      'Password reset link has been sent to your email';

  @override
  String get authFindIdFailed => 'Couldn\'t find your ID';

  @override
  String get authEmailSendFailed => 'Couldn\'t send email';

  @override
  String get authFindIdTitle => 'Find ID';

  @override
  String get authFindPasswordTitle => 'Find password';

  @override
  String get authFindIdBody =>
      'Enter the email you used to sign up.\nWe\'ll send your ID.';

  @override
  String get authFindPasswordBody =>
      'Enter your email and we\'ll send a password reset link.';

  @override
  String get authFindIdEmailHint => 'Enter your sign-up email';

  @override
  String get authFindIdSubmit => 'Find ID';

  @override
  String get authFindPasswordSubmit => 'Send reset link';

  @override
  String get hubSettingsTooltip => 'Settings';

  @override
  String get hubAuthExploreSeoulTitle => 'Explore Seoul with friends';

  @override
  String get hubAuthCreateProfileSubtitle =>
      'Create a nickname and pin to start.';

  @override
  String get hubAuthCreateProfileButton => 'Create profile';

  @override
  String get hubPausedNotice =>
      'Seoul Live paused — location/notifications blocked, chat OK';

  @override
  String get hubResumeButton => 'Resume';

  @override
  String get hubRoomTitle => 'Room';

  @override
  String get hubRoomEmpty => 'Create or join a room by code';

  @override
  String hubRoomCurrent(String code) {
    return 'In room · code $code';
  }

  @override
  String get hubFriendsTitle => 'Friends';

  @override
  String hubFriendsSubtitle(int count, int requests) {
    return '$count friends · $requests requests';
  }

  @override
  String get hubDmSubtitle => '1:1 chats with friends';

  @override
  String get hubFriendCodeTitle => 'Friend code';

  @override
  String hubFriendCodeSubtitle(String code) {
    return 'Share my code $code / enter one';
  }

  @override
  String get hubFriendGroupsTitle => 'Friend groups';

  @override
  String hubFriendGroupsSubtitle(int count) {
    return '$count groups';
  }

  @override
  String get hubSpotifyConnectedNoPlayback => 'Connected — no playback';

  @override
  String get hubSpotifyShareSubtitle => 'Share your tracks with friends';

  @override
  String get hubVisibilityGhost => 'Private — no send/receive';

  @override
  String get hubVisibilityFriends => 'Friend room — same-room members only';

  @override
  String get hubVisibilityPublic => 'Public — all Seoul Live users';

  @override
  String get hubActivityTitle => 'My activity';

  @override
  String get hubStatMeetups => 'Meetups';

  @override
  String get hubStatFriends => 'Friends';

  @override
  String get hubStatStreak => 'Streak';

  @override
  String hubStatStreakValue(int days) {
    return '${days}d';
  }

  @override
  String hubStatStreakBest(int days) {
    return 'Best $days';
  }

  @override
  String get hubBadgesEmptyHint =>
      'Earn badges with your first friend or first meetup';

  @override
  String get hubAgoJust => 'Just now';

  @override
  String hubAgoMin(int min) {
    return '$min min ago';
  }

  @override
  String hubAgoHour(int hour) {
    return '${hour}h ago';
  }

  @override
  String hubAgoDay(int day) {
    return '${day}d ago';
  }

  @override
  String get hubRecentMeetupsTitle => '🎉 Recent meetups';

  @override
  String hubRecentMeetupsCount(int count) {
    return '$count';
  }

  @override
  String get roomCodeRequired => 'Please enter a 6-character code.';

  @override
  String get roomLeaveTitle => 'Leave room';

  @override
  String get roomLeaveBody => 'Leaving ends location sharing and chat.';

  @override
  String get roomLeaveConfirm => 'Leave';

  @override
  String get roomTitle => 'Room';

  @override
  String get roomDescription =>
      'Share location and chat in real time with friends.';

  @override
  String get roomCapacityNote =>
      'Rooms auto-expire after 24 hours. Capacity 8.';

  @override
  String get roomCreateButton => 'Create room';

  @override
  String get roomCodeEntryTitle => 'Enter invite code (6 digits)';

  @override
  String get roomJoinButton => 'Join';

  @override
  String roomExpiresInMin(int min) {
    return 'Expires in $min min';
  }

  @override
  String get roomDefaultName => 'Unnamed room';

  @override
  String get roomInviteCode => 'Invite code';

  @override
  String get roomCodeCopied => 'Code copied';

  @override
  String roomExpiresInHours(int hour) {
    return 'Expires in ${hour}h';
  }

  @override
  String roomMembers(int current, int max) {
    return 'Members ($current/$max)';
  }

  @override
  String roomChatOpenWithUnread(int count) {
    return 'Open chat ($count)';
  }

  @override
  String get roomChatOpen => 'Open chat';

  @override
  String get roomLeaveButton => 'Leave room';

  @override
  String get roomEditNameTitle => 'Rename room';

  @override
  String get roomEditNameBody => 'Shown to room members';

  @override
  String get roomEditNamePlaceholder => 'e.g. Gwanghwamun meetup';

  @override
  String roomGenericError(String error) {
    return 'Failed: $error';
  }

  @override
  String get roomShareSubject => 'Seoul Live room invite';

  @override
  String roomShareBody(String nickname, String code) {
    return '$nickname invited you to a Seoul Live room!\n\nCode: $code\nJoin: com.seoul.prism://room/$code';
  }

  @override
  String get roomInviteTextCopied => 'Invite text copied';

  @override
  String get roomRefreshCodeTitle => 'Refresh invite code';

  @override
  String get roomRefreshCodeBody =>
      'The previous code stops working immediately. Continue?';

  @override
  String get roomRefreshCodeConfirm => 'Refresh';

  @override
  String get roomCodeRefreshed => 'Code refreshed';

  @override
  String roomKickTitle(String nickname) {
    return 'Kick $nickname';
  }

  @override
  String get roomKickBody => 'They\'ll be removed from the room immediately.';

  @override
  String get roomKickConfirm => 'Kick';

  @override
  String get roomKickFallbackName => 'Member';

  @override
  String roomNameMe(String name) {
    return '$name (me)';
  }

  @override
  String get roomMeetupBadge => 'Meetup';

  @override
  String get roomKickTooltip => 'Kick';

  @override
  String get roomUnknownUser => 'Someone';

  @override
  String roomDestTitle(String name) {
    return '🎯 Together — $name';
  }

  @override
  String roomDestSetBy(String name) {
    return 'Set by $name';
  }

  @override
  String get roomDestDefault => 'Destination';

  @override
  String get roomDestViewMap => 'View on map';

  @override
  String get roomDestClear => 'Clear destination';

  @override
  String get mpSettingsTitle => 'Seoul Live settings';

  @override
  String get mpSectionMyStatus => 'My status';

  @override
  String get mpPause => 'Pause Seoul Live';

  @override
  String get mpPauseHint =>
      '✓ Chat / room join / friend request — allowed\n✗ Location send / meetup alerts / pins — blocked\nData stays intact';

  @override
  String get mpSectionBattery => 'Battery mode';

  @override
  String get mpBatteryHint =>
      'Location update interval — more accurate = more battery';

  @override
  String get mpSectionNotifications => 'Notifications';

  @override
  String mpNotificationsFail(String error) {
    return 'Failed: $error';
  }

  @override
  String get mpNotificationsHint =>
      'Separate from system notification permission — turn off here to silence pushes.';

  @override
  String get mpSectionTutorial => 'Tutorial';

  @override
  String get mpReplayTutorial => 'Replay Seoul Live tutorial';

  @override
  String get mpTutorialToast => 'Tutorial will show next time you enter';

  @override
  String get mpReplayWhatsNew => 'Replay What\'s New';

  @override
  String mpReplayWhatsNewHint(String version) {
    return 'v$version updates';
  }

  @override
  String get mpSectionSafety => 'Safety';

  @override
  String get mpBlockList => 'Block list';

  @override
  String get mpBlockListHint => 'View blocked users / unblock';

  @override
  String get mpSectionConsent => 'Consent & data';

  @override
  String get mpRevokeConsent => 'Revoke location consent';

  @override
  String get mpRevokeConsentHint =>
      'Revoking disables multiplayer and deletes all data';

  @override
  String get mpDownloadMyData => 'Download my data';

  @override
  String get mpDownloadMyDataHint => 'PIPA data portability — email request';

  @override
  String get mpDownloadMyDataToast =>
      'Please email rush94434@gmail.com (within 10 days)';

  @override
  String get mpSectionOps => 'Operations';

  @override
  String get mpOpsMonitor => 'Ops monitor';

  @override
  String get mpOpsMonitorHint =>
      'Daily metrics · abuse signals · report handling';

  @override
  String get mpSectionDanger => 'Danger zone';

  @override
  String get mpLeaveSeoulLive => 'Leave Seoul Live';

  @override
  String get mpLeaveSeoulLiveHint =>
      'Bulk-delete multiplayer data (profile, friends, rooms, chat)';

  @override
  String get mpFootnote =>
      '※ Your Seoul Vista account remains. Only multiplayer data is deleted.';

  @override
  String get mpRevokeDialogTitle => 'Revoke consent';

  @override
  String get mpRevokeDialogBody =>
      'Revoking location processing consent disables multiplayer\nand deletes profile, friends, rooms, chat data. Continue?';

  @override
  String get mpRevokeDialogConfirm => 'Revoke';

  @override
  String get mpRevokedToast => 'Consent revoked and data deleted';

  @override
  String get mpLeaveDialogTitle => 'Leave Seoul Live';

  @override
  String get mpLeaveDialogBody =>
      'All multiplayer data will be permanently deleted.\nYou can rejoin, but friends, rooms, and chat history won\'t be restored.';

  @override
  String get mpLeaveConfirm => 'Leave';

  @override
  String get mpLeftToast => 'You\'ve left Seoul Live';

  @override
  String get mpNotifCatFriendRequest => 'Friend request';

  @override
  String get mpNotifCatFriendAccept => 'Friend accepted';

  @override
  String get mpNotifCatRoomMessage => 'Chat message';

  @override
  String get mpNotifCatMeetup => 'Meetup detected';

  @override
  String get mpNotifCatDestination => 'Destination change';

  @override
  String get mpNotifCatWelcome => 'Welcome';

  @override
  String get panelSubway => 'Subway';

  @override
  String get panelBus => 'Bus';

  @override
  String get panelFlights => 'Aircraft';

  @override
  String get panelDisplay => 'Display';

  @override
  String get panelLineFilter => 'Line filter';

  @override
  String get panelPerformance => 'Performance';

  @override
  String get panelLighting => 'Lighting';

  @override
  String get panelInfo => 'Info';

  @override
  String get panelDeveloper => 'Developer';

  @override
  String get panelDemoRunning => 'DEMO running';

  @override
  String get panelLiveRunning => 'LIVE running';

  @override
  String get panelOff => 'Off';

  @override
  String get panelSwitchToLive => 'Switch to LIVE';

  @override
  String get panelSwitchToDemo => 'Switch to DEMO';

  @override
  String get panelSubwayOn => 'Turn subway on';

  @override
  String get panelSubwayOff => 'Turn subway off';

  @override
  String panelTrainCount(int count) {
    return '$count trains';
  }

  @override
  String panelLastUpdate(String time) {
    return 'Updated $time';
  }

  @override
  String panelBusActive(int count) {
    return '$count buses showing';
  }

  @override
  String get panelSelectRoutes => 'Pick a route';

  @override
  String get panelTurnAllOff => 'Turn all off';

  @override
  String get panelBusPosition => 'Bus positions';

  @override
  String get panelHanRiverBus => '🚢 Han River bus';

  @override
  String get panelAddRoute => 'Add route';

  @override
  String panelFlightCount(String mode, int count) {
    return '$mode $count aircraft';
  }

  @override
  String get panelFlightFallback => 'Aircraft';

  @override
  String get panelFlightLegendClimb => 'Climb';

  @override
  String get panelFlightLegendCruise => 'Cruise';

  @override
  String get panelFlightLegendDescend => 'Descend';

  @override
  String get panelFlightLegendTakeoffLanding => 'Takeoff/Landing';

  @override
  String get panelRouteLines => 'Route lines';

  @override
  String get panelTrainPosition => 'Train positions';

  @override
  String get panelStationDisplay => 'Station display';

  @override
  String get panelSelectRoutesToShow => 'Pick routes to show';

  @override
  String get panelAll => 'All';

  @override
  String get panelPresetHigh => 'High';

  @override
  String get panelPresetMedium => 'Medium';

  @override
  String get panelPresetLow => 'Low';

  @override
  String get panelFps => 'FPS';

  @override
  String get panelNaverPolling => 'Naver polling';

  @override
  String panelRenderInfo(String engine) {
    return 'Rendering: $engine · GeoJSON cache';
  }

  @override
  String get panelLightAuto => 'Auto';

  @override
  String get panelLightDay => 'Day';

  @override
  String get panelLightNight => 'Night';

  @override
  String get panelLightDawn => 'Dawn';

  @override
  String get panelLightDusk => 'Dusk';

  @override
  String get panelTierFlagship => 'Flagship';

  @override
  String get panelTierHigh => 'High';

  @override
  String get panelTierMid => 'Mid';

  @override
  String get panelTierLow => 'Low';

  @override
  String get panelMapEngine => 'Map engine';

  @override
  String get panelDevice => 'Device';

  @override
  String get panelPerfTier => 'Performance tier';

  @override
  String get mapDisplay3D => '3D buildings';

  @override
  String get mapDisplayPois => 'POI icons';

  @override
  String get mapDisplayWeather => 'Weather effects (fog/rain)';

  @override
  String get mapDisplayLiveSubway => 'Live subway';

  @override
  String get friendsGroupTooltip => 'Friend groups';

  @override
  String get friendsCodeTooltip => 'Friend code';

  @override
  String get friendsAddByNickname => 'Add a friend by nickname';

  @override
  String get friendsSearchPlaceholder => 'Enter a nickname to search';

  @override
  String get friendsSearching => 'Searching…';

  @override
  String get friendsSearch => 'Search';

  @override
  String friendsNotFound(String query) {
    return 'No user matches \"$query\"';
  }

  @override
  String get friendsSearchHint =>
      'Nicknames must match exactly. You can also try the 8-char friend code.';

  @override
  String friendsReceivedRequests(int count) {
    return 'Received requests ($count)';
  }

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsReject => 'Reject';

  @override
  String friendsMyFriends(int count) {
    return 'My friends ($count)';
  }

  @override
  String get friendsEmpty => 'No friends yet. Add by nickname.';

  @override
  String get friendsCooldownTooltip =>
      'Rejected requests can be re-sent after 7 days';

  @override
  String friendsCooldownDays(int days) {
    return 'Retry in ${days}d';
  }

  @override
  String friendsCooldownHours(int hours) {
    return 'Retry in ${hours}h';
  }

  @override
  String get friendsBadgeFriend => 'Friend';

  @override
  String get friendsBadgeRequested => 'Requested';

  @override
  String get friendsApply => 'Apply';

  @override
  String friendsSendingRequestHint(String nickname) {
    return 'Send friend request to $nickname — they get a push if accepted';
  }

  @override
  String friendsDmStartFailed(String error) {
    return 'Couldn\'t start DM: $error';
  }

  @override
  String get friendsUnfriend => 'Unfriend';

  @override
  String get friendsReport => 'Report';

  @override
  String get friendsBlock => 'Block';

  @override
  String get friendsBlockDialogTitleFallback => 'Block this user';

  @override
  String friendsBlockDialogTitle(String nickname) {
    return 'Block $nickname';
  }

  @override
  String get friendsBlockDialogBody =>
      'Blocking prevents joining the same room and hides their messages.';

  @override
  String get friendsBlockConfirm => 'Block';

  @override
  String get friendsUnknown => 'Unknown';

  @override
  String friendsRequestSent(String nickname) {
    return 'Friend request sent to $nickname';
  }

  @override
  String friendsFailure(String error) {
    return 'Failed: $error';
  }

  @override
  String get friendsSuggestionsTitle =>
      'Friend suggestions (friends of friends)';

  @override
  String friendsMutualCount(int count) {
    return '$count mutual';
  }

  @override
  String get friendsAddShort => 'Add';

  @override
  String get searchRouteNotFound =>
      'Couldn\'t find a route. Check the start and end points.';

  @override
  String get searchLocationUnavailable =>
      'Couldn\'t get your current location. Check location permission and GPS.';

  @override
  String get searchTabRoute => 'Directions';

  @override
  String get searchTabProfile => 'Profile';

  @override
  String get searchPathTypeOptimal => 'Optimal';

  @override
  String get searchPathTypeShortest => 'Shortest';

  @override
  String get searchPathTypeMinTransfer => 'Min transfers';

  @override
  String get searchOutsideServiceTitle => 'Outside service area';

  @override
  String get searchOutsideServiceBody =>
      'Directions currently support Seoul · Incheon · Gyeonggi only. Please pick a start or end inside the metro region.';

  @override
  String get searchDepartureFieldHint => 'From';

  @override
  String get searchArrivalFieldHint => 'To';

  @override
  String get searchSwapDepArr => 'Swap from/to';

  @override
  String get searchCloseTooltip => 'Close directions';

  @override
  String get searchPlaceholder => 'Search places · bus · subway';

  @override
  String get searchClearLabel => 'Clear search';

  @override
  String get searchRecentTitle => 'Recent searches';

  @override
  String get searchRecentClearAll => 'Clear all';

  @override
  String get searchRecentRoutesTitle => 'Recent directions';

  @override
  String get searchBusTypeTrunk => 'Trunk';

  @override
  String get searchBusTypeBranch => 'Branch';

  @override
  String get searchBusTypeCircular => 'Circular';

  @override
  String get searchBusTypeMetro => 'Metro';

  @override
  String get searchBusTypeIncheon => 'Incheon';

  @override
  String get searchBusTypeGyeonggi => 'Gyeonggi';

  @override
  String get searchBusTypeDefault => 'Bus';

  @override
  String get searchCatFood => 'Food';

  @override
  String get searchCatCafe => 'Café';

  @override
  String get searchCatPark => 'Park';

  @override
  String get searchCatShopping => 'Shopping';

  @override
  String get searchCatMedical => 'Medical';

  @override
  String get searchCatEducation => 'Education';

  @override
  String get searchCatLodging => 'Lodging';

  @override
  String get searchCatFinance => 'Finance';

  @override
  String get searchCatTransit => 'Transit';

  @override
  String get searchCatAddress => 'Address';

  @override
  String get searchCatCity => 'City';

  @override
  String get searchCatNeighborhood => 'Neighborhood';

  @override
  String get searchCatRoad => 'Road';

  @override
  String liveBadgePeerTrack(String nickname, String track) {
    return '$nickname is listening to $track';
  }

  @override
  String liveBadgeSharing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'people',
      one: 'person',
    );
    return 'Sharing with $count $_temp0';
  }

  @override
  String get liveBadgeStopped => 'Stopped location sharing';

  @override
  String get seoulLiveStartTitle => 'Seoul Live started';

  @override
  String get seoulLiveStartBody => 'Your map just expanded to the world.';

  @override
  String get seoulLiveStep2Title => 'Your friends\' pins appear on the map';

  @override
  String get seoulLiveStep2Body =>
      'Members of the same friend room show up as pins (nickname + emoji) in real time. Their pin moves as they move.';

  @override
  String get seoulLiveStep3Title => 'Meet up by friend room code';

  @override
  String get seoulLiveStep3Body =>
      'Open Profile → Seoul Live → Friend Room to create a new room or join with a 6-digit invite code. Capacity is 8.';

  @override
  String get seoulLiveStep4Title => 'Meetup alerts within 50m';

  @override
  String get seoulLiveStep4Body =>
      'Haptics and a notification fire when you get close. Auto-logged to chat.';

  @override
  String get seoulLiveStep5Title => 'Go private anytime';

  @override
  String get seoulLiveStep5Body =>
      'Tap the \"Sharing\" badge at the top to switch to ghost mode instantly. Leaving a friend room also stops sending.';

  @override
  String get seoulLivePermTitle => 'Get notifications';

  @override
  String get seoulLivePermBody =>
      'We\'ll send a push when friend requests, new messages, or meetups happen. Tap \"Allow\" below.';

  @override
  String get seoulLivePermAllowed => '✓ Notifications allowed';

  @override
  String get seoulLivePermDenied => 'Denied — you can allow it from Settings';

  @override
  String get seoulLivePermRequesting => 'Requesting…';

  @override
  String get seoulLivePermAllow => 'Allow notifications';

  @override
  String get roomMembersEmpty => 'No one nearby yet';

  @override
  String roomMembersWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'friends',
      one: 'friend',
    );
    return '$count $_temp0 here';
  }

  @override
  String get roomMembersGhost => 'Private';

  @override
  String get roomMembersDisconnected => 'Disconnected';

  @override
  String get roomMembersRealtime => 'Live';

  @override
  String get roomMembersStale => 'Briefly out';

  @override
  String get dmListAgoJust => 'Now';

  @override
  String dmListAgoMin(int min) {
    return '${min}m';
  }

  @override
  String dmListAgoHour(int hour) {
    return '${hour}h';
  }

  @override
  String dmListAgoDay(int day) {
    return '${day}d';
  }

  @override
  String get dmListKindVoice => '🎙 Voice';

  @override
  String get dmListKindImage => '🖼 Photo';

  @override
  String get dmListKindPlace => '📍 Place';

  @override
  String get dmListKindSpotify => '🎵 Track';

  @override
  String get dmListEmpty => 'No DMs yet';

  @override
  String get dmListEmptyHint =>
      'Open a friend and tap the message button to start';

  @override
  String get friendGroupsNewTitle => 'New group';

  @override
  String get friendGroupsNewTooltip => 'New group';

  @override
  String get friendGroupsEmpty => 'No groups yet';

  @override
  String get friendGroupsEmptyHint => 'Tap + above to group your friends';

  @override
  String get friendGroupsEmptyHintAlt =>
      'Create a group with + in the top-right to organize friends.';

  @override
  String get friendGroupsNamePlaceholder => 'e.g. Family, Work, Club';

  @override
  String get friendGroupsCreate => 'Create';

  @override
  String get friendGroupsCreated => 'Group created';

  @override
  String friendGroupsFailure(String error) {
    return 'Failed: $error';
  }

  @override
  String friendGroupsDeleteTitle(String emoji, String name) {
    return 'Delete $emoji $name';
  }

  @override
  String get friendGroupsDeleteBody =>
      'The group is deleted but friends are kept.';

  @override
  String get friendGroupsDelete => 'Delete';

  @override
  String get friendGroupsName => 'Name';

  @override
  String get friendGroupsIcon => 'Icon';

  @override
  String friendGroupsMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'members',
      one: 'member',
    );
    return '$count $_temp0';
  }

  @override
  String get friendGroupsNoFriendsPrompt => 'Add friends first.';

  @override
  String get friendGroupsVisibilityHint =>
      'Used for group-based visibility / chat';

  @override
  String friendGroupsMembersTitle(String emoji, String name) {
    return '$emoji $name members';
  }

  @override
  String get friendGroupsEditMembers => 'Edit members';

  @override
  String get friendGroupsEmptyFriendsBox => 'No friends yet';

  @override
  String get loginRequiredTitle => 'Sign-in required';

  @override
  String get loginRequiredBody =>
      'Multiplayer is for signed-in users only.\nGuest (anonymous) accounts auto-delete after 30 days of inactivity,\nso friend/room data may be lost.';

  @override
  String get loginRequiredCta => 'Sign in';

  @override
  String get reportReasonSpam => 'Spam / Ads';

  @override
  String get reportReasonHate => 'Abuse / hate speech';

  @override
  String get reportReasonSexual => 'Sexual / disturbing content';

  @override
  String get reportReasonHarass => 'Harassment / stalking';

  @override
  String get reportReasonFakeLocation => 'Fake location / impersonation';

  @override
  String get reportReasonMinorAbuse => 'Minor safety violation';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportSelectReason => 'Please pick a reason.';

  @override
  String get reportSubmitted => 'Report received. Reviewed within 24h.';

  @override
  String reportTitleUser(String label) {
    return 'Report $label';
  }

  @override
  String get reportTitleMessage => 'Report message';

  @override
  String get reportNote =>
      'Our ops team reviews and takes action within 24 hours.';

  @override
  String get reportExtraPlaceholder => 'Add details (optional)';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String get reportSubmitting => 'Sending…';

  @override
  String get reportFallbackUser => 'user';

  @override
  String get blockedUsersTitle => 'Blocked';

  @override
  String get blockedUsersEmpty => 'No blocked users';

  @override
  String blockedUsersUnblockTitle(String name) {
    return 'Unblock $name';
  }

  @override
  String get blockedUsersUnblockBody =>
      'Unblocking lets you meet them again and see their messages.';

  @override
  String get blockedUsersUnblockConfirm => 'Unblock';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityCatMeetup => '🎉 Meetup';

  @override
  String get activityCatFriend => '🤝 Friend';

  @override
  String get activityCatRoomJoined => '🚪 Room joined';

  @override
  String get activityCatPlaceShared => '📍 Place shared';

  @override
  String get activityCatDestination => '🎯 Destination';

  @override
  String get activityAgoJust => 'Now';

  @override
  String activityAgoMin(int min) {
    return '$min min ago';
  }

  @override
  String activityAgoHour(int hour) {
    return '${hour}h ago';
  }

  @override
  String activityAgoDay(int day) {
    return '${day}d ago';
  }

  @override
  String get activityRanking => 'Friend ranking';

  @override
  String get activityRecent => 'Recent activity';

  @override
  String get activityEmpty => 'No activity recorded yet';

  @override
  String activityCode(String code) {
    return 'Code $code';
  }

  @override
  String get activityThisWeek => 'This week\'s activity';

  @override
  String activityTotalCount(int count) {
    return '$count total';
  }

  @override
  String get activityWeekdayMon => 'Mon';

  @override
  String get activityWeekdayTue => 'Tue';

  @override
  String get activityWeekdayWed => 'Wed';

  @override
  String get activityWeekdayThu => 'Thu';

  @override
  String get activityWeekdayFri => 'Fri';

  @override
  String get activityWeekdaySat => 'Sat';

  @override
  String get activityWeekdaySun => 'Sun';

  @override
  String get peerNowPlayingBtnFriend => 'Friends ✓';

  @override
  String get peerNowPlayingBtnRequested => 'Requested';

  @override
  String get peerNowPlayingBtnAccept => 'Accept request';

  @override
  String get peerNowPlayingBtnSendRequest => 'Send friend request';

  @override
  String get peerNowPlayingOpenInSpotify => 'Open in Spotify';

  @override
  String get mapNoLocationPermission =>
      'Without location permission, friends can\'t see your pin. Open Settings → Location to allow.';

  @override
  String get mapLeftRoom => 'You left the friend room';

  @override
  String mapShowOnMap(String name) {
    return 'Show \"$name\" on the map';
  }

  @override
  String mapBuildingInside(String name) {
    return '🏢 You\'re inside $name';
  }

  @override
  String get mapLocationChecking => 'Locating…';

  @override
  String get mapLocationPermissionDenied =>
      'Location permission denied → iOS Settings → Seoul Vista → Location';

  @override
  String get mapLocationServiceOff =>
      'iOS Settings → Privacy → Location services is off';

  @override
  String get mapMyLocationMoved => 'Moved to your location';

  @override
  String mapLocationFetchFailed(String error) {
    return 'Couldn\'t get location: $error';
  }

  @override
  String get mapMapAppUnavailable => 'Couldn\'t open the maps app';

  @override
  String get mapTabRecommend => 'Explore';

  @override
  String get mapTabSave => 'Saved';

  @override
  String get mapTabMap => 'Map';

  @override
  String get mapTabWorld => 'World';

  @override
  String get mapTabTrip => 'Trip';

  @override
  String get mapDirectionsRoadFetching => 'Loading driving route…';

  @override
  String get mapDirectionsWalkFetching => 'Loading walking route…';

  @override
  String get mapNoCoords => 'Couldn\'t find start/end coordinates';

  @override
  String get mapDirectionsFailed => 'Couldn\'t load the route';

  @override
  String mapInsufficientSavedPlaces(int min) {
    return 'Need more places — once favorites/visits reach $min+, a course is generated automatically';
  }

  @override
  String get subwayPanelExpand => 'Expand panel';

  @override
  String get subwayPanelCollapse => 'Collapse panel';

  @override
  String subwayPanelDelayedTrains(int count) {
    return 'Delayed trains $count';
  }

  @override
  String subwayPanelMinutes(int min) {
    return '$min min';
  }

  @override
  String subwayPanelOthersCount(int count) {
    return 'and $count more…';
  }

  @override
  String get subwayPanelOffTapToStart => 'OFF — tap to start';

  @override
  String get subwayPanelMode => 'Mode';

  @override
  String get subwayPanelDemoLabel => 'Demo (no API)';

  @override
  String get subwayPanelLiveLabel => 'Live';

  @override
  String get subwayPanelTrainsLabel => 'Trains';

  @override
  String subwayPanelTrainsValue(int count) {
    return '$count';
  }

  @override
  String get subwayPanelUpdate => 'Updated';

  @override
  String get subwayPanelToggleRoutes => 'Routes';

  @override
  String get subwayPanelToggleTrains => 'Train positions';

  @override
  String get subwayPanelToggleStations => 'Stations';

  @override
  String get subwayPanelToggleCongestion => 'Congestion';

  @override
  String get subwayPanelRouteFilter => 'Route filter';

  @override
  String get subwayPanelAll => 'All';

  @override
  String get subwayPanelToggleOn => 'Turn on subway visualization';

  @override
  String get subwayPanelToggleOff => 'Turn off subway visualization';

  @override
  String get subwayPanelNoArrivalInfo => 'No arrival info';

  @override
  String subwayPanelTrainDirection(String destination, String type) {
    return '$destination · $type';
  }

  @override
  String get subwayPanelCloseDetail => 'Close train detail';

  @override
  String subwayPanelTrainNo(String no) {
    return 'Train #$no';
  }

  @override
  String subwayPanelDelayedBadge(int min) {
    return '$min min delay';
  }

  @override
  String get subwayPanelLastTrainBadge => 'Last train';

  @override
  String subwayPanelTerminalDestination(String terminal) {
    return 'To $terminal';
  }

  @override
  String get subwayPanelPrevStation => 'Previous';

  @override
  String get subwayPanelDepartureStation => 'Departure';

  @override
  String get subwayPanelCurrentStation => 'Current';

  @override
  String get subwayPanelNextStation => 'Next';

  @override
  String get subwayPanelStateArriving => 'Arriving';

  @override
  String get subwayPanelStateStopped => 'Stopped';

  @override
  String get subwayPanelStateDeparted => 'Departed';

  @override
  String get subwayPanelStateMoving => 'Moving';

  @override
  String get subwayPanelStateOperating => 'In service';

  @override
  String get subwayPanelDirInnerLoop => 'Inner loop';

  @override
  String get subwayPanelDirOuterLoop => 'Outer loop';

  @override
  String get subwayPanelDirUp => 'Up';

  @override
  String get subwayPanelDirDown => 'Down';

  @override
  String get subwayPanelTrainTypeExpress => 'Express';

  @override
  String get subwayPanelTrainTypeSpecial => 'Special';

  @override
  String get subwayPanelTrainTypeRegular => 'Regular';

  @override
  String get searchTileSubway => 'Subway';

  @override
  String get profileEditNicknameInvalid =>
      'Please enter a nickname (1–20 chars).';

  @override
  String get profileEditBirthInvalid =>
      'Please enter a valid 4-digit birth year (YYYY).';

  @override
  String get profileEditAgeRestriction =>
      'Multiplayer is not available for users under 14.';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileEditSubtitle => 'This is how others see you in rooms.';

  @override
  String get profileEditNicknameLabel => 'Nickname (duplicates allowed)';

  @override
  String get profileEditNicknamePlaceholder => 'e.g. SeoulExplorer';

  @override
  String get profileEditBirthLabel => 'Birth year (14+ only)';

  @override
  String get profileEditBirthPlaceholder => 'e.g. 2000';

  @override
  String get profileEditEmojiLabel => 'Pin emoji';

  @override
  String get profileEditColorLabel => 'Pin color';

  @override
  String get profileEditVisibilityLabel => 'Location visibility';

  @override
  String get profileEditVisibilityGhost => 'Private';

  @override
  String get profileEditVisibilityFriends => 'Room';

  @override
  String get profileEditVisibilityGroup => 'Groups only';

  @override
  String get profileEditVisibilityPublic => 'Public';

  @override
  String get profileEditSaving => 'Saving…';

  @override
  String get profileEditSave => 'Save';

  @override
  String get profileEditPublicDialogTitle => 'Switch to public';

  @override
  String get profileEditPublicDialogBody =>
      'Your location becomes visible to all Seoul Live users in real time, including strangers.\n\n• Beware of inappropriate meetups / stalking risks\n• You can revert to Private/Room at any time\n• Block/report from the friend profile or chat menu';

  @override
  String get profileEditPublicDialogConfirm => 'Continue';

  @override
  String get profileEditVisibilityGhostDesc =>
      'Your location isn\'t sent. You can\'t see others\' locations either.';

  @override
  String get profileEditVisibilityFriendsDesc =>
      'Location is visible only to same-room members while you\'re in a room.';

  @override
  String get profileEditVisibilityGroupDesc =>
      'Only friends in the groups you pick can see your location.';

  @override
  String get profileEditVisibilityPublicDesc =>
      '⚠️ Any Seoul Live user can see your location. Also sent in rooms.';

  @override
  String get profileEditNoGroups =>
      'No groups yet. Create one in Friends → Groups.';

  @override
  String get adminMonitorTitle => 'Ops monitor';

  @override
  String get adminRefresh => 'Refresh';

  @override
  String get adminTabMetrics => 'Metrics';

  @override
  String get adminTabAbuse => 'Abuse';

  @override
  String get adminTabReports => 'Reports';

  @override
  String get adminMetricAllProfiles => 'All profiles';

  @override
  String get adminMetricActiveRooms => 'Active rooms';

  @override
  String get adminMetricTodayMeetups => 'Meetups today';

  @override
  String get adminMetricTodayBlocks => 'Blocks today';

  @override
  String get adminMetricTodayReports => 'Reports today';

  @override
  String get adminNoSuspiciousSignals =>
      'No suspicious signals (no user blocked by 3+ in 24h)';

  @override
  String adminRecentBlockCount(int count) {
    return 'Blocked by $count in 24h';
  }

  @override
  String get adminReportStatusPending => 'Pending';

  @override
  String get adminReportStatusReviewed => 'Reviewed';

  @override
  String get adminReportStatusActioned => 'Actioned';

  @override
  String get adminReportStatusDismissed => 'Dismissed';

  @override
  String get adminNoReports => 'No reports to show';

  @override
  String get adminReportTypeMessage => 'Message report';

  @override
  String get adminReportTypeUser => 'User report';

  @override
  String get adminReportActionReview => 'Review';

  @override
  String get adminReportActionAction => 'Action';

  @override
  String get adminReportActionDismiss => 'Dismiss';

  @override
  String adminAgoMin(int min) {
    return '$min min ago';
  }

  @override
  String adminAgoHour(int hour) {
    return '${hour}h ago';
  }

  @override
  String adminAgoDay(int day) {
    return '${day}d ago';
  }

  @override
  String get liveDiagTitle => 'Live diagnostics';

  @override
  String get liveDiagMyId => 'My ID';

  @override
  String get liveDiagVisibility => 'Visibility';

  @override
  String get liveDiagRoom => 'Room';

  @override
  String get liveDiagPeers => 'Peers receiving';

  @override
  String liveDiagPeersValue(int count) {
    return '$count';
  }

  @override
  String get liveDiagPresenceStatus => 'Presence status';

  @override
  String get liveDiagWorldStatus => 'World status';

  @override
  String get liveDiagLastSent => 'Last sent';

  @override
  String get liveDiagSendError => 'Send error';

  @override
  String get liveDiagGps => 'GPS';

  @override
  String get liveDiagPaused => 'Paused';

  @override
  String get liveDiagActivityFailCount => 'Activity fail count';

  @override
  String liveDiagActivityFailValue(int count) {
    return '$count';
  }

  @override
  String get liveDiagLastActivityError => 'Last activity error';

  @override
  String get liveDiagFooter => 'Capture this screen if there\'s an issue';

  @override
  String get liveDiagClose => 'Close';

  @override
  String get liveDiagNoProfile => '(no profile)';

  @override
  String get liveDiagNone => '(none)';

  @override
  String get liveDiagNotConnected => '(not connected)';

  @override
  String get liveDiagNotUsed => '(not used)';

  @override
  String get liveDiagNotSent => 'Not sent yet';

  @override
  String liveDiagSecondsAgo(int sec) {
    return '${sec}s ago';
  }

  @override
  String liveDiagRoomLabel(String code, int count) {
    return '$code ($count members)';
  }

  @override
  String get liveDiagGpsHas => 'yes';

  @override
  String get liveDiagGpsNo => 'no';

  @override
  String get mpConsentLocationDenied =>
      'Allow location permission in Settings > Location.';

  @override
  String get mpConsentTitle => 'Before starting multiplayer';

  @override
  String get mpConsentHeading => 'Seoul Live consent';

  @override
  String get mpConsentBody =>
      'To share your location with friends, you need to agree to the items below. Each item can be agreed/declined separately and revoked any time in Settings.';

  @override
  String get mpConsentItem1Title => '[Required] Profile data';

  @override
  String get mpConsentItem1Detail =>
      'Nickname, pin color/emoji, birth year. For service identification and 14+ age check. Retained until account deletion; deleted immediately on withdrawal.';

  @override
  String get mpConsentItem2Title => '[Required] Location data (LBS Act §18)';

  @override
  String get mpConsentItem2Detail =>
      'GPS coordinates and direction. Shared in real time with room members or, when set to public, all Seoul Live users. Not stored persistently — ephemeral over Realtime channels. Visibility (private/room/public) can be changed any time in your profile.';

  @override
  String get mpConsentItem3Title => '[Required] LBS terms of service';

  @override
  String get mpConsentItem3Detail =>
      'Provided by a KCC-registered operator. Not available to users under 14.';

  @override
  String get mpConsentItem3Link => 'Read the full terms';

  @override
  String get mpConsentDeclineNote =>
      'Declining only disables multiplayer; the rest of the app works normally.';

  @override
  String get mpConsentBackgroundNote =>
      'Location sharing auto-pauses when the app goes to the background (battery saver).';

  @override
  String get mpConsentSubmit => 'Agree and start';

  @override
  String get mpConsentLaterButton => 'Later';

  @override
  String get mpConsentSubmitBusy => 'Processing…';

  @override
  String get mpConsentLbsTermsBody =>
      'These terms govern the use of the location-based service (\"Service\") provided by Seoul Vista\'s Seoul Live.';

  @override
  String get optTitle => 'Tuned to your device';

  @override
  String get optSubtitle =>
      'Real-time visualization is GPU-intensive.\nPick what fits your device.';

  @override
  String get optPresetHighTitle => 'High quality';

  @override
  String get optPresetHighDetail => '60 fps · 5s refresh · AA on';

  @override
  String get optPresetSmoothTitle => 'Smooth';

  @override
  String get optPresetSmoothDetail => '30 fps · 10s refresh';

  @override
  String get optPresetBatteryTitle => 'Battery saver';

  @override
  String get optPresetBatteryDetail => '20 fps · 30s refresh · effects off';

  @override
  String get optAdvancedTitle => 'Advanced — pick layers';

  @override
  String get optLayerSubway => 'Subway (live train positions)';

  @override
  String get optLayerSubwaySub => 'Seoul subway + metro rail. Highest GPU load';

  @override
  String get optLayerBus => 'City bus';

  @override
  String get optLayerBusSub => 'Seoul + Gyeonggi city bus live positions';

  @override
  String get optLayerRiverBus => 'Han River bus';

  @override
  String get optLayerRiverBusSub => 'Han River ferries';

  @override
  String get optLayerFlights => 'Aircraft';

  @override
  String get optLayerFlightsSub => 'Live aircraft around Incheon airport';

  @override
  String optDetectedTier(String tier) {
    return 'Detected as $tier tier';
  }

  @override
  String get optRecommended => 'Recommended';

  @override
  String get vehicleCongestion => 'Crowdedness';

  @override
  String get vehicleCongestionNone => 'No data';

  @override
  String get vehicleCongestionFree => 'Light';

  @override
  String get vehicleCongestionNormal => 'Normal';

  @override
  String get vehicleCongestionBusy => 'Busy';

  @override
  String get vehicleCongestionPacked => 'Very crowded';

  @override
  String get vehicleCongestionFull => 'Full';

  @override
  String get vehicleStatus => 'Status';

  @override
  String get vehicleStopped => 'Stopped';

  @override
  String get vehicleRunning => 'Running';

  @override
  String get vehicleSection => 'Section';

  @override
  String vehicleSectionOrd(int ord) {
    return 'Stop $ord';
  }

  @override
  String get vehicleBusLowFloor => 'Low-floor';

  @override
  String get vehicleBusRegular => 'Standard';

  @override
  String get vehiclePhaseAscent => 'Climbing';

  @override
  String get vehiclePhaseCruise => 'Cruise';

  @override
  String get vehiclePhaseDescent => 'Descent';

  @override
  String get vehiclePhaseTakeoff => 'Takeoff/landing';

  @override
  String get vehiclePhaseGround => 'On ground';

  @override
  String get vehicleAltitude => 'Altitude';

  @override
  String get vehicleAltitudeOnGround => 'Ground';

  @override
  String get vehicleSpeed => 'Speed';

  @override
  String get vehicleHeading => 'Heading';

  @override
  String vehicleRiverBusRoute(String name) {
    return 'Han River bus $name';
  }

  @override
  String get vehicleRiverDirNormal => 'Forward';

  @override
  String get vehicleRiverDirReverse => 'Reverse';

  @override
  String get vehicleRiverPhaseStop => 'Docked';

  @override
  String get vehicleNext => 'Next';

  @override
  String get vehicleProgress => 'Progress';

  @override
  String get deepLinkRoomLoginRequired => 'Sign in to join a friend room';

  @override
  String deepLinkRoomEntered(String code) {
    return 'Joined room — code $code';
  }

  @override
  String deepLinkRoomFailure(String error) {
    return 'Couldn\'t join the room: $error';
  }

  @override
  String get snsAnalysisTitle => 'Analysis';

  @override
  String get snsAnalysisEmpty => 'No places extracted';

  @override
  String snsAnalysisCreatePlans(int count) {
    return 'Create plan ($count)';
  }

  @override
  String snsAnalysisPlanFailure(String error) {
    return 'Couldn\'t build a plan: $error';
  }

  @override
  String snsAnalysisNearestStation(String station, int minutes) {
    return '📍 $station station · $minutes min';
  }

  @override
  String get avatarMyPin => 'My pin';

  @override
  String get avatarNoRoomHint => 'Join a friend room to see friends here';

  @override
  String get avatarNoRoomMembers => 'No one\'s with you yet';

  @override
  String avatarRoomMembersCount(int count) {
    return 'With you · $count';
  }

  @override
  String get avatarNoTrack => 'Not listening to anything';

  @override
  String get qrScanTitle => 'Scan QR';

  @override
  String qrScanCameraError(String error) {
    return 'Camera unavailable\n$error';
  }

  @override
  String get qrScanHint => 'Frame your friend\'s QR code';

  @override
  String get buildingOccupantsFallbackName => 'Building';

  @override
  String buildingOccupantsInside(int count) {
    return '$count inside';
  }

  @override
  String get buildingOccupantsEmpty => 'Everyone left the building';

  @override
  String buildingOccupantsListening(String name, String artist) {
    return '🎵 Listening to $name · $artist';
  }

  @override
  String get buildingOccupantsInBuilding => '🏢 Inside the building';

  @override
  String get weatherWeeklyLabel => 'Weekly';

  @override
  String get weatherToday => 'Today';

  @override
  String get weatherDayMon => 'Mon';

  @override
  String get weatherDayTue => 'Tue';

  @override
  String get weatherDayWed => 'Wed';

  @override
  String get weatherDayThu => 'Thu';

  @override
  String get weatherDayFri => 'Fri';

  @override
  String get weatherDaySat => 'Sat';

  @override
  String get weatherDaySun => 'Sun';

  @override
  String get locPermTitle => 'Location permission needed';

  @override
  String get locPermBody =>
      'We need location access to show your position on the map\nand to provide accurate nearby info / directions.';

  @override
  String get locPermRequesting => 'Requesting…';

  @override
  String get locPermRequest => 'Allow location';

  @override
  String get locPermGranted => '✓ Location allowed';

  @override
  String get locPermDenied => 'Denied — enable it from Settings';

  @override
  String get locPermRetry => 'Retry';

  @override
  String get groupEditorTitle => 'Friend groups';

  @override
  String get groupEditorNew => 'New group';

  @override
  String get groupEditorEmpty => 'No groups yet';

  @override
  String get groupEditorEmptyHint =>
      'Tap + at top-right to create a group and organize friends.';

  @override
  String get groupEditorHelper => 'Used for group-based visibility / chat';

  @override
  String get groupEditorNamePlaceholder => 'e.g. Family, Work, Club';

  @override
  String get groupEditorCreate => 'Create';

  @override
  String groupEditorFailure(String error) {
    return 'Failed: $error';
  }

  @override
  String groupEditorMemberCount(int count) {
    return '$count';
  }

  @override
  String groupEditorDeleteTitle(String name) {
    return 'Delete group $name';
  }

  @override
  String get groupEditorDeleteBody =>
      'Only the group is deleted; friends are kept.';

  @override
  String get groupEditorDelete => 'Delete';

  @override
  String get groupEditorAddFriendsHint => 'Add friends first.';

  @override
  String get peerPinDestinationFallback => 'Destination';

  @override
  String peerPinDestinationLabel(String name) {
    return '🎯 $name';
  }

  @override
  String get stationDetailCloseLabel => 'Close station detail';

  @override
  String get stationDetailDeparture => 'Start';

  @override
  String get stationDetailArrival => 'End';

  @override
  String get stationDetailLiveArrivals => 'Live arrivals';

  @override
  String get stationDetailLoading => 'Loading…';

  @override
  String get stationDetailNoArrivals => 'No arrival info';

  @override
  String get stationDetailCrowdVery => 'Very crowded';

  @override
  String get stationDetailCrowdBusy => 'Crowded';

  @override
  String get stationDetailCrowdNormal => 'Normal';

  @override
  String get stationDetailCrowdFree => 'Light';

  @override
  String stationDetailBoardingCount(String count) {
    return 'Boarding $count';
  }

  @override
  String stationDetailAlightingCount(String count) {
    return 'Alighting $count';
  }

  @override
  String stationDetailClosureCount(int count) {
    return '$count closures';
  }

  @override
  String get visitTimelineTitle => 'My footprints';

  @override
  String visitTimelineSummary(int count, String ago) {
    return '$count places · last visit $ago';
  }

  @override
  String get visitTimelineEmpty => 'No visit history yet.';

  @override
  String get visitTimelineClose => 'Close';

  @override
  String visitTimelineExpand(int count) {
    return 'Show $count more';
  }

  @override
  String get visitTimelineCollapse => 'Collapse';

  @override
  String get visitTimelineDateToday => 'Today';

  @override
  String get visitTimelineDateYesterday => 'Yesterday';

  @override
  String visitTimelineDateDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String visitTimelineDateMonthDay(int month, int day) {
    return '$month/$day';
  }

  @override
  String get visitTimelineAgoNone => '—';

  @override
  String visitTimelineAgoMin(int min) {
    return '$min min ago';
  }

  @override
  String visitTimelineAgoHour(int hour) {
    return '${hour}h ago';
  }

  @override
  String visitTimelineAgoDay(int day) {
    return '${day}d ago';
  }

  @override
  String visitTimelineVisitCount(int count) {
    return '$count×';
  }

  @override
  String get permPageTitle => 'Permissions';

  @override
  String get permPageBody =>
      'Grant these up front\nso the app doesn\'t stop mid-flow.';

  @override
  String get permPageFooter =>
      'Denying is fine — only that feature is limited.';

  @override
  String get permPageRequesting => 'Requesting…';

  @override
  String get permPageAllGranted => '✓ All allowed';

  @override
  String get permPageRequestAll => 'Allow all';

  @override
  String get permItemLocation => 'Location';

  @override
  String get permItemLocationDesc =>
      'Show your pin on the map + live share in rooms';

  @override
  String get permItemNotification => 'Notifications';

  @override
  String get permItemNotificationDesc =>
      'Friend requests / chat / meetup alerts';

  @override
  String get permItemCamera => 'Camera';

  @override
  String get permItemCameraDesc => 'Place photo analysis + chat photos';

  @override
  String get permItemPhotos => 'Photos';

  @override
  String get permItemPhotosDesc => 'Share gallery photos in chat';

  @override
  String get permItemMicrophone => 'Microphone';

  @override
  String get permItemMicrophoneDesc => 'AI voice chat + voice messages';

  @override
  String permTapToSettings(String desc) {
    return '$desc (tap to open Settings)';
  }

  @override
  String get livingCityTitle => 'Seoul is alive';

  @override
  String get livingCityBody =>
      'Tap an icon and the camera flies to that scene.';

  @override
  String get livingCityVehSubway => 'Subway';

  @override
  String get livingCityVehBus => 'Bus';

  @override
  String get livingCityVehRiverBus => 'Han River bus';

  @override
  String get livingCityVehFlight => 'Aircraft';

  @override
  String get infoBarsTierFlagship => 'Flagship';

  @override
  String get infoBarsTierHigh => 'High';

  @override
  String get infoBarsTierMid => 'Mid';

  @override
  String get infoBarsTierLow => 'Low';

  @override
  String infoBarsProfileToast(String model, String tier, int fps, int pollMs) {
    return '$model · $tier\n$fps fps · ${pollMs}ms polling — optimized';
  }

  @override
  String get navBannerNext => 'Next';

  @override
  String navBannerWalkTo(String station) {
    return 'Walk to $station';
  }

  @override
  String navBannerBoardAt(String station, String line) {
    return 'Board $line at $station';
  }

  @override
  String navBannerWalkDetail(int min) {
    return '$min min walk';
  }

  @override
  String navBannerTransitDetail(String station, int min) {
    return 'Toward $station · $min min';
  }

  @override
  String get readyPageTitle => 'Ready';

  @override
  String get readyPageBody => 'Tap Start below\nand the live Seoul opens up.';

  @override
  String get welcomePageSubtitle => 'Seoul, in a new light';

  @override
  String get pathfindingPageTitle => 'What\'s the vibe today?';

  @override
  String get pathfindingPageBody =>
      'Your AI assistant will build a course around your mood.\nYou can change this anytime later.';

  @override
  String riverBusStopLabel(String name) {
    return '$name ferry pier';
  }

  @override
  String get riverBusRouteEnded => 'Service ended';

  @override
  String riverBusNextTime(String time) {
    return 'Next $time';
  }

  @override
  String get riverBusMaintenance => 'Maintenance';

  @override
  String get riverBusDeparture => 'Start';

  @override
  String get riverBusArrival => 'End';

  @override
  String get qualityPreviewDemoLabel => 'DEMO · Subway';

  @override
  String get qualityPresetHigh => 'High';

  @override
  String get qualityPresetMedium => 'Smooth';

  @override
  String get qualityPresetLow => 'Battery saver';

  @override
  String get qualityPresetHighDetail => '60 fps · effects on';

  @override
  String get qualityPresetMediumDetail => '30 fps · partial effects';

  @override
  String get qualityPresetLowDetail => '10 fps · effects off';
}
