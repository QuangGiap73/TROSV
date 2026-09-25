class SendOtpResult {
  const SendOtpResult({
    required this.message,
    required this.cooldownSeconds,
    this.debugOtp,
  });

  final String message;
  final int cooldownSeconds;
  final String? debugOtp;
}
