import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepository()
      : _dio = ApiClient().dio,
        _storage = const FlutterSecureStorage();

  /// Регистрация нового пользователя (phone + password)
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

  /// Выход
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    await _storage.write(key: 'access_token', value: data['access_token'] as String);
    await _storage.write(key: 'refresh_token', value: data['refresh_token'] as String);
    await _storage.write(key: 'user_role', value: data['role'] as String);
    await _storage.write(key: 'user_id', value: data['user_id'].toString());
    final name = data['full_name'] as String?;
    if (name != null && name.isNotEmpty) {
      await _storage.write(key: 'full_name', value: name);
    }
    final phone = data['phone'] as String?;
    if (phone != null) {
      await _storage.write(key: 'user_phone', value: phone);
    }
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
        'pharmacy' => '/pharmacies/my',
        _ => null,
      };
      if (endpoint == null) return false;
      final response = await _dio.get(endpoint);
      return response.data != null;
    } catch (_) {
      return false;
    }
  }
}
