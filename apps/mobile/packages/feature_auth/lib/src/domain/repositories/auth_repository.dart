import 'package:feature_auth/src/domain/models/auth_session_dtos.dart';
import 'package:feature_auth/src/domain/refresh_outcome.dart';
import 'package:chisto_infrastructure/core/auth/session_teardown_reason.dart';

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
  Future<void> invalidateLocalSession({
    int? observedEpoch,
    SessionTeardownReason? reason,
  });

  Future<void> restoreSession();

  /// Request OTP for the given (registered) phone number. Returns [SendOtpResult].
  Future<SendOtpResult> requestOtp(String phoneNumberE164);

  /// Verify OTP, mark phone verified, and persist session tokens locally.
  ///
  /// [rememberMe] controls client persistence and server refresh TTL. Defaults
  /// to persistent (registration and sign-in with Remember Me on).
  Future<void> verifyOtp(
    String phoneNumberE164,
    String code, {
    bool rememberMe = true,
  });

  Future<PasswordResetRequestResult> requestPasswordReset(
    String phoneNumberE164,
  );

  Future<PasswordResetRequestResult> requestPasswordResetByEmail(String email);

  /// Validates the SMS code for password reset without consuming the OTP.
  Future<void> verifyPasswordResetCode(String phoneNumberE164, String code);

  /// Validates the email code for password reset without consuming the OTP.
  Future<void> verifyPasswordResetCodeByEmail(String email, String code);

  Future<void> confirmPasswordReset({
    required String phoneNumberE164,
    required String code,
    required String newPassword,
  });

  Future<void> confirmPasswordResetByEmail({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Starts verified email change (OTP to new address). Requires Redis on API.
  Future<EmailChangeRequestResult> requestEmailChange(String newEmail);

  Future<void> confirmEmailChange({
    required String newEmail,
    required String code,
  });

  Future<void> deleteAccount();

  Future<void> updateHomeLocation({
    required double latitude,
    required double longitude,
    String? label,
  });

  /// Last known server flag: `false` = terms already accepted for current version.
  bool? get requiresTermsAcceptance;

  /// Refreshes terms consent from `GET /auth/me` (when [requiresTermsAcceptance] is unknown).
  Future<bool> refreshTermsConsentFromServer();

  /// Persists acceptance of current terms on the server (`POST /auth/me/accept-terms`).
  Future<void> acceptTermsOnServer();
}
