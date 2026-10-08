import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService();

  static const channel = AndroidNotificationChannel(
    'trosv_important',
    'Thông báo TrọSV',
    description: 'Lịch hẹn, tin đăng và các cập nhật quan trọng từ TrọSV.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize({
    required void Function(Map<String, dynamic> data) onNotificationTap,
  }) async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_trosv'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final data = decodePayload(response.payload);
        if (data.isNotEmpty) onNotificationTap(data);
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<Map<String, dynamic>> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return const {};
    return decodePayload(details?.notificationResponse?.payload);
  }

  Future<void> showRemoteMessage(RemoteMessage message) async {
    if (!_initialized) return;

    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'trosv_important',
        'Thông báo TrọSV',
        channelDescription:
            'Lịch hẹn, tin đăng và các cập nhật quan trọng từ TrọSV.',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_trosv',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id:
          message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title ?? 'TrọSV',
      body: body ?? '',
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  static Map<String, dynamic> decodePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map
          ? decoded.map((key, value) => MapEntry(key.toString(), value))
          : const {};
    } catch (_) {
      return const {};
    }
  }
}
