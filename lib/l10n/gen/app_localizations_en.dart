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
  String get languageChangedTitle => 'Language changed';

  @override
  String get languageChangedBody =>
      'Restart the app to fully apply the new language. Restart now?';

  @override
  String get languageRestartNow => 'Restart';

  @override
  String get languageRestartLater => 'Later';

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
  String get settingsThemeChangedTitle => 'Theme changed';

  @override
  String settingsThemeChangedBody(String theme) {
    return 'Restart to fully apply $theme mode. Restart now?';
  }

  @override
  String get settingsRestartConfirm => 'Restart';

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
}
