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
