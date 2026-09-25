import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/send_otp_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../dto/auth_session_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.remote, required this.local});

  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) => _executeSession(() => remote.login(phone: phone, password: password));

  @override
  Future<SendOtpResult> sendOtp(String phone) async {
    try {
      return (await remote.sendOtp(phone)).toEntity();
    } on DioException catch (error) {
      throw AuthFailure(_errorMessage(error));
    } on FormatException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String phone,
    required String email,
    required String otp,
    required String password,
    required String role,
  }) => _executeSession(
    () => remote.register(
      name: name,
      phone: phone,
      email: email,
      otp: otp,
      password: password,
      role: role,
    ),
  );

  Future<AuthSession> _executeSession(
    Future<AuthSessionDto> Function() request,
  ) async {
    try {
      final dto = await request();
      final session = dto.toEntity();
      await local.saveSession(session);
      return session;
    } on DioException catch (error) {
      throw AuthFailure(_errorMessage(error));
    } on FormatException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<AuthSession?> restoreSession() => local.readSession();

  @override
  Future<void> clearSession() => local.clearSession();

  String _errorMessage(DioException error) {
    final body = error.response?.data;
    if (body is Map<String, dynamic>) {
      final apiError = body['error'];
      if (apiError is Map<String, dynamic> && apiError['message'] is String) {
        return apiError['message'] as String;
      }
      if (body['detail'] is String) return body['detail'] as String;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Kết nối quá thời gian. Vui lòng thử lại.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối tới máy chủ.';
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }

  @override
  Future<AuthSession> switchActiveMode(String activeMode) {
    return _executeSession(() => remote.switchActiveMode(activeMode));
  }

  @override
  Future<AuthSession> getMyProfile() async {
    try {
      final current = await local.readSession();
      if (current == null) {
        throw const AuthFailure('Bạn cần đăng nhập để xem thông tin cá nhân.');
      }
      final user = await remote.getMyProfile();
      final session = AuthSession(
        accessToken: current.accessToken,
        refreshToken: current.refreshToken,
        user: user,
      );
      await local.saveSession(session);
      return session;
    } on AuthFailure {
      rethrow;
    } on DioException catch (error) {
      throw AuthFailure(_errorMessage(error));
    } on FormatException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<AuthSession> updateMyProfile({
    required String name,
    required String zaloPhone,
    required String avatarUrl,
  }) async {
    try {
      final current = await local.readSession();
      if (current == null) {
        throw const AuthFailure('Bạn cần đăng nhập để sửa thông tin cá nhân.');
      }
      final user = await remote.updateMyProfile(
        name: name,
        zaloPhone: zaloPhone,
        avatarUrl: avatarUrl,
      );
      final session = AuthSession(
        accessToken: current.accessToken,
        refreshToken: current.refreshToken,
        user: user,
      );
      await local.saveSession(session);
      return session;
    } on AuthFailure {
      rethrow;
    } on DioException catch (error) {
      throw AuthFailure(_errorMessage(error));
    } on FormatException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      return await remote.uploadProfileImage(bytes: bytes, filename: filename);
    } on DioException catch (error) {
      throw AuthFailure(_errorMessage(error));
    } on FormatException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await remote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on DioException catch (error) {
      throw AuthFailure(_errorMessage(error));
    } on FormatException catch (error) {
      throw AuthFailure(error.message);
    }
  }
}
