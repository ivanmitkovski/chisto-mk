import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/debug/chisto_submit_debug_log.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/network/connectivity_gate.dart';
import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:feature_reports/src/data/outbox/background/background_submit_scheduler.dart';
import 'package:feature_reports/src/data/outbox/outbox_config.dart';
import 'package:feature_reports/src/data/outbox/outbox_scheduler.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_constants.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_entry.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_pipeline_phase.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_repository.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_submit_error_handler.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_upload_phase.dart';
import 'package:feature_reports/src/data/report_photo_upload_prep.dart';
import 'package:feature_reports/src/domain/draft/new_report_flow_policy.dart';
import 'package:feature_reports/src/domain/draft/report_idempotency_key.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_submit_result.dart';
import 'package:feature_reports/src/domain/models/report_upload_prep_progress.dart';
import 'package:feature_reports/src/domain/report_input_sanitizer.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Drains the SQLite outbox: compress, upload, POST /reports with stable idempotency key.
class ReportOutboxCoordinator {
  ReportOutboxCoordinator({
    required ReportOutboxRepository repository,
    required ReportsApiRepository reportsApi,
    OutboxConfig config = OutboxConfig.defaults,
    OutboxScheduler scheduler = const OutboxScheduler(),
    BackgroundSubmitScheduler? backgroundSubmitScheduler,
  }) : _repo = repository,
       _api = reportsApi,
       _config = config,
       _scheduler = scheduler,
       _background =
           backgroundSubmitScheduler ?? InProcessBackgroundSubmitScheduler();

  final ReportOutboxRepository _repo;
  final ReportsApiRepository _api;
  final OutboxConfig _config;
  final OutboxScheduler _scheduler;
  final BackgroundSubmitScheduler _background;

  final String _ownerId =
      '${DateTime.now().microsecondsSinceEpoch}_${identityHashCode(Object())}';

  final StreamController<ReportOutboxEntry?> _active =
      StreamController<ReportOutboxEntry?>.broadcast();
  final StreamController<ReportOutboxSuccess> _success =
      StreamController<ReportOutboxSuccess>.broadcast();
  final StreamController<ReportOutboxPipelinePhase> _pipelinePhase =
      StreamController<ReportOutboxPipelinePhase>.broadcast();

  /// UI: JPEG normalization progress before HTTP photo upload.
  final ValueNotifier<ReportUploadPrepProgress?> uploadPrepProgress =
      ValueNotifier<ReportUploadPrepProgress?>(null);

  bool _disposed = false;
  final List<void Function()> _submitWaitDisposeHooks = <void Function()>[];

  late final ReportOutboxUploadPhase _uploadPhase = ReportOutboxUploadPhase(
    repository: _repo,
    reportsApi: _api,
    emitActiveEntry: _active.add,
    uploadAutoRetries: _config.uploadAutoRetries,
    onUploadPrepProgress: (int completed, int total) {
      uploadPrepProgress.value = ReportUploadPrepProgress(
        completed: completed,
        total: total,
      );
    },
    onUploadPrepProgressClear: () {
      uploadPrepProgress.value = null;
    },
  );

  late final ReportOutboxSubmitErrorHandler _submitErrors =
      ReportOutboxSubmitErrorHandler(
        repository: _repo,
        emitActiveEntry: _active.add,
        maxAttempts: _config.maxSubmitAttempts,
      );

  Stream<ReportOutboxEntry?> get activeEntryStream => _active.stream;
  Stream<ReportOutboxSuccess> get successStream => _success.stream;

  /// Observable coarse phase for UI (e.g. offline chip, cooldown banner).
  Stream<ReportOutboxPipelinePhase> get pipelinePhaseStream =>
      _pipelinePhase.stream;

  void _emitPhase(ReportOutboxPipelinePhase p) {
    if (_disposed || _pipelinePhase.isClosed) {
      chistoReportSentrySyncOutboxScope(pipelinePhase: p.name);
      return;
    }
    if (!_pipelinePhase.isClosed) {
      _pipelinePhase.add(p);
    }
    chistoReportSentrySyncOutboxScope(pipelinePhase: p.name);
  }

