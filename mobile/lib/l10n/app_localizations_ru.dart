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
}
