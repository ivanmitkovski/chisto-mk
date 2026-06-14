import 'dart:async';
import 'dart:io';

import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:chisto_infrastructure/core/observability/report_draft_metrics.dart';
import 'package:feature_reports/src/data/outbox/report_draft_photo_store.dart';
import 'package:feature_reports/src/data/outbox/report_draft_summary_projector.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_constants.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_entry.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_repository.dart';
import 'package:feature_reports/src/data/report_photo_upload_prep.dart';
import 'package:feature_reports/src/data/report_upload_image_validator.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:feature_reports/src/domain/models/report_draft_summary.dart';
import 'package:feature_reports/src/domain/models/report_wizard_restore_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sentry_flutter/sentry_flutter.dart';

export 'package:feature_reports/src/domain/models/report_draft_summary.dart'
    show ReportDraftSummary;

export 'report_draft_summary_projector.dart'
    show
        ReportDraftSummaryProjector,
        isReportWizardDraftEntryResumable,
        isReportWizardDraftTerminalSubmit,
        reportWizardRestoreSnapshotOf;

/// Outcome of loading a wizard draft from SQLite + photo store.
enum ReportDraftRestoreKind { empty, restored }

class ReportDraftLoadResult {
  const ReportDraftLoadResult._({
    required this.kind,
    this.restore,
    this.prunedPhotoCount = 0,
    this.migratedLegacyPhotoCount = 0,
  });

  const ReportDraftLoadResult.empty()
    : this._(kind: ReportDraftRestoreKind.empty);

  const ReportDraftLoadResult.restored({
    required ReportWizardRestoreSnapshot restore,
    required int prunedPhotoCount,
    required int migratedLegacyPhotoCount,
  }) : this._(
         kind: ReportDraftRestoreKind.restored,
         restore: restore,
         prunedPhotoCount: prunedPhotoCount,
         migratedLegacyPhotoCount: migratedLegacyPhotoCount,
       );

  final ReportDraftRestoreKind kind;
  final ReportWizardRestoreSnapshot? restore;
  final int prunedPhotoCount;
  final int migratedLegacyPhotoCount;

  bool get hasDraft {
    if (kind != ReportDraftRestoreKind.restored || restore == null) {
      return false;
    }
    return restore!.isResumableWizardBody;
  }
}

/// Facade: wizard row + managed photos + telemetry.
class ReportDraftRepository {
  ReportDraftRepository({
    required ReportOutboxRepository outbox,
    required ReportDraftPhotoStore photoStore,
  }) : _outbox = outbox,
       _photoStore = photoStore;

  final ReportOutboxRepository _outbox;
  final ReportDraftPhotoStore _photoStore;

  static const ReportDraftSummary _emptySummary = ReportDraftSummary.empty;

  final ValueNotifier<ReportDraftSummary> _summary =
      ValueNotifier<ReportDraftSummary>(_emptySummary);

  final StreamController<ReportDraftSummary> _summaryStreamController =
      StreamController<ReportDraftSummary>.broadcast(sync: true);

  void _emitSummaryIfChanged(ReportDraftSummary next) {
    if (_summary.value == next) {
      return;
    }
    _summary.value = next;
    if (!_summaryStreamController.isClosed) {
      _summaryStreamController.add(next);
    }
  }

  /// Emits the current value first, then every subsequent summary change.
  Stream<ReportDraftSummary> get summaryStream async* {
    yield _summary.value;
    yield* _summaryStreamController.stream;
  }

  /// Reactive draft presence for shell / list chrome (no polling).
  ValueListenable<ReportDraftSummary> get summaryListenable => _summary;

  /// One-shot after DI so UI matches SQLite before first interaction.
  Future<void> hydrate() => refreshSummary();

  Future<void> refreshSummary() async {
    try {
      final ReportDraftSummary next = await summary();
      _emitSummaryIfChanged(next);
    } catch (e, st) {
      chistoReportsBreadcrumb(
        'report_draft',
        'summary_refresh_failed',
        data: <String, Object?>{'error': e.runtimeType.toString()},
      );
      await Sentry.captureException(e, stackTrace: st);
    }
  }

  Future<ReportDraftSummary> summary() async {
    final ReportOutboxEntry? row = await _outbox.getWizardDraftEntry();
    return ReportDraftSummaryProjector.fromWizardRow(row);
  }

  Future<ReportOutboxEntry?> getWizardDraftEntry() =>
      _outbox.getWizardDraftEntry();

