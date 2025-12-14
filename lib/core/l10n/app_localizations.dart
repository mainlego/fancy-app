import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
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
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

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
    Locale('ru')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FANCY'**
  String get appName;

  /// No description provided for @navigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navigationHome;

  /// No description provided for @navigationChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navigationChats;

  /// No description provided for @navigationProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navigationProfile;

  /// No description provided for @navigationSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navigationSettings;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @filterGoals.
  ///
  /// In en, this message translates to:
  /// **'Dating goals'**
  String get filterGoals;

  /// No description provided for @filterGoalAnything.
  ///
  /// In en, this message translates to:
  /// **'Anything'**
  String get filterGoalAnything;

  /// No description provided for @filterGoalCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get filterGoalCasual;

  /// No description provided for @filterGoalVirtual.
  ///
  /// In en, this message translates to:
  /// **'Virtual'**
  String get filterGoalVirtual;

  /// No description provided for @filterGoalFriendship.
  ///
  /// In en, this message translates to:
  /// **'Friendship'**
  String get filterGoalFriendship;

  /// No description provided for @filterGoalLongTerm.
  ///
  /// In en, this message translates to:
  /// **'Long-term'**
  String get filterGoalLongTerm;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Relationship status'**
  String get filterStatus;

  /// No description provided for @filterStatusSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get filterStatusSingle;

  /// No description provided for @filterStatusComplicated.
  ///
  /// In en, this message translates to:
  /// **'Complicated'**
  String get filterStatusComplicated;

  /// No description provided for @filterStatusMarried.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get filterStatusMarried;

  /// No description provided for @filterStatusInRelationship.
  ///
  /// In en, this message translates to:
  /// **'In a relationship'**
  String get filterStatusInRelationship;

  /// No description provided for @filterDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get filterDistance;

  /// No description provided for @filterDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String filterDistanceKm(int distance);

  /// No description provided for @filterAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get filterAge;

  /// No description provided for @filterAgeRange.
  ///
  /// In en, this message translates to:
  /// **'{min} - {max} years'**
  String filterAgeRange(int min, int max);

  /// No description provided for @filterOnlineOnly.
  ///
  /// In en, this message translates to:
  /// **'Online only'**
  String get filterOnlineOnly;

  /// No description provided for @filterWithPhoto.
  ///
  /// In en, this message translates to:
  /// **'With photo'**
  String get filterWithPhoto;

  /// No description provided for @filterVerifiedPhoto.
  ///
  /// In en, this message translates to:
  /// **'Verified photos'**
  String get filterVerifiedPhoto;

  /// No description provided for @filterLookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking for'**
  String get filterLookingFor;

  /// No description provided for @filterLookingForWoman.
  ///
  /// In en, this message translates to:
  /// **'Woman'**
  String get filterLookingForWoman;

  /// No description provided for @filterLookingForMan.
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get filterLookingForMan;

  /// No description provided for @filterLookingForBoth.
  ///
  /// In en, this message translates to:
  /// **'Man & Woman'**
  String get filterLookingForBoth;

  /// No description provided for @filterLookingForManPair.
  ///
  /// In en, this message translates to:
  /// **'Man pair'**
  String get filterLookingForManPair;

  /// No description provided for @filterLookingForWomanPair.
  ///
  /// In en, this message translates to:
  /// **'Woman pair'**
  String get filterLookingForWomanPair;

  /// No description provided for @filterHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get filterHeight;

  /// No description provided for @filterWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get filterWeight;

  /// No description provided for @filterZodiac.
  ///
  /// In en, this message translates to:
  /// **'Zodiac sign'**
  String get filterZodiac;

  /// No description provided for @filterLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get filterLanguage;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get filterApply;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get profileAbout;

  /// No description provided for @profileAboutHint.
  ///
  /// In en, this message translates to:
  /// **'Tell about yourself (max 300 characters)'**
  String get profileAboutHint;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get profileAlbums;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profilePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get profilePhotos;

  /// No description provided for @profileAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get profileAddPhoto;

  /// No description provided for @profileOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get profileOnline;

  /// No description provided for @profileOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get profileOffline;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerified;

  /// No description provided for @profileNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get profileNotVerified;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTitle;

  /// No description provided for @profileEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileEditSave;

  /// No description provided for @profileEditGoals.
  ///
  /// In en, this message translates to:
  /// **'Dating goals'**
  String get profileEditGoals;

  /// No description provided for @profileEditStatus.
  ///
  /// In en, this message translates to:
  /// **'Relationship status'**
  String get profileEditStatus;

  /// No description provided for @profileEditInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get profileEditInterests;

  /// No description provided for @profileEditOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get profileEditOccupation;

  /// No description provided for @profileEditBirthday.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileEditBirthday;

  /// No description provided for @profileEditHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileEditHeight;

  /// No description provided for @profileEditWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get profileEditWeight;

  /// No description provided for @profileEditLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get profileEditLanguages;

  /// No description provided for @profileEditLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileEditLocation;

  /// No description provided for @profileEditType.
  ///
  /// In en, this message translates to:
  /// **'Profile type'**
  String get profileEditType;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsPremium.
  ///
  /// In en, this message translates to:
  /// **'Fancy Premium'**
  String get settingsPremium;

  /// No description provided for @settingsPremiumUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get settingsPremiumUpgrade;

  /// No description provided for @settingsVerification.
  ///
  /// In en, this message translates to:
  /// **'Photo verification'**
  String get settingsVerification;

  /// No description provided for @settingsVerificationStart.
  ///
  /// In en, this message translates to:
  /// **'Start verification'**
  String get settingsVerificationStart;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsRestorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get settingsRestorePurchase;

  /// No description provided for @settingsPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get settingsPaymentMethod;

  /// No description provided for @settingsCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get settingsCancelSubscription;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get settingsBlockedUsers;

  /// No description provided for @settingsIncognito.
  ///
  /// In en, this message translates to:
  /// **'Incognito mode'**
  String get settingsIncognito;

  /// No description provided for @settingsAppIcon.
  ///
  /// In en, this message translates to:
  /// **'App icon & name'**
  String get settingsAppIcon;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotifyMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get settingsNotifyMatches;

  /// No description provided for @settingsNotifyLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get settingsNotifyLikes;

  /// No description provided for @settingsNotifySuperLikes.
  ///
  /// In en, this message translates to:
  /// **'Super likes'**
  String get settingsNotifySuperLikes;

  /// No description provided for @settingsNotifyMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get settingsNotifyMessages;

  /// No description provided for @settingsOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get settingsOther;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get settingsTerms;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get settingsFaq;

  /// No description provided for @settingsSuggestImprovement.
  ///
  /// In en, this message translates to:
  /// **'Suggest improvement'**
  String get settingsSuggestImprovement;

  /// No description provided for @settingsContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get settingsContactUs;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// No description provided for @settingsUnitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get settingsUnitsMetric;

  /// No description provided for @settingsUnitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get settingsUnitsImperial;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsLanguageRu.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get settingsLanguageRu;

  /// No description provided for @chatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// No description provided for @chatsTabChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTabChats;

  /// No description provided for @chatsTabLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get chatsTabLikes;

  /// No description provided for @chatsTabFavs.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get chatsTabFavs;

  /// No description provided for @chatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get chatsEmpty;

  /// No description provided for @chatsDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get chatsDeleteChat;

  /// No description provided for @chatsTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatsTypeMessage;

  /// No description provided for @chatsSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatsSend;

  /// No description provided for @albumsTitle.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albumsTitle;

  /// No description provided for @albumsPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get albumsPublic;

  /// No description provided for @albumsPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get albumsPrivate;

  /// No description provided for @albumsAddMedia.
  ///
  /// In en, this message translates to:
  /// **'Add photo/video'**
  String get albumsAddMedia;

  /// No description provided for @albumsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get albumsDelete;

  /// No description provided for @albumsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get albumsEdit;

  /// No description provided for @homeQuickFilters.
  ///
  /// In en, this message translates to:
  /// **'Quick filters'**
  String get homeQuickFilters;

  /// No description provided for @homeNoProfiles.
  ///
  /// In en, this message translates to:
  /// **'No profiles found'**
  String get homeNoProfiles;

  /// No description provided for @homeLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get homeLoadMore;

  /// No description provided for @actionLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get actionLike;

  /// No description provided for @actionSuperLike.
  ///
  /// In en, this message translates to:
  /// **'Super like'**
  String get actionSuperLike;

  /// No description provided for @actionReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get actionReport;

  /// No description provided for @actionBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get actionBlock;

  /// No description provided for @actionHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get actionHide;

  /// No description provided for @distanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String distanceAway(int distance);

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String yearsOld(int age);

  /// No description provided for @zodiacAries.
  ///
  /// In en, this message translates to:
  /// **'Aries'**
  String get zodiacAries;

  /// No description provided for @zodiacTaurus.
  ///
  /// In en, this message translates to:
  /// **'Taurus'**
  String get zodiacTaurus;

  /// No description provided for @zodiacGemini.
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get zodiacGemini;

  /// No description provided for @zodiacCancer.
  ///
  /// In en, this message translates to:
  /// **'Cancer'**
  String get zodiacCancer;

  /// No description provided for @zodiacLeo.
  ///
  /// In en, this message translates to:
  /// **'Leo'**
  String get zodiacLeo;

  /// No description provided for @zodiacVirgo.
  ///
  /// In en, this message translates to:
  /// **'Virgo'**
  String get zodiacVirgo;

  /// No description provided for @zodiacLibra.
  ///
  /// In en, this message translates to:
  /// **'Libra'**
  String get zodiacLibra;

  /// No description provided for @zodiacScorpio.
  ///
  /// In en, this message translates to:
  /// **'Scorpio'**
  String get zodiacScorpio;

  /// No description provided for @zodiacSagittarius.
  ///
  /// In en, this message translates to:
  /// **'Sagittarius'**
  String get zodiacSagittarius;

  /// No description provided for @zodiacCapricorn.
  ///
  /// In en, this message translates to:
  /// **'Capricorn'**
  String get zodiacCapricorn;

  /// No description provided for @zodiacAquarius.
  ///
  /// In en, this message translates to:
  /// **'Aquarius'**
  String get zodiacAquarius;

  /// No description provided for @zodiacPisces.
  ///
  /// In en, this message translates to:
  /// **'Pisces'**
  String get zodiacPisces;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'ru':
      return SRu();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
