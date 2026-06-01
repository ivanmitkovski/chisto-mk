import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_auth/src/domain/models/auth_session_dtos.dart';
import 'package:feature_auth/src/domain/repositories/auth_repository.dart';

/// Configurable [AuthRepository] for widget and notifier tests.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.isAuthenticated = false,
    this.currentUserId,
    this.accessToken,
    Future<void> Function({
      required String phoneNumber,
      required String password,
      bool rememberMe,
    })?
    signInImpl,
    Future<RegisterResult> Function()? signUpImpl,
    Future<SendOtpResult> Function(String phone)? requestOtpImpl,
    Future<void> Function(String phone, String code)? verifyOtpImpl,
    Future<PasswordResetRequestResult> Function(String phone)?
    requestPasswordResetImpl,
    Future<PasswordResetRequestResult> Function(String email)?
    requestPasswordResetByEmailImpl,
    Future<void> Function(String phone, String code)?
    verifyPasswordResetCodeImpl,
    Future<void> Function({
      required String phoneNumberE164,
      required String code,
      required String newPassword,
    })?
    confirmPasswordResetImpl,
    Future<void> Function({required String token, required String newPassword})?
    confirmPasswordResetByEmailImpl,
    Future<void> Function()? restoreSessionImpl,
    Future<void> Function({
      required double latitude,
      required double longitude,
      String? label,
    })?
    updateHomeLocationImpl,
  }) : _signInImpl = signInImpl,
       _signUpImpl = signUpImpl,
       _requestOtpImpl = requestOtpImpl,
       _verifyOtpImpl = verifyOtpImpl,
       _requestPasswordResetImpl = requestPasswordResetImpl,
       _requestPasswordResetByEmailImpl = requestPasswordResetByEmailImpl,
       _verifyPasswordResetCodeImpl = verifyPasswordResetCodeImpl,
       _confirmPasswordResetImpl = confirmPasswordResetImpl,
       _confirmPasswordResetByEmailImpl = confirmPasswordResetByEmailImpl,
       _restoreSessionImpl = restoreSessionImpl,
       _updateHomeLocationImpl = updateHomeLocationImpl;

  @override
  bool isAuthenticated;

  @override
  String? currentUserId;

  @override
  String? accessToken;

  @override
  bool restoreProfileValidationPending = false;

  @override
  bool? requiresTermsAcceptance;

  @override
  Future<bool> refreshTermsConsentFromServer() async =>
      requiresTermsAcceptance ?? true;

  @override
  Future<void> acceptTermsOnServer() async {
    requiresTermsAcceptance = false;
  }

  final Future<void> Function({
    required String phoneNumber,
    required String password,
    bool rememberMe,
  })?
  _signInImpl;
  final Future<RegisterResult> Function()? _signUpImpl;
  final Future<SendOtpResult> Function(String phone)? _requestOtpImpl;
  final Future<void> Function(String phone, String code)? _verifyOtpImpl;
  final Future<PasswordResetRequestResult> Function(String phone)?
  _requestPasswordResetImpl;
  final Future<PasswordResetRequestResult> Function(String email)?
  _requestPasswordResetByEmailImpl;
  final Future<void> Function(String phone, String code)?
  _verifyPasswordResetCodeImpl;
  final Future<void> Function({
    required String phoneNumberE164,
    required String code,
    required String newPassword,
  })?
  _confirmPasswordResetImpl;
  final Future<void> Function({
    required String token,
    required String newPassword,
  })?
  _confirmPasswordResetByEmailImpl;
  final Future<void> Function()? _restoreSessionImpl;
  final Future<void> Function({
    required double latitude,
    required double longitude,
    String? label,
  })?
  _updateHomeLocationImpl;

  AppError? signInError;
  AppError? verifyOtpError;
  AppError? verifyPasswordResetCodeError;

  @override
  Future<void> signIn({
    required String phoneNumber,
    required String password,
    bool rememberMe = true,
  }) async {
    if (signInError != null) throw signInError!;
    final f = _signInImpl;
    if (f != null) {
      await f(
        phoneNumber: phoneNumber,
        password: password,
        rememberMe: rememberMe,
      );
      return;
    }
  }

  @override
  Future<RegisterResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final f = _signUpImpl;
    if (f != null) return f();
    return const RegisterResult(
      userId: 'u-test',
      phoneNumber: '+38970123456',
      otpExpiresInSeconds: 300,
    );
  }

  @override
  Future<RefreshOutcome> refreshSession() async => RefreshOutcome.success;

  @override
  Future<void> signOut() async {
    isAuthenticated = false;
    currentUserId = null;
    accessToken = null;
  }

  @override
  Future<void> invalidateLocalSession() async {
    isAuthenticated = false;
  }

  @override
  Future<void> restoreSession() async {
    final f = _restoreSessionImpl;
    if (f != null) await f();
  }

  @override
  Future<SendOtpResult> requestOtp(String phoneNumberE164) async {
    final f = _requestOtpImpl;
    if (f != null) return f(phoneNumberE164);
    return const SendOtpResult(expiresInSeconds: 300);
  }

  @override
  Future<void> verifyOtp(String phoneNumberE164, String code) async {
    if (verifyOtpError != null) throw verifyOtpError!;
    final f = _verifyOtpImpl;
    if (f != null) await f(phoneNumberE164, code);
  }

  @override
  Future<PasswordResetRequestResult> requestPasswordReset(
    String phoneNumberE164,
  ) async {
    final f = _requestPasswordResetImpl;
    if (f != null) return f(phoneNumberE164);
    return const PasswordResetRequestResult(message: 'ok');
  }

  @override
  Future<PasswordResetRequestResult> requestPasswordResetByEmail(
    String email,
  ) async {
    final f = _requestPasswordResetByEmailImpl;
    if (f != null) return f(email);
    return const PasswordResetRequestResult(message: 'ok');
  }

  @override
  Future<void> verifyPasswordResetCode(
    String phoneNumberE164,
    String code,
  ) async {
    if (verifyPasswordResetCodeError != null) {
      throw verifyPasswordResetCodeError!;
    }
    final f = _verifyPasswordResetCodeImpl;
    if (f != null) await f(phoneNumberE164, code);
  }

  @override
  Future<void> confirmPasswordReset({
    required String phoneNumberE164,
    required String code,
    required String newPassword,
  }) async {
    final f = _confirmPasswordResetImpl;
    if (f != null) {
      await f(
        phoneNumberE164: phoneNumberE164,
        code: code,
        newPassword: newPassword,
      );
    }
  }

  @override
  Future<void> confirmPasswordResetByEmail({
    required String token,
    required String newPassword,
  }) async {
    final f = _confirmPasswordResetByEmailImpl;
    if (f != null) await f(token: token, newPassword: newPassword);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccount() async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateHomeLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final f = _updateHomeLocationImpl;
    if (f != null) {
      await f(latitude: latitude, longitude: longitude, label: label);
    }
  }

  @override
  Future<EmailChangeRequestResult> requestEmailChange(String newEmail) async {
    return const EmailChangeRequestResult(expiresInSeconds: 300);
  }

  @override
  Future<void> confirmEmailChange({
    required String newEmail,
    required String code,
  }) async {}
}
