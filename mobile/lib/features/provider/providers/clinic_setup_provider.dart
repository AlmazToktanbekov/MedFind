import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/provider_repository.dart';

// ─── State ─────────────────────────────────────────────────────────────────

class ClinicSetupState {
  final int currentStep;
  final bool isLoading;
  final bool isSubmitted;
  final String? error;

  // Шаг 1 — Основная информация
  final String nameRu;
  final String phone;
  final String descriptionRu;
  final List<String> categories;
  final String website;
  final String? logoUrl;
  final String? logoLocalPath;

  // Шаг 2 — Адрес и локация
  final String addressRu;
  final String mapUrl;
  final String whatsapp;
  final String telegram;
  final String instagram;
  final String email;
  final String workingHoursRu;

  // Шаг 3 — Фото (галерея)
  final List<String> photoLocalPaths;

  const ClinicSetupState({
    this.currentStep = 0,
    this.isLoading = false,
    this.isSubmitted = false,
    this.error,
    this.nameRu = '',
    this.phone = '',
    this.descriptionRu = '',
    this.categories = const [],
    this.website = '',
    this.logoUrl,
    this.logoLocalPath,
    this.addressRu = '',
    this.mapUrl = '',
    this.whatsapp = '',
    this.telegram = '',
    this.instagram = '',
    this.email = '',
    this.workingHoursRu = '',
    this.photoLocalPaths = const [],
  });

  ClinicSetupState copyWith({
    int? currentStep,
    bool? isLoading,
    bool? isSubmitted,
    Object? error = _sentinel,
    String? nameRu,
    String? phone,
    String? descriptionRu,
    List<String>? categories,
    String? website,
    Object? logoUrl = _sentinel,
    Object? logoLocalPath = _sentinel,
    String? addressRu,
    String? mapUrl,
    String? whatsapp,
    String? telegram,
    String? instagram,
    String? email,
    String? workingHoursRu,
    List<String>? photoLocalPaths,
  }) =>
      ClinicSetupState(
        currentStep: currentStep ?? this.currentStep,
        isLoading: isLoading ?? this.isLoading,
        isSubmitted: isSubmitted ?? this.isSubmitted,
        error: error == _sentinel ? this.error : error as String?,
        nameRu: nameRu ?? this.nameRu,
        phone: phone ?? this.phone,
        descriptionRu: descriptionRu ?? this.descriptionRu,
        categories: categories ?? this.categories,
        website: website ?? this.website,
        logoUrl: logoUrl == _sentinel ? this.logoUrl : logoUrl as String?,
        logoLocalPath: logoLocalPath == _sentinel
            ? this.logoLocalPath
            : logoLocalPath as String?,
        addressRu: addressRu ?? this.addressRu,
        mapUrl: mapUrl ?? this.mapUrl,
        whatsapp: whatsapp ?? this.whatsapp,
        telegram: telegram ?? this.telegram,
        instagram: instagram ?? this.instagram,
        email: email ?? this.email,
        workingHoursRu: workingHoursRu ?? this.workingHoursRu,
        photoLocalPaths: photoLocalPaths ?? this.photoLocalPaths,
      );
}

const _sentinel = Object();

// ─── Notifier ──────────────────────────────────────────────────────────────

class ClinicSetupNotifier extends StateNotifier<ClinicSetupState> {
  final ProviderRepository _repo;

  ClinicSetupNotifier(this._repo) : super(const ClinicSetupState());

  void nextStep() =>
      state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() =>
      state = state.copyWith(currentStep: state.currentStep - 1);

  void updateStep1({
    required String descriptionRu,
    required List<String> categories,
    required String website,
  }) {
    state = state.copyWith(
      descriptionRu: descriptionRu,
      categories: categories,
      website: website,
    );
  }

  void updateStep2({
    required String addressRu,
    required String mapUrl,
    required String whatsapp,
    required String telegram,
    required String instagram,
    required String email,
    required String workingHoursRu,
  }) {
    state = state.copyWith(
      addressRu: addressRu,
      mapUrl: mapUrl,
      whatsapp: whatsapp,
      telegram: telegram,
      instagram: instagram,
      email: email,
      workingHoursRu: workingHoursRu,
    );
  }

  Future<void> addPhoto() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = await _repo.pickImagePath();
      if (path == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(
        photoLocalPaths: [...state.photoLocalPaths, path],
        isLoading: false,
      );
    } catch (_) {
      state =
          state.copyWith(isLoading: false, error: 'Не удалось выбрать фото');
    }
  }

  void removePhoto(int index) {
    final updated = List<String>.from(state.photoLocalPaths)..removeAt(index);
    state = state.copyWith(photoLocalPaths: updated);
  }

  Future<void> pickAndUploadLogo() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = await _repo.pickImagePath();
      if (path == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(logoLocalPath: path, isLoading: false);
    } catch (_) {
      state =
          state.copyWith(isLoading: false, error: 'Не удалось выбрать логотип');
    }
  }

  Future<bool> submit() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      const storage = FlutterSecureStorage();
      final nameRu = await storage.read(key: 'full_name') ?? '';
      final phone = await storage.read(key: 'user_phone') ?? '';

      String? uploadedLogoUrl;
      if (state.logoLocalPath != null) {
        uploadedLogoUrl = await _repo.uploadPhoto(state.logoLocalPath!);
      }

      final categoryStr =
          state.categories.isNotEmpty ? state.categories.join(', ') : null;

      final clinicId = await _repo.createClinic({
        'name_ru': nameRu,
        'description_ru':
            state.descriptionRu.isNotEmpty ? state.descriptionRu : null,
        'category_ru': categoryStr,
        'phone': phone.isNotEmpty ? phone : null,
        'website': state.website.isNotEmpty ? state.website : null,
        'address_ru': state.addressRu.isNotEmpty ? state.addressRu : null,
        'map_url': state.mapUrl.isNotEmpty ? state.mapUrl : null,
        'whatsapp': state.whatsapp.isNotEmpty ? state.whatsapp : null,
        'telegram': state.telegram.isNotEmpty ? state.telegram : null,
        'instagram': state.instagram.isNotEmpty ? state.instagram : null,
        'email': state.email.isNotEmpty ? state.email : null,
        'working_hours_ru':
            state.workingHoursRu.isNotEmpty ? state.workingHoursRu : null,
        'logo_url': uploadedLogoUrl,
      });

      for (int i = 0; i < state.photoLocalPaths.length; i++) {
        final url = await _repo.uploadPhoto(state.photoLocalPaths[i]);
        await _repo.addClinicPhoto(clinicId, url, order: i);
      }

      state = state.copyWith(isLoading: false, isSubmitted: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка при сохранении. Попробуйте снова.',
      );
      return false;
    }
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────

final clinicSetupProvider =
    StateNotifierProvider<ClinicSetupNotifier, ClinicSetupState>(
  (_) => ClinicSetupNotifier(ProviderRepository()),
);
