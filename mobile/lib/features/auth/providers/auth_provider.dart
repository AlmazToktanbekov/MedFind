import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/auth_repository.dart';

// ─── Repository provider ───────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

// ─── Auth state ────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? role;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.role,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? role,
  }) =>
      AuthState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        role: role ?? this.role,
      );
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  /// Проверяет авторизацию при старте (SplashScreen).
  /// Возвращает роль если авторизован, null иначе.
  Future<String?> checkAuth() async {
    final loggedIn = await _repo.isLoggedIn();
    if (!loggedIn) return null;
    return _repo.getRole();
  }

  /// Регистрация нового пользователя.
  /// Возвращает роль при успехе, null при ошибке.
  Future<String?> register({
    required String phone,
    required String password,
    required String fullName,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final data = await _repo.register(
        phone: phone,
        password: password,
        fullName: fullName,
        role: role,
      );
      final userRole = data['role'] as String;
      state = state.copyWith(status: AuthStatus.authenticated, role: userRole);
      return userRole;
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
      return null;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Ошибка регистрации. Попробуйте позже.',
      );
      return null;
    }
  }

  /// Вход по телефону и паролю.
  /// Возвращает роль при успехе, null при ошибке.
  Future<String?> login({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final data = await _repo.login(phone: phone, password: password);
      final userRole = data['role'] as String;
      state = state.copyWith(status: AuthStatus.authenticated, role: userRole);
      return userRole;
    } on DioException catch (e) {
      final message = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: message);
      return null;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Ошибка входа. Проверьте соединение.',
      );
      return null;
    }
  }

  /// Выход из аккаунта
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Проверить, есть ли у провайдера заполненный профиль
  Future<bool> hasProviderProfile(String role) {
    return _repo.hasProviderProfile(role);
  }

  String _extractError(DioException e) {
    final detail = e.response?.data?['detail'];
    if (detail is String) return detail;
    return e.response?.statusCode == 401
        ? 'Неверный номер телефона или пароль'
        : 'Произошла ошибка. Попробуйте позже.';
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
