import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/provider_repository.dart';

// ─── State ─────────────────────────────────────────────────────────────────

class PharmacySetupState {
  final int currentStep;
  final bool isLoading;
  final bool isSubmitted;
  final String? error;

  // Шаг 1 — Данные компании
  final String companyName;
  final String mainPhone;
  final String website;
  final String description;
  final String whatsapp;
  final String instagram;
  final String? logoLocalPath;
  final String? logoUrl;
  final String? coverLocalPath;
  final String? coverUrl;

  // Шаг 2 — Первый филиал
  final String branchAddress;
  final String branchPhone;
  final String mapLink;
  final double? latitude;
  final double? longitude;
  final String workingHours;
  final bool isOpen24h;
  final String? photoLocalPath;
  final String? photoUrl;

  const PharmacySetupState({
    this.currentStep = 0,
    this.isLoading = false,
    this.isSubmitted = false,
    this.error,
    this.companyName = '',
    this.mainPhone = '',
    this.website = '',
    this.description = '',
    this.whatsapp = '',
    this.instagram = '',
    this.logoLocalPath,
    this.logoUrl,
    this.coverLocalPath,
    this.coverUrl,
    this.branchAddress = '',
    this.branchPhone = '',
    this.mapLink = '',
    this.latitude,
    this.longitude,
    this.workingHours = '',
    this.isOpen24h = false,
    this.photoLocalPath,
    this.photoUrl,
  });

  PharmacySetupState copyWith({
    int? currentStep,
    bool? isLoading,
    bool? isSubmitted,
    Object? error = _sentinel,
    String? companyName,
    String? mainPhone,
    String? website,
    String? description,
    String? whatsapp,
    String? instagram,
    String? logoLocalPath,
    String? logoUrl,
    String? coverLocalPath,
    String? coverUrl,
    String? branchAddress,
    String? branchPhone,
    String? mapLink,
    double? latitude,
    double? longitude,
    String? workingHours,
    bool? isOpen24h,
    String? photoLocalPath,
    String? photoUrl,
  }) =>
      PharmacySetupState(
        currentStep: currentStep ?? this.currentStep,
        isLoading: isLoading ?? this.isLoading,
        isSubmitted: isSubmitted ?? this.isSubmitted,
        error: error == _sentinel ? this.error : error as String?,
        companyName: companyName ?? this.companyName,
        mainPhone: mainPhone ?? this.mainPhone,
        website: website ?? this.website,
        description: description ?? this.description,
        whatsapp: whatsapp ?? this.whatsapp,
        instagram: instagram ?? this.instagram,
        logoLocalPath: logoLocalPath ?? this.logoLocalPath,
        logoUrl: logoUrl ?? this.logoUrl,
        coverLocalPath: coverLocalPath ?? this.coverLocalPath,
        coverUrl: coverUrl ?? this.coverUrl,
        branchAddress: branchAddress ?? this.branchAddress,
        branchPhone: branchPhone ?? this.branchPhone,
        mapLink: mapLink ?? this.mapLink,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        workingHours: workingHours ?? this.workingHours,
        isOpen24h: isOpen24h ?? this.isOpen24h,
        photoLocalPath: photoLocalPath ?? this.photoLocalPath,
        photoUrl: photoUrl ?? this.photoUrl,
      );
}

const _sentinel = Object();

// ─── Notifier ──────────────────────────────────────────────────────────────

class PharmacySetupNotifier extends StateNotifier<PharmacySetupState> {
  final ProviderRepository _repo;

  PharmacySetupNotifier(this._repo) : super(const PharmacySetupState());

  void nextStep() =>
      state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() =>
      state = state.copyWith(currentStep: state.currentStep - 1);

  // Шаг 1
  void updateStep1({
    required String companyName,
    required String mainPhone,
    required String website,
    required String description,
    required String whatsapp,
    required String instagram,
  }) {
    state = state.copyWith(
      companyName: companyName,
      mainPhone: mainPhone,
      website: website,
      description: description,
      whatsapp: whatsapp,
      instagram: instagram,
    );
  }

  Future<void> pickLogo() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = await _repo.pickImagePath();
      state = state.copyWith(logoLocalPath: path, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Не удалось выбрать логотип');
    }
  }

  Future<void> pickCoverPhoto() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = await _repo.pickImagePath();
      state = state.copyWith(coverLocalPath: path, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Не удалось выбрать обложку');
    }
  }

  // Шаг 2
  void updateStep2({
    required String branchAddress,
    required String branchPhone,
    required String mapLink,
    required double latitude,
    required double longitude,
    required String workingHours,
    required bool isOpen24h,
  }) {
    state = state.copyWith(
      branchAddress: branchAddress,
      branchPhone: branchPhone,
      mapLink: mapLink,
      latitude: latitude,
      longitude: longitude,
      workingHours: workingHours,
      isOpen24h: isOpen24h,
    );
  }

  Future<void> pickBranchPhoto() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final path = await _repo.pickImagePath();
      state = state.copyWith(photoLocalPath: path, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Не удалось выбрать фото');
    }
  }

  Future<bool> submit() async {
    if (state.companyName.trim().isEmpty || state.branchAddress.trim().isEmpty) {
      state = state.copyWith(error: 'Заполните название и адрес');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      String? logoUrl;
      if (state.logoLocalPath != null) {
        logoUrl = await _repo.uploadPhoto(state.logoLocalPath!);
      }

      String? coverUrl;
      if (state.coverLocalPath != null) {
        coverUrl = await _repo.uploadPhoto(state.coverLocalPath!);
      }

      String? photoUrl;
      if (state.photoLocalPath != null) {
        photoUrl = await _repo.uploadPhoto(state.photoLocalPath!);
      }

      await _repo.registerPharmacy({
        'company': {
          'name': state.companyName.trim(),
          'main_phone': state.mainPhone.isNotEmpty ? state.mainPhone : null,
          'website': state.website.isNotEmpty ? state.website : null,
          'description': state.description.isNotEmpty ? state.description : null,
          'whatsapp': state.whatsapp.isNotEmpty ? '+996${state.whatsapp}' : null,
          'instagram': state.instagram.isNotEmpty ? '@${state.instagram.replaceAll('@', '')}' : null,
          'logo_url': logoUrl,
          'cover_photo_url': coverUrl,
        },
        'first_branch': {
          'address': state.branchAddress.trim(),
          'phone': state.branchPhone.isNotEmpty ? state.branchPhone : null,
          'map_link': state.mapLink.isNotEmpty ? state.mapLink : null,
          'latitude': state.latitude,
          'longitude': state.longitude,
          'working_hours':
              state.isOpen24h ? 'Круглосуточно' : (state.workingHours.isNotEmpty ? state.workingHours : null),
          'photo_url': photoUrl,
        },
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
