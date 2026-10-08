import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'notification_provider.dart';

final pushNotificationLifecycleProvider = Provider<void>((ref) {
  if (Firebase.apps.isEmpty) return;

  final service = ref.watch(pushNotificationServiceProvider);
  final messaging = service.messaging;
  if (messaging == null) return;
  final localNotifications = LocalNotificationService();

  void openNotification(Map<String, dynamic> data) {
    Future.microtask(() => _openNotification(ref, data));
  }

  unawaited(() async {
    try {
      await localNotifications.initialize(onNotificationTap: openNotification);

      final localLaunchPayload = await localNotifications.getLaunchPayload();
      if (localLaunchPayload.isNotEmpty) {
        openNotification(localLaunchPayload);
        return;
      }

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) openNotification(initialMessage.data);
    } catch (_) {
      // Không làm gián đoạn ứng dụng nếu plugin thông báo chưa sẵn sàng.
    }
  }());

  final tokenSubscription = messaging.onTokenRefresh.listen((token) async {
    final session = ref.read(authControllerProvider).asData?.value;
    if (session == null) return;
    try {
      await service.registerToken(token);
    } catch (_) {
      // FCM sẽ phát lại token ở lần khởi động/làm mới tiếp theo.
    }
  });

  final foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
    final session = ref.read(authControllerProvider).asData?.value;
    if (session == null) return;
    ref.invalidate(notificationsProvider);
    unawaited(() async {
      try {
        await localNotifications.showRemoteMessage(message);
      } catch (_) {
        // Danh sách trong app vẫn được cập nhật nếu banner hệ thống lỗi.
      }
    }());
  });

  final openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
    message,
  ) {
    openNotification(message.data);
  });

  ref.onDispose(() {
    unawaited(tokenSubscription.cancel());
    unawaited(foregroundSubscription.cancel());
    unawaited(openedSubscription.cancel());
  });
});

void _openNotification(Ref ref, Map<String, dynamic> data) {
  final session = ref.read(authControllerProvider).asData?.value;
  final router = ref.read(appRouterProvider);

  if (session == null) {
    router.push('/login');
    return;
  }

  final appointmentId = _value(data, 'appointment_id');
  if (appointmentId != null) {
    router.push(
      session.user.isLandlordMode
          ? '/landlord/appointments/$appointmentId'
          : '/profile/appointments/$appointmentId',
    );
    return;
  }

  final roommatePostId =
      _value(data, 'roommate_post_id') ?? _value(data, 'post_id');
  if (roommatePostId != null) {
    router.push('/roommate/posts/$roommatePostId');
    return;
  }

  final roomId = _value(data, 'room_id');
  if (roomId != null) {
    router.push('/rooms/$roomId');
    return;
  }

  router.push('/notifications');
}

String? _value(Map<String, dynamic> data, String key) {
  final value = data[key]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}
