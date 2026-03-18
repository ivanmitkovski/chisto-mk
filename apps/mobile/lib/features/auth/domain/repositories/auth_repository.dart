abstract class AuthRepository {
  bool get isAuthenticated;
  String? get currentUserId;
  String? get accessToken;

  Future<void> signIn({
    required String phoneNumber,
    required String password,
  });

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  });

  Future<void> refreshSession();

  Future<void> signOut();

  Future<void> restoreSession();

  /// Request OTP for the given (registered) phone number. Returns [SendOtpResult].
  Future<SendOtpResult> requestOtp(String phoneNumberE164);

  /// Verify OTP and mark phone as verified on the backend.
  Future<void> verifyOtp(String phoneNumberE164, String code);

  Future<SendOtpResult> requestPasswordReset(String phoneNumberE164);

  Future<void> confirmPasswordReset({
    required String phoneNumberE164,
    required String code,
    required String newPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class SendOtpResult {
  const SendOtpResult({required this.expiresInSeconds, this.devCode});

  final int expiresInSeconds;
  final String? devCode;
}
