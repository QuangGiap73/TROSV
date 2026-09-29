class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.data,
    this.readAt,
  });
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        title: json['title'] as String? ?? 'Thông báo',
        body: json['body'] as String? ?? '',
        data: json['data_json'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(
                json['data_json'] as Map<String, dynamic>,
              )
            : const {},
        readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
  final String id, userId, title, body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;
  bool get isRead => readAt != null;
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });
  final List<AppNotification> items;
  final int page, limit, total;
}
