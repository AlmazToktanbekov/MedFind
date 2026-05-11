import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';

class ApiClient {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(_authInterceptor());
    // Логгер запросов только в debug — в release он сильно тормозит и засоряет логи.
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          compact: true,
        ),
      );
    }
  }

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Callback вызывается при неудачном рефреше → разлогиниться
  static Future<void> Function()? onUnauthorized;

  // ── Refresh token queue ──────────────────────────────────────────────────
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

  // ── Auth interceptor ─────────────────────────────────────────────────────
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },

      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          handler.next(error);
          return;
        }

        // Не рефрешим запросы к самому /auth/refresh — иначе рекурсия
        final path = error.requestOptions.path;
        if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
          handler.next(error);
          return;
        }

        // Запрос уже повторялся после рефреша — не уходим в новый цикл
        if (error.requestOptions.extra['__retried_after_refresh'] == true) {
          await onUnauthorized?.call();
          handler.next(error);
          return;
        }

        if (_isRefreshing) {
          // Ставим запрос в очередь пока идёт рефреш
          final completer = Completer<String?>();
          _refreshQueue.add(completer);
          final newToken = await completer.future;
          if (newToken == null) {
            handler.reject(error);
            return;
          }
          try {
            final response = await _retryWithToken(error.requestOptions, newToken);
            handler.resolve(response);
          } catch (e) {
            handler.reject(error);
          }
          return;
        }

        // Начинаем рефреш
        _isRefreshing = true;
        final newToken = await _refreshAccessToken();
        _isRefreshing = false;

        if (newToken == null) {
          // Завершаем очередь с ошибкой
          for (final c in _refreshQueue) {
            c.complete(null);
          }
          _refreshQueue.clear();
          await onUnauthorized?.call();
          handler.reject(error);
          return;
        }

        // Завершаем очередь с новым токеном
        for (final c in _refreshQueue) {
          c.complete(newToken);
        }
        _refreshQueue.clear();

        // Повторяем исходный запрос
        try {
          final response = await _retryWithToken(error.requestOptions, newToken);
          handler.resolve(response);
        } catch (e) {
          handler.next(error);
        }
      },
    );
  }

  Future<Response<dynamic>> _retryWithToken(
      RequestOptions options, String token) {
    final opts = options.copyWith(
      headers: {...options.headers, 'Authorization': 'Bearer $token'},
      extra: {...options.extra, '__retried_after_refresh': true},
    );
    return _dio.fetch(opts);
  }

  /// Возвращает новый access_token или null при ошибке
  Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return null;

      // Отдельный Dio без наших интерцепторов чтобы избежать рекурсии
      final plain = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final response = await plain.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      final newAccess = data['access_token'] as String;
      final newRefresh = data['refresh_token'] as String;

      await _storage.write(key: 'access_token', value: newAccess);
      await _storage.write(key: 'refresh_token', value: newRefresh);
      return newAccess;
    } catch (_) {
      await _storage.deleteAll();
      return null;
    }
  }

  Dio get dio => _dio;
}
