import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_session.dart';

class AuthLocalDataSource {
  const AuthLocalDataSource(this._storage);

  static const accessTokenKey = 'auth.access_token';
  static const refreshTokenKey = 'auth.refresh_token';
  static const userKey = 'auth.user';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(AuthSession session) async {
    await Future.wait([
      _storage.write(key: accessTokenKey, value: session.accessToken),
      _storage.write(key: refreshTokenKey, value: session.refreshToken),
      _storage.write(key: userKey, value: jsonEncode(session.user.toJson())),
    ]);
  }

  Future<AuthSession?> readSession() async {
    final values = await Future.wait([
      _storage.read(key: accessTokenKey),
      _storage.read(key: refreshTokenKey),
      _storage.read(key: userKey),
    ]);
    if (values.any((value) => value == null)) return null;
    try {
      return AuthSession(
        accessToken: values[0]!,
        refreshToken: values[1]!,
        user: AuthUser.fromJson(jsonDecode(values[2]!) as Map<String, dynamic>),
      );
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: accessTokenKey),
      _storage.delete(key: refreshTokenKey),
      _storage.delete(key: userKey),
    ]);
  }
}
