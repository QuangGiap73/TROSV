import 'package:dio/dio.dart';
import '../../domain/entities/app_notification.dart';

class NotificationRemoteDataSource {
  const NotificationRemoteDataSource(this._dio);
  final Dio _dio;
  Future<NotificationPage> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );
    final envelope = response.data;
    final data = envelope?['data'];
    if (envelope?['success'] != true || data is! List) {
      throw const FormatException('Danh sách thông báo không đúng định dạng.');
    }
    final meta = envelope?['meta'];
    return NotificationPage(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList(growable: false),
      page: meta is Map ? (meta['page'] as num?)?.toInt() ?? page : page,
      limit: meta is Map ? (meta['limit'] as num?)?.toInt() ?? limit : limit,
      total: meta is Map
          ? (meta['total'] as num?)?.toInt() ?? data.length
          : data.length,
    );
  }

  Future<AppNotification> markRead(String id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/notifications/$id/read',
    );
    final envelope = response.data;
    final data = envelope?['data'];
    if (envelope?['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Thông báo trả về không đúng định dạng.');
    }
    return AppNotification.fromJson(data);
  }
}
