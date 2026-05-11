import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';

// ─── Profile state ─────────────────────────────────────────────────────────

class ProfileState {
  final String? fullName;
  final String? businessName; // clinic or pharmacy company name
  final String? phone;
  final String? role;
  final String? photoUrl;
  final bool isLoading;

  const ProfileState({
    this.fullName,
    this.businessName,
    this.phone,
    this.role,
    this.photoUrl,
    this.isLoading = true,
  });

  ProfileState copyWith({
    String? fullName,
    String? businessName,
    String? phone,
    String? role,
    String? photoUrl,
    bool? isLoading,
  }) =>
      ProfileState(
        fullName: fullName ?? this.fullName,
        businessName: businessName ?? this.businessName,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        photoUrl: photoUrl ?? this.photoUrl,
        isLoading: isLoading ?? this.isLoading,
      );

  // For clinic/pharmacy show business name, otherwise personal full_name
  String get displayName {
    if (businessName != null && businessName!.isNotEmpty) return businessName!;
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    return 'Пользователь';
  }

  String get initials {
    final name = displayName;
    if (name == 'Пользователь') return 'П';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<ProfileState> {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  ProfileNotifier(this._storage, this._dio) : super(const ProfileState()) {
    _load();
  }

  Future<void> _load() async {
    final name = await _storage.read(key: 'full_name');
    final phone = await _storage.read(key: 'user_phone');
    final role = await _storage.read(key: 'user_role');

    state = ProfileState(
      fullName: name?.isNotEmpty == true ? name : null,
      phone: phone?.isNotEmpty == true ? phone : null,
      role: role,
      isLoading: true,
    );

    String? businessName;
    String? photoUrl;

    // Fetch avatar and for clinic/pharmacy the business name
    try {
      final me = await _dio.get('/auth/me');
      final raw = me.data?['avatar_url'] as String?;
      photoUrl = raw != null ? AppConstants.fixUrl(raw) : null;
    } catch (_) {}

    // Fallback: for doctors use photo_url from doctor profile
    if (photoUrl == null && role == 'doctor') {
      try {
        final doc = await _dio.get('/doctors/my');
        final raw = doc.data?['photo_url'] as String?;
        if (raw != null) photoUrl = AppConstants.fixUrl(raw);
      } catch (_) {}
    }

    if (role == 'clinic') {
      try {
        final response = await _dio.get('/clinics/my');
        businessName = response.data?['name'] as String?;
        final raw = response.data?['logo_url'] as String?;
        if (photoUrl == null && raw != null && raw.isNotEmpty) {
          photoUrl = AppConstants.fixUrl(raw);
        }
      } catch (_) {}
    } else if (role == 'pharmacy') {
      try {
        final response = await _dio.get('/pharmacy-companies/my');
        businessName = response.data?['name'] as String?;
        final raw = response.data?['logo_url'] as String?;
        if (photoUrl == null && raw != null && raw.isNotEmpty) {
          photoUrl = AppConstants.fixUrl(raw);
        }
      } catch (_) {}
    }

    state = state.copyWith(
      businessName: businessName,
      photoUrl: photoUrl,
      isLoading: false,
    );
  }

  Future<void> refresh() => _load();
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>(
  (_) => ProfileNotifier(const FlutterSecureStorage(), ApiClient().dio),
);

// ─── Locale ────────────────────────────────────────────────────────────────

const _localeKey = 'app_locale';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((_) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ru')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_localeKey) ?? 'ru';
    state = Locale(lang);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}
