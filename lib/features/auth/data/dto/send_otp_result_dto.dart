import '../../domain/entities/send_otp_result.dart';

class SendOtpResultDto {
  const SendOtpResultDto({
    required this.message,
    required this.cooldownSeconds,
    this.debugOtp,
  });

  factory SendOtpResultDto.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (envelope['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Response OTP không hợp lệ.');
    }
    return SendOtpResultDto(
      message: data['message'] as String? ?? 'Đã gửi mã OTP.',
      cooldownSeconds: (data['cooldown_seconds'] as num?)?.toInt() ?? 60,
      debugOtp: data['debug_otp'] as String?,
    );
  }

  final String message;
  final int cooldownSeconds;
  final String? debugOtp;

  SendOtpResult toEntity() => SendOtpResult(
    message: message,
    cooldownSeconds: cooldownSeconds,
    debugOtp: debugOtp,
  );
}
