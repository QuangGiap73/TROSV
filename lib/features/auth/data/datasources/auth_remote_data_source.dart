import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../dto/auth_session_dto.dart';
import '../dto/send_otp_result_dto.dart';
import '../../domain/entities/auth_session.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AuthSessionDto> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: {'phone': phone.trim(), 'password': password},
    );
    return AuthSessionDto.fromEnvelope(response.data ?? const {});
  }

  Future<SendOtpResultDto> sendOtp(String phone) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/send-otp',
      data: {'phone': phone.trim()},
    );
    return SendOtpResultDto.fromEnvelope(response.data ?? const {});
  }

  Future<AuthSessionDto> register({
    required String name,
    required String phone,
    required String email,
    required String otp,
    required String password,
    required String role,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/register',
      data: {
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'otp': otp.trim(),
        'password': password,
        'role': role,
      },
    );
    return AuthSessionDto.fromEnvelope(response.data ?? const {});
  }

  // kiểm tra và trả về token mới và user có active_mode mới
  Future<AuthSessionDto> switchActiveMode(String activeMode) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/active-mode',
      data: {'active_mode': activeMode},
    );

    return AuthSessionDto.fromEnvelope(response.data ?? const {});
  }

  Future<AuthUser> getMyProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/me');
    final envelope = response.data;
    final data = envelope?['data'];
    if (envelope?['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Dữ liệu tài khoản không hợp lệ.');
    }
    return AuthUser.fromJson(data);
  }

  Future<AuthUser> updateMyProfile({
    required String name,
    required String zaloPhone,
    required String avatarUrl,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/me',
      data: {
        'name': name.trim(),
        'zalo_phone': zaloPhone.trim().isEmpty ? null : zaloPhone.trim(),
        'avatar_url': avatarUrl.trim().isEmpty ? null : avatarUrl.trim(),
      },
    );
    final envelope = response.data;
    final data = envelope?['data'];
    if (envelope?['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Dữ liệu tài khoản không hợp lệ.');
    }
    return AuthUser.fromJson(data);
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/media/upload',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    final envelope = response.data;
    final data = envelope?['data'];
    final url = data is Map<String, dynamic> ? data['url'] : null;
    if (envelope?['success'] != true || url is! String || url.isEmpty) {
      throw const FormatException('Máy chủ không trả về URL của ảnh.');
    }
    return url;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/change-password',
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
    if (response.data?['success'] != true) {
      throw const FormatException('Không thể đổi mật khẩu.');
    }
  }
}
