import 'package:dio/dio.dart';
import '../../domain/entities/app_notification.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepository {
  const NotificationRepository(this._remote);
  final NotificationRemoteDataSource _remote;
  Future<NotificationPage> getNotifications({int page = 1, int limit = 20}) =>
      _execute(() => _remote.getNotifications(page: page, limit: limit));
  Future<AppNotification> markRead(String id) =>
      _execute(() => _remote.markRead(id));
  Future<T> _execute<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] is String) {
        throw Exception(body['message']);
      }
      throw Exception('Không thể kết nối dịch vụ thông báo.');
    } on FormatException catch (e) {
      throw Exception(e.message);
    }
  }
}
