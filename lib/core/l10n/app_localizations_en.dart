// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FANCY';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationChats => 'Chats';

  @override
  String get navigationProfile => 'Profile';

  @override
  String get navigationSettings => 'Settings';

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterGoals => 'Dating goals';

  @override
  String get filterGoalAnything => 'Anything';

  @override
  String get filterGoalCasual => 'Casual';

  @override
  String get filterGoalVirtual => 'Virtual';

  @override
  String get filterGoalFriendship => 'Friendship';

  @override
  String get filterGoalLongTerm => 'Long-term';

  @override
  String get filterStatus => 'Relationship status';

  @override
  String get filterStatusSingle => 'Single';

  @override
  String get filterStatusComplicated => 'Complicated';

  @override
  String get filterStatusMarried => 'Married';

  @override
  String get filterStatusInRelationship => 'In a relationship';

  @override
  String get filterDistance => 'Distance';

  @override
  String filterDistanceKm(int distance) {
    return '$distance km';
  }

  @override
  String get filterAge => 'Age';

  @override
  String filterAgeRange(int min, int max) {
    return '$min - $max years';
  }

  @override
  String get filterOnlineOnly => 'Online only';

  @override
  String get filterWithPhoto => 'With photo';

  @override
  String get filterVerifiedPhoto => 'Verified photos';

  @override
  String get filterLookingFor => 'Looking for';

  @override
  String get filterLookingForWoman => 'Woman';

  @override
  String get filterLookingForMan => 'Man';

  @override
  String get filterLookingForBoth => 'Man & Woman';

  @override
  String get filterLookingForManPair => 'Man pair';

  @override
  String get filterLookingForWomanPair => 'Woman pair';

  @override
  String get filterHeight => 'Height';

  @override
  String get filterWeight => 'Weight';

  @override
  String get filterZodiac => 'Zodiac sign';

  @override
  String get filterLanguage => 'Language';

  @override
  String get filterApply => 'Apply filters';

  @override
  String get filterReset => 'Reset';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileAbout => 'About me';

  @override
  String get profileAboutHint => 'Tell about yourself (max 300 characters)';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileAlbums => 'Albums';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profilePhotos => 'Photos';

  @override
  String get profileAddPhoto => 'Add photo';

  @override
  String get profileOnline => 'Online';

  @override
  String get profileOffline => 'Offline';

  @override
  String get profileVerified => 'Verified';

  @override
  String get profileNotVerified => 'Not verified';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileEditSave => 'Save';

  @override
  String get profileEditGoals => 'Dating goals';

  @override
  String get profileEditStatus => 'Relationship status';

  @override
  String get profileEditInterests => 'Interests';

  @override
  String get profileEditOccupation => 'Occupation';

  @override
  String get profileEditBirthday => 'Date of birth';

  @override
  String get profileEditHeight => 'Height';

  @override
  String get profileEditWeight => 'Weight';

  @override
  String get profileEditLanguages => 'Languages';

  @override
  String get profileEditLocation => 'Location';

  @override
  String get profileEditType => 'Profile type';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPremium => 'Fancy Premium';

  @override
  String get settingsPremiumUpgrade => 'Upgrade to Premium';

  @override
  String get settingsVerification => 'Photo verification';

  @override
  String get settingsVerificationStart => 'Start verification';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsRestorePurchase => 'Restore purchase';

  @override
  String get settingsPaymentMethod => 'Payment method';

  @override
  String get settingsCancelSubscription => 'Cancel subscription';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsBlockedUsers => 'Blocked users';

  @override
  String get settingsIncognito => 'Incognito mode';

  @override
  String get settingsAppIcon => 'App icon & name';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifyMatches => 'Matches';

  @override
  String get settingsNotifyLikes => 'Likes';

  @override
  String get settingsNotifySuperLikes => 'Super likes';

  @override
  String get settingsNotifyMessages => 'Messages';

  @override
  String get settingsOther => 'Other';

  @override
  String get settingsTerms => 'Terms of use';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsFaq => 'FAQ';

  @override
  String get settingsSuggestImprovement => 'Suggest improvement';

  @override
  String get settingsContactUs => 'Contact us';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsUnitsMetric => 'Metric';

  @override
  String get settingsUnitsImperial => 'Imperial';

  @override
  String get settingsLanguage => 'App language';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageRu => 'Russian';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsTabChats => 'Chats';

  @override
  String get chatsTabLikes => 'Likes';

  @override
  String get chatsTabFavs => 'Favorites';

  @override
  String get chatsEmpty => 'No chats yet';

  @override
  String get chatsDeleteChat => 'Delete chat';

  @override
  String get chatsTypeMessage => 'Type a message...';

  @override
  String get chatsSend => 'Send';

  @override
  String get albumsTitle => 'Albums';

  @override
  String get albumsPublic => 'Public';

  @override
  String get albumsPrivate => 'Private';

  @override
  String get albumsAddMedia => 'Add photo/video';

  @override
  String get albumsDelete => 'Delete';

  @override
  String get albumsEdit => 'Edit';

  @override
  String get homeQuickFilters => 'Quick filters';

  @override
  String get homeNoProfiles => 'No profiles found';

  @override
  String get homeLoadMore => 'Load more';

  @override
  String get actionLike => 'Like';

  @override
  String get actionSuperLike => 'Super like';

  @override
  String get actionReport => 'Report';

  @override
  String get actionBlock => 'Block';

  @override
  String get actionHide => 'Hide';

  @override
  String distanceAway(int distance) {
    return '$distance km away';
  }

  @override
  String yearsOld(int age) {
    return '$age years old';
  }

  @override
  String get zodiacAries => 'Aries';

  @override
  String get zodiacTaurus => 'Taurus';

  @override
  String get zodiacGemini => 'Gemini';

  @override
  String get zodiacCancer => 'Cancer';

  @override
  String get zodiacLeo => 'Leo';

  @override
  String get zodiacVirgo => 'Virgo';

  @override
  String get zodiacLibra => 'Libra';

  @override
  String get zodiacScorpio => 'Scorpio';

  @override
  String get zodiacSagittarius => 'Sagittarius';

  @override
  String get zodiacCapricorn => 'Capricorn';

  @override
  String get zodiacAquarius => 'Aquarius';

  @override
  String get zodiacPisces => 'Pisces';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';
}
