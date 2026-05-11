import '../../../core/network/api_client.dart';
import 'notification_model.dart';

class NotificationsRepository {
  final _dio = ApiClient().dio;

  Future<List<NotificationItem>> getNotifications() async {
    final res = await _dio.get('/notifications');
    return (res.data as List).map((e) => NotificationItem.fromJson(e)).toList();
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get('/notifications/unread-count');
    return res.data['count'] as int;
  }

  Future<void> markRead(int id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Future<void> delete(int id) async {
    await _dio.delete('/notifications/$id');
  }

  Future<void> deleteAll() async {
    await _dio.delete('/notifications');
  }
}
