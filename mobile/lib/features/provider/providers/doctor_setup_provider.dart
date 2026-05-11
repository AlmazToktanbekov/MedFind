import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/provider_repository.dart';

// ─── Models ────────────────────────────────────────────────────────────────

class ServiceEntry {
  final String name;
  final String price;

  const ServiceEntry({this.name = '', this.price = ''});

  ServiceEntry copyWith({String? name, String? price}) =>
      ServiceEntry(name: name ?? this.name, price: price ?? this.price);
}

const _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

class ScheduleEntry {
  final int dayOfWeek;
  final bool isAvailable;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const ScheduleEntry({
    required this.dayOfWeek,
    this.isAvailable = false,
    this.startTime = const TimeOfDay(hour: 9, minute: 0),
    this.endTime = const TimeOfDay(hour: 18, minute: 0),
  });

  String get label => _dayLabels[dayOfWeek];

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get startStr => _fmt(startTime);
  String get endStr => _fmt(endTime);

  ScheduleEntry copyWith({
    bool? isAvailable,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) =>
      ScheduleEntry(
        dayOfWeek: dayOfWeek,
        isAvailable: isAvailable ?? this.isAvailable,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
      );
}

// ─── State ─────────────────────────────────────────────────────────────────

class DoctorSetupState {
  final int currentStep;
  final bool isLoading;
  final bool isSubmitted;
  final String? error;
  final int? doctorId;

  // Шаг 1
  final String? photoPath;
  final String? photoUrl;
  final String? coverPhotoPath;
  final String? coverPhotoUrl;
  final String fullName;

  // Шаг 2
  final String specialization;
  final bool hasOnline;
  final bool hasOffline;
  final String onlinePrice;
  final String offlinePrice;

  // Шаг 3
  final String bio;
  final String education;
  final String consultationLanguage;
  final String experienceYears;

  // Шаг 4
  final List<ServiceEntry> services;

  // Шаг 5
  final String phone;
  final String whatsapp;
  final String telegram;
  final String instagram;

  // Шаг 6
  final List<ScheduleEntry> schedules;

  // Шаг 7
  final int? selectedClinicId;
  final String? selectedClinicName;

  const DoctorSetupState({
    this.currentStep = 0,
    this.isLoading = false,
    this.isSubmitted = false,
    this.error,
    this.doctorId,
    this.photoPath,
    this.photoUrl,
    this.coverPhotoPath,
    this.coverPhotoUrl,
    this.fullName = '',
    this.specialization = '',
    this.hasOnline = false,
    this.hasOffline = true,
    this.onlinePrice = '',
    this.offlinePrice = '',
    this.bio = '',
    this.education = '',
    this.consultationLanguage = '',
    this.experienceYears = '',
    this.services = const [],
    this.phone = '',
    this.whatsapp = '',
    this.telegram = '',
    this.instagram = '',
    required this.schedules,
    this.selectedClinicId,
    this.selectedClinicName,
  });

  DoctorSetupState copyWith({
    int? currentStep,
    bool? isLoading,
    bool? isSubmitted,
    Object? error = _sentinel,
    Object? doctorId = _sentinel,
    Object? photoPath = _sentinel,
    Object? photoUrl = _sentinel,
    Object? coverPhotoPath = _sentinel,
    Object? coverPhotoUrl = _sentinel,
    String? fullName,
    String? specialization,
    bool? hasOnline,
    bool? hasOffline,
    String? onlinePrice,
    String? offlinePrice,
    String? bio,
    String? education,
    String? consultationLanguage,
    String? experienceYears,
    List<ServiceEntry>? services,
    String? phone,
    String? whatsapp,
    String? telegram,
    String? instagram,
    List<ScheduleEntry>? schedules,
    Object? selectedClinicId = _sentinel,
    Object? selectedClinicName = _sentinel,
  }) =>
      DoctorSetupState(
        currentStep: currentStep ?? this.currentStep,
        isLoading: isLoading ?? this.isLoading,
        isSubmitted: isSubmitted ?? this.isSubmitted,
        error: error == _sentinel ? this.error : error as String?,
        doctorId: doctorId == _sentinel ? this.doctorId : doctorId as int?,
        photoPath: photoPath == _sentinel ? this.photoPath : photoPath as String?,
        photoUrl: photoUrl == _sentinel ? this.photoUrl : photoUrl as String?,
        coverPhotoPath: coverPhotoPath == _sentinel ? this.coverPhotoPath : coverPhotoPath as String?,
        coverPhotoUrl: coverPhotoUrl == _sentinel ? this.coverPhotoUrl : coverPhotoUrl as String?,
        fullName: fullName ?? this.fullName,
        specialization: specialization ?? this.specialization,
        hasOnline: hasOnline ?? this.hasOnline,
        hasOffline: hasOffline ?? this.hasOffline,
        onlinePrice: onlinePrice ?? this.onlinePrice,
        offlinePrice: offlinePrice ?? this.offlinePrice,
        bio: bio ?? this.bio,
        education: education ?? this.education,
        consultationLanguage: consultationLanguage ?? this.consultationLanguage,
        experienceYears: experienceYears ?? this.experienceYears,
        services: services ?? this.services,
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
        telegram: telegram ?? this.telegram,
        instagram: instagram ?? this.instagram,
        schedules: schedules ?? this.schedules,
        selectedClinicId: selectedClinicId == _sentinel
            ? this.selectedClinicId
            : selectedClinicId as int?,
        selectedClinicName: selectedClinicName == _sentinel
            ? this.selectedClinicName
            : selectedClinicName as String?,
      );
}

const _sentinel = Object();

// ─── Notifier ──────────────────────────────────────────────────────────────

class DoctorSetupNotifier extends StateNotifier<DoctorSetupState> {
  final ProviderRepository _repo;
  final FlutterSecureStorage _storage;

