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

  @override
  String get healthTitle => 'Ден соолук';

  @override
  String get healthSubtitle => 'Биринчи жардам жана өзгөчө байланыштар';

  @override
  String get healthEmergencyContacts => 'Өзгөчө байланыштар';

  @override
  String get healthEmergencyAmbulance => 'Тез жардам';

  @override
  String get healthEmergencyPolice => 'Милиция';

  @override
  String get healthEmergencyFire => 'Өрт өчүрүү';

  @override
  String get healthEmergencyRescue => 'ПССУ';

  @override
  String get healthFirstAid => 'Биринчи жардам';

  @override
  String healthStepsCount(int count) {
    return '$count кадам';
  }

  @override
  String get healthFirstAidStepsTitle => 'Кадам-кадам аракеттер';

  @override
  String get healthCallAmbulance => 'Тез жардам чакыруу — 103';

  @override
  String get firstAidHeartAttackTitle => 'Жүрөк кризиси';

  @override
  String get firstAidHeartAttackWarning => 'Заматта 103 чакырыңыз!';

  @override
  String get firstAidHeartAttackSteps =>
      'Заматта тез жардамды 103 чакырыңыз\nЖабырлануучуну отургузуңуз же жаткырыңыз, кийимин чечиңиз\nАспирин 325 мг бериңиз — чайнатыңыз (аллергия жок болсо)\nЭси ооп, дем албай калса — СЛР: 30 кысуу + 2 дем алуу\nКысуунун жыштыгы: мүнөтүнө 100–120, тереңдиги: 5–6 см\nДарыгер келгенче жабырлануучуну жалгыз калтырбаңыз';

  @override
  String get firstAidStrokeTitle => 'Инсульт';

  @override
  String get firstAidStrokeWarning => 'Ар бир мүнөт баалуу — 103 чакырыңыз!';

  @override
  String get firstAidStrokeSteps =>
      'УДАР тести: Жылмаюу (кыйшык?), Колдор (бирөө түшөбү?), Сүйлөөсү (бузулдубу?), Чечим — 103 чалыңыз\nЖабырлануучуну жаткырып, башын бир аз көтөрүңүз\nКийимин чечип, аба жүрүшүн камсыз кылыңыз\nТамак, суу, дары бербеңиз\nКуса болсо — башын бир жакка буруңуз\nСимптомдор качан башталганын эстеп, дарыгерге айтыңыз';

  @override
  String get firstAidBurnsTitle => 'Күйүктөр';

  @override
  String get firstAidBurnsWarning => 'Муз, май, тиш паста колдонбоңуз!';

  @override
  String get firstAidBurnsSteps =>
      'Күйгөн жерди агып турган муздак суунун астында 10–20 мүнөт муздатыңыз\nКүйүктүн жанындагы заттарды жана кийимди алыңыз (жабышып калбаса)\nСтерилдүү дакасы же таза мата менен жабыңыз\nКабарчыктарды жарбаңыз\nМай, кефир, тиш паста же муз сүйкөбөңүз\nЖүзү, колдору же алакандан чоң жер күйсө — 103 чакырыңыз';

  @override
  String get firstAidBleedingTitle => 'Кан агуу';

  @override
  String get firstAidBleedingWarning => 'Ачык кызыл, секирген кан — жгут!';

  @override
  String get firstAidBleedingSteps =>
      'Колго мээлей же таза пакет кийиңиз\nЖараны таза мата же бинт менен 10–15 мүнөт басыңыз\nМатаны алмаштырбаңыз — суу болсо үстүнө жаңысын кошуңуз\nАртериалдык кан агууда жараның үстү жагынан жгут салыңыз\nЖгут салынган так убакытты жазыңыз\nЖгутту ооруканада гана чыгарышат — 103 чакырыңыз';

  @override
  String get firstAidFracturesTitle => 'Сыныктар';

  @override
  String get firstAidFracturesWarning => 'Сөөктү өзүңүз ордуна салбаңыз!';

  @override
  String get firstAidFracturesSteps =>
      'Сынган мүчөнү турган абалында кыймылсыз кылыңыз\nКолдонулган материалдан шина салыңыз (тактай, таяк)\nМата аркылуу муздак нерсе коюп 20 мүнөт кармаңыз\nАчык сыныкта — жараны стерилдүү байлоо менен жабыңыз\nСөөктү ордуна салууга же түздөөгө аракет кылбаңыз\n103 чакырыңыз же ооруканага жеткириңиз';

  @override
  String get firstAidPoisoningTitle => 'Уулануу';

  @override
  String get firstAidPoisoningWarning =>
      'Химия менен уулангандарда — кустурбаңыз!';

  @override
  String get firstAidPoisoningSteps =>
      '103 чалып, эмне менен уулангандыгын айтыңыз\nТамактан уулангандарда — 1–1,5 л суу ичирип, кустуруңуз (эси бар болсо)\nХимия же дары менен уулангандарда — кустурбаңыз\nАктивдештирилген көмүр бериңиз: ар 10 кг салмакка 1 таблетка\nЖабырлануучуну капталына жаткырыңыз\nДарыгер келгенче дем алышын карап туруңуз';

  @override
  String get firstAidHeatStrokeTitle => 'Ысыктык сокку';

  @override
  String get firstAidHeatStrokeWarning => '';

  @override
  String get firstAidHeatStrokeSteps =>
      'Жабырлануучуну салкын жерге же көлөкөгө алып барыңыз\nКеректүү эмес кийимдерин чечиңиз\nДененин температурасын түшүрүңүз: моюнга, кол алдына, чатка нымдуу мата\nЭси бар болсо, муздак сууну азыраак ууртмалап бериңиз\nАлкоголь же кофеин бербеңиз\nТемпература 39°C өйдө же эси оогон болсо — 103 чакырыңыз';

  @override
  String get firstAidFaintingTitle => 'Эс ооп калуу';

  @override
  String get firstAidFaintingWarning => '';

  @override
  String get firstAidFaintingSteps =>
      'Адамды тегиз жаткырып, буттарын 30 см көтөрүңүз\nТар кийимдерин чечип, аба жүрүшүн камсыз кылыңыз\nНашатырь спиртин мурунга алып келиңиз (этият, жакын эмес)\nЖүзүн муздак суу менен сүртүңүз\nЭси ордуна келгенден кийин — 10–15 мүнөт жаткырыңыз\nЭси 1–2 мүнөттө кайтып келбесе — 103 чакырыңыз';

  @override
  String get firstAidDrowningTitle => 'Сууга чөгүү';

  @override
  String get firstAidDrowningWarning =>
      'Куткарууда өзүңүздү тобокелге салбаңыз!';

  @override
  String get firstAidDrowningSteps =>
      'Жабырлануучуну суудан чыгарыңыз, өзүңүздү тобокелге салбай\nКатуу жерге капталына жаткырыңыз\nОозун суу жана кирден тазалаңыз\nДеми жок болсо — СЛР: 30 кысуу + 2 дем алуу\nПульсу бар, деми жок болсо — жасалма дем алуу гана (мүнөтүнө 12–15)\n103 чакырып, келгенче СЛРди уланта бериңиз';

  @override
  String get firstAidElectricShockTitle => 'Электр жаракаты';

  @override
  String get firstAidElectricShockWarning =>
      'Ток астындагы жабырлануучуга тийбеңиз!';

  @override
  String get firstAidElectricShockSteps =>
      'Жабырлануучу ток астында болсо тийбеңиз\nТоктун булагын өчүрүңүз же зымды кургак жыгач таяк менен четке сүрүңүз\nКоопсуздукка ынангандан кийин гана жабырлануучуга жакындаңыз\nДемин жана пульсун текшериңиз; зарыл болсо СЛР баштаңыз\nТоктун күйүктөрүн муздак суу менен муздатыңыз\nЖабырлануучу эси-эсинде болсо да 103 чакырыңыз';

  @override
  String get firstAidAnaphylaxisTitle => 'Анафилаксия';

  @override
  String get firstAidAnaphylaxisWarning => 'Заматта 103 чакырыңыз!';

  @override
  String get firstAidAnaphylaxisSteps =>
      'Заматта 103 чакырыңыз\nАдреналин (эпинефрин) автоинжектор менен сан этине сайыңыз (болсо)\nЖабырлануучуну жаткырып, буттарын көтөрүңүз (басымы төмөн болсо)\nКуса болсо — капталына жаткырыңыз\nДем алуу токтосо — СЛР баштаңыз\nДарыгер келгенче суу же тамак бербеңиз';

  @override
  String get firstAidAnimalBiteTitle => 'Жаныбардын тиштеши';

  @override
  String get firstAidAnimalBiteWarning =>
      'Жыланга чагылса — 103 чакырыңыз, уу соруп албаңыз!';

  @override
  String get firstAidAnimalBiteSteps =>
      'Жараны самын суу менен 5–10 мүнөт жууңуз\nЙод же суутектин кычкылы менен иштетиңиз\nСтерилдүү байлоо коюңуз\n24 сааттын ичинде травмпунктка кайрылыңыз\nЖаныбардын абалын дарыгерге айтыңыз (эмделдиби/жокпу, жапайыбы/үйдүкүбү)\nЖыланга чагылганда: мүчөнү кыймылсыз кылыңыз, уу соруп албаңыз, 103 чакырыңыз';
}
