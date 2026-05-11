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
}
