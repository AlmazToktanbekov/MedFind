// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kirghiz Kyrgyz (`ky`).
class AppLocalizationsKy extends AppLocalizations {
  AppLocalizationsKy([String locale = 'ky']) : super(locale);

  @override
  String get appTitle => 'MedFind';

  @override
  String get navHome => 'Башкы';

  @override
  String get navSearch => 'Издөө';

  @override
  String get navAi => 'ЖИ';

  @override
  String get navHealth => 'Ден соолук';

  @override
  String get navProfile => 'Профиль';

  @override
  String get commonRetry => 'Кайталоо';

  @override
  String get commonLoading => 'Жүктөлүүдө…';

  @override
  String get profileUser => 'Колдонуучу';

  @override
  String get profileFavorites => 'Тандалмалар';

  @override
  String get profileFavoriteClinics => 'Тандалган клиникалар';

  @override
  String get profileFavoritePharmacies => 'Тандалган дарыканалар';

  @override
  String get profileSearchHistory => 'Издөө тарыхы';

  @override
  String get profileClear => 'Тазалоо';

  @override
  String get profileAppLanguage => 'Колдонмонун тили';

  @override
  String get profileLogout => 'Чыгуу';

  @override
  String get pharmaciesTitle => 'Дарыканалар';

  @override
  String get pharmaciesAll => 'Бардык дарыканалар';

  @override
  String get pharmaciesNearby => 'Жакынкылар';

  @override
  String get pharmaciesNotFound => 'Дарыканалар табылган жок';

  @override
  String get pharmaciesNearbyNotFound => 'Жакын жерден дарыкана табылган жок';

  @override
  String pharmaciesDistanceFromYou(String km) {
    return 'Сизден $km км';
  }

  @override
  String get locationServiceDisabled =>
      'Геолокация түзмөктө өчүрүлгөн. Жөндөөлөрдөн күйгүзүңүз.';

  @override
  String get locationPermissionDenied =>
      'Жакынкы дарыканаларды көрсөтүү үчүн геолокацияга уруксат бериңиз.';

  @override
  String get locationPermissionDeniedForever =>
      'Геолокацияга уруксат жок. Колдонмонун жөндөөлөрүнөн уруксат бериңиз.';

  @override
  String get locationEnableGeo => 'Геолокацияны күйгүзүү';

  @override
  String get locationOpenSettings => 'Жөндөөлөрдү ачуу';

  @override
  String get locationAllow => 'Уруксат берүү';
}
