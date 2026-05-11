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
}
