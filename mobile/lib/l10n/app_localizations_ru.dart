// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'MedFind';

  @override
  String get navHome => 'Главная';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navAi => 'ИИ';

  @override
  String get navHealth => 'Здоровье';

  @override
  String get navProfile => 'Профиль';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonLoading => 'Загрузка…';

  @override
  String get commonDoctors => 'Врачи';

  @override
  String get commonClinics => 'Клиники';

  @override
  String get commonPharmacies => 'Аптеки';

  @override
  String get commonShowAll => 'Все';

  @override
  String get roleDoctor => 'Врач';

  @override
  String get roleClinic => 'Клиника';

  @override
  String get rolePharmacy => 'Аптека';

  @override
  String get roleAdmin => 'Админ';

  @override
  String get rolePatient => 'Пациент';

  @override
  String get profileUser => 'Пользователь';

  @override
  String get profileFavorites => 'Избранные';

  @override
  String get profileFavoriteClinics => 'Избранные клиники';

  @override
  String get profileFavoritePharmacies => 'Избранные аптеки';

  @override
  String get profileSearchHistory => 'История поиска';

  @override
  String get profileClear => 'Очистить';

  @override
  String get profileAppLanguage => 'Язык приложения';

  @override
  String get profileLogout => 'Выйти';

  @override
  String get pharmaciesTitle => 'Аптеки';

  @override
  String get pharmaciesAll => 'Все аптеки';

  @override
  String get pharmaciesNearby => 'Ближайшие';

  @override
  String get pharmaciesNotFound => 'Аптеки не найдены';

  @override
  String get pharmaciesNearbyNotFound => 'Аптек рядом не найдено';

  @override
  String pharmaciesDistanceFromYou(String km) {
    return '$km км от вас';
  }

  @override
  String get locationServiceDisabled =>
      'Геолокация отключена на устройстве. Включите её в настройках.';

  @override
  String get locationPermissionDenied =>
      'Чтобы показать ближайшие аптеки, разрешите доступ к геолокации.';

  @override
  String get locationPermissionDeniedForever =>
      'Доступ к геолокации запрещён. Разрешите его в настройках приложения.';

  @override
  String get locationEnableGeo => 'Включить геолокацию';

  @override
  String get locationOpenSettings => 'Открыть настройки';

  @override
  String get locationAllow => 'Разрешить';

  @override
  String get onboardingTagDoctors => '👨‍⚕️  Врачи';

  @override
  String get onboardingTagClinics => '🏥  Клиники';

  @override
  String get onboardingTagPharmacies => '💊  Аптеки';

  @override
  String get onboardingTagSearch => '🔍  Поиск рядом';

  @override
  String get onboardingTitle => 'Здоровье\nначинается здесь';

  @override
  String get onboardingSubtitle =>
      'Найдите врача, клинику или аптеку рядом с вами в Кыргызстане';

  @override
  String get authLoginTitle => 'Добро\nпожаловать!';

  @override
  String get authLoginSubtitle => 'Войдите в свой аккаунт MedFind';

  @override
  String get authPhoneLabel => 'Номер телефона';

  @override
  String get authPhoneHint => '700 000 000';

  @override
  String get authPhoneInvalid => 'Введите корректный номер (9 цифр)';

  @override
  String get authPasswordLabel => 'Пароль';

  @override
  String get authPasswordMin6 => 'Минимум 6 символов';

  @override
  String get authForgotPassword => 'Забыли пароль?';

  @override
  String get authLoginButton => 'Войти';

  @override
  String get authRegisterButton => 'Зарегистрироваться';

  @override
  String get authNoAccount => 'Нет аккаунта? ';

  @override
  String get authLoginError => 'Ошибка входа';

  @override
  String get homeGreetingMorning => 'Доброе утро';

  @override
  String get homeGreetingDay => 'Добрый день';

  @override
  String get homeGreetingEvening => 'Добрый вечер';

  @override
  String get homeQuickSearch => 'Поиск';

  @override
  String get homeAiHelper => 'ИИ-Помощник';

  @override
  String get homeAiHelperHint =>
      'Опишите симптомы — ИИ подскажет\nк какому врачу обратиться';

  @override
  String get homeSectionSymptoms => 'Симптомы';

  @override
  String get homeSectionSpecializations => 'Специализации';
}
