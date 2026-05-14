import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository()
      : _dio = ApiClient().dio,
        _storage = const FlutterSecureStorage();

  /// Регистрация по паролю (оставлена для совместимости с admin/провайдер-инструментами)
  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'phone': phone,
      'password': password,
      'full_name': fullName,
      'role': role,
    });
    await _saveSession(response.data as Map<String, dynamic>);
    return response.data as Map<String, dynamic>;
  }

  /// Вход по номеру телефона и паролю
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    await _saveSession(response.data as Map<String, dynamic>);
    return response.data as Map<String, dynamic>;
  }

  /// Отправить OTP-код на телефон
  Future<Map<String, dynamic>> sendOtp({
    required String phone,
    String? fullName,
    String role = 'patient',
  }) async {
    final response = await _dio.post('/auth/otp/send', data: {
      'phone': phone,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      'role': role,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Подтвердить OTP-код — вход или регистрация
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    String? fullName,
    String role = 'patient',
  }) async {
    final response = await _dio.post('/auth/otp/verify', data: {
      'phone': phone,
      'code': code,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      'role': role,
    });
    await _saveSession(response.data as Map<String, dynamic>);
    return response.data as Map<String, dynamic>;
  }

  /// Запросить код для сброса пароля
  Future<Map<String, dynamic>> forgotPassword({required String phone}) async {
    final response = await _dio.post('/auth/password/forgot', data: {
      'phone': phone,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Сбросить пароль по OTP-коду — автоматический вход после успеха
  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    final response = await _dio.post('/auth/password/reset', data: {
      'phone': phone,
      'code': code,
      'new_password': newPassword,
    });
    await _saveSession(response.data as Map<String, dynamic>);
    return response.data as Map<String, dynamic>;
  }

  /// Выход
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage.deleteAll();
    await _clearLocalUserCache();
    ApiClient().clearAuthCache();
  }

  /// Очищает локальные кэши, привязанные к аккаунту (избранное, история поиска).
  /// Язык приложения (`app_locale`) сохраняется.
  Future<void> _clearLocalUserCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favorites');
    await prefs.remove('search_history');
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    // Полностью сбрасываем предыдущую сессию, чтобы не осталось чужих токенов/данных.
    await _storage.deleteAll();
    await _clearLocalUserCache();

    final accessToken = data['access_token'] as String;
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: data['refresh_token'] as String);
    await _storage.write(key: 'user_role', value: data['role'] as String);
    await _storage.write(key: 'user_id', value: data['user_id'].toString());
    await _storage.write(key: 'full_name', value: data['full_name'] as String? ?? '');
    await _storage.write(key: 'user_phone', value: data['phone'] as String? ?? '');
    ApiClient().setAccessToken(accessToken);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getFullName() => _storage.read(key: 'full_name');
  Future<String?> getRole() => _storage.read(key: 'user_role');
  Future<String?> getPhone() => _storage.read(key: 'user_phone');

  /// Проверить, заполнен ли провайдерский профиль
  Future<bool> hasProviderProfile(String role) async {
    try {
      final endpoint = switch (role) {
        'doctor' => '/doctors/my',
        'clinic' => '/clinics/my',
        'pharmacy' => '/pharmacy-companies/my',
        _ => null,
      };
      if (endpoint == null) return false;
      final response = await _dio.get(endpoint);
      return response.data != null;
    } catch (_) {
      return false;
    }
  }

  // Returns doctor status string or null if no profile
  Future<String?> getDoctorStatus() async {
    try {
      final response = await _dio.get('/doctors/my');
      if (response.data == null) return null;
      return response.data['status'] as String?;
    } catch (_) {
      return null;
    }
  }
}
