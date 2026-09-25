import 'dart:typed_data';

import '../entities/auth_session.dart';
import '../entities/send_otp_result.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login({required String phone, required String password});

  Future<SendOtpResult> sendOtp(String phone);

  Future<AuthSession> register({
    required String name,
    required String phone,
    required String email,
    required String otp,
    required String password,
    required String role,
  });
  Future<AuthSession> switchActiveMode(String activeMode);
  Future<AuthSession> getMyProfile();
  Future<AuthSession> updateMyProfile({
    required String name,
    required String zaloPhone,
    required String avatarUrl,
  });
  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String filename,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<AuthSession?> restoreSession();
  Future<void> clearSession();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
