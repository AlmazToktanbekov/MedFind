import 'dart:ui' show Color;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_client.dart';

/// Top-level background handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Background/terminated: Firebase OS notification is shown automatically.
  // Nothing extra needed here.
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Вызывается при получении push в foreground — чтобы обновить in-app ленту/счётчик.
  /// Регистрируется из NotificationsNotifier.
  static void Function()? onPushReceived;

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'medfind_high',
    'MedFind уведомления',
    importance: Importance.high,
  );

  /// Вызывать после успешного логина.
  /// Молча пропускает если Firebase не инициализирован (заглушка в firebase_options.dart).
  Future<void> init() async {
    try {
      await _requestPermission();
      await _setupLocalNotifications();
      await _registerToken();
      _listenForeground();
      _listenTokenRefresh();
    } catch (_) {}
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _setupLocalNotifications() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _registerToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);
  }

  void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen(_saveToken);
  }

  Future<void> _saveToken(String token) async {
    try {
      await ApiClient().dio.post('/auth/fcm-token', data: {'fcm_token': token});
    } catch (_) {}
  }

  /// Показывает локальный баннер когда приложение в foreground.
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      onPushReceived?.call();
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
            color: const Color(0xFF1565C0),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }
}