  /// Clears the wizard row when submit finished but the user left without [clear].
  Future<void> clearTerminalSubmitIfPresent() async {
    final ReportOutboxEntry? row = await _outbox.getWizardDraftEntry();
    if (row != null && isReportWizardDraftTerminalSubmit(row)) {
      await clear();
    }
  }

  /// Loads wizard draft, migrates legacy absolute paths into the managed store,
  /// prunes missing files, and re-writes the row when migration or prune ran.
  Future<ReportDraftLoadResult> loadDraft() async {
    try {
      return await _loadDraftInner().timeout(
        kReportDraftLoadTimeout,
        onTimeout: () async {
          chistoReportsBreadcrumb(
            'report_draft',
            'restore_timeout',
            data: <String, Object?>{
              'timeoutMs': kReportDraftLoadTimeout.inMilliseconds,
            },
          );
          await Sentry.captureMessage(
            'Report draft load timed out',
            level: SentryLevel.warning,
          );
          return const ReportDraftLoadResult.empty();
        },
      );
    } finally {
      await refreshSummary();
    }
  }

  Future<ReportDraftLoadResult> _loadDraftInner() async {
    try {
      final ReportOutboxEntry? raw = await _outbox.getWizardDraftEntry();
      if (raw == null) {
        chistoReportsBreadcrumb('report_draft', 'restore_empty');
        return const ReportDraftLoadResult.empty();
      }
      if (isReportWizardDraftTerminalSubmit(raw)) {
        chistoReportsBreadcrumb(
          'report_draft',
          'restore_clear_terminal_submit',
        );
        await clear();
        return const ReportDraftLoadResult.empty();
      }

      int pruned = 0;
      int migrated = 0;
      final List<XFile> resolved = <XFile>[];

      for (final XFile f in raw.draft.photos) {
        final String path = f.path;
        if (path.isEmpty) {
          pruned++;
          continue;
        }
        if (await _photoStore.isManagedPath(path)) {
          final String abs = await _photoStore.absolutePath(path);
          if (File(abs).existsSync()) {
            resolved.add(XFile(abs));
          } else {
            pruned++;
          }
          continue;
        }
        if (p.isAbsolute(path)) {
          final File src = File(path);
          if (src.existsSync()) {
            try {
              final String rel = await _photoStore.importPhoto(f);
              resolved.add(XFile(await _photoStore.absolutePath(rel)));
              migrated++;
            } on Object catch (error, stackTrace) {
              AppLog.warn(
                'report draft: skipped missing photo during migration',
                error: error,
                stackTrace: stackTrace,
                category: 'reports_draft',
              );
              pruned++;
            }
          } else {
            pruned++;
          }
        } else {
          final String abs = await _photoStore.absolutePath(path);
          if (File(abs).existsSync()) {
            resolved.add(XFile(abs));
          } else {
            pruned++;
          }
        }
      }

      final ReportDraft nextDraft = raw.draft.copyWith(photos: resolved);
      ReportOutboxEntry nextRow = raw.copyWith(draft: nextDraft);

      final ReportOutboxEntry resumeCandidate = raw.copyWith(draft: nextDraft);
      if (!isReportWizardDraftEntryResumable(resumeCandidate)) {
        chistoReportsBreadcrumb('report_draft', 'restore_empty');
        return const ReportDraftLoadResult.empty();
      }

      if (migrated > 0 || pruned > 0) {
        await _outbox.saveWizardDraft(
          draft: nextDraft,
          title: raw.title,
          description: raw.description,
          currentStageName: raw.currentStageName,
          attemptedStageNames: raw.attemptedStageNames,
          lastPersistedAtMs: raw.lastPersistedAtMs,
        );
        final ReportOutboxEntry? reloaded = await _outbox.getWizardDraftEntry();
        if (reloaded != null) {
          nextRow = reloaded;
        }
      }

      if (pruned > 0) {
        chistoReportsBreadcrumb(
          'report_draft',
          'restore_photos_pruned',
          data: <String, Object?>{'count': pruned},
        );
      }
      if (migrated > 0) {
        chistoReportsBreadcrumb(
          'report_draft',
          'restore_legacy_paths_migrated',
          data: <String, Object?>{'count': migrated},
        );
      }
      chistoReportsBreadcrumb('report_draft', 'restore_loaded');
      return ReportDraftLoadResult.restored(
        restore: reportWizardRestoreSnapshotOf(nextRow),
        prunedPhotoCount: pruned,
        migratedLegacyPhotoCount: migrated,
      );
    } catch (e, st) {
      chistoReportsBreadcrumb(
        'report_draft',
        'restore_failed',
        data: <String, Object?>{'error': e.runtimeType.toString()},
      );
      await Sentry.captureException(e, stackTrace: st);
      return const ReportDraftLoadResult.empty();
    }
  }

