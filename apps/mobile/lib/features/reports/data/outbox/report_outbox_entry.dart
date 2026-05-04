import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';

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

  bool get isTerminal =>
      state == ReportOutboxState.succeeded || state == ReportOutboxState.failed;

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
    int? updatedAtMs,
    String? currentStageName,
    List<String>? attemptedStageNames,
    bool clearWizardStage = false,
    int? lastPersistedAtMs,
    bool clearLastPersistedAt = false,
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
      lastErrorCode: clearLastError ? null : (lastErrorCode ?? this.lastErrorCode),
      lastErrorMessage:
          clearLastError ? null : (lastErrorMessage ?? this.lastErrorMessage),
      cooldownUntilMs: clearCooldownUntil
          ? null
          : (cooldownUntilMs ?? this.cooldownUntilMs),
      reportId: reportId ?? this.reportId,
      createdAtMs: createdAtMs,
      updatedAtMs: updatedAtMs ?? now,
      currentStageName: clearWizardStage ? null : (currentStageName ?? this.currentStageName),
      attemptedStageNames: attemptedStageNames ?? this.attemptedStageNames,
      lastPersistedAtMs: clearLastPersistedAt
          ? null
          : (lastPersistedAtMs ?? this.lastPersistedAtMs),
    );
  }
}

/// Terminal success payload for UI.
class ReportOutboxSuccess {
  const ReportOutboxSuccess({
    required this.outboxId,
    required this.result,
  });

  final String outboxId;
  final ReportSubmitResult result;
}