  DoctorSetupNotifier(this._repo)
      : _storage = const FlutterSecureStorage(),
        super(DoctorSetupState(
          schedules: List.generate(7, (i) => ScheduleEntry(dayOfWeek: i)),
        )) {
    _loadDoctorFromServer();
  }

  /// Загружаем данные врача с сервера и заполняем форму для редактирования.
  Future<void> _loadDoctorFromServer() async {
    final savedName = await _storage.read(key: 'full_name') ?? '';
    final savedPhone = await _storage.read(key: 'user_phone') ?? '';

    final doctor = await _repo.getMyDoctor();
    if (doctor == null) {
      // Новый врач — чистое состояние, только данные аккаунта
      state = DoctorSetupState(
        schedules: List.generate(7, (i) => ScheduleEntry(dayOfWeek: i)),
        fullName: savedName,
        phone: savedPhone,
      );
      return;
    }
    final id = doctor['id'] as int?;
    if (id == null) return;

    // Parse services
    final rawServices = doctor['services'] as List<dynamic>? ?? [];
    final services = rawServices.map((s) {
      final m = s as Map<String, dynamic>;
      return ServiceEntry(
        name: m['name_ru'] as String? ?? '',
        price: (m['price'] as num?)?.toString() ?? '',
      );
    }).toList();

    // Parse schedules
    final rawSchedules = doctor['schedules'] as List<dynamic>? ?? [];
    final schedules = List.generate(7, (i) {
      final found = rawSchedules.cast<Map<String, dynamic>>().where(
            (s) => (s['day_of_week'] as int?) == i,
          );
      if (found.isEmpty) return ScheduleEntry(dayOfWeek: i);
      final s = found.first;
      TimeOfDay parseTime(String? t) {
        if (t == null) return const TimeOfDay(hour: 9, minute: 0);
        final parts = t.split(':');
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
        );
      }
      return ScheduleEntry(
        dayOfWeek: i,
        isAvailable: true,
        startTime: parseTime(s['start_time'] as String?),
        endTime: parseTime(s['end_time'] as String?),
      );
    });

    state = state.copyWith(
      isSubmitted: false,
      doctorId: id,
      photoUrl: doctor['photo_url'] as String?,
      coverPhotoUrl: doctor['cover_photo_url'] as String?,
      fullName: doctor['full_name_ru'] as String? ?? '',
      specialization: doctor['specialization_ru'] as String? ?? '',
      hasOnline: doctor['has_online'] as bool? ?? false,
      hasOffline: doctor['has_offline'] as bool? ?? true,
      onlinePrice: (doctor['online_price'] as num?)?.toString() ?? '',
      offlinePrice: (doctor['offline_price'] as num?)?.toString() ?? '',
      bio: doctor['bio_ru'] as String? ?? '',
      education: doctor['education'] as String? ?? '',
      experienceYears:
          (doctor['experience_years'] as num?)?.toString() ?? '',
      consultationLanguage:
          doctor['consultation_language'] as String? ?? '',
      phone: doctor['phone'] as String? ?? '',
      whatsapp: doctor['whatsapp'] as String? ?? '',
      telegram: doctor['telegram'] as String? ?? '',
      instagram: doctor['instagram'] as String? ?? '',
      services: services.isNotEmpty ? services : state.services,
      schedules: schedules,
      selectedClinicName: doctor['clinic_name'] as String?,
    );
  }