  Future<void> save({
    required ReportDraft draft,
    required String title,
    required String description,
    String? currentStageName,
    List<String>? attemptedStageNames,
    int? lastPersistedAtMs,
  }) async {
    final ReportDraft normalized = await _draftWithRelativePhotoPaths(draft);
    await _outbox.saveWizardDraft(
      draft: normalized,
      title: title,
      description: description,
      currentStageName: currentStageName,
      attemptedStageNames: attemptedStageNames,
      lastPersistedAtMs: lastPersistedAtMs,
    );
    ReportDraftMetrics.instance.recordPersistSuccess();
    await refreshSummary();
  }

  Future<ReportDraft> _draftWithRelativePhotoPaths(ReportDraft draft) async {
    final List<XFile> out = <XFile>[];
    for (final XFile f in draft.photos) {
      final String path = f.path;
      if (path.isEmpty) {
        continue;
      }
      if (p.isAbsolute(path) &&
          !File(path).existsSync() &&
          !await _photoStore.isManagedPath(path)) {
        continue;
      }
      final String rel = await _toRelativeStoredPath(path);
      if (rel.isEmpty) {
        continue;
      }
      out.add(XFile(rel));
    }
    return draft.copyWith(photos: out);
  }

  Future<String> _toRelativeStoredPath(String path) async {
    if (path.isEmpty) {
      return path;
    }
    if (!p.isAbsolute(path)) {
      return path;
    }
    if (await _photoStore.isManagedPath(path)) {
      return p.join(
        ReportDraftPhotoStore.relativeRoot,
        p.basename(p.normalize(path)),
      );
    }
    return _photoStore.importPhoto(XFile(path));
  }

  /// Copies a picker/camera file into the managed store; returns an [XFile] whose
  /// [XFile.path] is absolute (for [FileImage] / upload prep).
  Future<XFile> registerPhoto(XFile pickerFile) async {
    final ReportUploadImageValidation validation =
        await validateReportUploadImage(pickerFile);
    if (!validation.isSupported) {
      throw UnsupportedReportUploadImageException(
        validation.rejection ?? ReportUploadImageRejection.unsupportedFormat,
      );
    }
    final String rel = await _photoStore.importPhoto(pickerFile);
    chistoReportsBreadcrumb('report_draft', 'photo_added');
    final String abs = await _photoStore.absolutePath(rel);
    await compressManagedReportDraftPhotoInPlace(abs);
    final XFile out = XFile(abs);
    await refreshSummary();
    return out;
  }

  Future<void> deleteDraftPhoto(String absoluteOrRelativePath) async {
    await _photoStore.deletePhoto(absoluteOrRelativePath);
    chistoReportsBreadcrumb('report_draft', 'photo_removed');
    await refreshSummary();
  }

  Future<void> clear() async {
    await _photoStore.clearAll();
    final ReportOutboxEntry? existing = await _outbox.getById(
      kReportWizardDraftRowId,
    );
    final int t = DateTime.now().millisecondsSinceEpoch;
    if (existing == null) {
      await _outbox.saveWizardDraft(
        draft: ReportDraft(),
        title: '',
        description: '',
      );
      chistoReportsBreadcrumb('report_draft', 'clear');
      await refreshSummary();
      return;
    }
    await _outbox.update(
      existing.copyWith(
        draft: ReportDraft(),
        title: '',
        description: '',
        idempotencyKey: wizardDraftPlaceholderIdempotencyKey(),
        submitRequested: false,
        state: ReportOutboxState.pending,
        attemptCount: 0,
        clearReportId: true,
        clearMediaUrls: true,
        clearLastError: true,
        clearCooldownUntil: true,
        clearWizardStage: true,
        attemptedStageNames: const <String>[],
        clearLastPersistedAt: true,
        updatedAtMs: t,
      ),
    );
    chistoReportsBreadcrumb('report_draft', 'clear');
    await refreshSummary();
  }
}
