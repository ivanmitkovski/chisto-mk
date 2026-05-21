import 'package:chisto_mobile/features/auth/domain/models/register_result.dart';
import 'package:chisto_mobile/features/auth/domain/refresh_outcome.dart';

abstract class AuthRepository {
  bool get isAuthenticated;
  String? get currentUserId;
  String? get accessToken;

  /// True while [restoreSession] has optimistic auth but `/auth/me` is still in flight.
  bool get restoreProfileValidationPending;

  Future<void> signIn({
    required String phoneNumber,
    required String password,
    bool rememberMe = true,
  });

  /// Creates account and sends phone OTP. Does not persist a local session.
  Future<RegisterResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  });

  Future<RefreshOutcome> refreshSession();

  Future<void> signOut();

  /// Clears local tokens and auth UI state when the API reports an invalid session
  /// (e.g. 401). Does not call the server logout endpoint.
  Future<void> invalidateLocalSession();

  Future<void> restoreSession();

  /// Request OTP for the given (registered) phone number. Returns [SendOtpResult].
  Future<SendOtpResult> requestOtp(String phoneNumberE164);

  /// Verify OTP, mark phone verified, and persist session tokens locally.
  Future<void> verifyOtp(String phoneNumberE164, String code);

  Future<PasswordResetRequestResult> requestPasswordReset(String phoneNumberE164);

  Future<PasswordResetRequestResult> requestPasswordResetByEmail(String email);

  /// Validates the SMS code for password reset without consuming the OTP.
  Future<void> verifyPasswordResetCode(String phoneNumberE164, String code);

  Future<void> confirmPasswordReset({
    required String phoneNumberE164,
    required String code,
    required String newPassword,
  });

  Future<void> confirmPasswordResetByEmail({
    required String token,
    required String newPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> deleteAccount();

  Future<void> updateHomeLocation({
    required double latitude,
    required double longitude,
    String? label,
  });
}

class SendOtpResult {
  const SendOtpResult({required this.expiresInSeconds});

  final int expiresInSeconds;
}
