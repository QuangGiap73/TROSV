import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(
    dio: ref.watch(dioProvider),
    messaging: Firebase.apps.isEmpty ? null : FirebaseMessaging.instance,
  );
});

class PushNotificationService {
  const PushNotificationService({
    required Dio dio,
    required FirebaseMessaging? messaging,
  }) : _dio = dio,
       _messaging = messaging;

  final Dio _dio;
  final FirebaseMessaging? _messaging;

  FirebaseMessaging? get messaging => _messaging;

  Future<String?> registerCurrentDevice({bool requestPermission = true}) async {
    final messaging = _messaging;
    if (messaging == null || kIsWeb || !_isSupportedPlatform) return null;

    if (requestPermission) {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken == null || apnsToken.isEmpty) return null;
    }

    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return null;

    await registerToken(token);
    return token;
  }

  Future<void> registerToken(String token) async {
    if (token.trim().isEmpty || !_isSupportedPlatform) return;
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/devices',
      data: {'platform': _platform, 'fcm_token': token.trim()},
    );
  }

  Future<String?> unregisterCurrentDevice() async {
    final messaging = _messaging;
    if (messaging == null || kIsWeb || !_isSupportedPlatform) return null;

    final token = await messaging.getToken();
    if (token == null || token.isEmpty) return null;

    await _dio.delete<Map<String, dynamic>>(
      '/api/v1/devices',
      data: {'fcm_token': token},
    );
    return token;
  }

  Future<void> deleteLocalToken() async {
    await _messaging?.deleteToken();
  }

  bool get _isSupportedPlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID';
}
