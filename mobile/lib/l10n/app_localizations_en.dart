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

  @override
  String get healthTitle => 'Health';

  @override
  String get healthSubtitle => 'First aid and emergency contacts';

  @override
  String get healthEmergencyContacts => 'Emergency contacts';

  @override
  String get healthEmergencyAmbulance => 'Ambulance';

  @override
  String get healthEmergencyPolice => 'Police';

  @override
  String get healthEmergencyFire => 'Fire';

  @override
  String get healthEmergencyRescue => 'Rescue';

  @override
  String get healthFirstAid => 'First aid';

  @override
  String healthStepsCount(int count) {
    return '$count steps';
  }

  @override
  String get healthFirstAidStepsTitle => 'Step-by-step actions';

  @override
  String get healthCallAmbulance => 'Call ambulance — 103';

  @override
  String get firstAidHeartAttackTitle => 'Heart attack';

  @override
  String get firstAidHeartAttackWarning => 'Call 103 immediately!';

  @override
  String get firstAidHeartAttackSteps =>
      'Immediately call ambulance 103\nSeat or lay the victim down, loosen tight clothing\nGive aspirin 325 mg — chew (if no allergy)\nIf unconscious and not breathing — start CPR: 30 chest compressions + 2 breaths\nCompression rate: 100–120 per minute, depth: 5–6 cm\nDo not leave the victim alone until the doctor arrives';

  @override
  String get firstAidStrokeTitle => 'Stroke';

  @override
  String get firstAidStrokeWarning => 'Every minute counts — call 103!';

  @override
  String get firstAidStrokeSteps =>
      'FAST test: Face (drooping?), Arms (one falling?), Speech (slurred?), Time — call 103\nLay the victim down, slightly raise the head\nLoosen clothing, ensure airflow\nDo not give food, water or medicine\nIf vomiting — turn the head to the side\nRemember the exact time symptoms appeared — tell the doctor';

  @override
  String get firstAidBurnsTitle => 'Burns';

  @override
  String get firstAidBurnsWarning => 'Do not use ice, oil or toothpaste!';

  @override
  String get firstAidBurnsSteps =>
      'Cool the burn under cool running water for 10–20 minutes\nRemove jewellery and clothing near the burn (if not stuck)\nCover with sterile gauze or clean cloth\nDo not pop blisters\nDo not apply oil, kefir, toothpaste or ice\nFor burns on face, hands or larger than a palm — call 103';

  @override
  String get firstAidBleedingTitle => 'Bleeding';

  @override
  String get firstAidBleedingWarning =>
      'Bright red pulsating blood — apply a tourniquet!';

  @override
  String get firstAidBleedingSteps =>
      'Use gloves or a clean plastic bag on your hands\nPress a clean cloth or bandage onto the wound for 10–15 minutes\nDo not remove the cloth — add a new one on top if soaked\nFor arterial bleeding apply a tourniquet above the wound\nRecord the exact time the tourniquet was applied\nThe tourniquet must be removed only at hospital — call 103';

  @override
  String get firstAidFracturesTitle => 'Fractures';

  @override
  String get firstAidFracturesWarning => 'Do not realign the bone yourself!';

  @override
  String get firstAidFracturesSteps =>
      'Immobilise the limb in the position it is in\nApply a splint from available materials (board, stick)\nApply cold through cloth for 20 minutes\nFor an open fracture — cover the wound with sterile dressing\nDo not try to realign or straighten the bone\nCall 103 or take the victim to hospital';

  @override
  String get firstAidPoisoningTitle => 'Poisoning';

  @override
  String get firstAidPoisoningWarning =>
      'For chemical poisoning — do not induce vomiting!';

  @override
  String get firstAidPoisoningSteps =>
      'Call 103 and describe what the person was poisoned with\nFor food poisoning — give 1–1.5 L of water and induce vomiting (only if conscious)\nFor chemical or medicine poisoning — do not induce vomiting\nGive activated charcoal: 1 tablet per 10 kg of body weight\nLay the victim on their side\nMonitor breathing until the doctor arrives';

  @override
  String get firstAidHeatStrokeTitle => 'Heat stroke';

  @override
  String get firstAidHeatStrokeWarning => '';

  @override
  String get firstAidHeatStrokeSteps =>
      'Move the victim to a cool place or shade\nRemove excess clothing\nCool the body: wet cloth on neck, armpits, groin\nGive cool water in small sips (if conscious)\nDo not give alcohol or caffeine\nFor temperature above 39°C or loss of consciousness — call 103';

  @override
  String get firstAidFaintingTitle => 'Fainting';

  @override
  String get firstAidFaintingWarning => '';

  @override
  String get firstAidFaintingSteps =>
      'Lay the person flat, raise legs by 30 cm\nLoosen tight clothing, ensure airflow\nHold ammonia near the nose (carefully, not close)\nWipe face with cold water\nAfter regaining consciousness — let them lie 10–15 minutes\nIf consciousness does not return in 1–2 minutes — call 103';

  @override
  String get firstAidDrowningTitle => 'Drowning';

  @override
  String get firstAidDrowningWarning => 'Do not risk yourself during rescue!';

  @override
  String get firstAidDrowningSteps =>
      'Take the victim out of water without risking yourself\nLay on a hard surface, on the side\nClear the mouth of water and dirt\nIf not breathing — start CPR: 30 compressions + 2 breaths\nIf pulse present but no breathing — only rescue breaths (12–15 per minute)\nCall 103 and continue CPR until arrival';

  @override
  String get firstAidElectricShockTitle => 'Electric shock';

  @override
  String get firstAidElectricShockWarning =>
      'Do not touch the victim while under current!';

  @override
  String get firstAidElectricShockSteps =>
      'Do not touch the victim while they are under voltage\nTurn off the power source or push the wire away with a dry wooden stick\nOnly after ensuring safety — approach the victim\nCheck breathing and pulse; if needed start CPR\nCool electric burns with cool water\nCall 103 even if the victim is conscious';

  @override
  String get firstAidAnaphylaxisTitle => 'Anaphylaxis';

  @override
  String get firstAidAnaphylaxisWarning => 'Call 103 immediately!';

  @override
  String get firstAidAnaphylaxisSteps =>
      'Call 103 immediately\nInject epinephrine (adrenaline) auto-injector into the thigh (if available)\nLay the victim down, raise legs (for low blood pressure)\nIf vomiting — turn on the side\nIf breathing stops — start CPR\nDo not give food or drink until the doctor arrives';

  @override
  String get firstAidAnimalBiteTitle => 'Animal bite';

  @override
  String get firstAidAnimalBiteWarning =>
      'For snake bite — call 103, do not suck out the venom!';

  @override
  String get firstAidAnimalBiteSteps =>
      'Wash the wound with soap and water for 5–10 minutes\nTreat with iodine or hydrogen peroxide\nApply a sterile dressing\nGo to a trauma centre within 24 hours\nInform the doctor about the animal (vaccinated/not, wild/domestic)\nFor snake bite: immobilise the limb, do not suck out venom, call 103';
}
