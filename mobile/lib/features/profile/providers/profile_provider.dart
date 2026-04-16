import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Profile state ─────────────────────────────────────────────────────────

class ProfileState {
  final String? fullName;
  final String? phone;
  final bool isLoading;

  const ProfileState({
    this.fullName,
    this.phone,
    this.isLoading = true,
  });

  ProfileState copyWith({String? fullName, String? phone, bool? isLoading}) =>
      ProfileState(
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        isLoading: isLoading ?? this.isLoading,
      );

  String get displayName => fullName?.isNotEmpty == true ? fullName! : 'Пользователь';

  String get initials {
    if (fullName == null || fullName!.trim().isEmpty) return 'П';
    final parts = fullName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName![0].toUpperCase();
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final FlutterSecureStorage _storage;

  ProfileNotifier(this._storage) : super(const ProfileState()) {
    _load();
  }

  Future<void> _load() async {
    final name = await _storage.read(key: 'full_name');
    final phone = await _storage.read(key: 'user_phone');
    state = ProfileState(fullName: name, phone: phone, isLoading: false);
  }

  Future<void> refresh() => _load();
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>(
  (_) => ProfileNotifier(const FlutterSecureStorage()),
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
