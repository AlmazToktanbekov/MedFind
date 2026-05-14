import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/auth_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../profile/providers/profile_provider.dart';
import '../../search/providers/search_provider.dart';
import '../../provider/providers/doctor_setup_provider.dart';
import '../../clinics/presentation/screens/clinic_manage_screen.dart' show myClinicProvider;
import '../../../shared/providers/favorites_provider.dart';

// ─── Repository provider ───────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

// ─── Auth state ────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? role;
  final String? pendingDevCode;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.role,
    this.pendingDevCode,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? role,
    String? pendingDevCode,
  }) =>
      AuthState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        role: role ?? this.role,
        pendingDevCode: pendingDevCode,
      );
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AuthState());

  /// Сбрасывает все провайдеры, привязанные к конкретному пользователю,
  /// чтобы после смены аккаунта (вход / регистрация / выход) не показывались
  /// данные предыдущего пользователя.
  void _resetUserScopedState() {
    _ref.invalidate(profileProvider);
    _ref.invalidate(favoritesProvider);
    _ref.invalidate(searchProvider);
    _ref.invalidate(myDoctorProvider);
    _ref.invalidate(myClinicProvider);
  }

  /// Проверяет авторизацию при старте (SplashScreen).
  Future<String?> checkAuth() async {
    final loggedIn = await _repo.isLoggedIn();
    if (!loggedIn) return null;
    return _repo.getRole();
  }

  /// Регистрация по паролю. Возвращает роль при успехе, null при ошибке.
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
      _resetUserScopedState();
      state = state.copyWith(status: AuthStatus.authenticated, role: userRole);
      return userRole;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _extractError(e),
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Ошибка регистрации. Попробуйте позже.',
      );
      return null;
    }
  }

  /// Вход по паролю. Возвращает роль при успехе, null при ошибке.
  Future<String?> login({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final data = await _repo.login(phone: phone, password: password);
      final userRole = data['role'] as String;
      _resetUserScopedState();
      state = state.copyWith(status: AuthStatus.authenticated, role: userRole);
      NotificationService.instance.init();
      return userRole;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _extractError(e),
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Ошибка входа. Проверьте соединение.',
      );
      return null;
    }
  }

  /// Отправить OTP-код. Возвращает dev_code (DEV_MODE) или null (prod/ошибка).
  /// При ошибке устанавливает state.errorMessage.
  Future<bool> sendOtp({
    required String phone,
    String? fullName,
    String role = 'patient',
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      pendingDevCode: null,
    );
    try {
      final data = await _repo.sendOtp(phone: phone, fullName: fullName, role: role);
      state = state.copyWith(
        status: AuthStatus.initial,
        pendingDevCode: data['dev_code'] as String?,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _extractError(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Не удалось отправить код. Проверьте соединение.',
      );
      return false;
    }
  }

  /// Подтвердить OTP. Возвращает роль при успехе, null при ошибке.
  Future<String?> verifyOtp({
    required String phone,
    required String code,
    String? fullName,
    String role = 'patient',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final data = await _repo.verifyOtp(
        phone: phone,
        code: code,
        fullName: fullName,
        role: role,
      );
      final userRole = data['role'] as String;
      _resetUserScopedState();
      state = state.copyWith(status: AuthStatus.authenticated, role: userRole);
      NotificationService.instance.init();
      return userRole;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _extractError(e),
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Ошибка подтверждения. Попробуйте позже.',
      );
      return null;
    }
  }

  /// Запросить код для сброса пароля. true — успех (даже если номер не существует,
  /// бэкенд из соображений приватности всегда отвечает одинаково).
  Future<bool> forgotPassword({required String phone}) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      pendingDevCode: null,
    );
    try {
      final data = await _repo.forgotPassword(phone: phone);
      state = state.copyWith(
        status: AuthStatus.initial,
        pendingDevCode: data['dev_code'] as String?,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _extractError(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Не удалось отправить код. Проверьте соединение.',
      );
      return false;
    }
  }

  /// Сбросить пароль по OTP-коду. Возвращает роль при успехе, null при ошибке.
  /// После успеха пользователь автоматически авторизован.
  Future<String?> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final data = await _repo.resetPassword(
        phone: phone,
        code: code,
        newPassword: newPassword,
      );
      final userRole = data['role'] as String;
      _resetUserScopedState();
      state = state.copyWith(status: AuthStatus.authenticated, role: userRole);
      NotificationService.instance.init();
      return userRole;
    } on DioException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _extractError(e),
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Ошибка сброса пароля. Попробуйте позже.',
      );
      return null;
    }
  }

  /// Выход из аккаунта
  Future<void> logout() async {
    await _repo.logout();
    _resetUserScopedState();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Проверить, есть ли у провайдера заполненный профиль
  Future<bool> hasProviderProfile(String role) {
    return _repo.hasProviderProfile(role);
  }

  /// Получить статус профиля врача (pending/active/rejected/deactivated/removed)
  Future<String?> getDoctorStatus() {
    return _repo.getDoctorStatus();
  }

  String _extractError(DioException e) {
    final detail = e.response?.data?['detail'];
    if (detail is String) return detail;
    return 'Произошла ошибка. Попробуйте позже.';
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider), ref),
);
