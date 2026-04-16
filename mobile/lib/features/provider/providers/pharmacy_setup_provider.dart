import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/provider_repository.dart';

// ─── State ─────────────────────────────────────────────────────────────────

class PharmacySetupState {
  final int currentStep;
  final bool isLoading;
  final bool isSubmitted;
  final String? error;

  // Шаг 1 — Основная информация
  final String nameRu;
  final String addressRu;

  // Шаг 2 — Контакты и режим работы
  final String phone;
  final String workingHoursRu;
  final bool isOpen24h;

  // Шаг 3 — Фото
  final String? photoUrl;
  final String? photoLocalPath;

  const PharmacySetupState({
    this.currentStep = 0,
    this.isLoading = false,
    this.isSubmitted = false,
    this.error,
    this.nameRu = '',
    this.addressRu = '',
    this.phone = '',
    this.workingHoursRu = '',
    this.isOpen24h = false,
    this.photoUrl,
    this.photoLocalPath,
  });

  PharmacySetupState copyWith({
    int? currentStep,
    bool? isLoading,
    bool? isSubmitted,
    String? error,
    String? nameRu,
    String? addressRu,
    String? phone,
    String? workingHoursRu,
    bool? isOpen24h,
    String? photoUrl,
    String? photoLocalPath,
  }) =>
      PharmacySetupState(
        currentStep: currentStep ?? this.currentStep,
        isLoading: isLoading ?? this.isLoading,
        isSubmitted: isSubmitted ?? this.isSubmitted,
        error: error,
        nameRu: nameRu ?? this.nameRu,
        addressRu: addressRu ?? this.addressRu,
        phone: phone ?? this.phone,
        workingHoursRu: workingHoursRu ?? this.workingHoursRu,
        isOpen24h: isOpen24h ?? this.isOpen24h,
        photoUrl: photoUrl ?? this.photoUrl,
        photoLocalPath: photoLocalPath ?? this.photoLocalPath,
      );
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class PharmacySetupNotifier extends StateNotifier<PharmacySetupState> {
  final ProviderRepository _repo;

  PharmacySetupNotifier(this._repo) : super(const PharmacySetupState());

  void nextStep() =>
      state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() =>
      state = state.copyWith(currentStep: state.currentStep - 1);

  void updateStep1({required String nameRu, required String addressRu}) {
    state = state.copyWith(nameRu: nameRu, addressRu: addressRu);
  }

  void updateStep2({
    required String phone,
    required String workingHoursRu,
    required bool isOpen24h,
  }) {
    state = state.copyWith(
      phone: phone,
      workingHoursRu: workingHoursRu,
      isOpen24h: isOpen24h,
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
    } catch (_) {
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

      await _repo.createPharmacy({
        'name_ru': state.nameRu,
        'address_ru': state.addressRu,
        'phone': state.phone.isNotEmpty ? state.phone : null,
        'working_hours_ru':
            state.workingHoursRu.isNotEmpty ? state.workingHoursRu : null,
        'is_open_24h': state.isOpen24h,
        'photo_url': uploadedPhotoUrl,
      });

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

final pharmacySetupProvider =
    StateNotifierProvider<PharmacySetupNotifier, PharmacySetupState>(
  (_) => PharmacySetupNotifier(ProviderRepository()),
);
