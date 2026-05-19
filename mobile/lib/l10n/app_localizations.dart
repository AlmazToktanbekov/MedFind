import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('ky'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MedFind'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get navAi;

  /// No description provided for @navHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get navHealth;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonDoctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get commonDoctors;

  /// No description provided for @commonClinics.
  ///
  /// In en, this message translates to:
  /// **'Clinics'**
  String get commonClinics;

  /// No description provided for @commonPharmacies.
  ///
  /// In en, this message translates to:
  /// **'Pharmacies'**
  String get commonPharmacies;

  /// No description provided for @commonShowAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonShowAll;

  /// No description provided for @roleDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get roleDoctor;

  /// No description provided for @roleClinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get roleClinic;

  /// No description provided for @rolePharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get rolePharmacy;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @rolePatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get rolePatient;

  /// No description provided for @profileUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileUser;

  /// No description provided for @profileFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get profileFavorites;

  /// No description provided for @profileFavoriteClinics.
  ///
  /// In en, this message translates to:
  /// **'Favorite clinics'**
  String get profileFavoriteClinics;

  /// No description provided for @profileFavoritePharmacies.
  ///
  /// In en, this message translates to:
  /// **'Favorite pharmacies'**
  String get profileFavoritePharmacies;

  /// No description provided for @profileSearchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get profileSearchHistory;

  /// No description provided for @profileClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get profileClear;

  /// No description provided for @profileAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get profileAppLanguage;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// No description provided for @pharmaciesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacies'**
  String get pharmaciesTitle;

  /// No description provided for @pharmaciesAll.
  ///
  /// In en, this message translates to:
  /// **'All pharmacies'**
  String get pharmaciesAll;

  /// No description provided for @pharmaciesNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get pharmaciesNearby;

  /// No description provided for @pharmaciesNotFound.
  ///
  /// In en, this message translates to:
  /// **'No pharmacies found'**
  String get pharmaciesNotFound;

  /// No description provided for @pharmaciesNearbyNotFound.
  ///
  /// In en, this message translates to:
  /// **'No pharmacies nearby'**
  String get pharmaciesNearbyNotFound;

  /// No description provided for @pharmaciesDistanceFromYou.
  ///
  /// In en, this message translates to:
  /// **'{km} km from you'**
  String pharmaciesDistanceFromYou(String km);

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location is disabled on this device. Turn it on in settings.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'To show nearby pharmacies, allow location access.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is denied. Allow it in the app settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationEnableGeo.
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get locationEnableGeo;

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationOpenSettings;

  /// No description provided for @locationAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get locationAllow;

  /// No description provided for @onboardingTagDoctors.
  ///
  /// In en, this message translates to:
  /// **'👨‍⚕️  Doctors'**
  String get onboardingTagDoctors;

  /// No description provided for @onboardingTagClinics.
  ///
  /// In en, this message translates to:
  /// **'🏥  Clinics'**
  String get onboardingTagClinics;

  /// No description provided for @onboardingTagPharmacies.
  ///
  /// In en, this message translates to:
  /// **'💊  Pharmacies'**
  String get onboardingTagPharmacies;

  /// No description provided for @onboardingTagSearch.
  ///
  /// In en, this message translates to:
  /// **'🔍  Search nearby'**
  String get onboardingTagSearch;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your health\nstarts here'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find a doctor, clinic or pharmacy near you in Kyrgyzstan'**
  String get onboardingSubtitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome\nback!'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your MedFind account'**
  String get authLoginSubtitle;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'700 000 000'**
  String get authPhoneHint;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number (9 digits)'**
  String get authPhoneInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordMin6.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get authPasswordMin6;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authLoginButton;

  /// No description provided for @authRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authRegisterButton;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account? '**
  String get authNoAccount;

  /// No description provided for @authLoginError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed'**
  String get authLoginError;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingDay.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingDay;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeQuickSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeQuickSearch;

  /// No description provided for @homeAiHelper.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get homeAiHelper;

  /// No description provided for @homeAiHelperHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your symptoms — AI will suggest\nwhich doctor to see'**
  String get homeAiHelperHint;

  /// No description provided for @homeSectionSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get homeSectionSymptoms;

  /// No description provided for @homeSectionSpecializations.
  ///
  /// In en, this message translates to:
  /// **'Specializations'**
  String get homeSectionSpecializations;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ky', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ky':
      return AppLocalizationsKy();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