  /// Completes on success, throws [AppError] on terminal failure. Cooldown/retry keeps waiting.
  Future<ReportSubmitResult> waitForSubmitResult(String outboxId) {
    final Completer<ReportSubmitResult> done = Completer<ReportSubmitResult>();
    void cancelBecauseDisposed() {
      if (!done.isCompleted) {
        done.completeError(StateError('ReportOutboxCoordinator disposed'));
      }
    }

    _submitWaitDisposeHooks.add(cancelBecauseDisposed);
    late final StreamSubscription<ReportOutboxSuccess> subOk;
    late final StreamSubscription<ReportOutboxEntry?> subAct;
    subOk = _success.stream.listen((ReportOutboxSuccess s) {
      if (s.outboxId == outboxId && !done.isCompleted) {
        done.complete(s.result);
      }
    });
    subAct = _active.stream.listen((ReportOutboxEntry? e) {
      if (e == null || e.id != outboxId) {
        return;
      }
      if (e.state == ReportOutboxState.failed && !done.isCompleted) {
        done.completeError(
          AppError.validation(
            message: e.lastErrorMessage ?? 'Submission failed',
            details: e.lastErrorCode,
          ),
        );
      }
    });
    return done.future.whenComplete(() async {
      _submitWaitDisposeHooks.remove(cancelBecauseDisposed);
      await subOk.cancel();
      await subAct.cancel();
    });
  }

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _started = false;
  bool _busy = false;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    await _selfHealStuckWizardRow();
    _connSub = ConnectivityGate.watch().listen((_) {
      _background.scheduleDrain(scheduleProcess);
    });
    await scheduleProcess();
  }

  /// Recovers a wizard row stuck in `uploading` / `submitting` from a prior
  /// crashed isolate. We only reset rows whose lease has expired (or is
  /// unset); a live owner is left alone.
  Future<void> _selfHealStuckWizardRow() async {
    try {
      final ReportOutboxEntry? wizard = await _repo.getById(
        kReportWizardDraftRowId,
      );
      if (wizard == null) {
        return;
      }
      final bool stuckState =
          wizard.state == ReportOutboxState.uploading ||
          wizard.state == ReportOutboxState.submitting;
      if (!stuckState) {
        return;
      }
      final int now = DateTime.now().millisecondsSinceEpoch;
      final bool leaseExpired = wizard.processingLeaseUntilMs == null ||
          wizard.processingLeaseUntilMs! <= now;
      if (!leaseExpired) {
        return;
      }
      AppLog.warn(
        'report outbox: self-heal stuck wizard row state=${wizard.state.name} '
        'attempt=${wizard.attemptCount}',
        category: 'reports_outbox',
      );
      await _repo.update(
        wizard.copyWith(
          state: ReportOutboxState.pending,
          clearProcessingLease: true,
          clearLastError: true,
          clearCooldownUntil: true,
        ),
      );
    } on Object catch (err, st) {
      AppLog.warn(
        'report outbox: self-heal failed: $err',
        error: err,
        stackTrace: st,
        category: 'reports_outbox',
      );
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    chistoReportSentryClearReportPipelineScope();
    for (final void Function() hook in List<void Function()>.from(
      _submitWaitDisposeHooks,
    )) {
      hook();
    }
    _submitWaitDisposeHooks.clear();
    uploadPrepProgress.dispose();
    await _connSub?.cancel();
    _connSub = null;
    await _active.close();
    await _success.close();
    await _pipelinePhase.close();
  }

  /// Registers listeners then enqueues work so success events are never missed.
  Future<ReportSubmitResult> submitReportAndAwait({
    required ReportDraft draft,
    required String title,
    required String description,
  }) async {
    const String rowId = kReportWizardDraftRowId;
    final ReportOutboxEntry? wizard = await _repo.getById(rowId);
    final ReportSubmitResult? alreadySucceeded =
        _resultIfWizardAlreadySucceeded(wizard);
    if (alreadySucceeded != null) {
      chistoSubmitDebugLog(
        'submitReportAndAwait: wizard already succeeded reportId=${alreadySucceeded.reportId}',
      );
      return alreadySucceeded;
    }
    if (_wizardSubmitInFlight(wizard)) {
      _background.scheduleDrain(scheduleProcess);
      return waitForSubmitResult(rowId).timeout(_config.submitAwaitTimeout);
    }
    final Future<ReportSubmitResult> outcome = waitForSubmitResult(rowId);
    await enqueueSubmit(draft: draft, title: title, description: description);
    return outcome.timeout(_config.submitAwaitTimeout);
  }

  /// Prevents a second POST after the pipeline already succeeded but before
  /// [ReportDraftRepository.clear] (coordinator used to reset the row immediately).
  ReportSubmitResult? _resultIfWizardAlreadySucceeded(ReportOutboxEntry? wizard) {
    final String? reportId = wizard?.reportId;
    if (wizard == null ||
        wizard.state != ReportOutboxState.succeeded ||
        reportId == null ||
        reportId.isEmpty) {
      return null;
    }
    return ReportSubmitResult(
      reportId: reportId,
      siteId: '',
      isNewSite: false,
      pointsAwarded: 0,
    );
  }

  bool _wizardSubmitInFlight(ReportOutboxEntry? wizard) {
    if (wizard == null) {
      return false;
    }
    return wizard.occupiesSubmitPipeline;
  }

  /// Marks the wizard draft row ready for the outbox pipeline ([kReportWizardDraftRowId]).
  Future<void> enqueueSubmit({
    required ReportDraft draft,
    required String title,
    required String description,
  }) async {
    uploadPrepProgress.value = null;
    ReportOutboxEntry? wizard = await _repo.getById(kReportWizardDraftRowId);
    if (wizard != null &&
        wizard.state == ReportOutboxState.succeeded &&
        (wizard.reportId?.isNotEmpty ?? false)) {
      throw StateError(
        'Report already submitted (${wizard.reportId}). '
        'Start a new report after leaving the wizard.',
      );
    }
    if (wizard == null) {
      await _repo.saveWizardDraft(
        draft: draft,
        title: ReportInputSanitizer.clampTitle(title),
        description: ReportInputSanitizer.clampDescription(description),
      );
      wizard = await _repo.getById(kReportWizardDraftRowId);
    }
    if (wizard == null) {
      throw StateError('Report draft row could not be created.');
    }
    final String idem = _resolveSubmitIdempotencyKey(wizard);
    if (!ReportIdempotencyKey.isValidShape(idem)) {
      await Sentry.captureMessage(
        'Generated report idempotency key failed shape check',
        level: SentryLevel.error,
      );
      throw StateError('Invalid idempotency key shape.');
    }
    await _repo.atomicEnqueueWizardSubmit(
      draft: draft,
      title: ReportInputSanitizer.clampTitle(title),
      description: ReportInputSanitizer.clampDescription(description),
      idempotencyKey: idem,
    );
    chistoOutboxBreadcrumb(phase: 'enqueue');
    _background.scheduleDrain(scheduleProcess);
  }

  /// Reuses any valid persisted submit key (failed, in-flight, or cooldown) so
  /// retries and duplicate taps do not mint a new [Idempotency-Key] and create
  /// another report server-side.
  String _resolveSubmitIdempotencyKey(ReportOutboxEntry wizard) {
    final String key = wizard.idempotencyKey;
    if (!isWizardDraftPlaceholderIdempotencyKey(key) &&
        ReportIdempotencyKey.isValidShape(key)) {
      return key;
    }
    return ReportIdempotencyKey.generate();
  }

  Future<void> resetFailedToPending(String id) async {
    final ReportOutboxEntry? e = await _repo.getById(id);
    if (e == null || e.state != ReportOutboxState.failed) {
      return;
    }
    await _repo.update(
      e.copyWith(
        state: ReportOutboxState.pending,
        attemptCount: 0,
        clearLastError: true,
        clearCooldownUntil: true,
      ),
    );
    _background.scheduleDrain(scheduleProcess);
  }

  Future<void> scheduleProcess() async {
    if (_disposed) {
      return;
    }
    if (_busy) {
      return;
    }
    _busy = true;
    try {
      while (true) {
        final ReportOutboxEntry? raw = await _repo.claimNextProcessable(
          ownerId: _ownerId,
          leaseDuration: _config.processingLeaseDuration,
        );
        if (raw == null) {
          if (!_disposed) {
            if (!_active.isClosed) {
              _active.add(null);
            }
            chistoReportSentryClearOutboxEntryScope();
            _emitPhase(ReportOutboxPipelinePhase.idle);
          }
          break;
        }
        if (_disposed) {
          await _repo.releaseLease(raw.id);
          break;
        }
        try {
          final List<ConnectivityResult> conn = await ConnectivityGate.check();
          if (_disposed) {
            break;
          }
          if (_scheduler.shouldStopAfterFetch(
            online: ConnectivityGate.isOnline(conn),
            foundRow: true,
          )) {
            if (!_disposed && !_active.isClosed) {
              _active.add(raw);
            }
            chistoReportSentrySyncOutboxScope(
              outboxState: raw.state.name,
              outboxId: raw.id,
            );
            _emitPhase(ReportOutboxPipelinePhase.offlineWait);
            chistoOutboxBreadcrumb(
              phase: 'offline_wait',
              attempt: raw.attemptCount,
            );
            _background.scheduleDrain(
              scheduleProcess,
              requestNativeFollowUp: true,
            );
            break;
          }
          _emitPhase(ReportOutboxPipelinePhase.active);
          final ReportOutboxEntry? latest = await _repo.getById(raw.id);
          if (latest == null) {
            continue;
          }
          await _processEntry(latest);
          final ReportOutboxEntry? check = await _repo.getById(raw.id);
          final OutboxAfterProcessInstruction next = _scheduler.afterProcess(
            check: check,
          );
          if (next == OutboxAfterProcessInstruction.breakOnCooldown) {
            if (check != null) {
              _active.add(check);
              chistoReportSentrySyncOutboxScope(
                outboxState: check.state.name,
                outboxId: check.id,
              );
            }
            _emitPhase(ReportOutboxPipelinePhase.cooldownWait);
            _background.scheduleDrain(
              scheduleProcess,
              requestNativeFollowUp: true,
            );
            break;
          }
        } finally {
          await _repo.releaseLease(raw.id);
        }
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _processEntry(ReportOutboxEntry entry) async {
    _active.add(entry);
    chistoReportSentrySyncOutboxScope(
      outboxState: entry.state.name,
      outboxId: entry.id,
    );
    final Stopwatch pipelineWatch = Stopwatch()..start();
    ReportOutboxEntry e = entry;
    List<String> uploadTemps = <String>[];
    var uploadPhotosSkippedCount = 0;
    var uploadCompressionFallbackCount = 0;

    try {
      if (e.state == ReportOutboxState.cooldown) {
        e = e.copyWith(
          state: ReportOutboxState.submitting,
          clearCooldownUntil: true,
        );
        await _repo.update(e);
      }

      if (e.state == ReportOutboxState.pending ||
          e.state == ReportOutboxState.uploading) {
        final ({
          ReportOutboxEntry entry,
          List<String> uploadTemps,
          int compressionFallbackCount,
          int skippedPhotoCount,
        })
        up = await _uploadPhase.run(e);
        e = up.entry;
        uploadTemps = up.uploadTemps;
        uploadCompressionFallbackCount = up.compressionFallbackCount;
        uploadPhotosSkippedCount = up.skippedPhotoCount;
        if (e.state == ReportOutboxState.failed ||
            e.state == ReportOutboxState.cooldown) {
          return;
        }
      }

      if (e.state == ReportOutboxState.submitting ||
          (e.state == ReportOutboxState.pending && e.mediaUrls != null)) {
        e = e.copyWith(state: ReportOutboxState.submitting);
        await _repo.update(e);
      }

      if (e.state != ReportOutboxState.submitting) {
        return;
      }

      if (!NewReportFlowPolicy.hasValidLocation(e.draft)) {
        final AppError locationErr = AppError.validation(
          message: 'Report location is missing or outside coverage.',
        );
        await _submitErrors.handle(e, locationErr);
        chistoOutboxBreadcrumb(
          phase: 'submit_invalid_location',
          attempt: e.attemptCount,
        );
        return;
      }

      try {
        final ReportSubmitResult apiResult = await _api.submitReport(
          latitude: e.draft.latitude!,
          longitude: e.draft.longitude!,
          title: e.title,
          description: e.description.isNotEmpty ? e.description : null,
          mediaUrls: e.mediaUrls,
          category: e.draft.category?.apiString,
          severity: e.draft.severity,
          address: e.draft.address?.trim().isNotEmpty ?? false
              ? e.draft.address!.trim()
              : null,
          cleanupEffort: e.draft.cleanupEffort?.apiKey,
          idempotencyKey: e.idempotencyKey,
        );
        final ReportSubmitResult result = apiResult.copyWith(
          submittedMediaUrls: List<String>.from(
            e.mediaUrls ?? const <String>[],
          ),
          uploadPhotosSkippedCount: uploadPhotosSkippedCount,
          uploadCompressionFallbackCount: uploadCompressionFallbackCount,
        );
        chistoOutboxBreadcrumb(
          phase: 'submit_ok',
          attempt: e.attemptCount,
          retryable: false,
        );
        _success.add(ReportOutboxSuccess(outboxId: e.id, result: result));
        deleteReportUploadTempFiles(uploadTemps);
        final int t = DateTime.now().millisecondsSinceEpoch;
        if (e.id == kReportWizardDraftRowId) {
          await _repo.update(
            e.copyWith(
              state: ReportOutboxState.succeeded,
              reportId: result.reportId,
              submitRequested: false,
              clearMediaUrls: true,
              updatedAtMs: t,
            ),
          );
        } else {
          await _repo.update(
            e.copyWith(
              state: ReportOutboxState.succeeded,
              reportId: result.reportId,
              submitRequested: false,
              clearMediaUrls: true,
              updatedAtMs: t,
            ),
          );
        }
        _active.add(null);
        chistoReportSentryClearOutboxEntryScope();
        _emitPhase(ReportOutboxPipelinePhase.idle);
      } on AppError catch (err, st) {
        chistoSubmitDebugLog(
          'outbox submit AppError code=${err.code} retryable=${err.retryable} '
          'attempt=${e.attemptCount} msg=${err.message}',
          error: err,
          stack: st,
        );
        AppLog.warn(
          'report submit failed: code=${err.code} retryable=${err.retryable} '
          'attempt=${e.attemptCount} message=${err.message}',
          error: err,
          stackTrace: st,
          category: 'reports_outbox',
        );
        await _submitErrors.handle(e, err);
        chistoOutboxBreadcrumb(
          phase: 'submit_err',
          attempt: e.attemptCount,
          retryable: err.retryable,
          code: err.code,
        );
      } catch (err, st) {
        chistoSubmitDebugLog(
          'outbox submit non-AppError type=${err.runtimeType} attempt=${e.attemptCount}',
          error: err,
          stack: st,
        );
        AppLog.error(
          'report submit threw non-AppError (wrapped UNKNOWN): '
          'type=${err.runtimeType} attempt=${e.attemptCount} message=$err',
          error: err,
          stackTrace: st,
          category: 'reports_outbox',
        );
        unawaited(Sentry.captureException(err, stackTrace: st));
        final AppError wrapped = AppError.unknown(cause: err);
        await _submitErrors.handle(e, wrapped);
        chistoOutboxBreadcrumb(
          phase: 'submit_err',
          attempt: e.attemptCount,
          retryable: wrapped.retryable,
          code: wrapped.code,
        );
      }
    } finally {
      pipelineWatch.stop();
      chistoOutboxBreadcrumb(
        phase: 'pipeline_done',
        durationMs: pipelineWatch.elapsedMilliseconds,
      );
    }
  }
}
