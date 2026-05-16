import 'dart:async';
import 'package:flutter/widgets.dart';
import '../network/api_client.dart';

/// Singleton-трекер событий пациентов.
///
/// Использование:
///   AnalyticsTracker().viewClinic(clinicId);
///   AnalyticsTracker().clickCall('doctor', doctorId);
///
/// События буферизуются и отправляются батчем каждые [_flushInterval] секунд,
/// либо когда буфер достиг [_flushThreshold]. Также flush при background.
/// Все ошибки сети глотаются — трекинг не должен ломать UX.
class AnalyticsTracker with WidgetsBindingObserver {
  AnalyticsTracker._internal();
  static final AnalyticsTracker _instance = AnalyticsTracker._internal();
  factory AnalyticsTracker() => _instance;

  static const Duration _flushInterval = Duration(seconds: 10);
  static const int _flushThreshold = 20;

  final List<Map<String, dynamic>> _buffer = [];
  Timer? _timer;
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_flushInterval, (_) => _flush());
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _flush();
    }
  }

  // ─── Публичные методы ──────────────────────────────────────────────────

  void viewClinic(int clinicId) =>
      _enqueue('view_clinic', targetType: 'clinic', targetId: clinicId);

  void viewDoctor(int doctorId) =>
      _enqueue('view_doctor', targetType: 'doctor', targetId: doctorId);

  void viewPharmacyBranch(int branchId) =>
      _enqueue('view_pharmacy_branch', targetType: 'pharmacy_branch', targetId: branchId);

  void clickCall(String targetType, int targetId) =>
      _enqueue('click_call', targetType: targetType, targetId: targetId);

  void clickWhatsapp(String targetType, int targetId) =>
      _enqueue('click_whatsapp', targetType: targetType, targetId: targetId);

  void clickTelegram(String targetType, int targetId) =>
      _enqueue('click_telegram', targetType: targetType, targetId: targetId);

  void clickRoute(String targetType, int targetId) =>
      _enqueue('click_route', targetType: targetType, targetId: targetId);

  void addFavorite(String targetType, int targetId) =>
      _enqueue('add_favorite', targetType: targetType, targetId: targetId);

  void search(String query) =>
      _enqueue('search', metadata: {'query': query});

  // ─── Внутреннее ────────────────────────────────────────────────────────

  void _enqueue(
    String eventType, {
    String? targetType,
    int? targetId,
    Map<String, dynamic>? metadata,
  }) {
    _buffer.add({
      'event_type': eventType,
      'target_type': ?targetType,
      'target_id': ?targetId,
      'metadata': ?metadata,
    });
    if (_buffer.length >= _flushThreshold) {
      _flush();
    }
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();
    try {
      await ApiClient().dio.post(
            '/analytics/track',
            data: {'events': batch},
            options: null,
          );
    } catch (_) {
      // Глотаем — не должно влиять на UX
    }
  }
}
