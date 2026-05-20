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

  @override
  String get healthTitle => 'Здоровье';

  @override
  String get healthSubtitle => 'Первая помощь и экстренные контакты';

  @override
  String get healthEmergencyContacts => 'Экстренные контакты';

  @override
  String get healthEmergencyAmbulance => 'Скорая';

  @override
  String get healthEmergencyPolice => 'Полиция';

  @override
  String get healthEmergencyFire => 'Пожарные';

  @override
  String get healthEmergencyRescue => 'ПССУ';

  @override
  String get healthFirstAid => 'Первая помощь';

  @override
  String healthStepsCount(int count) {
    return '$count шагов';
  }

  @override
  String get healthFirstAidStepsTitle => 'Действия по шагам';

  @override
  String get healthCallAmbulance => 'Вызвать скорую — 103';

  @override
  String get firstAidHeartAttackTitle => 'Сердечный приступ';

  @override
  String get firstAidHeartAttackWarning => 'Немедленно вызовите 103!';

  @override
  String get firstAidHeartAttackSteps =>
      'Немедленно вызовите скорую 103\nУсадите или уложите пострадавшего, расстегните одежду\nДайте аспирин 325 мг — разжевать (если нет аллергии)\nПри потере сознания и отсутствии дыхания — начните СЛР: 30 нажатий на грудь + 2 вдоха\nЧастота нажатий: 100–120 в минуту, глубина: 5–6 см\nНе оставляйте пострадавшего одного до приезда врача';

  @override
  String get firstAidStrokeTitle => 'Инсульт';

  @override
  String get firstAidStrokeWarning => 'Каждая минута на счету — вызовите 103!';

  @override
  String get firstAidStrokeSteps =>
      'Тест УДАР: Улыбка (кривая?), Движение рук (одна падает?), Артикуляция (речь нарушена?), Решение — звоните 103\nУложите пострадавшего, чуть приподнимите голову\nРасстегните одежду, обеспечьте доступ воздуха\nНе давайте еду, воду и лекарства\nПри рвоте — поверните голову на бок\nЗапомните точное время появления симптомов — сообщите врачу';

  @override
  String get firstAidBurnsTitle => 'Ожоги';

  @override
  String get firstAidBurnsWarning =>
      'Не используйте лёд, масло и зубную пасту!';

  @override
  String get firstAidBurnsSteps =>
      'Охладите место ожога под прохладной проточной водой 10–20 минут\nСнимите украшения и одежду рядом с ожогом (если не прилипли)\nНакройте стерильной марлей или чистой тканью\nНе вскрывайте волдыри\nНе наносите масло, кефир, зубную пасту или лёд\nПри ожоге лица, рук или площади больше ладони — вызовите 103';

  @override
  String get firstAidBleedingTitle => 'Кровотечение';

  @override
  String get firstAidBleedingWarning =>
      'При ярко-красной пульсирующей крови — жгут!';

  @override
  String get firstAidBleedingSteps =>
      'Используйте перчатки или чистый пакет на руки\nПрижмите рану чистой тканью или бинтом и держите 10–15 минут\nНе убирайте ткань — добавьте поверх новую, если промокла\nПри артериальном кровотечении наложите жгут выше раны\nЗапишите точное время наложения жгута\nЖгут снимать только в больнице — вызовите 103';

  @override
  String get firstAidFracturesTitle => 'Переломы';

  @override
  String get firstAidFracturesWarning => 'Не вправляйте кость самостоятельно!';

  @override
  String get firstAidFracturesSteps =>
      'Обездвижьте конечность в том положении, в котором она находится\nНаложите шину из подручных материалов (доска, палка)\nПриложите холод через ткань на 20 минут\nПри открытом переломе — закройте рану стерильной повязкой\nНе пытайтесь вправить или выпрямить кость\nВызовите 103 или доставьте в больницу';

  @override
  String get firstAidPoisoningTitle => 'Отравление';

  @override
  String get firstAidPoisoningWarning =>
      'При отравлении химикатами — не вызывайте рвоту!';

  @override
  String get firstAidPoisoningSteps =>
      'Позвоните 103 и опишите, чем отравился человек\nПри пищевом отравлении — дайте выпить 1–1,5 л воды и вызовите рвоту (только если в сознании)\nПри отравлении химикатами или лекарствами — рвоту не вызывать\nДайте активированный уголь: 1 таблетка на 10 кг веса\nУложите пострадавшего на бок\nСледите за дыханием до приезда врача';

  @override
  String get firstAidHeatStrokeTitle => 'Тепловой удар';

  @override
  String get firstAidHeatStrokeWarning => '';

  @override
  String get firstAidHeatStrokeSteps =>
      'Перенесите пострадавшего в прохладное место или тень\nСнимите лишнюю одежду\nОхладите тело: влажная ткань на шею, подмышки, пах\nДавайте прохладную воду небольшими глотками (если в сознании)\nНе давайте алкоголь или кофеин\nПри температуре выше 39°C или потере сознания — вызовите 103';

  @override
  String get firstAidFaintingTitle => 'Обморок';

  @override
  String get firstAidFaintingWarning => '';

  @override
  String get firstAidFaintingSteps =>
      'Уложите человека горизонтально, приподнимите ноги на 30 см\nРасстегните тесную одежду, обеспечьте доступ воздуха\nПоднесите нашатырный спирт к носу (осторожно, не вплотную)\nПротрите лицо холодной водой\nПосле прихода в сознание — дайте полежать 10–15 минут\nЕсли сознание не вернулось за 1–2 минуты — вызовите 103';

  @override
  String get firstAidDrowningTitle => 'Утопление';

  @override
  String get firstAidDrowningWarning => 'Не рискуйте собой при спасении!';

  @override
  String get firstAidDrowningSteps =>
      'Выньте пострадавшего из воды, не рискуя собой\nУложите на твёрдую поверхность на бок\nОчистите рот от воды и грязи\nЕсли нет дыхания — начните СЛР: 30 нажатий на грудь + 2 вдоха\nЕсли есть пульс, но нет дыхания — только искусственное дыхание (12–15 в минуту)\nВызовите 103 и продолжайте СЛР до приезда';

  @override
  String get firstAidElectricShockTitle => 'Электротравма';

  @override
  String get firstAidElectricShockWarning =>
      'Не прикасайтесь к пострадавшему под током!';

  @override
  String get firstAidElectricShockSteps =>
      'Не прикасайтесь к пострадавшему, пока он под напряжением\nОтключите источник тока или отодвиньте провод сухой деревянной палкой\nТолько убедившись в безопасности — подойдите к пострадавшему\nПроверьте дыхание и пульс; при необходимости начните СЛР\nОхладите ожоги от тока прохладной водой\nВызовите 103, даже если пострадавший в сознании';

  @override
  String get firstAidAnaphylaxisTitle => 'Анафилаксия';

  @override
  String get firstAidAnaphylaxisWarning => 'Вызовите 103 немедленно!';

  @override
  String get firstAidAnaphylaxisSteps =>
      'Вызовите 103 немедленно\nВведите адреналин (эпинефрин) аутоинъектором в бедро (если есть)\nУложите пострадавшего, приподнимите ноги (при низком давлении)\nПри рвоте — уложите на бок\nПри остановке дыхания — начните СЛР\nНе давайте пить или есть до приезда врача';

  @override
  String get firstAidAnimalBiteTitle => 'Укус животного';

  @override
  String get firstAidAnimalBiteWarning =>
      'При укусе змеи — вызовите 103, не отсасывайте яд!';

  @override
  String get firstAidAnimalBiteSteps =>
      'Промойте рану водой с мылом 5–10 минут\nОбработайте йодом или перекисью водорода\nНаложите стерильную повязку\nОбратитесь в травмпункт в течение 24 часов\nСообщите врачу о состоянии животного (привито/нет, дикое/домашнее)\nПри укусе змеи: обездвижьте конечность, не отсасывайте яд, вызовите 103';
}
