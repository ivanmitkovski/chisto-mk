import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/background/background_submit_scheduler.dart';
import 'package:chisto_mobile/features/reports/data/outbox/outbox_config.dart';
import 'package:chisto_mobile/features/reports/data/outbox/outbox_scheduler.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_constants.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_pipeline_phase.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_submit_error_handler.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_upload_prep_progress.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_upload_phase.dart';
import 'package:chisto_mobile/features/reports/data/report_photo_upload_prep.dart';
import 'package:chisto_mobile/features/reports/domain/draft/report_idempotency_key.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/domain/report_input_sanitizer.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
       _background = backgroundSubmitScheduler ?? InProcessBackgroundSubmitScheduler();

  final ReportOutboxRepository _repo;
  final ReportsApiRepository _api;
  final OutboxConfig _config;
  final OutboxScheduler _scheduler;
  final BackgroundSubmitScheduler _background;

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

  late final ReportOutboxSubmitErrorHandler _submitErrors = ReportOutboxSubmitErrorHandler(
    repository: _repo,
    emitActiveEntry: _active.add,
    maxAttempts: _config.maxSubmitAttempts,
  );

  Stream<ReportOutboxEntry?> get activeEntryStream => _active.stream;
  Stream<ReportOutboxSuccess> get successStream => _success.stream;

  /// Observable coarse phase for UI (e.g. offline chip, cooldown banner).
  Stream<ReportOutboxPipelinePhase> get pipelinePhaseStream => _pipelinePhase.stream;

  void _emitPhase(ReportOutboxPipelinePhase p) {
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

  Future<void> start() {
    if (_started) {
      return Future<void>.value();
    }
    _started = true;
    _connSub = ConnectivityGate.watch().listen((_) {
      _background.scheduleDrain(scheduleProcess);
    });
    return scheduleProcess();
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
    final Future<ReportSubmitResult> outcome = waitForSubmitResult(rowId);
    await enqueueSubmit(
      draft: draft,
      title: title,
      description: description,
    );
    return outcome.timeout(_config.submitAwaitTimeout);
  }

  /// Marks the wizard draft row ready for the outbox pipeline ([kReportWizardDraftRowId]).
  Future<void> enqueueSubmit({
    required ReportDraft draft,
    required String title,
    required String description,
  }) async {
    uploadPrepProgress.value = null;
    final int n = await _repo.countSubmitPipeline();
    if (n > 0) {
      throw StateError('An in-flight report submission already exists.');
    }
    final int now = DateTime.now().millisecondsSinceEpoch;
    final String idem = ReportIdempotencyKey.generate();
    if (!ReportIdempotencyKey.isValidShape(idem)) {
      await Sentry.captureMessage(
        'Generated report idempotency key failed shape check',
        level: SentryLevel.error,
      );
      throw StateError('Invalid idempotency key shape.');
    }
    final String safeTitle = ReportInputSanitizer.clampTitle(title);
    final String safeDescription = ReportInputSanitizer.clampDescription(description);
    ReportOutboxEntry? wizard = await _repo.getById(kReportWizardDraftRowId);
    if (wizard == null) {
      await _repo.saveWizardDraft(
        draft: draft,
        title: safeTitle,
        description: safeDescription,
      );
      wizard = await _repo.getById(kReportWizardDraftRowId);
    }
    if (wizard == null) {
      throw StateError('Report draft row could not be created.');
    }
    await _repo.update(
      wizard.copyWith(
        draft: draft,
        title: safeTitle,
        description: safeDescription,
        idempotencyKey: idem,
        submitRequested: true,
        state: ReportOutboxState.pending,
        attemptCount: 0,
        clearMediaUrls: true,
        clearLastError: true,
        clearCooldownUntil: true,
        updatedAtMs: now,
      ),
    );
    chistoOutboxBreadcrumb(phase: 'enqueue');
    _background.scheduleDrain(scheduleProcess);
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
        final ReportOutboxEntry? raw = await _repo.getNextProcessable();
        if (raw == null) {
          _active.add(null);
          chistoReportSentryClearOutboxEntryScope();
          _emitPhase(ReportOutboxPipelinePhase.idle);
          break;
        }
        final List<ConnectivityResult> conn = await ConnectivityGate.check();
        if (_scheduler.shouldStopAfterFetch(
          online: ConnectivityGate.isOnline(conn),
          foundRow: true,
        )) {
          _active.add(raw);
          chistoReportSentrySyncOutboxScope(
            outboxState: raw.state.name,
            outboxId: raw.id,
          );
          _emitPhase(ReportOutboxPipelinePhase.offlineWait);
          chistoOutboxBreadcrumb(
            phase: 'offline_wait',
            attempt: raw.attemptCount,
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
        final OutboxAfterProcessInstruction next =
            _scheduler.afterProcess(check: check);
        if (next == OutboxAfterProcessInstruction.breakOnCooldown) {
          if (check != null) {
            _active.add(check);
            chistoReportSentrySyncOutboxScope(
              outboxState: check.state.name,
              outboxId: check.id,
            );
          }
          _emitPhase(ReportOutboxPipelinePhase.cooldownWait);
          break;
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
        final ({ReportOutboxEntry entry, List<String> uploadTemps}) up =
            await _uploadPhase.run(e);
        e = up.entry;
        uploadTemps = up.uploadTemps;
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

      try {
        final ReportSubmitResult apiResult = await _api.submitReport(
          latitude: e.draft.latitude!,
          longitude: e.draft.longitude!,
          title: e.title,
          description: e.description.isNotEmpty ? e.description : null,
          mediaUrls: e.mediaUrls,
          category: e.draft.category?.apiString,
          severity: e.draft.severity,
          address: e.draft.address?.trim().isNotEmpty == true
              ? e.draft.address!.trim()
              : null,
          cleanupEffort: e.draft.cleanupEffort?.apiKey,
          idempotencyKey: e.idempotencyKey,
        );
        final ReportSubmitResult result = apiResult.copyWith(
          submittedMediaUrls: List<String>.from(e.mediaUrls ?? const <String>[]),
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
            ReportOutboxEntry(
              id: kReportWizardDraftRowId,
              idempotencyKey: 'idem_$kReportWizardDraftRowId',
              draft: ReportDraft(),
              title: '',
              description: '',
              submitRequested: false,
              state: ReportOutboxState.pending,
              attemptCount: 0,
              createdAtMs: t,
              updatedAtMs: t,
              currentStageName: null,
              attemptedStageNames: const <String>[],
              lastPersistedAtMs: null,
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
      } on AppError catch (err) {
        await _submitErrors.handle(e, err);
        chistoOutboxBreadcrumb(
          phase: 'submit_err',
          attempt: e.attemptCount,
          retryable: err.retryable,
          code: err.code,
        );
      } catch (err) {
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
