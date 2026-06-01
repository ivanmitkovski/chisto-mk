import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_draft_summary.freezed.dart';

/// Summary for resume UI (no PII beyond counts and title preview).
@freezed
class ReportDraftSummary with _$ReportDraftSummary {
  const factory ReportDraftSummary({
    required bool hasDraft,
    required int photoCount,
    required String titlePreview,
    required int lastPersistedAtMs,
  }) = _ReportDraftSummary;

  static const ReportDraftSummary empty = ReportDraftSummary(
    hasDraft: false,
    photoCount: 0,
    titlePreview: '',
    lastPersistedAtMs: 0,
  );
}
