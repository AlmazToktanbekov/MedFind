import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/provider_repository.dart';

// ─── State ─────────────────────────────────────────────────────────────────

class ClinicSetupState {
  final int currentStep;
  final bool isLoading;
  final bool isSubmitted;
  final String? error;

  // Шаг 1 — Основная информация
  final String nameRu;
  final String descriptionRu;
  final String categoryRu;

  // Шаг 2 — Контакты и адрес
  final String addressRu;
  final String phone;
  final String website;
  final String workingHoursRu;

  // Шаг 3 — Фото
  final String? photoUrl;
  final String? photoLocalPath;

  const ClinicSetupState({
    this.currentStep = 0,
    this.isLoading = false,
    this.isSubmitted = false,
    this.error,
    this.nameRu = '',
    this.descriptionRu = '',
    this.categoryRu = '',
    this.addressRu = '',
    this.phone = '',
    this.website = '',
    this.workingHoursRu = '',
    this.photoUrl,
    this.photoLocalPath,
  });

  ClinicSetupState copyWith({
    int? currentStep,
    bool? isLoading,
    bool? isSubmitted,
    String? error,
    String? nameRu,
    String? descriptionRu,
    String? categoryRu,
    String? addressRu,
    String? phone,
    String? website,
    String? workingHoursRu,
    String? photoUrl,
    String? photoLocalPath,
  }) =>
      ClinicSetupState(
        currentStep: currentStep ?? this.currentStep,
        isLoading: isLoading ?? this.isLoading,
        isSubmitted: isSubmitted ?? this.isSubmitted,
        error: error,
        nameRu: nameRu ?? this.nameRu,
        descriptionRu: descriptionRu ?? this.descriptionRu,
        categoryRu: categoryRu ?? this.categoryRu,
        addressRu: addressRu ?? this.addressRu,
        phone: phone ?? this.phone,
        website: website ?? this.website,
        workingHoursRu: workingHoursRu ?? this.workingHoursRu,
        photoUrl: photoUrl ?? this.photoUrl,
        photoLocalPath: photoLocalPath ?? this.photoLocalPath,
      );
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class ClinicSetupNotifier extends StateNotifier<ClinicSetupState> {
  final ProviderRepository _repo;

  ClinicSetupNotifier(this._repo) : super(const ClinicSetupState());

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() => state = state.copyWith(currentStep: state.currentStep - 1);

  void updateStep1({
    required String nameRu,
    required String descriptionRu,
    required String categoryRu,
  }) {
    state = state.copyWith(
      nameRu: nameRu,
      descriptionRu: descriptionRu,
      categoryRu: categoryRu,
    );
  }

  void updateStep2({
    required String addressRu,
    required String phone,
    required String website,
    required String workingHoursRu,
  }) {
    state = state.copyWith(
      addressRu: addressRu,
      phone: phone,
      website: website,
      workingHoursRu: workingHoursRu,
    );
  }

  Future<void> pickAndUploadPhoto() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = await _repo.pickImagePath();
      if (path == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(photoLocalPath: path, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось выбрать фото',
      );
    }
  }

  Future<bool> submit() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      String? uploadedPhotoUrl;
      if (state.photoLocalPath != null) {
        uploadedPhotoUrl = await _repo.uploadPhoto(state.photoLocalPath!);
      }

      await _repo.createClinic({
        'name_ru': state.nameRu,
        'description_ru': state.descriptionRu,
        'category_ru': state.categoryRu,
        'address_ru': state.addressRu,
        'phone': state.phone.isNotEmpty ? state.phone : null,
        'website': state.website.isNotEmpty ? state.website : null,
        'working_hours_ru': state.workingHoursRu.isNotEmpty
            ? state.workingHoursRu
            : null,
        'photo_url': uploadedPhotoUrl,
      });

      state = state.copyWith(isLoading: false, isSubmitted: true);
      return true;
    } catch (e) {
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
