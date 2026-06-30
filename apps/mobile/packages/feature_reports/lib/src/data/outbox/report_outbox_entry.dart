import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';

/// Local persistence state for report submit outbox.
enum ReportOutboxState {
  pending,
  uploading,
  submitting,
  succeeded,
  failed,
  cooldown,
}

/// One queued or in-flight report submission.
class ReportOutboxEntry {
  const ReportOutboxEntry({
    required this.id,
    required this.idempotencyKey,
    required this.draft,
    required this.title,
    required this.description,
    this.submitRequested = false,
    this.mediaUrls,
    required this.state,
    required this.attemptCount,
    this.lastErrorCode,
    this.lastErrorMessage,
    this.cooldownUntilMs,
    this.reportId,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.currentStageName,
    this.attemptedStageNames = const <String>[],
    this.lastPersistedAtMs,
    this.processingOwner,
    this.processingLeaseUntilMs,
  });

  final String id;
  final String idempotencyKey;
  final ReportDraft draft;
  final String title;
  final String description;

  /// When false, row is wizard autosave only; coordinator ignores until true.
  final bool submitRequested;
  final List<String>? mediaUrls;
  final ReportOutboxState state;
  final int attemptCount;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final int? cooldownUntilMs;
  final String? reportId;
  final int createdAtMs;
  final int updatedAtMs;

  /// [ReportStage.name] for wizard resume (e.g. `evidence`). Wizard-only.
  final String? currentStageName;

  /// [ReportStage.name] values the user has visited. Wizard-only.
  final List<String> attemptedStageNames;

  /// When the wizard draft was last persisted (autosave). Wizard-only.
  final int? lastPersistedAtMs;

  /// Isolate that claimed this row for processing (cross-isolate lease).
  final String? processingOwner;

  /// Epoch ms until [processingOwner] holds the lease; null when unclaimed.
  final int? processingLeaseUntilMs;

  bool get isTerminal =>
      state == ReportOutboxState.succeeded || state == ReportOutboxState.failed;

  /// Row is eligible for the submit pipeline (upload / POST / cooldown retry).
  bool get occupiesSubmitPipeline =>
      state == ReportOutboxState.uploading ||
      state == ReportOutboxState.submitting ||
      state == ReportOutboxState.cooldown ||
      (state == ReportOutboxState.pending && submitRequested);

  ReportOutboxEntry copyWith({
    ReportDraft? draft,
    String? title,
    String? description,
    bool? submitRequested,
    String? idempotencyKey,
    List<String>? mediaUrls,
    bool clearMediaUrls = false,
    ReportOutboxState? state,
    int? attemptCount,
    String? lastErrorCode,
    String? lastErrorMessage,
    bool clearLastError = false,
    int? cooldownUntilMs,
    bool clearCooldownUntil = false,
    String? reportId,
    bool clearReportId = false,
    int? updatedAtMs,
    String? currentStageName,
    List<String>? attemptedStageNames,
    bool clearWizardStage = false,
    int? lastPersistedAtMs,
    bool clearLastPersistedAt = false,
    String? processingOwner,
    int? processingLeaseUntilMs,
    bool clearProcessingLease = false,
  }) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    return ReportOutboxEntry(
      id: id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      draft: draft ?? this.draft,
      title: title ?? this.title,
      description: description ?? this.description,
      submitRequested: submitRequested ?? this.submitRequested,
      mediaUrls: clearMediaUrls ? null : (mediaUrls ?? this.mediaUrls),
      state: state ?? this.state,
      attemptCount: attemptCount ?? this.attemptCount,
      lastErrorCode: clearLastError
          ? null
          : (lastErrorCode ?? this.lastErrorCode),
      lastErrorMessage: clearLastError
          ? null
          : (lastErrorMessage ?? this.lastErrorMessage),
      cooldownUntilMs: clearCooldownUntil
          ? null
          : (cooldownUntilMs ?? this.cooldownUntilMs),
      reportId: clearReportId ? null : (reportId ?? this.reportId),
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? now,
      currentStageName: clearWizardStage
          ? null
          : (currentStageName ?? this.currentStageName),
      attemptedStageNames: attemptedStageNames ?? this.attemptedStageNames,
      lastPersistedAtMs: clearLastPersistedAt
          ? null
          : (lastPersistedAtMs ?? this.lastPersistedAtMs),
      processingOwner: clearProcessingLease
          ? null
          : (processingOwner ?? this.processingOwner),
      processingLeaseUntilMs: clearProcessingLease
          ? null
          : (processingLeaseUntilMs ?? this.processingLeaseUntilMs),
    );
  }
}

/// Terminal success payload for UI.
class ReportOutboxSuccess {
  const ReportOutboxSuccess({required this.outboxId, required this.result});

  final String outboxId;
  final ReportSubmitResult result;
}