  // ── Шаг 1 ──────────────────────────────────────────────────────────────
  void setPhoto(String path) => state = state.copyWith(photoPath: path);
  void setCoverPhoto(String path) => state = state.copyWith(coverPhotoPath: path);
  void setFullName(String v) => state = state.copyWith(fullName: v);

  // ── Шаг 2 ──────────────────────────────────────────────────────────────
  void setSpecialization(String v) => state = state.copyWith(specialization: v);
  void setHasOnline(bool v) => state = state.copyWith(hasOnline: v);
  void setHasOffline(bool v) => state = state.copyWith(hasOffline: v);
  void setOnlinePrice(String v) => state = state.copyWith(onlinePrice: v);
  void setOfflinePrice(String v) => state = state.copyWith(offlinePrice: v);

  // ── Шаг 3 ──────────────────────────────────────────────────────────────
  void setBio(String v) => state = state.copyWith(bio: v);
  void setEducation(String v) => state = state.copyWith(education: v);
  void setConsultationLanguage(String v) => state = state.copyWith(consultationLanguage: v);
  void setExperienceYears(String v) => state = state.copyWith(experienceYears: v);

  // ── Шаг 4 ──────────────────────────────────────────────────────────────
  void addService() =>
      state = state.copyWith(services: [...state.services, const ServiceEntry()]);

  void updateService(int i, ServiceEntry e) {
    final list = [...state.services]..[i] = e;
    state = state.copyWith(services: list);
  }

  void removeService(int i) {
    final list = [...state.services]..removeAt(i);
    state = state.copyWith(services: list);
  }

  // ── Шаг 5 ──────────────────────────────────────────────────────────────
  void setPhone(String v) => state = state.copyWith(phone: v);
  void setWhatsapp(String v) => state = state.copyWith(whatsapp: v);
  void setTelegram(String v) => state = state.copyWith(telegram: v);
  void setInstagram(String v) => state = state.copyWith(instagram: v);

  // ── Шаг 6 ──────────────────────────────────────────────────────────────
  void updateSchedule(int day, ScheduleEntry e) {
    final list = [...state.schedules]..[day] = e;
    state = state.copyWith(schedules: list);
  }

  // ── Шаг 7 ──────────────────────────────────────────────────────────────
  void setClinic(int id, String name) =>
      state = state.copyWith(selectedClinicId: id, selectedClinicName: name, error: null);

  void clearClinic() => state = state.copyWith(
        selectedClinicId: null,
        selectedClinicName: null,
        error: null,
      );

  Future<List<Map<String, dynamic>>> searchClinics(String query) =>
      _repo.searchClinics(query);

  // ── Навигация ───────────────────────────────────────────────────────────
  void nextStep() {
    final error = _validateCurrentStep();
    if (error != null) {
      state = state.copyWith(error: error);
      return;
    }
    if (state.currentStep < 6) {
      state = state.copyWith(currentStep: state.currentStep + 1, error: null);
    }
  }

