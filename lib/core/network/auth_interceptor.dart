import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, {required this.onSessionExpired});

  static const _retriedKey = 'auth.has_retried';
  static const _skipRefreshKey = 'auth.skip_refresh';

  final FlutterSecureStorage _storage;
  final void Function() onSessionExpired;
  Future<bool>? _refreshing;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AuthLocalDataSource.accessTokenKey);
    if (token != null && token.isNotEmpty && !_isPublicAuthPath(options.path)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        request.extra[_retriedKey] != true &&
        request.extra[_skipRefreshKey] != true &&
        !_isPublicAuthPath(request.path);

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    try {
      final refreshed = await _refreshOnce(request);
      if (!refreshed) {
        handler.next(err);
        return;
      }

      final accessToken = await _storage.read(
        key: AuthLocalDataSource.accessTokenKey,
      );
      if (accessToken == null || accessToken.isEmpty) {
        handler.next(err);
        return;
      }

      final retryOptions = request.copyWith(
        headers: {...request.headers, 'Authorization': 'Bearer $accessToken'},
        extra: {...request.extra, _retriedKey: true},
        data: request.data is FormData
            ? (request.data as FormData).clone()
            : request.data,
      );
      final response = await _plainDio(request).fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<bool> _refreshOnce(RequestOptions request) {
    final running = _refreshing;
    if (running != null) return running;

    final completer = Completer<bool>();
    _refreshing = completer.future;
    _performRefresh(request)
        .then(completer.complete)
        .catchError((_) {
          completer.complete(false);
        })
        .whenComplete(() {
          _refreshing = null;
        });
    return completer.future;
  }

  Future<bool> _performRefresh(RequestOptions request) async {
    final refreshToken = await _storage.read(
      key: AuthLocalDataSource.refreshTokenKey,
    );
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      return false;
    }

    try {
      final response = await _plainDio(request).post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: const {_skipRefreshKey: true}),
      );
      final envelope = response.data;
      final data = envelope?['data'];
      if (envelope?['success'] != true || data is! Map<String, dynamic>) {
        await _expireSession();
        return false;
      }

      final newAccessToken = data['access_token'];
      final newRefreshToken = data['refresh_token'];
      final user = data['user'];
      if (newAccessToken is! String ||
          newAccessToken.isEmpty ||
          newRefreshToken is! String ||
          newRefreshToken.isEmpty) {
        await _expireSession();
        return false;
      }

      await Future.wait([
        _storage.write(
          key: AuthLocalDataSource.accessTokenKey,
          value: newAccessToken,
        ),
        _storage.write(
          key: AuthLocalDataSource.refreshTokenKey,
          value: newRefreshToken,
        ),
        if (user is Map<String, dynamic>)
          _storage.write(
            key: AuthLocalDataSource.userKey,
            value: jsonEncode(user),
          ),
      ]);
      return true;
    } on DioException {
      await _expireSession();
      return false;
    } on FormatException {
      await _expireSession();
      return false;
    }
  }

  Dio _plainDio(RequestOptions request) => Dio(
    BaseOptions(
      baseUrl: request.baseUrl,
      connectTimeout: request.connectTimeout,
      sendTimeout: request.sendTimeout,
      receiveTimeout: request.receiveTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  );

  Future<void> _expireSession() async {
    await Future.wait([
      _storage.delete(key: AuthLocalDataSource.accessTokenKey),
      _storage.delete(key: AuthLocalDataSource.refreshTokenKey),
      _storage.delete(key: AuthLocalDataSource.userKey),
    ]);
    onSessionExpired();
  }

  bool _isPublicAuthPath(String path) {
    const publicPaths = {
      '/api/v1/auth/login',
      '/api/v1/auth/register',
      '/api/v1/auth/send-otp',
      '/api/v1/auth/verify-otp',
      '/api/v1/auth/forgot-password',
      '/api/v1/auth/reset-password',
      '/api/v1/auth/refresh',
    };
    return publicPaths.contains(path);
  }
}
