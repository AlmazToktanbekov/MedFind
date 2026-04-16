import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final String fullName;

  // Шаг 2
  final String specialization;
  final bool hasOnline;
  final bool hasOffline;
  final String onlinePrice;
  final String offlinePrice;

  // Шаг 3
  final String bio;
  final String experienceYears;

  // Шаг 4
  final List<ServiceEntry> services;

  // Шаг 5
  final String phone;
  final String whatsapp;
  final String telegram;
  final String instagram;

  // Шаг 6
  final String address;
  final List<ScheduleEntry> schedules;

  const DoctorSetupState({
    this.currentStep = 0,
    this.isLoading = false,
    this.isSubmitted = false,
    this.error,
    this.doctorId,
    this.photoPath,
    this.photoUrl,
    this.fullName = '',
    this.specialization = '',
    this.hasOnline = false,
    this.hasOffline = true,
    this.onlinePrice = '',
    this.offlinePrice = '',
    this.bio = '',
    this.experienceYears = '',
    this.services = const [],
    this.phone = '',
    this.whatsapp = '',
    this.telegram = '',
    this.instagram = '',
    this.address = '',
    required this.schedules,
  });

  DoctorSetupState copyWith({
    int? currentStep,
    bool? isLoading,
    bool? isSubmitted,
    Object? error = _sentinel,
    Object? doctorId = _sentinel,
    Object? photoPath = _sentinel,
    Object? photoUrl = _sentinel,
    String? fullName,
    String? specialization,
    bool? hasOnline,
    bool? hasOffline,
    String? onlinePrice,
    String? offlinePrice,
    String? bio,
    String? experienceYears,
    List<ServiceEntry>? services,
    String? phone,
    String? whatsapp,
    String? telegram,
    String? instagram,
    String? address,
    List<ScheduleEntry>? schedules,
  }) =>
      DoctorSetupState(
        currentStep: currentStep ?? this.currentStep,
        isLoading: isLoading ?? this.isLoading,
        isSubmitted: isSubmitted ?? this.isSubmitted,
        error: error == _sentinel ? this.error : error as String?,
        doctorId: doctorId == _sentinel ? this.doctorId : doctorId as int?,
        photoPath: photoPath == _sentinel ? this.photoPath : photoPath as String?,
        photoUrl: photoUrl == _sentinel ? this.photoUrl : photoUrl as String?,
        fullName: fullName ?? this.fullName,
        specialization: specialization ?? this.specialization,
        hasOnline: hasOnline ?? this.hasOnline,
        hasOffline: hasOffline ?? this.hasOffline,
        onlinePrice: onlinePrice ?? this.onlinePrice,
        offlinePrice: offlinePrice ?? this.offlinePrice,
        bio: bio ?? this.bio,
        experienceYears: experienceYears ?? this.experienceYears,
        services: services ?? this.services,
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
        telegram: telegram ?? this.telegram,
        instagram: instagram ?? this.instagram,
        address: address ?? this.address,
        schedules: schedules ?? this.schedules,
      );
}

const _sentinel = Object();

// ─── Notifier ──────────────────────────────────────────────────────────────

class DoctorSetupNotifier extends StateNotifier<DoctorSetupState> {
  final ProviderRepository _repo;

  DoctorSetupNotifier(this._repo)
      : super(DoctorSetupState(
          schedules: List.generate(7, (i) => ScheduleEntry(dayOfWeek: i)),
        )) {
    _loadExistingDoctorId();
  }

  Future<void> _loadExistingDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('doctor_id');
    if (id != null) {
      state = state.copyWith(doctorId: id);
    }
  }

  // ── Шаг 1 ──────────────────────────────────────────────────────────────
  void setPhoto(String path) => state = state.copyWith(photoPath: path);
  void setFullName(String v) => state = state.copyWith(fullName: v);

  // ── Шаг 2 ──────────────────────────────────────────────────────────────
  void setSpecialization(String v) => state = state.copyWith(specialization: v);
  void setHasOnline(bool v) => state = state.copyWith(hasOnline: v);
  void setHasOffline(bool v) => state = state.copyWith(hasOffline: v);
  void setOnlinePrice(String v) => state = state.copyWith(onlinePrice: v);
  void setOfflinePrice(String v) => state = state.copyWith(offlinePrice: v);

  // ── Шаг 3 ──────────────────────────────────────────────────────────────
  void setBio(String v) => state = state.copyWith(bio: v);
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
  void setAddress(String v) => state = state.copyWith(address: v);
  void updateSchedule(int day, ScheduleEntry e) {
    final list = [...state.schedules]..[day] = e;
    state = state.copyWith(schedules: list);
  }

  // ── Навигация ───────────────────────────────────────────────────────────
  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        error: null,
      );
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
      // 1. Загрузить фото если выбрано
      String? photoUrl = state.photoUrl;
      if (state.photoPath != null && photoUrl == null) {
        photoUrl = await _repo.uploadPhoto(state.photoPath!);
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
        'address_ru': state.address.isNotEmpty ? state.address : null,
        'contacts': contacts,
        'services': services,
        'schedules': schedules,
      };

      final int doctorId;
      if (state.doctorId == null) {
        doctorId = await _repo.createDoctor(body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('doctor_id', doctorId);
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
    StateNotifierProvider<DoctorSetupNotifier, DoctorSetupState>(
  (ref) => DoctorSetupNotifier(ref.read(providerRepositoryProvider)),
);
