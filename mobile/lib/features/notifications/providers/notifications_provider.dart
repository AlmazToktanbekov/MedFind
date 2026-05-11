import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../data/notification_model.dart';
import '../data/notifications_repository.dart';

class NotificationsState {
  final List<NotificationItem> items;
  final int unreadCount;
  final bool isLoading;

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationsState copyWith({
    List<NotificationItem>? items,
    int? unreadCount,
    bool? isLoading,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
      );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repo;

  NotificationsNotifier(this._repo) : super(const NotificationsState()) {
    NotificationService.onPushReceived = load;
    load();
  }

  @override
  void dispose() {
    if (NotificationService.onPushReceived == load) {
      NotificationService.onPushReceived = null;
    }
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repo.getNotifications();
      final unread = items.where((n) => !n.isRead).length;
      state = state.copyWith(items: items, unreadCount: unread, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _repo.markRead(id);
      final updated = state.items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
      state = state.copyWith(
        items: updated,
        unreadCount: updated.where((n) => !n.isRead).length,
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _repo.markAllRead();
      final updated = state.items.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(items: updated, unreadCount: 0);
    } catch (_) {}
  }

  Future<void> delete(int id) async {
    try {
      await _repo.delete(id);
      final updated = state.items.where((n) => n.id != id).toList();
      state = state.copyWith(items: updated, unreadCount: updated.where((n) => !n.isRead).length);
    } catch (_) {}
  }

  Future<void> deleteAll() async {
    try {
      await _repo.deleteAll();
      state = state.copyWith(items: [], unreadCount: 0);
    } catch (_) {}
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (_) => NotificationsNotifier(NotificationsRepository()),
);
