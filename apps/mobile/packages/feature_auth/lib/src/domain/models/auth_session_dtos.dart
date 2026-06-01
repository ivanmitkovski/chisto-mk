import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session_dtos.freezed.dart';

/// Tokens persisted after login / OTP verify (local session snapshot).
@freezed
class AuthSessionTokens with _$AuthSessionTokens {
  const factory AuthSessionTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    String? displayName,
    String? phoneNumber,
  }) = _AuthSessionTokens;
}

@freezed
class RegisterResult with _$RegisterResult {
  const factory RegisterResult({
    required String userId,
    required String phoneNumber,
    required int otpExpiresInSeconds,
  }) = _RegisterResult;
}

@freezed
class PasswordResetRequestResult with _$PasswordResetRequestResult {
  const factory PasswordResetRequestResult({
    required String message,
    String? channel,
    int? expiresInSeconds,
  }) = _PasswordResetRequestResult;
}

@freezed
class SendOtpResult with _$SendOtpResult {
  const factory SendOtpResult({required int expiresInSeconds}) = _SendOtpResult;
}

@freezed
class EmailChangeRequestResult with _$EmailChangeRequestResult {
  const factory EmailChangeRequestResult({
    required int expiresInSeconds,
    String? devCode,
  }) = _EmailChangeRequestResult;
}
