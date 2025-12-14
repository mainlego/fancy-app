// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'FANCY';

  @override
  String get navigationHome => 'Главная';

  @override
  String get navigationChats => 'Чаты';

  @override
  String get navigationProfile => 'Профиль';

  @override
  String get navigationSettings => 'Настройки';

  @override
  String get filterTitle => 'Фильтры';

  @override
  String get filterGoals => 'Цели знакомства';

  @override
  String get filterGoalAnything => 'Любые';

  @override
  String get filterGoalCasual => 'Флирт';

  @override
  String get filterGoalVirtual => 'Виртуальное';

  @override
  String get filterGoalFriendship => 'Дружба';

  @override
  String get filterGoalLongTerm => 'Серьёзные';

  @override
  String get filterStatus => 'Семейное положение';

  @override
  String get filterStatusSingle => 'Свободен';

  @override
  String get filterStatusComplicated => 'Всё сложно';

  @override
  String get filterStatusMarried => 'В браке';

  @override
  String get filterStatusInRelationship => 'В отношениях';

  @override
  String get filterDistance => 'Расстояние';

  @override
  String filterDistanceKm(int distance) {
    return '$distance км';
  }

  @override
  String get filterAge => 'Возраст';

  @override
  String filterAgeRange(int min, int max) {
    return '$min - $max лет';
  }

  @override
  String get filterOnlineOnly => 'Только онлайн';

  @override
  String get filterWithPhoto => 'С фото';

  @override
  String get filterVerifiedPhoto => 'С проверенным фото';

  @override
  String get filterLookingFor => 'Ищу';

  @override
  String get filterLookingForWoman => 'Женщину';

  @override
  String get filterLookingForMan => 'Мужчину';

  @override
  String get filterLookingForBoth => 'Мужчину и женщину';

  @override
  String get filterLookingForManPair => 'Мужскую пару';

  @override
  String get filterLookingForWomanPair => 'Женскую пару';

  @override
  String get filterHeight => 'Рост';

  @override
  String get filterWeight => 'Вес';

  @override
  String get filterZodiac => 'Знак зодиака';

  @override
  String get filterLanguage => 'Язык';

  @override
  String get filterApply => 'Применить';

  @override
  String get filterReset => 'Сбросить';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileAbout => 'О себе';

  @override
  String get profileAboutHint => 'Расскажите о себе (макс. 300 символов)';

  @override
  String get profileEdit => 'Редактировать';

  @override
  String get profileAlbums => 'Альбомы';

  @override
  String get profileSettings => 'Настройки';

  @override
  String get profilePhotos => 'Фотографии';

  @override
  String get profileAddPhoto => 'Добавить фото';

  @override
  String get profileOnline => 'Онлайн';

  @override
  String get profileOffline => 'Не в сети';

  @override
  String get profileVerified => 'Проверено';

  @override
  String get profileNotVerified => 'Не проверено';

  @override
  String get profileEditTitle => 'Редактирование профиля';

  @override
  String get profileEditSave => 'Сохранить';

  @override
  String get profileEditGoals => 'Цели знакомства';

  @override
  String get profileEditStatus => 'Семейное положение';

  @override
  String get profileEditInterests => 'Интересы';

  @override
  String get profileEditOccupation => 'Род деятельности';

  @override
  String get profileEditBirthday => 'Дата рождения';

  @override
  String get profileEditHeight => 'Рост';

  @override
  String get profileEditWeight => 'Вес';

  @override
  String get profileEditLanguages => 'Языки';

  @override
  String get profileEditLocation => 'Местоположение';

  @override
  String get profileEditType => 'Тип профиля';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsPremium => 'Fancy Premium';

  @override
  String get settingsPremiumUpgrade => 'Перейти на Premium';

  @override
  String get settingsVerification => 'Верификация фото';

  @override
  String get settingsVerificationStart => 'Начать верификацию';

  @override
  String get settingsSubscription => 'Подписка';

  @override
  String get settingsRestorePurchase => 'Восстановить покупку';

  @override
  String get settingsPaymentMethod => 'Способ оплаты';

  @override
  String get settingsCancelSubscription => 'Отменить подписку';

  @override
  String get settingsSecurity => 'Безопасность';

  @override
  String get settingsBlockedUsers => 'Заблокированные';

  @override
  String get settingsIncognito => 'Режим инкогнито';

  @override
  String get settingsAppIcon => 'Иконка приложения';

  @override
  String get settingsDeleteAccount => 'Удалить аккаунт';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsNotifyMatches => 'Совпадения';

  @override
  String get settingsNotifyLikes => 'Лайки';

  @override
  String get settingsNotifySuperLikes => 'Супер лайки';

  @override
  String get settingsNotifyMessages => 'Сообщения';

  @override
  String get settingsOther => 'Прочее';

  @override
  String get settingsTerms => 'Условия использования';

  @override
  String get settingsPrivacy => 'Политика конфиденциальности';

  @override
  String get settingsFaq => 'ЧАВО';

  @override
  String get settingsSuggestImprovement => 'Предложить улучшение';

  @override
  String get settingsContactUs => 'Связаться с нами';

  @override
  String get settingsUnits => 'Система измерений';

  @override
  String get settingsUnitsMetric => 'Метрическая';

  @override
  String get settingsUnitsImperial => 'Имперская';

  @override
  String get settingsLanguage => 'Язык приложения';

  @override
  String get settingsLanguageEn => 'Английский';

  @override
  String get settingsLanguageRu => 'Русский';

  @override
  String get chatsTitle => 'Чаты';

  @override
  String get chatsTabChats => 'Чаты';

  @override
  String get chatsTabLikes => 'Лайки';

  @override
  String get chatsTabFavs => 'Избранное';

  @override
  String get chatsEmpty => 'Пока нет чатов';

  @override
  String get chatsDeleteChat => 'Удалить чат';

  @override
  String get chatsTypeMessage => 'Введите сообщение...';

  @override
  String get chatsSend => 'Отправить';

  @override
  String get albumsTitle => 'Альбомы';

  @override
  String get albumsPublic => 'Публичные';

  @override
  String get albumsPrivate => 'Приватные';

  @override
  String get albumsAddMedia => 'Добавить фото/видео';

  @override
  String get albumsDelete => 'Удалить';

  @override
  String get albumsEdit => 'Редактировать';

  @override
  String get homeQuickFilters => 'Быстрые фильтры';

  @override
  String get homeNoProfiles => 'Профили не найдены';

  @override
  String get homeLoadMore => 'Загрузить ещё';

  @override
  String get actionLike => 'Нравится';

  @override
  String get actionSuperLike => 'Супер лайк';

  @override
  String get actionReport => 'Пожаловаться';

  @override
  String get actionBlock => 'Заблокировать';

  @override
  String get actionHide => 'Скрыть';

  @override
  String distanceAway(int distance) {
    return '$distance км от вас';
  }

  @override
  String yearsOld(int age) {
    return '$age лет';
  }

  @override
  String get zodiacAries => 'Овен';

  @override
  String get zodiacTaurus => 'Телец';

  @override
  String get zodiacGemini => 'Близнецы';

  @override
  String get zodiacCancer => 'Рак';

  @override
  String get zodiacLeo => 'Лев';

  @override
  String get zodiacVirgo => 'Дева';

  @override
  String get zodiacLibra => 'Весы';

  @override
  String get zodiacScorpio => 'Скорпион';

  @override
  String get zodiacSagittarius => 'Стрелец';

  @override
  String get zodiacCapricorn => 'Козерог';

  @override
  String get zodiacAquarius => 'Водолей';

  @override
  String get zodiacPisces => 'Рыбы';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get ok => 'ОК';

  @override
  String get error => 'Ошибка';

  @override
  String get loading => 'Загрузка...';

  @override
  String get retry => 'Повторить';
}
