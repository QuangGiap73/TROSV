import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/entities/app_notification.dart';

final notificationRemoteProvider = Provider(
  (ref) => NotificationRemoteDataSource(ref.watch(dioProvider)),
);
final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(ref.watch(notificationRemoteProvider)),
);
final notificationsProvider =
    AsyncNotifierProvider<NotificationController, NotificationPage>(
      NotificationController.new,
    );
final unreadNotificationCountProvider = Provider<int>(
  (ref) =>
      ref
          .watch(notificationsProvider)
          .asData
          ?.value
          .items
          .where((e) => !e.isRead)
          .length ??
      0,
);

class NotificationController extends AsyncNotifier<NotificationPage> {
  @override
  Future<NotificationPage> build() =>
      ref.watch(notificationRepositoryProvider).getNotifications();
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).getNotifications(),
    );
  }

  Future<bool> markRead(AppNotification item) async {
    if (item.isRead) return true;
    try {
      final updated = await ref
          .read(notificationRepositoryProvider)
          .markRead(item.id);
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(
          NotificationPage(
            items: current.items
                .map((e) => e.id == updated.id ? updated : e)
                .toList(growable: false),
            page: current.page,
            limit: current.limit,
            total: current.total,
          ),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
