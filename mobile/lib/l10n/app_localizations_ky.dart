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
  String get commonDoctors => 'Дарыгерлер';

  @override
  String get commonClinics => 'Клиникалар';

  @override
  String get commonPharmacies => 'Дарыканалар';

  @override
  String get commonShowAll => 'Баары';

  @override
  String get roleDoctor => 'Дарыгер';

  @override
  String get roleClinic => 'Клиника';

  @override
  String get rolePharmacy => 'Дарыкана';

  @override
  String get roleAdmin => 'Админ';

  @override
  String get rolePatient => 'Бейтап';

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

  @override
  String get onboardingTagDoctors => '👨‍⚕️  Дарыгерлер';

  @override
  String get onboardingTagClinics => '🏥  Клиникалар';

  @override
  String get onboardingTagPharmacies => '💊  Дарыканалар';

  @override
  String get onboardingTagSearch => '🔍  Жакындан издөө';

  @override
  String get onboardingTitle => 'Ден соолук\nушул жерден башталат';

  @override
  String get onboardingSubtitle =>
      'Кыргызстанда жакын жерден дарыгерди, клиниканы же дарыкананы табыңыз';

  @override
  String get authLoginTitle => 'Кош\nкелиңиз!';

  @override
  String get authLoginSubtitle => 'MedFind аккаунтуңузга кириңиз';

  @override
  String get authPhoneLabel => 'Телефон номери';

  @override
  String get authPhoneHint => '700 000 000';

  @override
  String get authPhoneInvalid => 'Туура номер киргизиңиз (9 цифра)';

  @override
  String get authPasswordLabel => 'Сырсөз';

  @override
  String get authPasswordMin6 => 'Кеминде 6 символ';

  @override
  String get authForgotPassword => 'Сырсөздү унуттуңузбу?';

  @override
  String get authLoginButton => 'Кирүү';

  @override
  String get authRegisterButton => 'Катталуу';

  @override
  String get authNoAccount => 'Аккаунтуңуз жокпу? ';

  @override
  String get authLoginError => 'Кирүү катасы';

  @override
  String get homeGreetingMorning => 'Кутмандуу таң';

  @override
  String get homeGreetingDay => 'Кутмандуу күн';

  @override
  String get homeGreetingEvening => 'Кутмандуу кеч';

  @override
  String get homeQuickSearch => 'Издөө';

  @override
  String get homeAiHelper => 'ЖИ-Жардамчы';

  @override
  String get homeAiHelperHint =>
      'Симптомдоруңузду жазыңыз — ЖИ\nкайсы дарыгерге барууну айтат';

  @override
  String get homeSectionSymptoms => 'Симптомдор';

  @override
  String get homeSectionSpecializations => 'Адистиктер';
}
