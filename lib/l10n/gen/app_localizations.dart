import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// Application name shown in OS task switcher and onGenerateTitle.
  ///
  /// In en, this message translates to:
  /// **'Seoul Vista'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get commonLater;

  /// Label for the app-wide UI language picker in settings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsAppLanguageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageKo.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKo;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageJa.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJa;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @languageChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Language saved'**
  String get languageChangedTitle;

  /// No description provided for @languageChangedBody.
  ///
  /// In en, this message translates to:
  /// **'To fully apply the new language, please close the app (swipe up from the app switcher) and reopen it.'**
  String get languageChangedBody;

  /// No description provided for @routeUnitHour.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get routeUnitHour;

  /// No description provided for @routeUnitMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get routeUnitMin;

  /// No description provided for @routeTransfersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transfers'**
  String routeTransfersCount(int count);

  /// No description provided for @routeDeparture.
  ///
  /// In en, this message translates to:
  /// **'Depart'**
  String get routeDeparture;

  /// No description provided for @routeArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrive'**
  String get routeArrival;

  /// No description provided for @routeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get routeTransfer;

  /// No description provided for @routeTransferDetail.
  ///
  /// In en, this message translates to:
  /// **'{line} · {min} min'**
  String routeTransferDetail(String line, int min);

  /// No description provided for @routeBoardLine.
  ///
  /// In en, this message translates to:
  /// **'Board {line}'**
  String routeBoardLine(String line);

  /// No description provided for @routeSegmentBus.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to} · {count} stops · {min} min'**
  String routeSegmentBus(String from, String to, int count, int min);

  /// No description provided for @routeSegmentTrain.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to} · {count} stations · {min} min'**
  String routeSegmentTrain(String from, String to, int count, int min);

  /// No description provided for @routeSegmentShort.
  ///
  /// In en, this message translates to:
  /// **'{from} · {min} min'**
  String routeSegmentShort(String from, int min);

  /// No description provided for @routeShowStops.
  ///
  /// In en, this message translates to:
  /// **'Show stops ▼'**
  String get routeShowStops;

  /// No description provided for @routeCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse ▲'**
  String get routeCollapse;

  /// No description provided for @snsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Plan'**
  String get snsTitle;

  /// No description provided for @snsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build a Seoul day plan from social posts'**
  String get snsSubtitle;

  /// No description provided for @snsSectionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get snsSectionPhotos;

  /// No description provided for @snsSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get snsSectionDescription;

  /// No description provided for @snsSectionLink.
  ///
  /// In en, this message translates to:
  /// **'Social link'**
  String get snsSectionLink;

  /// No description provided for @snsTextHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us where you\'d like to go and what you\'d like to do'**
  String get snsTextHint;

  /// No description provided for @snsUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Instagram, TikTok URL'**
  String get snsUrlHint;

  /// No description provided for @snsAnalyzeButton.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get snsAnalyzeButton;

  /// No description provided for @snsAnalyzeError.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed: {error}'**
  String snsAnalyzeError(String error);

  /// No description provided for @snsImageGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get snsImageGallery;

  /// No description provided for @snsImageCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get snsImageCamera;

  /// No description provided for @dayPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Day plan'**
  String get dayPlanTitle;

  /// No description provided for @dayPlanNavigateAll.
  ///
  /// In en, this message translates to:
  /// **'Navigate all'**
  String get dayPlanNavigateAll;

  /// No description provided for @dayPlanTransitSummary.
  ///
  /// In en, this message translates to:
  /// **'🚇 {min} min'**
  String dayPlanTransitSummary(int min);

  /// No description provided for @dayPlanTransfersSummary.
  ///
  /// In en, this message translates to:
  /// **'🔄 {count}'**
  String dayPlanTransfersSummary(int count);

  /// No description provided for @dayPlanStyleStats.
  ///
  /// In en, this message translates to:
  /// **'{count} stops · {min} min'**
  String dayPlanStyleStats(int count, int min);

  /// No description provided for @dayPlanNavigateStop.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get dayPlanNavigateStop;

  /// No description provided for @whatsNewClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get whatsNewClose;

  /// No description provided for @whatsNewSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get whatsNewSkip;

  /// No description provided for @whatsNewStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get whatsNewStart;

  /// No description provided for @whatsNewNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get whatsNewNext;

  /// No description provided for @whatsNewPage1Title.
  ///
  /// In en, this message translates to:
  /// **'v{version} — Welcome back'**
  String whatsNewPage1Title(String version);

  /// No description provided for @whatsNewPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Your trips just got more personal.\nFrom travel moods to friends and memories —\nmeet 14 new features.'**
  String get whatsNewPage1Body;

  /// No description provided for @whatsNewPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Your travel mood'**
  String get whatsNewPage2Title;

  /// No description provided for @whatsNewPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Pick from Relax · Play · History · Mix and\nthe AI tone, recommendations, and Trip tab\nshift to match.'**
  String get whatsNewPage2Body;

  /// No description provided for @whatsNewPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Go together'**
  String get whatsNewPage3Title;

  /// No description provided for @whatsNewPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Set a shared destination in a friend room.\nDistances for each member update live.\nAn orange pin lands on the map.'**
  String get whatsNewPage3Body;

  /// No description provided for @whatsNewPage4Title.
  ///
  /// In en, this message translates to:
  /// **'1:1 DMs + voice/photo'**
  String get whatsNewPage4Title;

  /// No description provided for @whatsNewPage4Body.
  ///
  /// In en, this message translates to:
  /// **'Chat with a friend without a room.\n🎙 Long-press the mic for voice, 📷 pick a photo,\n📍 share a location — all in one chat.'**
  String get whatsNewPage4Body;

  /// No description provided for @whatsNewPage5Title.
  ///
  /// In en, this message translates to:
  /// **'Spotify sharing'**
  String get whatsNewPage5Title;

  /// No description provided for @whatsNewPage5Body.
  ///
  /// In en, this message translates to:
  /// **'Send what you\'re listening to.\nTap 🎵 in chat and your currently-playing\nSpotify track shares as a card.'**
  String get whatsNewPage5Body;

  /// No description provided for @whatsNewPage6Title.
  ///
  /// In en, this message translates to:
  /// **'More friends'**
  String get whatsNewPage6Title;

  /// No description provided for @whatsNewPage6Body.
  ///
  /// In en, this message translates to:
  /// **'Friend-of-friend suggestions,\nQR codes for instant adds,\nroom invite links for one-tap join.'**
  String get whatsNewPage6Body;

  /// No description provided for @whatsNewPage7Title.
  ///
  /// In en, this message translates to:
  /// **'Activity becomes points'**
  String get whatsNewPage7Title;

  /// No description provided for @whatsNewPage7Body.
  ///
  /// In en, this message translates to:
  /// **'Earn points and badges from adds, meetups, and streaks.\nCompare with friends in the ranking,\nand review your week on a chart.'**
  String get whatsNewPage7Body;

  /// No description provided for @whatsNewPage8Title.
  ///
  /// In en, this message translates to:
  /// **'Your way'**
  String get whatsNewPage8Title;

  /// No description provided for @whatsNewPage8Body.
  ///
  /// In en, this message translates to:
  /// **'Toggle notifications by type,\nshare your location with only certain groups.\nSafety and privacy stay with you.'**
  String get whatsNewPage8Body;

  /// No description provided for @whatsNewPage9Title.
  ///
  /// In en, this message translates to:
  /// **'Routes, end to end'**
  String get whatsNewPage9Title;

  /// No description provided for @whatsNewPage9Body.
  ///
  /// In en, this message translates to:
  /// **'Subway, bus, and walking — all in one.\nTransfers, live arrivals, and station exits\nshow up where you need them.'**
  String get whatsNewPage9Body;

  /// No description provided for @whatsNewPage10Title.
  ///
  /// In en, this message translates to:
  /// **'Day plans, made for you'**
  String get whatsNewPage10Title;

  /// No description provided for @whatsNewPage10Body.
  ///
  /// In en, this message translates to:
  /// **'Turn your saved places into a day.\nEfficient, leisurely, or food-focused —\npick a style and go.'**
  String get whatsNewPage10Body;

  /// No description provided for @whatsNewPage11Title.
  ///
  /// In en, this message translates to:
  /// **'Speaks your language'**
  String get whatsNewPage11Title;

  /// No description provided for @whatsNewPage11Body.
  ///
  /// In en, this message translates to:
  /// **'Korean, English, Japanese, Chinese.\nThe AI assistant replies in the same.\nIt follows your device language.'**
  String get whatsNewPage11Body;

  /// No description provided for @whatsNewPage12Title.
  ///
  /// In en, this message translates to:
  /// **'Just ask out loud'**
  String get whatsNewPage12Title;

  /// No description provided for @whatsNewPage12Body.
  ///
  /// In en, this message translates to:
  /// **'Talk to the AI naturally.\nSearch, navigate, get picks — by voice.\nGemini Live listens and answers live.'**
  String get whatsNewPage12Body;

  /// No description provided for @profileCategoryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get profileCategoryFavorites;

  /// No description provided for @profileCategoryRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get profileCategoryRecent;

  /// No description provided for @profileCategoryFrequent.
  ///
  /// In en, this message translates to:
  /// **'Frequent'**
  String get profileCategoryFrequent;

  /// No description provided for @profileGuestName.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get profileGuestName;

  /// No description provided for @profileDefaultName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileDefaultName;

  /// No description provided for @profileSyncCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync across devices'**
  String get profileSyncCta;

  /// No description provided for @profileAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String profileAgoDays(int days);

  /// No description provided for @profileAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String profileAgoHours(int hours);

  /// No description provided for @profileAgoNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get profileAgoNow;

  /// No description provided for @profileVisitCount.
  ///
  /// In en, this message translates to:
  /// **'{count} visits'**
  String profileVisitCount(int count);

  /// No description provided for @profileEmptyFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get profileEmptyFavorites;

  /// No description provided for @profileEmptyVisits.
  ///
  /// In en, this message translates to:
  /// **'No visits yet'**
  String get profileEmptyVisits;

  /// No description provided for @profileCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get profileCollapse;

  /// No description provided for @profileMoreCount.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String profileMoreCount(int count);

  /// No description provided for @profileLiveShareBeta.
  ///
  /// In en, this message translates to:
  /// **'Real-time location & chat (Beta)'**
  String get profileLiveShareBeta;

  /// No description provided for @profileTimeline.
  ///
  /// In en, this message translates to:
  /// **'My timeline'**
  String get profileTimeline;

  /// No description provided for @profilePlaceCount.
  ///
  /// In en, this message translates to:
  /// **'{count} places'**
  String profilePlaceCount(int count);

  /// No description provided for @profileEmptyVisitsCta.
  ///
  /// In en, this message translates to:
  /// **'No visits yet. Explore places and try directions.'**
  String get profileEmptyVisitsCta;

  /// No description provided for @profileToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get profileToday;

  /// No description provided for @profileYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get profileYesterday;

  /// No description provided for @profileMonthDay.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String profileMonthDay(int month, int day);

  /// No description provided for @profileVisitTimes.
  ///
  /// In en, this message translates to:
  /// **'{count}×'**
  String profileVisitTimes(int count);

  /// No description provided for @profileEditName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get profileEditName;

  /// No description provided for @profileNewNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get profileNewNameHint;

  /// No description provided for @profileTagline.
  ///
  /// In en, this message translates to:
  /// **'Every moment in Seoul'**
  String get profileTagline;

  /// No description provided for @profileMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get profileMore;

  /// No description provided for @profileEmptyMapPlaces.
  ///
  /// In en, this message translates to:
  /// **'Your visits will appear on this map'**
  String get profileEmptyMapPlaces;

  /// No description provided for @profileRecentPlaceCount.
  ///
  /// In en, this message translates to:
  /// **'Last {count} places'**
  String profileRecentPlaceCount(int count);

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String chatSendFailed(String error);

  /// No description provided for @chatRoomDestSet.
  ///
  /// In en, this message translates to:
  /// **'🎯 Set as room destination'**
  String get chatRoomDestSet;

  /// No description provided for @chatActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String chatActionFailed(String error);

  /// No description provided for @chatMapAppUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the maps app'**
  String get chatMapAppUnavailable;

  /// No description provided for @chatMicPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get chatMicPermissionRequired;

  /// No description provided for @chatRecordStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start recording: {error}'**
  String chatRecordStartFailed(String error);

  /// No description provided for @chatRecordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short — press and hold to record'**
  String get chatRecordTooShort;

  /// No description provided for @chatRecordStopFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t stop recording: {error}'**
  String chatRecordStopFailed(String error);

  /// No description provided for @chatPhotoSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send photo: {error}'**
  String chatPhotoSendFailed(String error);

  /// No description provided for @chatSpotifyClientIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Spotify not set up — developer must add SPOTIFY_CLIENT_ID'**
  String get chatSpotifyClientIdMissing;

  /// No description provided for @chatSpotifyAuthRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Tap again after Spotify auth'**
  String get chatSpotifyAuthRetryHint;

  /// No description provided for @chatSpotifyAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Spotify connection failed: {error}'**
  String chatSpotifyAuthFailed(String error);

  /// No description provided for @chatMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get chatMyLocation;

  /// No description provided for @chatLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t fetch your location'**
  String get chatLocationUnavailable;

  /// No description provided for @chatDefaultRoomName.
  ///
  /// In en, this message translates to:
  /// **'Friend room'**
  String get chatDefaultRoomName;

  /// No description provided for @chatMembersInRoom.
  ///
  /// In en, this message translates to:
  /// **'{count} in the room'**
  String chatMembersInRoom(int count);

  /// No description provided for @chatRecordingHint.
  ///
  /// In en, this message translates to:
  /// **'Recording… release to send, drag up to cancel'**
  String get chatRecordingHint;

  /// No description provided for @chatRecordingPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'🎙 Recording'**
  String get chatRecordingPlaceholder;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get chatMessageHint;

  /// No description provided for @chatActionMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get chatActionMap;

  /// No description provided for @chatActionDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get chatActionDirections;

  /// No description provided for @chatActionRoomDest.
  ///
  /// In en, this message translates to:
  /// **'🎯 Room destination'**
  String get chatActionRoomDest;

  /// No description provided for @chatVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s voice'**
  String chatVoiceLabel(int seconds);

  /// No description provided for @chatPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Playback failed: {error}'**
  String chatPlaybackFailed(String error);

  /// No description provided for @chatEmptyTitleNamed.
  ///
  /// In en, this message translates to:
  /// **'{roomName} has started'**
  String chatEmptyTitleNamed(String roomName);

  /// No description provided for @chatEmptyTitleDefault.
  ///
  /// In en, this message translates to:
  /// **'The friend room is on'**
  String get chatEmptyTitleDefault;

  /// No description provided for @chatEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Say hi to your friends here, share your location,\nand plan where to go together.'**
  String get chatEmptyBody;

  /// No description provided for @chatStart.
  ///
  /// In en, this message translates to:
  /// **'Start the chat'**
  String get chatStart;

  /// No description provided for @chatReport.
  ///
  /// In en, this message translates to:
  /// **'Report this message'**
  String get chatReport;

  /// No description provided for @chatBlockDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {nickname}'**
  String chatBlockDialogTitle(String nickname);

  /// No description provided for @chatBlockDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Blocking removes them from the room and hides their messages.'**
  String get chatBlockDialogBody;

  /// No description provided for @chatBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chatBlockConfirm;

  /// No description provided for @chatUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get chatUnknownUser;

  /// No description provided for @spotifyOpenInApp.
  ///
  /// In en, this message translates to:
  /// **'Open in Spotify'**
  String get spotifyOpenInApp;

  /// No description provided for @spotifyShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed: {error}'**
  String spotifyShareFailed(String error);

  /// No description provided for @spotifyNoTrack.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing right now'**
  String get spotifyNoTrack;

  /// No description provided for @dmAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Can\'t access this conversation'**
  String get dmAccessDenied;

  /// No description provided for @dmSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String dmSendFailed(String error);

  /// No description provided for @dmDefaultPeer.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get dmDefaultPeer;

  /// No description provided for @dmEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Send the first message'**
  String get dmEmptyHint;

  /// No description provided for @dmMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get dmMessageHint;

  /// No description provided for @friendCodeLengthError.
  ///
  /// In en, this message translates to:
  /// **'Please enter an 8-character code.'**
  String get friendCodeLengthError;

  /// No description provided for @friendCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user matches that code.'**
  String get friendCodeNotFound;

  /// No description provided for @friendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to {nickname}.'**
  String friendRequestSent(String nickname);

  /// No description provided for @friendShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Add me on Seoul Live'**
  String get friendShareSubject;

  /// No description provided for @friendShareBody.
  ///
  /// In en, this message translates to:
  /// **'{nickname} sent you a Seoul Live friend code!\n\nCode: {code}\nAdd instantly: com.seoul.prism://friend/{code}'**
  String friendShareBody(String nickname, String code);

  /// No description provided for @friendShareCopied.
  ///
  /// In en, this message translates to:
  /// **'Share text copied'**
  String get friendShareCopied;

  /// No description provided for @friendCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend code'**
  String get friendCodeTitle;

  /// No description provided for @friendCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your code, or add a friend\'s.'**
  String get friendCodeSubtitle;

  /// No description provided for @friendMyCode.
  ///
  /// In en, this message translates to:
  /// **'My friend code'**
  String get friendMyCode;

  /// No description provided for @friendCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get friendCodeCopied;

  /// No description provided for @friendQrHint.
  ///
  /// In en, this message translates to:
  /// **'Friends can scan with their camera to add you'**
  String get friendQrHint;

  /// No description provided for @friendShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get friendShareButton;

  /// No description provided for @friendAddByCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a friend by code'**
  String get friendAddByCodeTitle;

  /// No description provided for @friendAddByCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter an 8-character code or scan a QR'**
  String get friendAddByCodeHint;

  /// No description provided for @friendCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. AB12CD34'**
  String get friendCodePlaceholder;

  /// No description provided for @friendSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send friend request'**
  String get friendSendRequest;

  /// No description provided for @peerFriendCode.
  ///
  /// In en, this message translates to:
  /// **'Friend code {code}'**
  String peerFriendCode(String code);

  /// No description provided for @peerOwnPin.
  ///
  /// In en, this message translates to:
  /// **'That\'s your own pin'**
  String get peerOwnPin;

  /// No description provided for @peerReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get peerReport;

  /// No description provided for @peerBlockDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {nickname}'**
  String peerBlockDialogTitle(String nickname);

  /// No description provided for @peerBlockDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Blocking removes them from this room and hides their messages and pins.'**
  String get peerBlockDialogBody;

  /// No description provided for @peerBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get peerBlockConfirm;

  /// No description provided for @peerBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get peerBlock;

  /// No description provided for @peerIsFriend.
  ///
  /// In en, this message translates to:
  /// **'Friends ✓'**
  String get peerIsFriend;

  /// No description provided for @peerCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get peerCancelRequest;

  /// No description provided for @peerRequestCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled the request to {nickname}'**
  String peerRequestCanceled(String nickname);

  /// No description provided for @peerAcceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Accept friend request'**
  String get peerAcceptRequest;

  /// No description provided for @peerNowFriend.
  ///
  /// In en, this message translates to:
  /// **'You\'re now friends with {nickname}'**
  String peerNowFriend(String nickname);

  /// No description provided for @peerCanRequestInDays.
  ///
  /// In en, this message translates to:
  /// **'Can request again in {days}d'**
  String peerCanRequestInDays(int days);

  /// No description provided for @peerCanRequestInHours.
  ///
  /// In en, this message translates to:
  /// **'Can request again in {hours}h'**
  String peerCanRequestInHours(int hours);

  /// No description provided for @peerSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send friend request'**
  String get peerSendRequest;

  /// No description provided for @peerRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to {nickname}'**
  String peerRequestSent(String nickname);

  /// No description provided for @peerDistanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String peerDistanceMeters(int meters);

  /// No description provided for @peerDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String peerDistanceKm(String km);

  /// No description provided for @spotifyRoomRequired.
  ///
  /// In en, this message translates to:
  /// **'Join a friend room and try again'**
  String get spotifyRoomRequired;

  /// No description provided for @spotifyShareSuccess.
  ///
  /// In en, this message translates to:
  /// **'🎵 Shared with the room'**
  String get spotifyShareSuccess;

  /// No description provided for @spotifyDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Spotify'**
  String get spotifyDisconnectTitle;

  /// No description provided for @spotifyDisconnectBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the saved token and stops sharing tracks with friends.'**
  String get spotifyDisconnectBody;

  /// No description provided for @spotifyDisconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get spotifyDisconnectConfirm;

  /// No description provided for @spotifyDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Spotify disconnected'**
  String get spotifyDisconnected;

  /// No description provided for @spotifyAuthRetryHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll return automatically after Spotify auth'**
  String get spotifyAuthRetryHint;

  /// No description provided for @spotifyConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String spotifyConnectFailed(String error);

  /// No description provided for @spotifyClientIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Developer hasn\'t set SPOTIFY_CLIENT_ID'**
  String get spotifyClientIdMissing;

  /// No description provided for @spotifyTokenExpired.
  ///
  /// In en, this message translates to:
  /// **'Connection expired. Please log in again.'**
  String get spotifyTokenExpired;

  /// No description provided for @spotifyReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect Spotify'**
  String get spotifyReconnect;

  /// No description provided for @spotifyConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect Spotify'**
  String get spotifyConnect;

  /// No description provided for @spotifyConnectDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect to share what you\'re listening to in friend rooms,\nand see what your friends are playing.'**
  String get spotifyConnectDescription;

  /// No description provided for @spotifyLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in with Spotify'**
  String get spotifyLoginButton;

  /// No description provided for @spotifyShareToRoom.
  ///
  /// In en, this message translates to:
  /// **'Share with room'**
  String get spotifyShareToRoom;

  /// No description provided for @spotifyDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get spotifyDisconnect;

  /// No description provided for @spotifyConnectedNoTrack.
  ///
  /// In en, this message translates to:
  /// **'Spotify connected (no playback)'**
  String get spotifyConnectedNoTrack;

  /// No description provided for @spotifyNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get spotifyNowPlaying;

  /// No description provided for @departureTimePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Departure time'**
  String get departureTimePickerTitle;

  /// No description provided for @departureTimePickerHint.
  ///
  /// In en, this message translates to:
  /// **'Arrival time is calculated from this departure time.'**
  String get departureTimePickerHint;

  /// No description provided for @departureTimeNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get departureTimeNow;

  /// No description provided for @departureTime30min.
  ///
  /// In en, this message translates to:
  /// **'In 30 min'**
  String get departureTime30min;

  /// No description provided for @departureTime1hour.
  ///
  /// In en, this message translates to:
  /// **'In 1 hour'**
  String get departureTime1hour;

  /// No description provided for @departureTimeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get departureTimeCustom;

  /// No description provided for @placeActionDepart.
  ///
  /// In en, this message translates to:
  /// **'Depart'**
  String get placeActionDepart;

  /// No description provided for @placeActionArrive.
  ///
  /// In en, this message translates to:
  /// **'Arrive'**
  String get placeActionArrive;

  /// No description provided for @placeActionInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get placeActionInfo;

  /// No description provided for @placeDetailTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap for photos · reviews · hours'**
  String get placeDetailTapHint;

  /// No description provided for @savedPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedPanelTitle;

  /// No description provided for @savedEmptyFavorites.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet'**
  String get savedEmptyFavorites;

  /// No description provided for @savedRemoveFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get savedRemoveFavoriteTooltip;

  /// No description provided for @travelThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme suggestions'**
  String get travelThemeTitle;

  /// No description provided for @travelThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One tap to generate a course'**
  String get travelThemeSubtitle;

  /// No description provided for @travelTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get travelTitle;

  /// No description provided for @travelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From Gyeongbokgung to the Han River — we\'ll plan your day'**
  String get travelSubtitle;

  /// No description provided for @travelEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'This week\'s events'**
  String get travelEventsTitle;

  /// No description provided for @travelEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cultural events happening in Seoul'**
  String get travelEventsSubtitle;

  /// No description provided for @travelEventsCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String travelEventsCount(int count);

  /// No description provided for @travelEventsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load events. Pull down to retry.'**
  String get travelEventsLoadError;

  /// No description provided for @travelAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI plans your day'**
  String get travelAiTitle;

  /// No description provided for @travelAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Considers time · weather · routes'**
  String get travelAiSubtitle;

  /// No description provided for @travelFromSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Build from saved places'**
  String get travelFromSavedTitle;

  /// No description provided for @travelFromSavedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Course based on favorites + visit history'**
  String get travelFromSavedSubtitle;

  /// No description provided for @travelYourTheme.
  ///
  /// In en, this message translates to:
  /// **'Your theme'**
  String get travelYourTheme;

  /// No description provided for @travelStartWithMood.
  ///
  /// In en, this message translates to:
  /// **'Start with this mood'**
  String get travelStartWithMood;

  /// No description provided for @travelEventBadgeOngoing.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get travelEventBadgeOngoing;

  /// No description provided for @travelEventBadgeFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get travelEventBadgeFree;

  /// No description provided for @travelThemeStops.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String travelThemeStops(int count);

  /// No description provided for @travelMoodAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing track mood…'**
  String get travelMoodAnalyzing;

  /// No description provided for @travelMoodExcited.
  ///
  /// In en, this message translates to:
  /// **'For upbeat vibes,'**
  String get travelMoodExcited;

  /// No description provided for @travelMoodToday.
  ///
  /// In en, this message translates to:
  /// **'On a day like today,'**
  String get travelMoodToday;

  /// No description provided for @travelMoodIntense.
  ///
  /// In en, this message translates to:
  /// **'For intense beats,'**
  String get travelMoodIntense;

  /// No description provided for @travelMoodCalm.
  ///
  /// In en, this message translates to:
  /// **'For a calm mood,'**
  String get travelMoodCalm;

  /// No description provided for @travelTodayMoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s mood'**
  String get travelTodayMoodLabel;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'New updates will appear here'**
  String get notificationsEmptySubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionRealtime.
  ///
  /// In en, this message translates to:
  /// **'Real-time visualization'**
  String get settingsSectionRealtime;

  /// No description provided for @settingsLineSubway.
  ///
  /// In en, this message translates to:
  /// **'Subway lines'**
  String get settingsLineSubway;

  /// No description provided for @settingsTrainPos.
  ///
  /// In en, this message translates to:
  /// **'Subway trains'**
  String get settingsTrainPos;

  /// No description provided for @settingsStations.
  ///
  /// In en, this message translates to:
  /// **'Subway stations'**
  String get settingsStations;

  /// No description provided for @settingsBuses.
  ///
  /// In en, this message translates to:
  /// **'City buses'**
  String get settingsBuses;

  /// No description provided for @settingsRiverBus.
  ///
  /// In en, this message translates to:
  /// **'Han River bus'**
  String get settingsRiverBus;

  /// No description provided for @settingsFlights.
  ///
  /// In en, this message translates to:
  /// **'Aircraft'**
  String get settingsFlights;

  /// No description provided for @settingsSectionDataSource.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get settingsSectionDataSource;

  /// No description provided for @settingsSubwayMode.
  ///
  /// In en, this message translates to:
  /// **'Subway mode'**
  String get settingsSubwayMode;

  /// No description provided for @settingsSubwayModeLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get settingsSubwayModeLive;

  /// No description provided for @settingsSubwayModeDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get settingsSubwayModeDemo;

  /// No description provided for @settingsSeoulApi.
  ///
  /// In en, this message translates to:
  /// **'Seoul Open API (60s)'**
  String get settingsSeoulApi;

  /// No description provided for @settingsNaverApi.
  ///
  /// In en, this message translates to:
  /// **'Naver API (5s interp.)'**
  String get settingsNaverApi;

  /// No description provided for @settingsSectionLighting.
  ///
  /// In en, this message translates to:
  /// **'Lighting'**
  String get settingsSectionLighting;

  /// No description provided for @settingsAutoLighting.
  ///
  /// In en, this message translates to:
  /// **'Auto (time + weather)'**
  String get settingsAutoLighting;

  /// No description provided for @settingsLightPreset.
  ///
  /// In en, this message translates to:
  /// **'Light preset'**
  String get settingsLightPreset;

  /// No description provided for @settingsLightAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsLightAuto;

  /// No description provided for @settingsLightDawn.
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get settingsLightDawn;

  /// No description provided for @settingsLightDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get settingsLightDay;

  /// No description provided for @settingsLightDusk.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get settingsLightDusk;

  /// No description provided for @settingsLightNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get settingsLightNight;

  /// No description provided for @settingsCountValue.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String settingsCountValue(int count);

  /// No description provided for @settingsLabelFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get settingsLabelFavorites;

  /// No description provided for @settingsLabelVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get settingsLabelVisits;

  /// No description provided for @settingsLabelRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get settingsLabelRecentSearches;

  /// No description provided for @settingsAiAssistantLanguage.
  ///
  /// In en, this message translates to:
  /// **'AI assistant language'**
  String get settingsAiAssistantLanguage;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme saved'**
  String get settingsThemeChangedTitle;

  /// No description provided for @settingsThemeChangedBody.
  ///
  /// In en, this message translates to:
  /// **'To fully apply {theme} mode, please close the app (swipe up from the app switcher) and reopen it.'**
  String settingsThemeChangedBody(String theme);

  /// No description provided for @settingsRestartConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get settingsRestartConfirm;

  /// No description provided for @settingsMapHome.
  ///
  /// In en, this message translates to:
  /// **'Map home start'**
  String get settingsMapHome;

  /// No description provided for @settingsMapHomeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsMapHomeDefault;

  /// No description provided for @settingsMapHomeMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get settingsMapHomeMyLocation;

  /// No description provided for @settingsMapHomeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent search'**
  String get settingsMapHomeRecent;

  /// No description provided for @settingsKeepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get settingsKeepScreenOn;

  /// No description provided for @settingsAutoRotate.
  ///
  /// In en, this message translates to:
  /// **'Auto-rotate screen'**
  String get settingsAutoRotate;

  /// No description provided for @settingsAlwaysMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Always start directions from my location'**
  String get settingsAlwaysMyLocation;

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear all usage history'**
  String get settingsClearHistory;

  /// No description provided for @settingsClearSearchHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear recent searches'**
  String get settingsClearSearchHistory;

  /// No description provided for @settingsConvertAccount.
  ///
  /// In en, this message translates to:
  /// **'Convert to full account'**
  String get settingsConvertAccount;

  /// No description provided for @settingsEditNameItem.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get settingsEditNameItem;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsLogout;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsMapDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Map display & data'**
  String get settingsMapDataLabel;

  /// No description provided for @settingsSectionDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsSectionDeveloper;

  /// No description provided for @settingsDebugLogs.
  ///
  /// In en, this message translates to:
  /// **'Debug log output'**
  String get settingsDebugLogs;

  /// No description provided for @settingsResetTutorial.
  ///
  /// In en, this message translates to:
  /// **'Replay tutorial'**
  String get settingsResetTutorial;

  /// No description provided for @settingsReplayWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'Replay What\'s New'**
  String get settingsReplayWhatsNew;

  /// No description provided for @settingsWhatsNewToast.
  ///
  /// In en, this message translates to:
  /// **'What\'s New will be shown on next app launch'**
  String get settingsWhatsNewToast;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersion;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsClearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear usage history'**
  String get settingsClearHistoryTitle;

  /// No description provided for @settingsClearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'All usage history will be deleted.\nThis cannot be undone.'**
  String get settingsClearHistoryBody;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @settingsClearedHistoryToast.
  ///
  /// In en, this message translates to:
  /// **'All usage history has been deleted'**
  String get settingsClearedHistoryToast;

  /// No description provided for @settingsClearSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear search history'**
  String get settingsClearSearchTitle;

  /// No description provided for @settingsClearSearchBody.
  ///
  /// In en, this message translates to:
  /// **'All recent searches will be deleted.'**
  String get settingsClearSearchBody;

  /// No description provided for @settingsClearedSearchToast.
  ///
  /// In en, this message translates to:
  /// **'Search history has been cleared'**
  String get settingsClearedSearchToast;

  /// No description provided for @settingsEditNameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get settingsEditNameDialogTitle;

  /// No description provided for @settingsEditNameDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a new name.'**
  String get settingsEditNameDialogBody;

  /// No description provided for @settingsEditNameConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settingsEditNameConfirm;

  /// No description provided for @settingsNewNameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get settingsNewNameDialogTitle;

  /// No description provided for @settingsChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePasswordTitle;

  /// No description provided for @settingsChangePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send the password reset link to {email}.'**
  String settingsChangePasswordBody(String email);

  /// No description provided for @settingsSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get settingsSendButton;

  /// No description provided for @settingsPasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Reset email has been sent'**
  String get settingsPasswordResetSent;

  /// No description provided for @settingsLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsLogoutTitle;

  /// No description provided for @settingsLogoutBody.
  ///
  /// In en, this message translates to:
  /// **'Sign out now?'**
  String get settingsLogoutBody;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your account and all data will be permanently deleted.\nThis cannot be undone.'**
  String get settingsDeleteAccountBody;

  /// No description provided for @settingsDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDeleteAccountConfirm;

  /// No description provided for @settingsDeleteError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during account deletion'**
  String get settingsDeleteError;

  /// No description provided for @settingsResetTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay tutorial'**
  String get settingsResetTutorialTitle;

  /// No description provided for @settingsResetTutorialBody.
  ///
  /// In en, this message translates to:
  /// **'Saved progress will be cleared and the tutorial will start over on next launch.'**
  String get settingsResetTutorialBody;

  /// No description provided for @settingsResetTutorialConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get settingsResetTutorialConfirm;

  /// No description provided for @settingsMapDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Map display & data'**
  String get settingsMapDisplayTitle;

  /// No description provided for @settingsSectionMapDisplay.
  ///
  /// In en, this message translates to:
  /// **'Map display'**
  String get settingsSectionMapDisplay;

  /// No description provided for @aiStatusSearchingCourse.
  ///
  /// In en, this message translates to:
  /// **'Searching course…'**
  String get aiStatusSearchingCourse;

  /// No description provided for @aiPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'Found {count} places! Check below.'**
  String aiPlacesFound(int count);

  /// No description provided for @aiStatusFindingInfo.
  ///
  /// In en, this message translates to:
  /// **'Looking it up…'**
  String get aiStatusFindingInfo;

  /// No description provided for @aiStatusAnalyzingImage.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image…'**
  String get aiStatusAnalyzingImage;

  /// No description provided for @aiNoPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'No places found.'**
  String get aiNoPlacesFound;

  /// No description provided for @aiAnalysisError.
  ///
  /// In en, this message translates to:
  /// **'Analysis error: {error}'**
  String aiAnalysisError(String error);

  /// No description provided for @aiSelectPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Please select a photo'**
  String get aiSelectPhotoHint;

  /// No description provided for @aiPhotoShoot.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get aiPhotoShoot;

  /// No description provided for @aiStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get aiStatusConnecting;

  /// No description provided for @aiStatusListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get aiStatusListening;

  /// No description provided for @aiStatusThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get aiStatusThinking;

  /// No description provided for @aiStatusSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get aiStatusSpeaking;

  /// No description provided for @aiStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get aiStatusIdle;

  /// No description provided for @aiStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get aiStatusReady;

  /// No description provided for @aiFoundPlacesHeader.
  ///
  /// In en, this message translates to:
  /// **'Found places ({count})'**
  String aiFoundPlacesHeader(int count);

  /// No description provided for @aiVoiceCommandHint.
  ///
  /// In en, this message translates to:
  /// **'\"Add a cafe\", \"Remove Gyeongbokgung\", \"Confirm this\" — try it'**
  String get aiVoiceCommandHint;

  /// No description provided for @aiPlaceStationDistance.
  ///
  /// In en, this message translates to:
  /// **'{station} stn · {minutes} min'**
  String aiPlaceStationDistance(String station, int minutes);

  /// No description provided for @aiDefaultSearch.
  ///
  /// In en, this message translates to:
  /// **'Seoul travel recommendations'**
  String get aiDefaultSearch;

  /// No description provided for @recommendTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendTitle;

  /// No description provided for @recommendSubtitleNearbyArea.
  ///
  /// In en, this message translates to:
  /// **'Popular near {area} right now'**
  String recommendSubtitleNearbyArea(String area);

  /// No description provided for @recommendSubtitleNearbyDefault.
  ///
  /// In en, this message translates to:
  /// **'Popular nearby right now'**
  String get recommendSubtitleNearbyDefault;

  /// No description provided for @recommendRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get recommendRefresh;

  /// No description provided for @recommendNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results nearby.\nTry again later.'**
  String get recommendNoResults;

  /// No description provided for @recommendRank.
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String recommendRank(int rank);

  /// No description provided for @recommendEventsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load cultural events.\nTry again later.'**
  String get recommendEventsLoadError;

  /// No description provided for @recommendStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get recommendStatusUpcoming;

  /// No description provided for @recommendBadgePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get recommendBadgePaid;

  /// No description provided for @recommendUniqueMood.
  ///
  /// In en, this message translates to:
  /// **'✨ Your own'**
  String get recommendUniqueMood;

  /// No description provided for @recommendTabFood.
  ///
  /// In en, this message translates to:
  /// **'🍜 Food'**
  String get recommendTabFood;

  /// No description provided for @recommendTabCafe.
  ///
  /// In en, this message translates to:
  /// **'☕️ Café'**
  String get recommendTabCafe;

  /// No description provided for @recommendTabShopping.
  ///
  /// In en, this message translates to:
  /// **'🛍 Shopping'**
  String get recommendTabShopping;

  /// No description provided for @recommendTabOutdoor.
  ///
  /// In en, this message translates to:
  /// **'🌳 Parks · Night'**
  String get recommendTabOutdoor;

  /// No description provided for @recommendTabEvents.
  ///
  /// In en, this message translates to:
  /// **'🎭 Culture'**
  String get recommendTabEvents;

  /// No description provided for @authTabSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authTabSignUp;

  /// No description provided for @authTabSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authTabSignIn;

  /// No description provided for @authProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get authProcessing;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// No description provided for @authLabelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authLabelEmail;

  /// No description provided for @authHintEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authHintEmail;

  /// No description provided for @authLabelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authLabelPassword;

  /// No description provided for @authHintPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authHintPassword;

  /// No description provided for @authFindId.
  ///
  /// In en, this message translates to:
  /// **'Find ID'**
  String get authFindId;

  /// No description provided for @authFindPassword.
  ///
  /// In en, this message translates to:
  /// **'Find password'**
  String get authFindPassword;

  /// No description provided for @authLabelUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authLabelUsername;

  /// No description provided for @authHintUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get authHintUsername;

  /// No description provided for @authLabelConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authLabelConfirmPassword;

  /// No description provided for @authHintConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get authHintConfirmPassword;

  /// No description provided for @authSnsLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with social'**
  String get authSnsLogin;

  /// No description provided for @authGoogleAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Google authentication failed'**
  String get authGoogleAuthFailed;

  /// No description provided for @authGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get authGoogleSignInFailed;

  /// No description provided for @authGuestSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Guest sign-in failed'**
  String get authGuestSignInFailed;

  /// No description provided for @authAppleAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple authentication failed'**
  String get authAppleAuthFailed;

  /// No description provided for @authAppleSignInCanceled.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in was canceled'**
  String get authAppleSignInCanceled;

  /// No description provided for @authAppleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed'**
  String get authAppleSignInFailed;

  /// No description provided for @authEmailAndPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter email and password'**
  String get authEmailAndPasswordRequired;

  /// No description provided for @authUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get authUsernameRequired;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get authPasswordMismatch;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get authGenericError;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get authErrorEmailExists;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email format'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Email verification not complete. Check your inbox.'**
  String get authErrorEmailNotConfirmed;

  /// No description provided for @authEmailConfirmRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verification required'**
  String get authEmailConfirmRequiredTitle;

  /// No description provided for @authEmailConfirmRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'A verification email has been sent to {email}.\nCheck your inbox, verify, and then sign in.'**
  String authEmailConfirmRequiredBody(String email);

  /// No description provided for @authFindIdResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Find ID result'**
  String get authFindIdResultTitle;

  /// No description provided for @authFindIdResultBefore.
  ///
  /// In en, this message translates to:
  /// **'Your username is '**
  String get authFindIdResultBefore;

  /// No description provided for @authFindIdResultAfter.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get authFindIdResultAfter;

  /// No description provided for @authFindIdEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email'**
  String get authFindIdEmailRequired;

  /// No description provided for @authFindIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for that email'**
  String get authFindIdNotFound;

  /// No description provided for @authPasswordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link has been sent to your email'**
  String get authPasswordResetSent;

  /// No description provided for @authFindIdFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find your ID'**
  String get authFindIdFailed;

  /// No description provided for @authEmailSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send email'**
  String get authEmailSendFailed;

  /// No description provided for @authFindIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Find ID'**
  String get authFindIdTitle;

  /// No description provided for @authFindPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Find password'**
  String get authFindPasswordTitle;

  /// No description provided for @authFindIdBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you used to sign up.\nWe\'ll send your ID.'**
  String get authFindIdBody;

  /// No description provided for @authFindPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send a password reset link.'**
  String get authFindPasswordBody;

  /// No description provided for @authFindIdEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your sign-up email'**
  String get authFindIdEmailHint;

  /// No description provided for @authFindIdSubmit.
  ///
  /// In en, this message translates to:
  /// **'Find ID'**
  String get authFindIdSubmit;

  /// No description provided for @authFindPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authFindPasswordSubmit;

  /// No description provided for @hubSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get hubSettingsTooltip;

  /// No description provided for @hubAuthExploreSeoulTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore Seoul with friends'**
  String get hubAuthExploreSeoulTitle;

  /// No description provided for @hubAuthCreateProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a nickname and pin to start.'**
  String get hubAuthCreateProfileSubtitle;

  /// No description provided for @hubAuthCreateProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get hubAuthCreateProfileButton;

  /// No description provided for @hubPausedNotice.
  ///
  /// In en, this message translates to:
  /// **'Seoul Live paused — location/notifications blocked, chat OK'**
  String get hubPausedNotice;

  /// No description provided for @hubResumeButton.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get hubResumeButton;

  /// No description provided for @hubRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get hubRoomTitle;

  /// No description provided for @hubRoomEmpty.
  ///
  /// In en, this message translates to:
  /// **'Create or join a room by code'**
  String get hubRoomEmpty;

  /// No description provided for @hubRoomCurrent.
  ///
  /// In en, this message translates to:
  /// **'In room · code {code}'**
  String hubRoomCurrent(String code);

  /// No description provided for @hubFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get hubFriendsTitle;

  /// No description provided for @hubFriendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} friends · {requests} requests'**
  String hubFriendsSubtitle(int count, int requests);

  /// No description provided for @hubDmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'1:1 chats with friends'**
  String get hubDmSubtitle;

  /// No description provided for @hubFriendCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend code'**
  String get hubFriendCodeTitle;

  /// No description provided for @hubFriendCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share my code {code} / enter one'**
  String hubFriendCodeSubtitle(String code);

  /// No description provided for @hubFriendGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend groups'**
  String get hubFriendGroupsTitle;

  /// No description provided for @hubFriendGroupsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} groups'**
  String hubFriendGroupsSubtitle(int count);

  /// No description provided for @hubSpotifyConnectedNoPlayback.
  ///
  /// In en, this message translates to:
  /// **'Connected — no playback'**
  String get hubSpotifyConnectedNoPlayback;

  /// No description provided for @hubSpotifyShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your tracks with friends'**
  String get hubSpotifyShareSubtitle;

  /// No description provided for @hubVisibilityGhost.
  ///
  /// In en, this message translates to:
  /// **'Private — no send/receive'**
  String get hubVisibilityGhost;

  /// No description provided for @hubVisibilityFriends.
  ///
  /// In en, this message translates to:
  /// **'Friend room — same-room members only'**
  String get hubVisibilityFriends;

  /// No description provided for @hubVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public — all Seoul Live users'**
  String get hubVisibilityPublic;

  /// No description provided for @hubActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'My activity'**
  String get hubActivityTitle;

  /// No description provided for @hubStatMeetups.
  ///
  /// In en, this message translates to:
  /// **'Meetups'**
  String get hubStatMeetups;

  /// No description provided for @hubStatFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get hubStatFriends;

  /// No description provided for @hubStatStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get hubStatStreak;

  /// No description provided for @hubStatStreakValue.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String hubStatStreakValue(int days);

  /// No description provided for @hubStatStreakBest.
  ///
  /// In en, this message translates to:
  /// **'Best {days}'**
  String hubStatStreakBest(int days);

  /// No description provided for @hubBadgesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Earn badges with your first friend or first meetup'**
  String get hubBadgesEmptyHint;

  /// No description provided for @hubAgoJust.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get hubAgoJust;

  /// No description provided for @hubAgoMin.
  ///
  /// In en, this message translates to:
  /// **'{min} min ago'**
  String hubAgoMin(int min);

  /// No description provided for @hubAgoHour.
  ///
  /// In en, this message translates to:
  /// **'{hour}h ago'**
  String hubAgoHour(int hour);

  /// No description provided for @hubAgoDay.
  ///
  /// In en, this message translates to:
  /// **'{day}d ago'**
  String hubAgoDay(int day);

  /// No description provided for @hubRecentMeetupsTitle.
  ///
  /// In en, this message translates to:
  /// **'🎉 Recent meetups'**
  String get hubRecentMeetupsTitle;

  /// No description provided for @hubRecentMeetupsCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String hubRecentMeetupsCount(int count);

  /// No description provided for @roomCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 6-character code.'**
  String get roomCodeRequired;

  /// No description provided for @roomLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get roomLeaveTitle;

  /// No description provided for @roomLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Leaving ends location sharing and chat.'**
  String get roomLeaveBody;

  /// No description provided for @roomLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get roomLeaveConfirm;

  /// No description provided for @roomTitle.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomTitle;

  /// No description provided for @roomDescription.
  ///
  /// In en, this message translates to:
  /// **'Share location and chat in real time with friends.'**
  String get roomDescription;

  /// No description provided for @roomCapacityNote.
  ///
  /// In en, this message translates to:
  /// **'Rooms auto-expire after 24 hours. Capacity 8.'**
  String get roomCapacityNote;

  /// No description provided for @roomCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get roomCreateButton;

  /// No description provided for @roomCodeEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter invite code (6 digits)'**
  String get roomCodeEntryTitle;

  /// No description provided for @roomJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get roomJoinButton;

  /// No description provided for @roomExpiresInMin.
  ///
  /// In en, this message translates to:
  /// **'Expires in {min} min'**
  String roomExpiresInMin(int min);

  /// No description provided for @roomDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Unnamed room'**
  String get roomDefaultName;

  /// No description provided for @roomInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get roomInviteCode;

  /// No description provided for @roomCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get roomCodeCopied;

  /// No description provided for @roomExpiresInHours.
  ///
  /// In en, this message translates to:
  /// **'Expires in {hour}h'**
  String roomExpiresInHours(int hour);

  /// No description provided for @roomMembers.
  ///
  /// In en, this message translates to:
  /// **'Members ({current}/{max})'**
  String roomMembers(int current, int max);

  /// No description provided for @roomChatOpenWithUnread.
  ///
  /// In en, this message translates to:
  /// **'Open chat ({count})'**
  String roomChatOpenWithUnread(int count);

  /// No description provided for @roomChatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get roomChatOpen;

  /// No description provided for @roomLeaveButton.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get roomLeaveButton;

  /// No description provided for @roomEditNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename room'**
  String get roomEditNameTitle;

  /// No description provided for @roomEditNameBody.
  ///
  /// In en, this message translates to:
  /// **'Shown to room members'**
  String get roomEditNameBody;

  /// No description provided for @roomEditNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Gwanghwamun meetup'**
  String get roomEditNamePlaceholder;

  /// No description provided for @roomGenericError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String roomGenericError(String error);

  /// No description provided for @roomShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Seoul Live room invite'**
  String get roomShareSubject;

  /// No description provided for @roomShareBody.
  ///
  /// In en, this message translates to:
  /// **'{nickname} invited you to a Seoul Live room!\n\nCode: {code}\nJoin: com.seoul.prism://room/{code}'**
  String roomShareBody(String nickname, String code);

  /// No description provided for @roomInviteTextCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite text copied'**
  String get roomInviteTextCopied;

  /// No description provided for @roomRefreshCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Refresh invite code'**
  String get roomRefreshCodeTitle;

  /// No description provided for @roomRefreshCodeBody.
  ///
  /// In en, this message translates to:
  /// **'The previous code stops working immediately. Continue?'**
  String get roomRefreshCodeBody;

  /// No description provided for @roomRefreshCodeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get roomRefreshCodeConfirm;

  /// No description provided for @roomCodeRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Code refreshed'**
  String get roomCodeRefreshed;

  /// No description provided for @roomKickTitle.
  ///
  /// In en, this message translates to:
  /// **'Kick {nickname}'**
  String roomKickTitle(String nickname);

  /// No description provided for @roomKickBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be removed from the room immediately.'**
  String get roomKickBody;

  /// No description provided for @roomKickConfirm.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get roomKickConfirm;

  /// No description provided for @roomKickFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roomKickFallbackName;

  /// No description provided for @roomNameMe.
  ///
  /// In en, this message translates to:
  /// **'{name} (me)'**
  String roomNameMe(String name);

  /// No description provided for @roomMeetupBadge.
  ///
  /// In en, this message translates to:
  /// **'Meetup'**
  String get roomMeetupBadge;

  /// No description provided for @roomKickTooltip.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get roomKickTooltip;

  /// No description provided for @roomUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get roomUnknownUser;

  /// No description provided for @roomDestTitle.
  ///
  /// In en, this message translates to:
  /// **'🎯 Together — {name}'**
  String roomDestTitle(String name);

  /// No description provided for @roomDestSetBy.
  ///
  /// In en, this message translates to:
  /// **'Set by {name}'**
  String roomDestSetBy(String name);

  /// No description provided for @roomDestDefault.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get roomDestDefault;

  /// No description provided for @roomDestViewMap.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get roomDestViewMap;

  /// No description provided for @roomDestClear.
  ///
  /// In en, this message translates to:
  /// **'Clear destination'**
  String get roomDestClear;

  /// No description provided for @mpSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Seoul Live settings'**
  String get mpSettingsTitle;

  /// No description provided for @mpSectionMyStatus.
  ///
  /// In en, this message translates to:
  /// **'My status'**
  String get mpSectionMyStatus;

  /// No description provided for @mpPause.
  ///
  /// In en, this message translates to:
  /// **'Pause Seoul Live'**
  String get mpPause;

  /// No description provided for @mpPauseHint.
  ///
  /// In en, this message translates to:
  /// **'✓ Chat / room join / friend request — allowed\n✗ Location send / meetup alerts / pins — blocked\nData stays intact'**
  String get mpPauseHint;

  /// No description provided for @mpSectionBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery mode'**
  String get mpSectionBattery;

  /// No description provided for @mpBatteryHint.
  ///
  /// In en, this message translates to:
  /// **'Location update interval — more accurate = more battery'**
  String get mpBatteryHint;

  /// No description provided for @mpSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get mpSectionNotifications;

  /// No description provided for @mpNotificationsFail.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String mpNotificationsFail(String error);

  /// No description provided for @mpNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Separate from system notification permission — turn off here to silence pushes.'**
  String get mpNotificationsHint;

  /// No description provided for @mpSectionTutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get mpSectionTutorial;

  /// No description provided for @mpReplayTutorial.
  ///
  /// In en, this message translates to:
  /// **'Replay Seoul Live tutorial'**
  String get mpReplayTutorial;

  /// No description provided for @mpTutorialToast.
  ///
  /// In en, this message translates to:
  /// **'Tutorial will show next time you enter'**
  String get mpTutorialToast;

  /// No description provided for @mpReplayWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'Replay What\'s New'**
  String get mpReplayWhatsNew;

  /// No description provided for @mpReplayWhatsNewHint.
  ///
  /// In en, this message translates to:
  /// **'v{version} updates'**
  String mpReplayWhatsNewHint(String version);

  /// No description provided for @mpSectionSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get mpSectionSafety;

  /// No description provided for @mpBlockList.
  ///
  /// In en, this message translates to:
  /// **'Block list'**
  String get mpBlockList;

  /// No description provided for @mpBlockListHint.
  ///
  /// In en, this message translates to:
  /// **'View blocked users / unblock'**
  String get mpBlockListHint;

  /// No description provided for @mpSectionConsent.
  ///
  /// In en, this message translates to:
  /// **'Consent & data'**
  String get mpSectionConsent;

  /// No description provided for @mpRevokeConsent.
  ///
  /// In en, this message translates to:
  /// **'Revoke location consent'**
  String get mpRevokeConsent;

  /// No description provided for @mpRevokeConsentHint.
  ///
  /// In en, this message translates to:
  /// **'Revoking disables multiplayer and deletes all data'**
  String get mpRevokeConsentHint;

  /// No description provided for @mpDownloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get mpDownloadMyData;

  /// No description provided for @mpDownloadMyDataHint.
  ///
  /// In en, this message translates to:
  /// **'PIPA data portability — email request'**
  String get mpDownloadMyDataHint;

  /// No description provided for @mpDownloadMyDataToast.
  ///
  /// In en, this message translates to:
  /// **'Please email rush94434@gmail.com (within 10 days)'**
  String get mpDownloadMyDataToast;

  /// No description provided for @mpSectionOps.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get mpSectionOps;

  /// No description provided for @mpOpsMonitor.
  ///
  /// In en, this message translates to:
  /// **'Ops monitor'**
  String get mpOpsMonitor;

  /// No description provided for @mpOpsMonitorHint.
  ///
  /// In en, this message translates to:
  /// **'Daily metrics · abuse signals · report handling'**
  String get mpOpsMonitorHint;

  /// No description provided for @mpSectionDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get mpSectionDanger;

  /// No description provided for @mpLeaveSeoulLive.
  ///
  /// In en, this message translates to:
  /// **'Leave Seoul Live'**
  String get mpLeaveSeoulLive;

  /// No description provided for @mpLeaveSeoulLiveHint.
  ///
  /// In en, this message translates to:
  /// **'Bulk-delete multiplayer data (profile, friends, rooms, chat)'**
  String get mpLeaveSeoulLiveHint;

  /// No description provided for @mpFootnote.
  ///
  /// In en, this message translates to:
  /// **'※ Your Seoul Vista account remains. Only multiplayer data is deleted.'**
  String get mpFootnote;

  /// No description provided for @mpRevokeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke consent'**
  String get mpRevokeDialogTitle;

  /// No description provided for @mpRevokeDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Revoking location processing consent disables multiplayer\nand deletes profile, friends, rooms, chat data. Continue?'**
  String get mpRevokeDialogBody;

  /// No description provided for @mpRevokeDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get mpRevokeDialogConfirm;

  /// No description provided for @mpRevokedToast.
  ///
  /// In en, this message translates to:
  /// **'Consent revoked and data deleted'**
  String get mpRevokedToast;

  /// No description provided for @mpLeaveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Seoul Live'**
  String get mpLeaveDialogTitle;

  /// No description provided for @mpLeaveDialogBody.
  ///
  /// In en, this message translates to:
  /// **'All multiplayer data will be permanently deleted.\nYou can rejoin, but friends, rooms, and chat history won\'t be restored.'**
  String get mpLeaveDialogBody;

  /// No description provided for @mpLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get mpLeaveConfirm;

  /// No description provided for @mpLeftToast.
  ///
  /// In en, this message translates to:
  /// **'You\'ve left Seoul Live'**
  String get mpLeftToast;

  /// No description provided for @mpNotifCatFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Friend request'**
  String get mpNotifCatFriendRequest;

  /// No description provided for @mpNotifCatFriendAccept.
  ///
  /// In en, this message translates to:
  /// **'Friend accepted'**
  String get mpNotifCatFriendAccept;

  /// No description provided for @mpNotifCatRoomMessage.
  ///
  /// In en, this message translates to:
  /// **'Chat message'**
  String get mpNotifCatRoomMessage;

  /// No description provided for @mpNotifCatMeetup.
  ///
  /// In en, this message translates to:
  /// **'Meetup detected'**
  String get mpNotifCatMeetup;

  /// No description provided for @mpNotifCatDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination change'**
  String get mpNotifCatDestination;

  /// No description provided for @mpNotifCatWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get mpNotifCatWelcome;

  /// No description provided for @panelSubway.
  ///
  /// In en, this message translates to:
  /// **'Subway'**
  String get panelSubway;

  /// No description provided for @panelBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get panelBus;

  /// No description provided for @panelFlights.
  ///
  /// In en, this message translates to:
  /// **'Aircraft'**
  String get panelFlights;

  /// No description provided for @panelDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get panelDisplay;

  /// No description provided for @panelLineFilter.
  ///
  /// In en, this message translates to:
  /// **'Line filter'**
  String get panelLineFilter;

  /// No description provided for @panelPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get panelPerformance;

  /// No description provided for @panelLighting.
  ///
  /// In en, this message translates to:
  /// **'Lighting'**
  String get panelLighting;

  /// No description provided for @panelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get panelInfo;

  /// No description provided for @panelDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get panelDeveloper;

  /// No description provided for @panelDemoRunning.
  ///
  /// In en, this message translates to:
  /// **'DEMO running'**
  String get panelDemoRunning;

  /// No description provided for @panelLiveRunning.
  ///
  /// In en, this message translates to:
  /// **'LIVE running'**
  String get panelLiveRunning;

  /// No description provided for @panelOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get panelOff;

  /// No description provided for @panelSwitchToLive.
  ///
  /// In en, this message translates to:
  /// **'Switch to LIVE'**
  String get panelSwitchToLive;

  /// No description provided for @panelSwitchToDemo.
  ///
  /// In en, this message translates to:
  /// **'Switch to DEMO'**
  String get panelSwitchToDemo;

  /// No description provided for @panelSubwayOn.
  ///
  /// In en, this message translates to:
  /// **'Turn subway on'**
  String get panelSubwayOn;

  /// No description provided for @panelSubwayOff.
  ///
  /// In en, this message translates to:
  /// **'Turn subway off'**
  String get panelSubwayOff;

  /// No description provided for @panelTrainCount.
  ///
  /// In en, this message translates to:
  /// **'{count} trains'**
  String panelTrainCount(int count);

  /// No description provided for @panelLastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String panelLastUpdate(String time);

  /// No description provided for @panelBusActive.
  ///
  /// In en, this message translates to:
  /// **'{count} buses showing'**
  String panelBusActive(int count);

  /// No description provided for @panelSelectRoutes.
  ///
  /// In en, this message translates to:
  /// **'Pick a route'**
  String get panelSelectRoutes;

  /// No description provided for @panelTurnAllOff.
  ///
  /// In en, this message translates to:
  /// **'Turn all off'**
  String get panelTurnAllOff;

  /// No description provided for @panelBusPosition.
  ///
  /// In en, this message translates to:
  /// **'Bus positions'**
  String get panelBusPosition;

  /// No description provided for @panelHanRiverBus.
  ///
  /// In en, this message translates to:
  /// **'🚢 Han River bus'**
  String get panelHanRiverBus;

  /// No description provided for @panelAddRoute.
  ///
  /// In en, this message translates to:
  /// **'Add route'**
  String get panelAddRoute;

  /// No description provided for @panelFlightCount.
  ///
  /// In en, this message translates to:
  /// **'{mode} {count} aircraft'**
  String panelFlightCount(String mode, int count);

  /// No description provided for @panelFlightFallback.
  ///
  /// In en, this message translates to:
  /// **'Aircraft'**
  String get panelFlightFallback;

  /// No description provided for @panelFlightLegendClimb.
  ///
  /// In en, this message translates to:
  /// **'Climb'**
  String get panelFlightLegendClimb;

  /// No description provided for @panelFlightLegendCruise.
  ///
  /// In en, this message translates to:
  /// **'Cruise'**
  String get panelFlightLegendCruise;

  /// No description provided for @panelFlightLegendDescend.
  ///
  /// In en, this message translates to:
  /// **'Descend'**
  String get panelFlightLegendDescend;

  /// No description provided for @panelFlightLegendTakeoffLanding.
  ///
  /// In en, this message translates to:
  /// **'Takeoff/Landing'**
  String get panelFlightLegendTakeoffLanding;

  /// No description provided for @panelRouteLines.
  ///
  /// In en, this message translates to:
  /// **'Route lines'**
  String get panelRouteLines;

  /// No description provided for @panelTrainPosition.
  ///
  /// In en, this message translates to:
  /// **'Train positions'**
  String get panelTrainPosition;

  /// No description provided for @panelStationDisplay.
  ///
  /// In en, this message translates to:
  /// **'Station display'**
  String get panelStationDisplay;

  /// No description provided for @panelSelectRoutesToShow.
  ///
  /// In en, this message translates to:
  /// **'Pick routes to show'**
  String get panelSelectRoutesToShow;

  /// No description provided for @panelAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get panelAll;

  /// No description provided for @panelPresetHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get panelPresetHigh;

  /// No description provided for @panelPresetMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get panelPresetMedium;

  /// No description provided for @panelPresetLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get panelPresetLow;

  /// No description provided for @panelFps.
  ///
  /// In en, this message translates to:
  /// **'FPS'**
  String get panelFps;

  /// No description provided for @panelNaverPolling.
  ///
  /// In en, this message translates to:
  /// **'Naver polling'**
  String get panelNaverPolling;

  /// No description provided for @panelRenderInfo.
  ///
  /// In en, this message translates to:
  /// **'Rendering: {engine} · GeoJSON cache'**
  String panelRenderInfo(String engine);

  /// No description provided for @panelLightAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get panelLightAuto;

  /// No description provided for @panelLightDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get panelLightDay;

  /// No description provided for @panelLightNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get panelLightNight;

  /// No description provided for @panelLightDawn.
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get panelLightDawn;

  /// No description provided for @panelLightDusk.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get panelLightDusk;

  /// No description provided for @panelTierFlagship.
  ///
  /// In en, this message translates to:
  /// **'Flagship'**
  String get panelTierFlagship;

  /// No description provided for @panelTierHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get panelTierHigh;

  /// No description provided for @panelTierMid.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get panelTierMid;

  /// No description provided for @panelTierLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get panelTierLow;

  /// No description provided for @panelMapEngine.
  ///
  /// In en, this message translates to:
  /// **'Map engine'**
  String get panelMapEngine;

  /// No description provided for @panelDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get panelDevice;

  /// No description provided for @panelPerfTier.
  ///
  /// In en, this message translates to:
  /// **'Performance tier'**
  String get panelPerfTier;

  /// No description provided for @mapDisplay3D.
  ///
  /// In en, this message translates to:
  /// **'3D buildings'**
  String get mapDisplay3D;

  /// No description provided for @mapDisplayPois.
  ///
  /// In en, this message translates to:
  /// **'POI icons'**
  String get mapDisplayPois;

  /// No description provided for @mapDisplayWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather effects (fog/rain)'**
  String get mapDisplayWeather;

  /// No description provided for @mapDisplayLiveSubway.
  ///
  /// In en, this message translates to:
  /// **'Live subway'**
  String get mapDisplayLiveSubway;

  /// No description provided for @friendsGroupTooltip.
  ///
  /// In en, this message translates to:
  /// **'Friend groups'**
  String get friendsGroupTooltip;

  /// No description provided for @friendsCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Friend code'**
  String get friendsCodeTooltip;

  /// No description provided for @friendsAddByNickname.
  ///
  /// In en, this message translates to:
  /// **'Add a friend by nickname'**
  String get friendsAddByNickname;

  /// No description provided for @friendsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname to search'**
  String get friendsSearchPlaceholder;

  /// No description provided for @friendsSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get friendsSearching;

  /// No description provided for @friendsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get friendsSearch;

  /// No description provided for @friendsNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user matches \"{query}\"'**
  String friendsNotFound(String query);

  /// No description provided for @friendsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Nicknames must match exactly. You can also try the 8-char friend code.'**
  String get friendsSearchHint;

  /// No description provided for @friendsReceivedRequests.
  ///
  /// In en, this message translates to:
  /// **'Received requests ({count})'**
  String friendsReceivedRequests(int count);

  /// No description provided for @friendsAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendsAccept;

  /// No description provided for @friendsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get friendsReject;

  /// No description provided for @friendsMyFriends.
  ///
  /// In en, this message translates to:
  /// **'My friends ({count})'**
  String friendsMyFriends(int count);

  /// No description provided for @friendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No friends yet. Add by nickname.'**
  String get friendsEmpty;

  /// No description provided for @friendsCooldownTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rejected requests can be re-sent after 7 days'**
  String get friendsCooldownTooltip;

  /// No description provided for @friendsCooldownDays.
  ///
  /// In en, this message translates to:
  /// **'Retry in {days}d'**
  String friendsCooldownDays(int days);

  /// No description provided for @friendsCooldownHours.
  ///
  /// In en, this message translates to:
  /// **'Retry in {hours}h'**
  String friendsCooldownHours(int hours);

  /// No description provided for @friendsBadgeFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friendsBadgeFriend;

  /// No description provided for @friendsBadgeRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get friendsBadgeRequested;

  /// No description provided for @friendsApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get friendsApply;

  /// No description provided for @friendsSendingRequestHint.
  ///
  /// In en, this message translates to:
  /// **'Send friend request to {nickname} — they get a push if accepted'**
  String friendsSendingRequestHint(String nickname);

  /// No description provided for @friendsDmStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start DM: {error}'**
  String friendsDmStartFailed(String error);

  /// No description provided for @friendsUnfriend.
  ///
  /// In en, this message translates to:
  /// **'Unfriend'**
  String get friendsUnfriend;

  /// No description provided for @friendsReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get friendsReport;

  /// No description provided for @friendsBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get friendsBlock;

  /// No description provided for @friendsBlockDialogTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Block this user'**
  String get friendsBlockDialogTitleFallback;

  /// No description provided for @friendsBlockDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {nickname}'**
  String friendsBlockDialogTitle(String nickname);

  /// No description provided for @friendsBlockDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Blocking prevents joining the same room and hides their messages.'**
  String get friendsBlockDialogBody;

  /// No description provided for @friendsBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get friendsBlockConfirm;

  /// No description provided for @friendsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get friendsUnknown;

  /// No description provided for @friendsRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to {nickname}'**
  String friendsRequestSent(String nickname);

  /// No description provided for @friendsFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String friendsFailure(String error);

  /// No description provided for @friendsSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend suggestions (friends of friends)'**
  String get friendsSuggestionsTitle;

  /// No description provided for @friendsMutualCount.
  ///
  /// In en, this message translates to:
  /// **'{count} mutual'**
  String friendsMutualCount(int count);

  /// No description provided for @friendsAddShort.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get friendsAddShort;

  /// No description provided for @searchRouteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find a route. Check the start and end points.'**
  String get searchRouteNotFound;

  /// No description provided for @searchLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your current location. Check location permission and GPS.'**
  String get searchLocationUnavailable;

  /// No description provided for @searchTabRoute.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get searchTabRoute;

  /// No description provided for @searchTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get searchTabProfile;

  /// No description provided for @searchPathTypeOptimal.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get searchPathTypeOptimal;

  /// No description provided for @searchPathTypeShortest.
  ///
  /// In en, this message translates to:
  /// **'Shortest'**
  String get searchPathTypeShortest;

  /// No description provided for @searchPathTypeMinTransfer.
  ///
  /// In en, this message translates to:
  /// **'Min transfers'**
  String get searchPathTypeMinTransfer;

  /// No description provided for @searchOutsideServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Outside service area'**
  String get searchOutsideServiceTitle;

  /// No description provided for @searchOutsideServiceBody.
  ///
  /// In en, this message translates to:
  /// **'Directions currently support Seoul · Incheon · Gyeonggi only. Please pick a start or end inside the metro region.'**
  String get searchOutsideServiceBody;

  /// No description provided for @searchDepartureFieldHint.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get searchDepartureFieldHint;

  /// No description provided for @searchArrivalFieldHint.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get searchArrivalFieldHint;

  /// No description provided for @searchSwapDepArr.
  ///
  /// In en, this message translates to:
  /// **'Swap from/to'**
  String get searchSwapDepArr;

  /// No description provided for @searchCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close directions'**
  String get searchCloseTooltip;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search places · bus · subway'**
  String get searchPlaceholder;

  /// No description provided for @searchClearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClearLabel;

  /// No description provided for @searchRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecentTitle;

  /// No description provided for @searchRecentClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get searchRecentClearAll;

  /// No description provided for @searchRecentRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent directions'**
  String get searchRecentRoutesTitle;

  /// No description provided for @searchBusTypeTrunk.
  ///
  /// In en, this message translates to:
  /// **'Trunk'**
  String get searchBusTypeTrunk;

  /// No description provided for @searchBusTypeBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get searchBusTypeBranch;

  /// No description provided for @searchBusTypeCircular.
  ///
  /// In en, this message translates to:
  /// **'Circular'**
  String get searchBusTypeCircular;

  /// No description provided for @searchBusTypeMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro'**
  String get searchBusTypeMetro;

  /// No description provided for @searchBusTypeIncheon.
  ///
  /// In en, this message translates to:
  /// **'Incheon'**
  String get searchBusTypeIncheon;

  /// No description provided for @searchBusTypeGyeonggi.
  ///
  /// In en, this message translates to:
  /// **'Gyeonggi'**
  String get searchBusTypeGyeonggi;

  /// No description provided for @searchBusTypeDefault.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get searchBusTypeDefault;

  /// No description provided for @searchCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get searchCatFood;

  /// No description provided for @searchCatCafe.
  ///
  /// In en, this message translates to:
  /// **'Café'**
  String get searchCatCafe;

  /// No description provided for @searchCatPark.
  ///
  /// In en, this message translates to:
  /// **'Park'**
  String get searchCatPark;

  /// No description provided for @searchCatShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get searchCatShopping;

  /// No description provided for @searchCatMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get searchCatMedical;

  /// No description provided for @searchCatEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get searchCatEducation;

  /// No description provided for @searchCatLodging.
  ///
  /// In en, this message translates to:
  /// **'Lodging'**
  String get searchCatLodging;

  /// No description provided for @searchCatFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get searchCatFinance;

  /// No description provided for @searchCatTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get searchCatTransit;

  /// No description provided for @searchCatAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get searchCatAddress;

  /// No description provided for @searchCatCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get searchCatCity;

  /// No description provided for @searchCatNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood'**
  String get searchCatNeighborhood;

  /// No description provided for @searchCatRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get searchCatRoad;

  /// No description provided for @liveBadgePeerTrack.
  ///
  /// In en, this message translates to:
  /// **'{nickname} is listening to {track}'**
  String liveBadgePeerTrack(String nickname, String track);

  /// No description provided for @liveBadgeSharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing with {count} {count, plural, one{person} other{people}}'**
  String liveBadgeSharing(int count);

  /// No description provided for @liveBadgeStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped location sharing'**
  String get liveBadgeStopped;

  /// No description provided for @seoulLiveStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Seoul Live started'**
  String get seoulLiveStartTitle;

  /// No description provided for @seoulLiveStartBody.
  ///
  /// In en, this message translates to:
  /// **'Your map just expanded to the world.'**
  String get seoulLiveStartBody;

  /// No description provided for @seoulLiveStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Your friends\' pins appear on the map'**
  String get seoulLiveStep2Title;

  /// No description provided for @seoulLiveStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Members of the same friend room show up as pins (nickname + emoji) in real time. Their pin moves as they move.'**
  String get seoulLiveStep2Body;

  /// No description provided for @seoulLiveStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Meet up by friend room code'**
  String get seoulLiveStep3Title;

  /// No description provided for @seoulLiveStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Open Profile → Seoul Live → Friend Room to create a new room or join with a 6-digit invite code. Capacity is 8.'**
  String get seoulLiveStep3Body;

  /// No description provided for @seoulLiveStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Meetup alerts within 50m'**
  String get seoulLiveStep4Title;

  /// No description provided for @seoulLiveStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Haptics and a notification fire when you get close. Auto-logged to chat.'**
  String get seoulLiveStep4Body;

  /// No description provided for @seoulLiveStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Go private anytime'**
  String get seoulLiveStep5Title;

  /// No description provided for @seoulLiveStep5Body.
  ///
  /// In en, this message translates to:
  /// **'Tap the \"Sharing\" badge at the top to switch to ghost mode instantly. Leaving a friend room also stops sending.'**
  String get seoulLiveStep5Body;

  /// No description provided for @seoulLivePermTitle.
  ///
  /// In en, this message translates to:
  /// **'Get notifications'**
  String get seoulLivePermTitle;

  /// No description provided for @seoulLivePermBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a push when friend requests, new messages, or meetups happen. Tap \"Allow\" below.'**
  String get seoulLivePermBody;

  /// No description provided for @seoulLivePermAllowed.
  ///
  /// In en, this message translates to:
  /// **'✓ Notifications allowed'**
  String get seoulLivePermAllowed;

  /// No description provided for @seoulLivePermDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied — you can allow it from Settings'**
  String get seoulLivePermDenied;

  /// No description provided for @seoulLivePermRequesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting…'**
  String get seoulLivePermRequesting;

  /// No description provided for @seoulLivePermAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get seoulLivePermAllow;

  /// No description provided for @roomMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one nearby yet'**
  String get roomMembersEmpty;

  /// No description provided for @roomMembersWithCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, one{friend} other{friends}} here'**
  String roomMembersWithCount(int count);

  /// No description provided for @roomMembersGhost.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get roomMembersGhost;

  /// No description provided for @roomMembersDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get roomMembersDisconnected;

  /// No description provided for @roomMembersRealtime.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get roomMembersRealtime;

  /// No description provided for @roomMembersStale.
  ///
  /// In en, this message translates to:
  /// **'Briefly out'**
  String get roomMembersStale;

  /// No description provided for @dmListAgoJust.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get dmListAgoJust;

  /// No description provided for @dmListAgoMin.
  ///
  /// In en, this message translates to:
  /// **'{min}m'**
  String dmListAgoMin(int min);

  /// No description provided for @dmListAgoHour.
  ///
  /// In en, this message translates to:
  /// **'{hour}h'**
  String dmListAgoHour(int hour);

  /// No description provided for @dmListAgoDay.
  ///
  /// In en, this message translates to:
  /// **'{day}d'**
  String dmListAgoDay(int day);

  /// No description provided for @dmListKindVoice.
  ///
  /// In en, this message translates to:
  /// **'🎙 Voice'**
  String get dmListKindVoice;

  /// No description provided for @dmListKindImage.
  ///
  /// In en, this message translates to:
  /// **'🖼 Photo'**
  String get dmListKindImage;

  /// No description provided for @dmListKindPlace.
  ///
  /// In en, this message translates to:
  /// **'📍 Place'**
  String get dmListKindPlace;

  /// No description provided for @dmListKindSpotify.
  ///
  /// In en, this message translates to:
  /// **'🎵 Track'**
  String get dmListKindSpotify;

  /// No description provided for @dmListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No DMs yet'**
  String get dmListEmpty;

  /// No description provided for @dmListEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Open a friend and tap the message button to start'**
  String get dmListEmptyHint;

  /// No description provided for @friendGroupsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get friendGroupsNewTitle;

  /// No description provided for @friendGroupsNewTooltip.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get friendGroupsNewTooltip;

  /// No description provided for @friendGroupsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get friendGroupsEmpty;

  /// No description provided for @friendGroupsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + above to group your friends'**
  String get friendGroupsEmptyHint;

  /// No description provided for @friendGroupsEmptyHintAlt.
  ///
  /// In en, this message translates to:
  /// **'Create a group with + in the top-right to organize friends.'**
  String get friendGroupsEmptyHintAlt;

  /// No description provided for @friendGroupsNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Family, Work, Club'**
  String get friendGroupsNamePlaceholder;

  /// No description provided for @friendGroupsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get friendGroupsCreate;

  /// No description provided for @friendGroupsCreated.
  ///
  /// In en, this message translates to:
  /// **'Group created'**
  String get friendGroupsCreated;

  /// No description provided for @friendGroupsFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String friendGroupsFailure(String error);

  /// No description provided for @friendGroupsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {emoji} {name}'**
  String friendGroupsDeleteTitle(String emoji, String name);

  /// No description provided for @friendGroupsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The group is deleted but friends are kept.'**
  String get friendGroupsDeleteBody;

  /// No description provided for @friendGroupsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get friendGroupsDelete;

  /// No description provided for @friendGroupsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get friendGroupsName;

  /// No description provided for @friendGroupsIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get friendGroupsIcon;

  /// No description provided for @friendGroupsMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, one{member} other{members}}'**
  String friendGroupsMemberCount(int count);

  /// No description provided for @friendGroupsNoFriendsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add friends first.'**
  String get friendGroupsNoFriendsPrompt;

  /// No description provided for @friendGroupsVisibilityHint.
  ///
  /// In en, this message translates to:
  /// **'Used for group-based visibility / chat'**
  String get friendGroupsVisibilityHint;

  /// No description provided for @friendGroupsMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {name} members'**
  String friendGroupsMembersTitle(String emoji, String name);

  /// No description provided for @friendGroupsEditMembers.
  ///
  /// In en, this message translates to:
  /// **'Edit members'**
  String get friendGroupsEditMembers;

  /// No description provided for @friendGroupsEmptyFriendsBox.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get friendGroupsEmptyFriendsBox;

  /// No description provided for @loginRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in required'**
  String get loginRequiredTitle;

  /// No description provided for @loginRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer is for signed-in users only.\nGuest (anonymous) accounts auto-delete after 30 days of inactivity,\nso friend/room data may be lost.'**
  String get loginRequiredBody;

  /// No description provided for @loginRequiredCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginRequiredCta;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam / Ads'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonHate.
  ///
  /// In en, this message translates to:
  /// **'Abuse / hate speech'**
  String get reportReasonHate;

  /// No description provided for @reportReasonSexual.
  ///
  /// In en, this message translates to:
  /// **'Sexual / disturbing content'**
  String get reportReasonSexual;

  /// No description provided for @reportReasonHarass.
  ///
  /// In en, this message translates to:
  /// **'Harassment / stalking'**
  String get reportReasonHarass;

  /// No description provided for @reportReasonFakeLocation.
  ///
  /// In en, this message translates to:
  /// **'Fake location / impersonation'**
  String get reportReasonFakeLocation;

  /// No description provided for @reportReasonMinorAbuse.
  ///
  /// In en, this message translates to:
  /// **'Minor safety violation'**
  String get reportReasonMinorAbuse;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @reportSelectReason.
  ///
  /// In en, this message translates to:
  /// **'Please pick a reason.'**
  String get reportSelectReason;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report received. Reviewed within 24h.'**
  String get reportSubmitted;

  /// No description provided for @reportTitleUser.
  ///
  /// In en, this message translates to:
  /// **'Report {label}'**
  String reportTitleUser(String label);

  /// No description provided for @reportTitleMessage.
  ///
  /// In en, this message translates to:
  /// **'Report message'**
  String get reportTitleMessage;

  /// No description provided for @reportNote.
  ///
  /// In en, this message translates to:
  /// **'Our ops team reviews and takes action within 24 hours.'**
  String get reportNote;

  /// No description provided for @reportExtraPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add details (optional)'**
  String get reportExtraPlaceholder;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmit;

  /// No description provided for @reportSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get reportSubmitting;

  /// No description provided for @reportFallbackUser.
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get reportFallbackUser;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedUsersTitle;

  /// No description provided for @blockedUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get blockedUsersEmpty;

  /// No description provided for @blockedUsersUnblockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}'**
  String blockedUsersUnblockTitle(String name);

  /// No description provided for @blockedUsersUnblockBody.
  ///
  /// In en, this message translates to:
  /// **'Unblocking lets you meet them again and see their messages.'**
  String get blockedUsersUnblockBody;

  /// No description provided for @blockedUsersUnblockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get blockedUsersUnblockConfirm;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activityCatMeetup.
  ///
  /// In en, this message translates to:
  /// **'🎉 Meetup'**
  String get activityCatMeetup;

  /// No description provided for @activityCatFriend.
  ///
  /// In en, this message translates to:
  /// **'🤝 Friend'**
  String get activityCatFriend;

  /// No description provided for @activityCatRoomJoined.
  ///
  /// In en, this message translates to:
  /// **'🚪 Room joined'**
  String get activityCatRoomJoined;

  /// No description provided for @activityCatPlaceShared.
  ///
  /// In en, this message translates to:
  /// **'📍 Place shared'**
  String get activityCatPlaceShared;

  /// No description provided for @activityCatDestination.
  ///
  /// In en, this message translates to:
  /// **'🎯 Destination'**
  String get activityCatDestination;

  /// No description provided for @activityAgoJust.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get activityAgoJust;

  /// No description provided for @activityAgoMin.
  ///
  /// In en, this message translates to:
  /// **'{min} min ago'**
  String activityAgoMin(int min);

  /// No description provided for @activityAgoHour.
  ///
  /// In en, this message translates to:
  /// **'{hour}h ago'**
  String activityAgoHour(int hour);

  /// No description provided for @activityAgoDay.
  ///
  /// In en, this message translates to:
  /// **'{day}d ago'**
  String activityAgoDay(int day);

  /// No description provided for @activityRanking.
  ///
  /// In en, this message translates to:
  /// **'Friend ranking'**
  String get activityRanking;

  /// No description provided for @activityRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get activityRecent;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet'**
  String get activityEmpty;

  /// No description provided for @activityCode.
  ///
  /// In en, this message translates to:
  /// **'Code {code}'**
  String activityCode(String code);

  /// No description provided for @activityThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week\'s activity'**
  String get activityThisWeek;

  /// No description provided for @activityTotalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String activityTotalCount(int count);

  /// No description provided for @activityWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get activityWeekdayMon;

  /// No description provided for @activityWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get activityWeekdayTue;

  /// No description provided for @activityWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get activityWeekdayWed;

  /// No description provided for @activityWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get activityWeekdayThu;

  /// No description provided for @activityWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get activityWeekdayFri;

  /// No description provided for @activityWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get activityWeekdaySat;

  /// No description provided for @activityWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get activityWeekdaySun;

  /// No description provided for @peerNowPlayingBtnFriend.
  ///
  /// In en, this message translates to:
  /// **'Friends ✓'**
  String get peerNowPlayingBtnFriend;

  /// No description provided for @peerNowPlayingBtnRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get peerNowPlayingBtnRequested;

  /// No description provided for @peerNowPlayingBtnAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept request'**
  String get peerNowPlayingBtnAccept;

  /// No description provided for @peerNowPlayingBtnSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send friend request'**
  String get peerNowPlayingBtnSendRequest;

  /// No description provided for @peerNowPlayingOpenInSpotify.
  ///
  /// In en, this message translates to:
  /// **'Open in Spotify'**
  String get peerNowPlayingOpenInSpotify;

  /// No description provided for @mapNoLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Without location permission, friends can\'t see your pin. Open Settings → Location to allow.'**
  String get mapNoLocationPermission;

  /// No description provided for @mapLeftRoom.
  ///
  /// In en, this message translates to:
  /// **'You left the friend room'**
  String get mapLeftRoom;

  /// No description provided for @mapShowOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show \"{name}\" on the map'**
  String mapShowOnMap(String name);

  /// No description provided for @mapBuildingInside.
  ///
  /// In en, this message translates to:
  /// **'🏢 You\'re inside {name}'**
  String mapBuildingInside(String name);

  /// No description provided for @mapLocationChecking.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get mapLocationChecking;

  /// No description provided for @mapLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied → iOS Settings → Seoul Vista → Location'**
  String get mapLocationPermissionDenied;

  /// No description provided for @mapLocationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'iOS Settings → Privacy → Location services is off'**
  String get mapLocationServiceOff;

  /// No description provided for @mapMyLocationMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved to your location'**
  String get mapMyLocationMoved;

  /// No description provided for @mapLocationFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get location: {error}'**
  String mapLocationFetchFailed(String error);

  /// No description provided for @mapMapAppUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the maps app'**
  String get mapMapAppUnavailable;

  /// No description provided for @mapTabRecommend.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get mapTabRecommend;

  /// No description provided for @mapTabSave.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get mapTabSave;

  /// No description provided for @mapTabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTabMap;

  /// No description provided for @mapTabWorld.
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get mapTabWorld;

  /// No description provided for @mapTabTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get mapTabTrip;

  /// No description provided for @mapDirectionsRoadFetching.
  ///
  /// In en, this message translates to:
  /// **'Loading driving route…'**
  String get mapDirectionsRoadFetching;

  /// No description provided for @mapDirectionsWalkFetching.
  ///
  /// In en, this message translates to:
  /// **'Loading walking route…'**
  String get mapDirectionsWalkFetching;

  /// No description provided for @mapNoCoords.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find start/end coordinates'**
  String get mapNoCoords;

  /// No description provided for @mapDirectionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the route'**
  String get mapDirectionsFailed;

  /// No description provided for @mapInsufficientSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Need more places — once favorites/visits reach {min}+, a course is generated automatically'**
  String mapInsufficientSavedPlaces(int min);

  /// No description provided for @subwayPanelExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand panel'**
  String get subwayPanelExpand;

  /// No description provided for @subwayPanelCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse panel'**
  String get subwayPanelCollapse;

  /// No description provided for @subwayPanelDelayedTrains.
  ///
  /// In en, this message translates to:
  /// **'Delayed trains {count}'**
  String subwayPanelDelayedTrains(int count);

  /// No description provided for @subwayPanelMinutes.
  ///
  /// In en, this message translates to:
  /// **'{min} min'**
  String subwayPanelMinutes(int min);

  /// No description provided for @subwayPanelOthersCount.
  ///
  /// In en, this message translates to:
  /// **'and {count} more…'**
  String subwayPanelOthersCount(int count);

  /// No description provided for @subwayPanelOffTapToStart.
  ///
  /// In en, this message translates to:
  /// **'OFF — tap to start'**
  String get subwayPanelOffTapToStart;

  /// No description provided for @subwayPanelMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get subwayPanelMode;

  /// No description provided for @subwayPanelDemoLabel.
  ///
  /// In en, this message translates to:
  /// **'Demo (no API)'**
  String get subwayPanelDemoLabel;

  /// No description provided for @subwayPanelLiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get subwayPanelLiveLabel;

  /// No description provided for @subwayPanelTrainsLabel.
  ///
  /// In en, this message translates to:
  /// **'Trains'**
  String get subwayPanelTrainsLabel;

  /// No description provided for @subwayPanelTrainsValue.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String subwayPanelTrainsValue(int count);

  /// No description provided for @subwayPanelUpdate.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get subwayPanelUpdate;

  /// No description provided for @subwayPanelToggleRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get subwayPanelToggleRoutes;

  /// No description provided for @subwayPanelToggleTrains.
  ///
  /// In en, this message translates to:
  /// **'Train positions'**
  String get subwayPanelToggleTrains;

  /// No description provided for @subwayPanelToggleStations.
  ///
  /// In en, this message translates to:
  /// **'Stations'**
  String get subwayPanelToggleStations;

  /// No description provided for @subwayPanelToggleCongestion.
  ///
  /// In en, this message translates to:
  /// **'Congestion'**
  String get subwayPanelToggleCongestion;

  /// No description provided for @subwayPanelRouteFilter.
  ///
  /// In en, this message translates to:
  /// **'Route filter'**
  String get subwayPanelRouteFilter;

  /// No description provided for @subwayPanelAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get subwayPanelAll;

  /// No description provided for @subwayPanelToggleOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on subway visualization'**
  String get subwayPanelToggleOn;

  /// No description provided for @subwayPanelToggleOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off subway visualization'**
  String get subwayPanelToggleOff;

  /// No description provided for @subwayPanelNoArrivalInfo.
  ///
  /// In en, this message translates to:
  /// **'No arrival info'**
  String get subwayPanelNoArrivalInfo;

  /// No description provided for @subwayPanelTrainDirection.
  ///
  /// In en, this message translates to:
  /// **'{destination} · {type}'**
  String subwayPanelTrainDirection(String destination, String type);

  /// No description provided for @subwayPanelCloseDetail.
  ///
  /// In en, this message translates to:
  /// **'Close train detail'**
  String get subwayPanelCloseDetail;

  /// No description provided for @subwayPanelTrainNo.
  ///
  /// In en, this message translates to:
  /// **'Train #{no}'**
  String subwayPanelTrainNo(String no);

  /// No description provided for @subwayPanelDelayedBadge.
  ///
  /// In en, this message translates to:
  /// **'{min} min delay'**
  String subwayPanelDelayedBadge(int min);

  /// No description provided for @subwayPanelLastTrainBadge.
  ///
  /// In en, this message translates to:
  /// **'Last train'**
  String get subwayPanelLastTrainBadge;

  /// No description provided for @subwayPanelTerminalDestination.
  ///
  /// In en, this message translates to:
  /// **'To {terminal}'**
  String subwayPanelTerminalDestination(String terminal);

  /// No description provided for @subwayPanelPrevStation.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get subwayPanelPrevStation;

  /// No description provided for @subwayPanelDepartureStation.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get subwayPanelDepartureStation;

  /// No description provided for @subwayPanelCurrentStation.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get subwayPanelCurrentStation;

  /// No description provided for @subwayPanelNextStation.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get subwayPanelNextStation;

  /// No description provided for @subwayPanelStateArriving.
  ///
  /// In en, this message translates to:
  /// **'Arriving'**
  String get subwayPanelStateArriving;

  /// No description provided for @subwayPanelStateStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get subwayPanelStateStopped;

  /// No description provided for @subwayPanelStateDeparted.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get subwayPanelStateDeparted;

  /// No description provided for @subwayPanelStateMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving'**
  String get subwayPanelStateMoving;

  /// No description provided for @subwayPanelStateOperating.
  ///
  /// In en, this message translates to:
  /// **'In service'**
  String get subwayPanelStateOperating;

  /// No description provided for @subwayPanelDirInnerLoop.
  ///
  /// In en, this message translates to:
  /// **'Inner loop'**
  String get subwayPanelDirInnerLoop;

  /// No description provided for @subwayPanelDirOuterLoop.
  ///
  /// In en, this message translates to:
  /// **'Outer loop'**
  String get subwayPanelDirOuterLoop;

  /// No description provided for @subwayPanelDirUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get subwayPanelDirUp;

  /// No description provided for @subwayPanelDirDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get subwayPanelDirDown;

  /// No description provided for @subwayPanelTrainTypeExpress.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get subwayPanelTrainTypeExpress;

  /// No description provided for @subwayPanelTrainTypeSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get subwayPanelTrainTypeSpecial;

  /// No description provided for @subwayPanelTrainTypeRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get subwayPanelTrainTypeRegular;

  /// No description provided for @searchTileSubway.
  ///
  /// In en, this message translates to:
  /// **'Subway'**
  String get searchTileSubway;

  /// No description provided for @profileEditNicknameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname (1–20 chars).'**
  String get profileEditNicknameInvalid;

  /// No description provided for @profileEditBirthInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 4-digit birth year (YYYY).'**
  String get profileEditBirthInvalid;

  /// No description provided for @profileEditAgeRestriction.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer is not available for users under 14.'**
  String get profileEditAgeRestriction;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// No description provided for @profileEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is how others see you in rooms.'**
  String get profileEditSubtitle;

  /// No description provided for @profileEditNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname (duplicates allowed)'**
  String get profileEditNicknameLabel;

  /// No description provided for @profileEditNicknamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. SeoulExplorer'**
  String get profileEditNicknamePlaceholder;

  /// No description provided for @profileEditBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth year (14+ only)'**
  String get profileEditBirthLabel;

  /// No description provided for @profileEditBirthPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2000'**
  String get profileEditBirthPlaceholder;

  /// No description provided for @profileEditEmojiLabel.
  ///
  /// In en, this message translates to:
  /// **'Pin emoji'**
  String get profileEditEmojiLabel;

  /// No description provided for @profileEditColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Pin color'**
  String get profileEditColorLabel;

  /// No description provided for @profileEditVisibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Location visibility'**
  String get profileEditVisibilityLabel;

  /// No description provided for @profileEditVisibilityGhost.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get profileEditVisibilityGhost;

  /// No description provided for @profileEditVisibilityFriends.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get profileEditVisibilityFriends;

  /// No description provided for @profileEditVisibilityGroup.
  ///
  /// In en, this message translates to:
  /// **'Groups only'**
  String get profileEditVisibilityGroup;

  /// No description provided for @profileEditVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get profileEditVisibilityPublic;

  /// No description provided for @profileEditSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get profileEditSaving;

  /// No description provided for @profileEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileEditSave;

  /// No description provided for @profileEditPublicDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to public'**
  String get profileEditPublicDialogTitle;

  /// No description provided for @profileEditPublicDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Your location becomes visible to all Seoul Live users in real time, including strangers.\n\n• Beware of inappropriate meetups / stalking risks\n• You can revert to Private/Room at any time\n• Block/report from the friend profile or chat menu'**
  String get profileEditPublicDialogBody;

  /// No description provided for @profileEditPublicDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileEditPublicDialogConfirm;

  /// No description provided for @profileEditVisibilityGhostDesc.
  ///
  /// In en, this message translates to:
  /// **'Your location isn\'t sent. You can\'t see others\' locations either.'**
  String get profileEditVisibilityGhostDesc;

  /// No description provided for @profileEditVisibilityFriendsDesc.
  ///
  /// In en, this message translates to:
  /// **'Location is visible only to same-room members while you\'re in a room.'**
  String get profileEditVisibilityFriendsDesc;

  /// No description provided for @profileEditVisibilityGroupDesc.
  ///
  /// In en, this message translates to:
  /// **'Only friends in the groups you pick can see your location.'**
  String get profileEditVisibilityGroupDesc;

  /// No description provided for @profileEditVisibilityPublicDesc.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Any Seoul Live user can see your location. Also sent in rooms.'**
  String get profileEditVisibilityPublicDesc;

  /// No description provided for @profileEditNoGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups yet. Create one in Friends → Groups.'**
  String get profileEditNoGroups;

  /// No description provided for @adminMonitorTitle.
  ///
  /// In en, this message translates to:
  /// **'Ops monitor'**
  String get adminMonitorTitle;

  /// No description provided for @adminRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get adminRefresh;

  /// No description provided for @adminTabMetrics.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get adminTabMetrics;

  /// No description provided for @adminTabAbuse.
  ///
  /// In en, this message translates to:
  /// **'Abuse'**
  String get adminTabAbuse;

  /// No description provided for @adminTabReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminTabReports;

  /// No description provided for @adminMetricAllProfiles.
  ///
  /// In en, this message translates to:
  /// **'All profiles'**
  String get adminMetricAllProfiles;

  /// No description provided for @adminMetricActiveRooms.
  ///
  /// In en, this message translates to:
  /// **'Active rooms'**
  String get adminMetricActiveRooms;

  /// No description provided for @adminMetricTodayMeetups.
  ///
  /// In en, this message translates to:
  /// **'Meetups today'**
  String get adminMetricTodayMeetups;

  /// No description provided for @adminMetricTodayBlocks.
  ///
  /// In en, this message translates to:
  /// **'Blocks today'**
  String get adminMetricTodayBlocks;

  /// No description provided for @adminMetricTodayReports.
  ///
  /// In en, this message translates to:
  /// **'Reports today'**
  String get adminMetricTodayReports;

  /// No description provided for @adminNoSuspiciousSignals.
  ///
  /// In en, this message translates to:
  /// **'No suspicious signals (no user blocked by 3+ in 24h)'**
  String get adminNoSuspiciousSignals;

  /// No description provided for @adminRecentBlockCount.
  ///
  /// In en, this message translates to:
  /// **'Blocked by {count} in 24h'**
  String adminRecentBlockCount(int count);

  /// No description provided for @adminReportStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminReportStatusPending;

  /// No description provided for @adminReportStatusReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get adminReportStatusReviewed;

  /// No description provided for @adminReportStatusActioned.
  ///
  /// In en, this message translates to:
  /// **'Actioned'**
  String get adminReportStatusActioned;

  /// No description provided for @adminReportStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get adminReportStatusDismissed;

  /// No description provided for @adminNoReports.
  ///
  /// In en, this message translates to:
  /// **'No reports to show'**
  String get adminNoReports;

  /// No description provided for @adminReportTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Message report'**
  String get adminReportTypeMessage;

  /// No description provided for @adminReportTypeUser.
  ///
  /// In en, this message translates to:
  /// **'User report'**
  String get adminReportTypeUser;

  /// No description provided for @adminReportActionReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get adminReportActionReview;

  /// No description provided for @adminReportActionAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get adminReportActionAction;

  /// No description provided for @adminReportActionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get adminReportActionDismiss;

  /// No description provided for @adminAgoMin.
  ///
  /// In en, this message translates to:
  /// **'{min} min ago'**
  String adminAgoMin(int min);

  /// No description provided for @adminAgoHour.
  ///
  /// In en, this message translates to:
  /// **'{hour}h ago'**
  String adminAgoHour(int hour);

  /// No description provided for @adminAgoDay.
  ///
  /// In en, this message translates to:
  /// **'{day}d ago'**
  String adminAgoDay(int day);

  /// No description provided for @liveDiagTitle.
  ///
  /// In en, this message translates to:
  /// **'Live diagnostics'**
  String get liveDiagTitle;

  /// No description provided for @liveDiagMyId.
  ///
  /// In en, this message translates to:
  /// **'My ID'**
  String get liveDiagMyId;

  /// No description provided for @liveDiagVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get liveDiagVisibility;

  /// No description provided for @liveDiagRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get liveDiagRoom;

  /// No description provided for @liveDiagPeers.
  ///
  /// In en, this message translates to:
  /// **'Peers receiving'**
  String get liveDiagPeers;

  /// No description provided for @liveDiagPeersValue.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String liveDiagPeersValue(int count);

  /// No description provided for @liveDiagPresenceStatus.
  ///
  /// In en, this message translates to:
  /// **'Presence status'**
  String get liveDiagPresenceStatus;

  /// No description provided for @liveDiagWorldStatus.
  ///
  /// In en, this message translates to:
  /// **'World status'**
  String get liveDiagWorldStatus;

  /// No description provided for @liveDiagLastSent.
  ///
  /// In en, this message translates to:
  /// **'Last sent'**
  String get liveDiagLastSent;

  /// No description provided for @liveDiagSendError.
  ///
  /// In en, this message translates to:
  /// **'Send error'**
  String get liveDiagSendError;

  /// No description provided for @liveDiagGps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get liveDiagGps;

  /// No description provided for @liveDiagPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get liveDiagPaused;

  /// No description provided for @liveDiagActivityFailCount.
  ///
  /// In en, this message translates to:
  /// **'Activity fail count'**
  String get liveDiagActivityFailCount;

  /// No description provided for @liveDiagActivityFailValue.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String liveDiagActivityFailValue(int count);

  /// No description provided for @liveDiagLastActivityError.
  ///
  /// In en, this message translates to:
  /// **'Last activity error'**
  String get liveDiagLastActivityError;

  /// No description provided for @liveDiagFooter.
  ///
  /// In en, this message translates to:
  /// **'Capture this screen if there\'s an issue'**
  String get liveDiagFooter;

  /// No description provided for @liveDiagClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get liveDiagClose;

  /// No description provided for @liveDiagNoProfile.
  ///
  /// In en, this message translates to:
  /// **'(no profile)'**
  String get liveDiagNoProfile;

  /// No description provided for @liveDiagNone.
  ///
  /// In en, this message translates to:
  /// **'(none)'**
  String get liveDiagNone;

  /// No description provided for @liveDiagNotConnected.
  ///
  /// In en, this message translates to:
  /// **'(not connected)'**
  String get liveDiagNotConnected;

  /// No description provided for @liveDiagNotUsed.
  ///
  /// In en, this message translates to:
  /// **'(not used)'**
  String get liveDiagNotUsed;

  /// No description provided for @liveDiagNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent yet'**
  String get liveDiagNotSent;

  /// No description provided for @liveDiagSecondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{sec}s ago'**
  String liveDiagSecondsAgo(int sec);

  /// No description provided for @liveDiagRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'{code} ({count} members)'**
  String liveDiagRoomLabel(String code, int count);

  /// No description provided for @liveDiagGpsHas.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get liveDiagGpsHas;

  /// No description provided for @liveDiagGpsNo.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get liveDiagGpsNo;

  /// No description provided for @mpConsentLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow location permission in Settings > Location.'**
  String get mpConsentLocationDenied;

  /// No description provided for @mpConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before starting multiplayer'**
  String get mpConsentTitle;

  /// No description provided for @mpConsentHeading.
  ///
  /// In en, this message translates to:
  /// **'Seoul Live consent'**
  String get mpConsentHeading;

  /// No description provided for @mpConsentBody.
  ///
  /// In en, this message translates to:
  /// **'To share your location with friends, you need to agree to the items below. Each item can be agreed/declined separately and revoked any time in Settings.'**
  String get mpConsentBody;

  /// No description provided for @mpConsentItem1Title.
  ///
  /// In en, this message translates to:
  /// **'[Required] Profile data'**
  String get mpConsentItem1Title;

  /// No description provided for @mpConsentItem1Detail.
  ///
  /// In en, this message translates to:
  /// **'Nickname, pin color/emoji, birth year. For service identification and 14+ age check. Retained until account deletion; deleted immediately on withdrawal.'**
  String get mpConsentItem1Detail;

  /// No description provided for @mpConsentItem2Title.
  ///
  /// In en, this message translates to:
  /// **'[Required] Location data (LBS Act §18)'**
  String get mpConsentItem2Title;

  /// No description provided for @mpConsentItem2Detail.
  ///
  /// In en, this message translates to:
  /// **'GPS coordinates and direction. Shared in real time with room members or, when set to public, all Seoul Live users. Not stored persistently — ephemeral over Realtime channels. Visibility (private/room/public) can be changed any time in your profile.'**
  String get mpConsentItem2Detail;

  /// No description provided for @mpConsentItem3Title.
  ///
  /// In en, this message translates to:
  /// **'[Required] LBS terms of service'**
  String get mpConsentItem3Title;

  /// No description provided for @mpConsentItem3Detail.
  ///
  /// In en, this message translates to:
  /// **'Provided by a KCC-registered operator. Not available to users under 14.'**
  String get mpConsentItem3Detail;

  /// No description provided for @mpConsentItem3Link.
  ///
  /// In en, this message translates to:
  /// **'Read the full terms'**
  String get mpConsentItem3Link;

  /// No description provided for @mpConsentDeclineNote.
  ///
  /// In en, this message translates to:
  /// **'Declining only disables multiplayer; the rest of the app works normally.'**
  String get mpConsentDeclineNote;

  /// No description provided for @mpConsentBackgroundNote.
  ///
  /// In en, this message translates to:
  /// **'Location sharing auto-pauses when the app goes to the background (battery saver).'**
  String get mpConsentBackgroundNote;

  /// No description provided for @mpConsentSubmit.
  ///
  /// In en, this message translates to:
  /// **'Agree and start'**
  String get mpConsentSubmit;

  /// No description provided for @mpConsentLaterButton.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get mpConsentLaterButton;

  /// No description provided for @mpConsentSubmitBusy.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get mpConsentSubmitBusy;

  /// No description provided for @mpConsentLbsTermsBody.
  ///
  /// In en, this message translates to:
  /// **'These terms govern the use of the location-based service (\"Service\") provided by Seoul Vista\'s Seoul Live.'**
  String get mpConsentLbsTermsBody;

  /// No description provided for @optTitle.
  ///
  /// In en, this message translates to:
  /// **'Tuned to your device'**
  String get optTitle;

  /// No description provided for @optSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time visualization is GPU-intensive.\nPick what fits your device.'**
  String get optSubtitle;

  /// No description provided for @optPresetHighTitle.
  ///
  /// In en, this message translates to:
  /// **'High quality'**
  String get optPresetHighTitle;

  /// No description provided for @optPresetHighDetail.
  ///
  /// In en, this message translates to:
  /// **'60 fps · 5s refresh · AA on'**
  String get optPresetHighDetail;

  /// No description provided for @optPresetSmoothTitle.
  ///
  /// In en, this message translates to:
  /// **'Smooth'**
  String get optPresetSmoothTitle;

  /// No description provided for @optPresetSmoothDetail.
  ///
  /// In en, this message translates to:
  /// **'30 fps · 10s refresh'**
  String get optPresetSmoothDetail;

  /// No description provided for @optPresetBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery saver'**
  String get optPresetBatteryTitle;

  /// No description provided for @optPresetBatteryDetail.
  ///
  /// In en, this message translates to:
  /// **'20 fps · 30s refresh · effects off'**
  String get optPresetBatteryDetail;

  /// No description provided for @optAdvancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced — pick layers'**
  String get optAdvancedTitle;

  /// No description provided for @optLayerSubway.
  ///
  /// In en, this message translates to:
  /// **'Subway (live train positions)'**
  String get optLayerSubway;

  /// No description provided for @optLayerSubwaySub.
  ///
  /// In en, this message translates to:
  /// **'Seoul subway + metro rail. Highest GPU load'**
  String get optLayerSubwaySub;

  /// No description provided for @optLayerBus.
  ///
  /// In en, this message translates to:
  /// **'City bus'**
  String get optLayerBus;

  /// No description provided for @optLayerBusSub.
  ///
  /// In en, this message translates to:
  /// **'Seoul + Gyeonggi city bus live positions'**
  String get optLayerBusSub;

  /// No description provided for @optLayerRiverBus.
  ///
  /// In en, this message translates to:
  /// **'Han River bus'**
  String get optLayerRiverBus;

  /// No description provided for @optLayerRiverBusSub.
  ///
  /// In en, this message translates to:
  /// **'Han River ferries'**
  String get optLayerRiverBusSub;

  /// No description provided for @optLayerFlights.
  ///
  /// In en, this message translates to:
  /// **'Aircraft'**
  String get optLayerFlights;

  /// No description provided for @optLayerFlightsSub.
  ///
  /// In en, this message translates to:
  /// **'Live aircraft around Incheon airport'**
  String get optLayerFlightsSub;

  /// No description provided for @optDetectedTier.
  ///
  /// In en, this message translates to:
  /// **'Detected as {tier} tier'**
  String optDetectedTier(String tier);

  /// No description provided for @optRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get optRecommended;

  /// No description provided for @vehicleCongestion.
  ///
  /// In en, this message translates to:
  /// **'Crowdedness'**
  String get vehicleCongestion;

  /// No description provided for @vehicleCongestionNone.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get vehicleCongestionNone;

  /// No description provided for @vehicleCongestionFree.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get vehicleCongestionFree;

  /// No description provided for @vehicleCongestionNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get vehicleCongestionNormal;

  /// No description provided for @vehicleCongestionBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get vehicleCongestionBusy;

  /// No description provided for @vehicleCongestionPacked.
  ///
  /// In en, this message translates to:
  /// **'Very crowded'**
  String get vehicleCongestionPacked;

  /// No description provided for @vehicleCongestionFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get vehicleCongestionFull;

  /// No description provided for @vehicleStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get vehicleStatus;

  /// No description provided for @vehicleStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get vehicleStopped;

  /// No description provided for @vehicleRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get vehicleRunning;

  /// No description provided for @vehicleSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get vehicleSection;

  /// No description provided for @vehicleSectionOrd.
  ///
  /// In en, this message translates to:
  /// **'Stop {ord}'**
  String vehicleSectionOrd(int ord);

  /// No description provided for @vehicleBusLowFloor.
  ///
  /// In en, this message translates to:
  /// **'Low-floor'**
  String get vehicleBusLowFloor;

  /// No description provided for @vehicleBusRegular.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get vehicleBusRegular;

  /// No description provided for @vehiclePhaseAscent.
  ///
  /// In en, this message translates to:
  /// **'Climbing'**
  String get vehiclePhaseAscent;

  /// No description provided for @vehiclePhaseCruise.
  ///
  /// In en, this message translates to:
  /// **'Cruise'**
  String get vehiclePhaseCruise;

  /// No description provided for @vehiclePhaseDescent.
  ///
  /// In en, this message translates to:
  /// **'Descent'**
  String get vehiclePhaseDescent;

  /// No description provided for @vehiclePhaseTakeoff.
  ///
  /// In en, this message translates to:
  /// **'Takeoff/landing'**
  String get vehiclePhaseTakeoff;

  /// No description provided for @vehiclePhaseGround.
  ///
  /// In en, this message translates to:
  /// **'On ground'**
  String get vehiclePhaseGround;

  /// No description provided for @vehicleAltitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get vehicleAltitude;

  /// No description provided for @vehicleAltitudeOnGround.
  ///
  /// In en, this message translates to:
  /// **'Ground'**
  String get vehicleAltitudeOnGround;

  /// No description provided for @vehicleSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get vehicleSpeed;

  /// No description provided for @vehicleHeading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get vehicleHeading;

  /// No description provided for @vehicleRiverBusRoute.
  ///
  /// In en, this message translates to:
  /// **'Han River bus {name}'**
  String vehicleRiverBusRoute(String name);

  /// No description provided for @vehicleRiverDirNormal.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get vehicleRiverDirNormal;

  /// No description provided for @vehicleRiverDirReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get vehicleRiverDirReverse;

  /// No description provided for @vehicleRiverPhaseStop.
  ///
  /// In en, this message translates to:
  /// **'Docked'**
  String get vehicleRiverPhaseStop;

  /// No description provided for @vehicleNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get vehicleNext;

  /// No description provided for @vehicleProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get vehicleProgress;

  /// No description provided for @deepLinkRoomLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join a friend room'**
  String get deepLinkRoomLoginRequired;

  /// No description provided for @deepLinkRoomEntered.
  ///
  /// In en, this message translates to:
  /// **'Joined room — code {code}'**
  String deepLinkRoomEntered(String code);

  /// No description provided for @deepLinkRoomFailure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t join the room: {error}'**
  String deepLinkRoomFailure(String error);

  /// No description provided for @snsAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get snsAnalysisTitle;

  /// No description provided for @snsAnalysisEmpty.
  ///
  /// In en, this message translates to:
  /// **'No places extracted'**
  String get snsAnalysisEmpty;

  /// No description provided for @snsAnalysisCreatePlans.
  ///
  /// In en, this message translates to:
  /// **'Create plan ({count})'**
  String snsAnalysisCreatePlans(int count);

  /// No description provided for @snsAnalysisPlanFailure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t build a plan: {error}'**
  String snsAnalysisPlanFailure(String error);

  /// No description provided for @snsAnalysisNearestStation.
  ///
  /// In en, this message translates to:
  /// **'📍 {station} station · {minutes} min'**
  String snsAnalysisNearestStation(String station, int minutes);

  /// No description provided for @avatarMyPin.
  ///
  /// In en, this message translates to:
  /// **'My pin'**
  String get avatarMyPin;

  /// No description provided for @avatarNoRoomHint.
  ///
  /// In en, this message translates to:
  /// **'Join a friend room to see friends here'**
  String get avatarNoRoomHint;

  /// No description provided for @avatarNoRoomMembers.
  ///
  /// In en, this message translates to:
  /// **'No one\'s with you yet'**
  String get avatarNoRoomMembers;

  /// No description provided for @avatarRoomMembersCount.
  ///
  /// In en, this message translates to:
  /// **'With you · {count}'**
  String avatarRoomMembersCount(int count);

  /// No description provided for @avatarNoTrack.
  ///
  /// In en, this message translates to:
  /// **'Not listening to anything'**
  String get avatarNoTrack;

  /// No description provided for @qrScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get qrScanTitle;

  /// No description provided for @qrScanCameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable\n{error}'**
  String qrScanCameraError(String error);

  /// No description provided for @qrScanHint.
  ///
  /// In en, this message translates to:
  /// **'Frame your friend\'s QR code'**
  String get qrScanHint;

  /// No description provided for @buildingOccupantsFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get buildingOccupantsFallbackName;

  /// No description provided for @buildingOccupantsInside.
  ///
  /// In en, this message translates to:
  /// **'{count} inside'**
  String buildingOccupantsInside(int count);

  /// No description provided for @buildingOccupantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Everyone left the building'**
  String get buildingOccupantsEmpty;

  /// No description provided for @buildingOccupantsListening.
  ///
  /// In en, this message translates to:
  /// **'🎵 Listening to {name} · {artist}'**
  String buildingOccupantsListening(String name, String artist);

  /// No description provided for @buildingOccupantsInBuilding.
  ///
  /// In en, this message translates to:
  /// **'🏢 Inside the building'**
  String get buildingOccupantsInBuilding;

  /// No description provided for @weatherWeeklyLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weatherWeeklyLabel;

  /// No description provided for @weatherToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get weatherToday;

  /// No description provided for @weatherDayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weatherDayMon;

  /// No description provided for @weatherDayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weatherDayTue;

  /// No description provided for @weatherDayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weatherDayWed;

  /// No description provided for @weatherDayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weatherDayThu;

  /// No description provided for @weatherDayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weatherDayFri;

  /// No description provided for @weatherDaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weatherDaySat;

  /// No description provided for @weatherDaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weatherDaySun;

  /// No description provided for @locPermTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get locPermTitle;

  /// No description provided for @locPermBody.
  ///
  /// In en, this message translates to:
  /// **'We need location access to show your position on the map\nand to provide accurate nearby info / directions.'**
  String get locPermBody;

  /// No description provided for @locPermRequesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting…'**
  String get locPermRequesting;

  /// No description provided for @locPermRequest.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get locPermRequest;

  /// No description provided for @locPermGranted.
  ///
  /// In en, this message translates to:
  /// **'✓ Location allowed'**
  String get locPermGranted;

  /// No description provided for @locPermDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied — enable it from Settings'**
  String get locPermDenied;

  /// No description provided for @locPermRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get locPermRetry;

  /// No description provided for @groupEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend groups'**
  String get groupEditorTitle;

  /// No description provided for @groupEditorNew.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get groupEditorNew;

  /// No description provided for @groupEditorEmpty.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get groupEditorEmpty;

  /// No description provided for @groupEditorEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + at top-right to create a group and organize friends.'**
  String get groupEditorEmptyHint;

  /// No description provided for @groupEditorHelper.
  ///
  /// In en, this message translates to:
  /// **'Used for group-based visibility / chat'**
  String get groupEditorHelper;

  /// No description provided for @groupEditorNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Family, Work, Club'**
  String get groupEditorNamePlaceholder;

  /// No description provided for @groupEditorCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get groupEditorCreate;

  /// No description provided for @groupEditorFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String groupEditorFailure(String error);

  /// No description provided for @groupEditorMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String groupEditorMemberCount(int count);

  /// No description provided for @groupEditorDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete group {name}'**
  String groupEditorDeleteTitle(String name);

  /// No description provided for @groupEditorDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Only the group is deleted; friends are kept.'**
  String get groupEditorDeleteBody;

  /// No description provided for @groupEditorDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get groupEditorDelete;

  /// No description provided for @groupEditorAddFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Add friends first.'**
  String get groupEditorAddFriendsHint;

  /// No description provided for @peerPinDestinationFallback.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get peerPinDestinationFallback;

  /// No description provided for @peerPinDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'🎯 {name}'**
  String peerPinDestinationLabel(String name);

  /// No description provided for @stationDetailCloseLabel.
  ///
  /// In en, this message translates to:
  /// **'Close station detail'**
  String get stationDetailCloseLabel;

  /// No description provided for @stationDetailDeparture.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get stationDetailDeparture;

  /// No description provided for @stationDetailArrival.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get stationDetailArrival;

  /// No description provided for @stationDetailLiveArrivals.
  ///
  /// In en, this message translates to:
  /// **'Live arrivals'**
  String get stationDetailLiveArrivals;

  /// No description provided for @stationDetailLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get stationDetailLoading;

  /// No description provided for @stationDetailNoArrivals.
  ///
  /// In en, this message translates to:
  /// **'No arrival info'**
  String get stationDetailNoArrivals;

  /// No description provided for @stationDetailCrowdVery.
  ///
  /// In en, this message translates to:
  /// **'Very crowded'**
  String get stationDetailCrowdVery;

  /// No description provided for @stationDetailCrowdBusy.
  ///
  /// In en, this message translates to:
  /// **'Crowded'**
  String get stationDetailCrowdBusy;

  /// No description provided for @stationDetailCrowdNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get stationDetailCrowdNormal;

  /// No description provided for @stationDetailCrowdFree.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get stationDetailCrowdFree;

  /// No description provided for @stationDetailBoardingCount.
  ///
  /// In en, this message translates to:
  /// **'Boarding {count}'**
  String stationDetailBoardingCount(String count);

  /// No description provided for @stationDetailAlightingCount.
  ///
  /// In en, this message translates to:
  /// **'Alighting {count}'**
  String stationDetailAlightingCount(String count);

  /// No description provided for @stationDetailClosureCount.
  ///
  /// In en, this message translates to:
  /// **'{count} closures'**
  String stationDetailClosureCount(int count);
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'ja':
      return AppL10nJa();
    case 'ko':
      return AppL10nKo();
    case 'zh':
      return AppL10nZh();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
