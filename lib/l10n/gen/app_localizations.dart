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
  /// **'Language changed'**
  String get languageChangedTitle;

  /// No description provided for @languageChangedBody.
  ///
  /// In en, this message translates to:
  /// **'Restart the app to fully apply the new language. Restart now?'**
  String get languageChangedBody;

  /// No description provided for @languageRestartNow.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get languageRestartNow;

  /// No description provided for @languageRestartLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get languageRestartLater;

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
  /// **'Theme changed'**
  String get settingsThemeChangedTitle;

  /// No description provided for @settingsThemeChangedBody.
  ///
  /// In en, this message translates to:
  /// **'Restart to fully apply {theme} mode. Restart now?'**
  String settingsThemeChangedBody(String theme);

  /// No description provided for @settingsRestartConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
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
