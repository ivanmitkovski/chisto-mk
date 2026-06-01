// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_session_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AuthSessionTokens {
  String get accessToken => throw _privateConstructorUsedError;
  String get refreshToken => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get phoneNumber => throw _privateConstructorUsedError;

  /// Create a copy of AuthSessionTokens
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthSessionTokensCopyWith<AuthSessionTokens> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthSessionTokensCopyWith<$Res> {
  factory $AuthSessionTokensCopyWith(
    AuthSessionTokens value,
    $Res Function(AuthSessionTokens) then,
  ) = _$AuthSessionTokensCopyWithImpl<$Res, AuthSessionTokens>;
  @useResult
  $Res call({
    String accessToken,
    String refreshToken,
    String userId,
    String? displayName,
    String? phoneNumber,
  });
}

/// @nodoc
class _$AuthSessionTokensCopyWithImpl<$Res, $Val extends AuthSessionTokens>
    implements $AuthSessionTokensCopyWith<$Res> {
  _$AuthSessionTokensCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthSessionTokens
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? userId = null,
    Object? displayName = freezed,
    Object? phoneNumber = freezed,
  }) {
    return _then(
      _value.copyWith(
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            refreshToken: null == refreshToken
                ? _value.refreshToken
                : refreshToken // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            phoneNumber: freezed == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthSessionTokensImplCopyWith<$Res>
    implements $AuthSessionTokensCopyWith<$Res> {
  factory _$$AuthSessionTokensImplCopyWith(
    _$AuthSessionTokensImpl value,
    $Res Function(_$AuthSessionTokensImpl) then,
  ) = __$$AuthSessionTokensImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String accessToken,
    String refreshToken,
    String userId,
    String? displayName,
    String? phoneNumber,
  });
}

/// @nodoc
class __$$AuthSessionTokensImplCopyWithImpl<$Res>
    extends _$AuthSessionTokensCopyWithImpl<$Res, _$AuthSessionTokensImpl>
    implements _$$AuthSessionTokensImplCopyWith<$Res> {
  __$$AuthSessionTokensImplCopyWithImpl(
    _$AuthSessionTokensImpl _value,
    $Res Function(_$AuthSessionTokensImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthSessionTokens
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? userId = null,
    Object? displayName = freezed,
    Object? phoneNumber = freezed,
  }) {
    return _then(
      _$AuthSessionTokensImpl(
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        refreshToken: null == refreshToken
            ? _value.refreshToken
            : refreshToken // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        phoneNumber: freezed == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$AuthSessionTokensImpl implements _AuthSessionTokens {
  const _$AuthSessionTokensImpl({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    this.displayName,
    this.phoneNumber,
  });

  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final String userId;
  @override
  final String? displayName;
  @override
  final String? phoneNumber;

  @override
  String toString() {
    return 'AuthSessionTokens(accessToken: $accessToken, refreshToken: $refreshToken, userId: $userId, displayName: $displayName, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthSessionTokensImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    accessToken,
    refreshToken,
    userId,
    displayName,
    phoneNumber,
  );

  /// Create a copy of AuthSessionTokens
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthSessionTokensImplCopyWith<_$AuthSessionTokensImpl> get copyWith =>
      __$$AuthSessionTokensImplCopyWithImpl<_$AuthSessionTokensImpl>(
        this,
        _$identity,
      );
}

abstract class _AuthSessionTokens implements AuthSessionTokens {
  const factory _AuthSessionTokens({
    required final String accessToken,
    required final String refreshToken,
    required final String userId,
    final String? displayName,
    final String? phoneNumber,
  }) = _$AuthSessionTokensImpl;

  @override
  String get accessToken;
  @override
  String get refreshToken;
  @override
  String get userId;
  @override
  String? get displayName;
  @override
  String? get phoneNumber;

  /// Create a copy of AuthSessionTokens
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthSessionTokensImplCopyWith<_$AuthSessionTokensImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RegisterResult {
  String get userId => throw _privateConstructorUsedError;
  String get phoneNumber => throw _privateConstructorUsedError;
  int get otpExpiresInSeconds => throw _privateConstructorUsedError;

  /// Create a copy of RegisterResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RegisterResultCopyWith<RegisterResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegisterResultCopyWith<$Res> {
  factory $RegisterResultCopyWith(
    RegisterResult value,
    $Res Function(RegisterResult) then,
  ) = _$RegisterResultCopyWithImpl<$Res, RegisterResult>;
  @useResult
  $Res call({String userId, String phoneNumber, int otpExpiresInSeconds});
}

/// @nodoc
class _$RegisterResultCopyWithImpl<$Res, $Val extends RegisterResult>
    implements $RegisterResultCopyWith<$Res> {
  _$RegisterResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RegisterResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? phoneNumber = null,
    Object? otpExpiresInSeconds = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            phoneNumber: null == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            otpExpiresInSeconds: null == otpExpiresInSeconds
                ? _value.otpExpiresInSeconds
                : otpExpiresInSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RegisterResultImplCopyWith<$Res>
    implements $RegisterResultCopyWith<$Res> {
  factory _$$RegisterResultImplCopyWith(
    _$RegisterResultImpl value,
    $Res Function(_$RegisterResultImpl) then,
  ) = __$$RegisterResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String userId, String phoneNumber, int otpExpiresInSeconds});
}

/// @nodoc
class __$$RegisterResultImplCopyWithImpl<$Res>
    extends _$RegisterResultCopyWithImpl<$Res, _$RegisterResultImpl>
    implements _$$RegisterResultImplCopyWith<$Res> {
  __$$RegisterResultImplCopyWithImpl(
    _$RegisterResultImpl _value,
    $Res Function(_$RegisterResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RegisterResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? phoneNumber = null,
    Object? otpExpiresInSeconds = null,
  }) {
    return _then(
      _$RegisterResultImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        phoneNumber: null == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        otpExpiresInSeconds: null == otpExpiresInSeconds
            ? _value.otpExpiresInSeconds
            : otpExpiresInSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$RegisterResultImpl implements _RegisterResult {
  const _$RegisterResultImpl({
    required this.userId,
    required this.phoneNumber,
    required this.otpExpiresInSeconds,
  });

  @override
  final String userId;
  @override
  final String phoneNumber;
  @override
  final int otpExpiresInSeconds;

  @override
  String toString() {
    return 'RegisterResult(userId: $userId, phoneNumber: $phoneNumber, otpExpiresInSeconds: $otpExpiresInSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegisterResultImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.otpExpiresInSeconds, otpExpiresInSeconds) ||
                other.otpExpiresInSeconds == otpExpiresInSeconds));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, phoneNumber, otpExpiresInSeconds);

  /// Create a copy of RegisterResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegisterResultImplCopyWith<_$RegisterResultImpl> get copyWith =>
      __$$RegisterResultImplCopyWithImpl<_$RegisterResultImpl>(
        this,
        _$identity,
      );
}

abstract class _RegisterResult implements RegisterResult {
  const factory _RegisterResult({
    required final String userId,
    required final String phoneNumber,
    required final int otpExpiresInSeconds,
  }) = _$RegisterResultImpl;

  @override
  String get userId;
  @override
  String get phoneNumber;
  @override
  int get otpExpiresInSeconds;

  /// Create a copy of RegisterResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegisterResultImplCopyWith<_$RegisterResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PasswordResetRequestResult {
  String get message => throw _privateConstructorUsedError;
  String? get channel => throw _privateConstructorUsedError;
  int? get expiresInSeconds => throw _privateConstructorUsedError;

  /// Create a copy of PasswordResetRequestResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PasswordResetRequestResultCopyWith<PasswordResetRequestResult>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PasswordResetRequestResultCopyWith<$Res> {
  factory $PasswordResetRequestResultCopyWith(
    PasswordResetRequestResult value,
    $Res Function(PasswordResetRequestResult) then,
  ) =
      _$PasswordResetRequestResultCopyWithImpl<
        $Res,
        PasswordResetRequestResult
      >;
  @useResult
  $Res call({String message, String? channel, int? expiresInSeconds});
}

/// @nodoc
class _$PasswordResetRequestResultCopyWithImpl<
  $Res,
  $Val extends PasswordResetRequestResult
>
    implements $PasswordResetRequestResultCopyWith<$Res> {
  _$PasswordResetRequestResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PasswordResetRequestResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? channel = freezed,
    Object? expiresInSeconds = freezed,
  }) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            channel: freezed == channel
                ? _value.channel
                : channel // ignore: cast_nullable_to_non_nullable
                      as String?,
            expiresInSeconds: freezed == expiresInSeconds
                ? _value.expiresInSeconds
                : expiresInSeconds // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PasswordResetRequestResultImplCopyWith<$Res>
    implements $PasswordResetRequestResultCopyWith<$Res> {
  factory _$$PasswordResetRequestResultImplCopyWith(
    _$PasswordResetRequestResultImpl value,
    $Res Function(_$PasswordResetRequestResultImpl) then,
  ) = __$$PasswordResetRequestResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, String? channel, int? expiresInSeconds});
}

/// @nodoc
class __$$PasswordResetRequestResultImplCopyWithImpl<$Res>
    extends
        _$PasswordResetRequestResultCopyWithImpl<
          $Res,
          _$PasswordResetRequestResultImpl
        >
    implements _$$PasswordResetRequestResultImplCopyWith<$Res> {
  __$$PasswordResetRequestResultImplCopyWithImpl(
    _$PasswordResetRequestResultImpl _value,
    $Res Function(_$PasswordResetRequestResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PasswordResetRequestResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? channel = freezed,
    Object? expiresInSeconds = freezed,
  }) {
    return _then(
      _$PasswordResetRequestResultImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        channel: freezed == channel
            ? _value.channel
            : channel // ignore: cast_nullable_to_non_nullable
                  as String?,
        expiresInSeconds: freezed == expiresInSeconds
            ? _value.expiresInSeconds
            : expiresInSeconds // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$PasswordResetRequestResultImpl implements _PasswordResetRequestResult {
  const _$PasswordResetRequestResultImpl({
    required this.message,
    this.channel,
    this.expiresInSeconds,
  });

  @override
  final String message;
  @override
  final String? channel;
  @override
  final int? expiresInSeconds;

  @override
  String toString() {
    return 'PasswordResetRequestResult(message: $message, channel: $channel, expiresInSeconds: $expiresInSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PasswordResetRequestResultImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.channel, channel) || other.channel == channel) &&
            (identical(other.expiresInSeconds, expiresInSeconds) ||
                other.expiresInSeconds == expiresInSeconds));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, message, channel, expiresInSeconds);

  /// Create a copy of PasswordResetRequestResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PasswordResetRequestResultImplCopyWith<_$PasswordResetRequestResultImpl>
  get copyWith =>
      __$$PasswordResetRequestResultImplCopyWithImpl<
        _$PasswordResetRequestResultImpl
      >(this, _$identity);
}

abstract class _PasswordResetRequestResult
    implements PasswordResetRequestResult {
  const factory _PasswordResetRequestResult({
    required final String message,
    final String? channel,
    final int? expiresInSeconds,
  }) = _$PasswordResetRequestResultImpl;

  @override
  String get message;
  @override
  String? get channel;
  @override
  int? get expiresInSeconds;

  /// Create a copy of PasswordResetRequestResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PasswordResetRequestResultImplCopyWith<_$PasswordResetRequestResultImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SendOtpResult {
  int get expiresInSeconds => throw _privateConstructorUsedError;

  /// Create a copy of SendOtpResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SendOtpResultCopyWith<SendOtpResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SendOtpResultCopyWith<$Res> {
  factory $SendOtpResultCopyWith(
    SendOtpResult value,
    $Res Function(SendOtpResult) then,
  ) = _$SendOtpResultCopyWithImpl<$Res, SendOtpResult>;
  @useResult
  $Res call({int expiresInSeconds});
}

/// @nodoc
class _$SendOtpResultCopyWithImpl<$Res, $Val extends SendOtpResult>
    implements $SendOtpResultCopyWith<$Res> {
  _$SendOtpResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SendOtpResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? expiresInSeconds = null}) {
    return _then(
      _value.copyWith(
            expiresInSeconds: null == expiresInSeconds
                ? _value.expiresInSeconds
                : expiresInSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SendOtpResultImplCopyWith<$Res>
    implements $SendOtpResultCopyWith<$Res> {
  factory _$$SendOtpResultImplCopyWith(
    _$SendOtpResultImpl value,
    $Res Function(_$SendOtpResultImpl) then,
  ) = __$$SendOtpResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int expiresInSeconds});
}

/// @nodoc
class __$$SendOtpResultImplCopyWithImpl<$Res>
    extends _$SendOtpResultCopyWithImpl<$Res, _$SendOtpResultImpl>
    implements _$$SendOtpResultImplCopyWith<$Res> {
  __$$SendOtpResultImplCopyWithImpl(
    _$SendOtpResultImpl _value,
    $Res Function(_$SendOtpResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SendOtpResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? expiresInSeconds = null}) {
    return _then(
      _$SendOtpResultImpl(
        expiresInSeconds: null == expiresInSeconds
            ? _value.expiresInSeconds
            : expiresInSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$SendOtpResultImpl implements _SendOtpResult {
  const _$SendOtpResultImpl({required this.expiresInSeconds});

  @override
  final int expiresInSeconds;

  @override
  String toString() {
    return 'SendOtpResult(expiresInSeconds: $expiresInSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SendOtpResultImpl &&
            (identical(other.expiresInSeconds, expiresInSeconds) ||
                other.expiresInSeconds == expiresInSeconds));
  }

  @override
  int get hashCode => Object.hash(runtimeType, expiresInSeconds);

  /// Create a copy of SendOtpResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SendOtpResultImplCopyWith<_$SendOtpResultImpl> get copyWith =>
      __$$SendOtpResultImplCopyWithImpl<_$SendOtpResultImpl>(this, _$identity);
}

abstract class _SendOtpResult implements SendOtpResult {
  const factory _SendOtpResult({required final int expiresInSeconds}) =
      _$SendOtpResultImpl;

  @override
  int get expiresInSeconds;

  /// Create a copy of SendOtpResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SendOtpResultImplCopyWith<_$SendOtpResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EmailChangeRequestResult {
  int get expiresInSeconds => throw _privateConstructorUsedError;
  String? get devCode => throw _privateConstructorUsedError;

  /// Create a copy of EmailChangeRequestResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EmailChangeRequestResultCopyWith<EmailChangeRequestResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmailChangeRequestResultCopyWith<$Res> {
  factory $EmailChangeRequestResultCopyWith(
    EmailChangeRequestResult value,
    $Res Function(EmailChangeRequestResult) then,
  ) = _$EmailChangeRequestResultCopyWithImpl<$Res, EmailChangeRequestResult>;
  @useResult
  $Res call({int expiresInSeconds, String? devCode});
}

/// @nodoc
class _$EmailChangeRequestResultCopyWithImpl<
  $Res,
  $Val extends EmailChangeRequestResult
>
    implements $EmailChangeRequestResultCopyWith<$Res> {
  _$EmailChangeRequestResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EmailChangeRequestResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? expiresInSeconds = null, Object? devCode = freezed}) {
    return _then(
      _value.copyWith(
            expiresInSeconds: null == expiresInSeconds
                ? _value.expiresInSeconds
                : expiresInSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            devCode: freezed == devCode
                ? _value.devCode
                : devCode // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EmailChangeRequestResultImplCopyWith<$Res>
    implements $EmailChangeRequestResultCopyWith<$Res> {
  factory _$$EmailChangeRequestResultImplCopyWith(
    _$EmailChangeRequestResultImpl value,
    $Res Function(_$EmailChangeRequestResultImpl) then,
  ) = __$$EmailChangeRequestResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int expiresInSeconds, String? devCode});
}

/// @nodoc
class __$$EmailChangeRequestResultImplCopyWithImpl<$Res>
    extends
        _$EmailChangeRequestResultCopyWithImpl<
          $Res,
          _$EmailChangeRequestResultImpl
        >
    implements _$$EmailChangeRequestResultImplCopyWith<$Res> {
  __$$EmailChangeRequestResultImplCopyWithImpl(
    _$EmailChangeRequestResultImpl _value,
    $Res Function(_$EmailChangeRequestResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EmailChangeRequestResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? expiresInSeconds = null, Object? devCode = freezed}) {
    return _then(
      _$EmailChangeRequestResultImpl(
        expiresInSeconds: null == expiresInSeconds
            ? _value.expiresInSeconds
            : expiresInSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        devCode: freezed == devCode
            ? _value.devCode
            : devCode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$EmailChangeRequestResultImpl implements _EmailChangeRequestResult {
  const _$EmailChangeRequestResultImpl({
    required this.expiresInSeconds,
    this.devCode,
  });

  @override
  final int expiresInSeconds;
  @override
  final String? devCode;

  @override
  String toString() {
    return 'EmailChangeRequestResult(expiresInSeconds: $expiresInSeconds, devCode: $devCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmailChangeRequestResultImpl &&
            (identical(other.expiresInSeconds, expiresInSeconds) ||
                other.expiresInSeconds == expiresInSeconds) &&
            (identical(other.devCode, devCode) || other.devCode == devCode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, expiresInSeconds, devCode);

  /// Create a copy of EmailChangeRequestResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmailChangeRequestResultImplCopyWith<_$EmailChangeRequestResultImpl>
  get copyWith =>
      __$$EmailChangeRequestResultImplCopyWithImpl<
        _$EmailChangeRequestResultImpl
      >(this, _$identity);
}

abstract class _EmailChangeRequestResult implements EmailChangeRequestResult {
  const factory _EmailChangeRequestResult({
    required final int expiresInSeconds,
    final String? devCode,
  }) = _$EmailChangeRequestResultImpl;

  @override
  int get expiresInSeconds;
  @override
  String? get devCode;

  /// Create a copy of EmailChangeRequestResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmailChangeRequestResultImplCopyWith<_$EmailChangeRequestResultImpl>
  get copyWith => throw _privateConstructorUsedError;
}
