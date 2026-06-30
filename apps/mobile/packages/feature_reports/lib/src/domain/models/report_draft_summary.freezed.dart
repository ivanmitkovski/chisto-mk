// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_draft_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ReportDraftSummary {
  bool get hasDraft => throw _privateConstructorUsedError;
  int get photoCount => throw _privateConstructorUsedError;
  String get titlePreview => throw _privateConstructorUsedError;
  int get lastPersistedAtMs => throw _privateConstructorUsedError;

  /// Create a copy of ReportDraftSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReportDraftSummaryCopyWith<ReportDraftSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportDraftSummaryCopyWith<$Res> {
  factory $ReportDraftSummaryCopyWith(
    ReportDraftSummary value,
    $Res Function(ReportDraftSummary) then,
  ) = _$ReportDraftSummaryCopyWithImpl<$Res, ReportDraftSummary>;
  @useResult
  $Res call({
    bool hasDraft,
    int photoCount,
    String titlePreview,
    int lastPersistedAtMs,
  });
}

/// @nodoc
class _$ReportDraftSummaryCopyWithImpl<$Res, $Val extends ReportDraftSummary>
    implements $ReportDraftSummaryCopyWith<$Res> {
  _$ReportDraftSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReportDraftSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasDraft = null,
    Object? photoCount = null,
    Object? titlePreview = null,
    Object? lastPersistedAtMs = null,
  }) {
    return _then(
      _value.copyWith(
            hasDraft: null == hasDraft
                ? _value.hasDraft
                : hasDraft // ignore: cast_nullable_to_non_nullable
                      as bool,
            photoCount: null == photoCount
                ? _value.photoCount
                : photoCount // ignore: cast_nullable_to_non_nullable
                      as int,
            titlePreview: null == titlePreview
                ? _value.titlePreview
                : titlePreview // ignore: cast_nullable_to_non_nullable
                      as String,
            lastPersistedAtMs: null == lastPersistedAtMs
                ? _value.lastPersistedAtMs
                : lastPersistedAtMs // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReportDraftSummaryImplCopyWith<$Res>
    implements $ReportDraftSummaryCopyWith<$Res> {
  factory _$$ReportDraftSummaryImplCopyWith(
    _$ReportDraftSummaryImpl value,
    $Res Function(_$ReportDraftSummaryImpl) then,
  ) = __$$ReportDraftSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool hasDraft,
    int photoCount,
    String titlePreview,
    int lastPersistedAtMs,
  });
}

/// @nodoc
class __$$ReportDraftSummaryImplCopyWithImpl<$Res>
    extends _$ReportDraftSummaryCopyWithImpl<$Res, _$ReportDraftSummaryImpl>
    implements _$$ReportDraftSummaryImplCopyWith<$Res> {
  __$$ReportDraftSummaryImplCopyWithImpl(
    _$ReportDraftSummaryImpl _value,
    $Res Function(_$ReportDraftSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReportDraftSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasDraft = null,
    Object? photoCount = null,
    Object? titlePreview = null,
    Object? lastPersistedAtMs = null,
  }) {
    return _then(
      _$ReportDraftSummaryImpl(
        hasDraft: null == hasDraft
            ? _value.hasDraft
            : hasDraft // ignore: cast_nullable_to_non_nullable
                  as bool,
        photoCount: null == photoCount
            ? _value.photoCount
            : photoCount // ignore: cast_nullable_to_non_nullable
                  as int,
        titlePreview: null == titlePreview
            ? _value.titlePreview
            : titlePreview // ignore: cast_nullable_to_non_nullable
                  as String,
        lastPersistedAtMs: null == lastPersistedAtMs
            ? _value.lastPersistedAtMs
            : lastPersistedAtMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ReportDraftSummaryImpl implements _ReportDraftSummary {
  const _$ReportDraftSummaryImpl({
    required this.hasDraft,
    required this.photoCount,
    required this.titlePreview,
    required this.lastPersistedAtMs,
  });

  @override
  final bool hasDraft;
  @override
  final int photoCount;
  @override
  final String titlePreview;
  @override
  final int lastPersistedAtMs;

  @override
  String toString() {
    return 'ReportDraftSummary(hasDraft: $hasDraft, photoCount: $photoCount, titlePreview: $titlePreview, lastPersistedAtMs: $lastPersistedAtMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportDraftSummaryImpl &&
            (identical(other.hasDraft, hasDraft) ||
                other.hasDraft == hasDraft) &&
            (identical(other.photoCount, photoCount) ||
                other.photoCount == photoCount) &&
            (identical(other.titlePreview, titlePreview) ||
                other.titlePreview == titlePreview) &&
            (identical(other.lastPersistedAtMs, lastPersistedAtMs) ||
                other.lastPersistedAtMs == lastPersistedAtMs));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    hasDraft,
    photoCount,
    titlePreview,
    lastPersistedAtMs,
  );

  /// Create a copy of ReportDraftSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportDraftSummaryImplCopyWith<_$ReportDraftSummaryImpl> get copyWith =>
      __$$ReportDraftSummaryImplCopyWithImpl<_$ReportDraftSummaryImpl>(
        this,
        _$identity,
      );
}

abstract class _ReportDraftSummary implements ReportDraftSummary {
  const factory _ReportDraftSummary({
    required final bool hasDraft,
    required final int photoCount,
    required final String titlePreview,
    required final int lastPersistedAtMs,
  }) = _$ReportDraftSummaryImpl;

  @override
  bool get hasDraft;
  @override
  int get photoCount;
  @override
  String get titlePreview;
  @override
  int get lastPersistedAtMs;

  /// Create a copy of ReportDraftSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReportDraftSummaryImplCopyWith<_$ReportDraftSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
