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
  String get commonDoctors => 'Doctors';

  @override
  String get commonClinics => 'Clinics';

  @override
  String get commonPharmacies => 'Pharmacies';

  @override
  String get commonShowAll => 'All';

  @override
  String get roleDoctor => 'Doctor';

  @override
  String get roleClinic => 'Clinic';

  @override
  String get rolePharmacy => 'Pharmacy';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get rolePatient => 'Patient';

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

  @override
  String get onboardingTagDoctors => '👨‍⚕️  Doctors';

  @override
  String get onboardingTagClinics => '🏥  Clinics';

  @override
  String get onboardingTagPharmacies => '💊  Pharmacies';

  @override
  String get onboardingTagSearch => '🔍  Search nearby';

  @override
  String get onboardingTitle => 'Your health\nstarts here';

  @override
  String get onboardingSubtitle =>
      'Find a doctor, clinic or pharmacy near you in Kyrgyzstan';

  @override
  String get authLoginTitle => 'Welcome\nback!';

  @override
  String get authLoginSubtitle => 'Sign in to your MedFind account';

  @override
  String get authPhoneLabel => 'Phone number';

  @override
  String get authPhoneHint => '700 000 000';

  @override
  String get authPhoneInvalid => 'Enter a valid number (9 digits)';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordMin6 => 'Minimum 6 characters';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authLoginButton => 'Sign in';

  @override
  String get authRegisterButton => 'Sign up';

  @override
  String get authNoAccount => 'No account? ';

  @override
  String get authLoginError => 'Sign-in failed';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingDay => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeQuickSearch => 'Search';

  @override
  String get homeAiHelper => 'AI Assistant';

  @override
  String get homeAiHelperHint =>
      'Describe your symptoms — AI will suggest\nwhich doctor to see';

  @override
  String get homeSectionSymptoms => 'Symptoms';

  @override
  String get homeSectionSpecializations => 'Specializations';
}
