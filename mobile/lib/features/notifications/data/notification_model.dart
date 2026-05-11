class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String type;
  final String? route;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.route,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: j['id'] as int,
        title: j['title'] as String,
        body: j['body'] as String,
        type: j['type'] as String,
        route: (j['data'] as Map<String, dynamic>?)?['route'] as String?,
        isRead: j['is_read'] as bool,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        body: body,
        type: type,
        route: route,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
