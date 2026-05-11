// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MedFind';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navAi => 'AI';

  @override
  String get navHealth => 'Health';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get profileUser => 'User';

  @override
  String get profileFavorites => 'Favorites';

  @override
  String get profileFavoriteClinics => 'Favorite clinics';

  @override
  String get profileFavoritePharmacies => 'Favorite pharmacies';

  @override
  String get profileSearchHistory => 'Search history';

  @override
  String get profileClear => 'Clear';

  @override
  String get profileAppLanguage => 'App language';

  @override
  String get profileLogout => 'Log out';

  @override
  String get pharmaciesTitle => 'Pharmacies';

  @override
  String get pharmaciesAll => 'All pharmacies';

  @override
  String get pharmaciesNearby => 'Nearby';

  @override
  String get pharmaciesNotFound => 'No pharmacies found';

  @override
  String get pharmaciesNearbyNotFound => 'No pharmacies nearby';

  @override
  String pharmaciesDistanceFromYou(String km) {
    return '$km km from you';
  }

  @override
  String get locationServiceDisabled =>
      'Location is disabled on this device. Turn it on in settings.';

  @override
  String get locationPermissionDenied =>
      'To show nearby pharmacies, allow location access.';

  @override
  String get locationPermissionDeniedForever =>
      'Location access is denied. Allow it in the app settings.';

  @override
  String get locationEnableGeo => 'Enable location';

  @override
  String get locationOpenSettings => 'Open settings';

  @override
  String get locationAllow => 'Allow';
}
