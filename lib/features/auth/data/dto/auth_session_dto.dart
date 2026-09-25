import '../../domain/entities/auth_session.dart';

class AuthSessionDto {
  const AuthSessionDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthSessionDto.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (envelope['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Response xác thực không hợp lệ.');
    }
    final user = data['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Thiếu thông tin người dùng.');
    }
    return AuthSessionDto(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      user: user,
    );
  }

  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  AuthSession toEntity() => AuthSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    user: AuthUser.fromJson(user),
  );
}
