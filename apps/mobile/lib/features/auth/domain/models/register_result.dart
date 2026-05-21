class RegisterResult {
  const RegisterResult({
    required this.userId,
    required this.phoneNumber,
    required this.otpExpiresInSeconds,
  });

  final String userId;
  final String phoneNumber;
  final int otpExpiresInSeconds;
}

class PasswordResetRequestResult {
  const PasswordResetRequestResult({
    required this.message,
    this.channel,
    this.expiresInSeconds,
  });

  final String message;
  final String? channel;
  final int? expiresInSeconds;
}