  String? _validateCurrentStep() {
    switch (state.currentStep) {
      case 0:
        if (state.fullName.trim().isEmpty) return 'Введите ФИО';
        if (state.fullName.trim().split(RegExp(r'\s+')).length < 2) {
          return 'Введите ФИО полностью (минимум 2 слова)';
        }
        final phoneDigits = state.phone.replaceAll(RegExp(r'\D'), '');
        if (phoneDigits.length < 11) return 'Введите корректный номер телефона (+996 + 9 цифр)';
        return null;
      case 1:
        if (state.specialization.isEmpty) return 'Выберите специализацию';
        if (!state.hasOffline && !state.hasOnline) return 'Выберите хотя бы один тип приёма';
        if (state.hasOffline && state.offlinePrice.trim().isEmpty) {
          return 'Введите цену очного приёма';
        }
        if (state.hasOffline && int.tryParse(state.offlinePrice.trim()) == null) {
          return 'Цена должна быть числом';
        }
        if (state.hasOnline && state.onlinePrice.trim().isEmpty) {
          return 'Введите цену онлайн-консультации';
        }
        if (state.hasOnline && int.tryParse(state.onlinePrice.trim()) == null) {
          return 'Цена онлайн должна быть числом';
        }
        return null;
      case 2:
        if (state.education.trim().isEmpty) return 'Введите информацию об образовании';
        if (state.bio.trim().isEmpty) return 'Заполните поле «О себе»';
        if (state.consultationLanguage.trim().isEmpty) return 'Укажите язык консультации';
        if (state.experienceYears.trim().isEmpty) return 'Укажите стаж (лет)';
        if (int.tryParse(state.experienceYears.trim()) == null) return 'Стаж должен быть числом';
        return null;
      case 3:
        if (state.services.isEmpty) return 'Добавьте хотя бы одну услугу';
        for (final s in state.services) {
          if (s.name.trim().isEmpty) return 'Введите название услуги';
          if (s.price.trim().isEmpty) return 'Введите цену услуги';
          if (int.tryParse(s.price.trim()) == null) return 'Цена услуги должна быть числом';
        }
        return null;
      case 4:
        if (state.whatsapp.isEmpty && state.telegram.isEmpty && state.instagram.isEmpty) {
          return 'Добавьте хотя бы один мессенджер';
        }
        if (state.whatsapp.isNotEmpty) {
          final digits = state.whatsapp.replaceAll(RegExp(r'\D'), '');
          if (digits.length < 11) return 'Введите корректный номер WhatsApp (+996 + 9 цифр)';
        }
        return null;
      case 6:
        if (state.selectedClinicId == null) return 'Выберите клинику';
        return null;
      default:
        return null;
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, error: null);
    }
  }

  // ── Отправка ────────────────────────────────────────────────────────────
  Future<void> submit() async {
    if (state.fullName.trim().isEmpty || state.specialization.isEmpty) {
      state = state.copyWith(error: 'Заполните ФИО и специализацию');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Загрузить аватар и обложку если выбраны
      String? photoUrl = state.photoUrl;
      if (state.photoPath != null) {
        photoUrl = await _repo.uploadPhoto(state.photoPath!);
      }
      String? coverPhotoUrl = state.coverPhotoUrl;
      if (state.coverPhotoPath != null) {
        coverPhotoUrl = await _repo.uploadPhoto(state.coverPhotoPath!);
      }

      // 2. Контакты
      final contacts = <Map<String, dynamic>>[];
      if (state.phone.isNotEmpty) contacts.add({'type': 'phone', 'value': state.phone});
      if (state.whatsapp.isNotEmpty) contacts.add({'type': 'whatsapp', 'value': state.whatsapp});
      if (state.telegram.isNotEmpty) contacts.add({'type': 'telegram', 'value': state.telegram});
      if (state.instagram.isNotEmpty) contacts.add({'type': 'instagram', 'value': state.instagram});

      // 3. Услуги
      final services = state.services
          .where((s) => s.name.trim().isNotEmpty)
          .map((s) => {
                'name_ru': s.name,
                'price': s.price.isNotEmpty ? double.tryParse(s.price) : null,
              })
          .toList();

      // 4. График
      final schedules = state.schedules
          .where((s) => s.isAvailable)
          .map((s) => {
                'day_of_week': s.dayOfWeek,
                'start_time': s.startStr,
                'end_time': s.endStr,
                'is_available': true,
              })
          .toList();

      final body = {
        'full_name_ru': state.fullName.trim(),
        'specialization_ru': state.specialization,
        'bio_ru': state.bio.isNotEmpty ? state.bio : null,
        'education': state.education.isNotEmpty ? state.education : null,
        'consultation_language': state.consultationLanguage.isNotEmpty
            ? state.consultationLanguage
            : null,
        'experience_years': int.tryParse(state.experienceYears),
        'has_online': state.hasOnline,
        'has_offline': state.hasOffline,
        'online_price': state.hasOnline && state.onlinePrice.isNotEmpty
            ? double.tryParse(state.onlinePrice)
            : null,
        'offline_price': state.hasOffline && state.offlinePrice.isNotEmpty
            ? double.tryParse(state.offlinePrice)
            : null,
        'photo_url': photoUrl,
        'cover_photo_url': coverPhotoUrl,
        'contacts': contacts,
        'services': services,
        'schedules': schedules,
        if (state.selectedClinicId != null) 'clinic_id': state.selectedClinicId,
      };

      final int doctorId;
      if (state.doctorId == null) {
        doctorId = await _repo.createDoctor(body);
      } else {
        doctorId = await _repo.updateDoctor(state.doctorId!, body);
      }

      state = state.copyWith(
        isLoading: false,
        isSubmitted: true,
        doctorId: doctorId,
        photoUrl: photoUrl,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка отправки. Проверьте подключение.',
      );
    }
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────

final providerRepositoryProvider =
    Provider<ProviderRepository>((_) => ProviderRepository());

final doctorSetupProvider =
    StateNotifierProvider.autoDispose<DoctorSetupNotifier, DoctorSetupState>(
  (ref) => DoctorSetupNotifier(ref.watch(providerRepositoryProvider)),
);

/// Загружает профиль текущего авторизованного врача (null если не врач)
final myDoctorProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return ref.read(providerRepositoryProvider).getMyDoctor();
});
