import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_provider.dart';
import 'auth_interceptor.dart';
import 'session_expiry_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
      storage,
      onSessionExpired: () {
        ref.read(sessionExpiryProvider.notifier).notifyExpired();
      },
    ),
  );
  dio.interceptors.add(
    LogInterceptor(
      requestBody: false,
      responseBody: false,
      requestHeader: false,
      responseHeader: false,
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});
