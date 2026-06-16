import 'package:chisto_infrastructure/core/debug/chisto_submit_debug_log.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_entry.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_error_classifier.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_repository.dart';
import 'package:feature_reports/src/data/report_photo_upload_prep.dart';
import 'package:feature_reports/src/domain/models/report_photo_upload_outcome.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';

/// Photo upload loop for the outbox (pending/uploading → submitting or failed).
class ReportOutboxUploadPhase {
  ReportOutboxUploadPhase({
    required ReportOutboxRepository repository,
    required ReportsApiRepository reportsApi,
    required void Function(ReportOutboxEntry? entry) emitActiveEntry,
    required int uploadAutoRetries,
    void Function(int completed, int total)? onUploadPrepProgress,
    void Function()? onUploadPrepProgressClear,
  }) : _repo = repository,
       _api = reportsApi,
       _emitActiveEntry = emitActiveEntry,
       _uploadAutoRetries = uploadAutoRetries,
       _onUploadPrepProgress = onUploadPrepProgress,
       _onUploadPrepProgressClear = onUploadPrepProgressClear;

  final ReportOutboxRepository _repo;
  final ReportsApiRepository _api;
  final void Function(ReportOutboxEntry? entry) _emitActiveEntry;
  final int _uploadAutoRetries;
  final void Function(int completed, int total)? _onUploadPrepProgress;
  final void Function()? _onUploadPrepProgressClear;

  Future<
    ({
      ReportOutboxEntry entry,
      List<String> uploadTemps,
      int compressionFallbackCount,
      int skippedPhotoCount,
    })
  >
  run(ReportOutboxEntry e) async {
    if (e.draft.photos.isEmpty) {
      final ReportOutboxEntry next = e.copyWith(
        state: ReportOutboxState.submitting,
        clearMediaUrls: true,
      );
      await _repo.update(next);
      return (
        entry: next,
        uploadTemps: <String>[],
        compressionFallbackCount: 0,
        skippedPhotoCount: 0,
      );
    }
    if (e.mediaUrls != null && e.mediaUrls!.isNotEmpty) {
      final ReportOutboxEntry next = e.copyWith(
        state: ReportOutboxState.submitting,
      );
      await _repo.update(next);
      return (
        entry: next,
        uploadTemps: <String>[],
        compressionFallbackCount: 0,
        skippedPhotoCount: 0,
      );
    }

    ReportOutboxEntry cur = e.copyWith(state: ReportOutboxState.uploading);
    await _repo.update(cur);

    final ReportPhotoPrepResult prep;
    try {
      prep = await prepareReportPhotoPathsForUpload(
        cur.draft.photos,
        onPrepProgress: _onUploadPrepProgress,
      );
    } finally {
      _onUploadPrepProgressClear?.call();
    }
    final List<String> prepared = prep.paths;
    // All photo sources vanished (e.g. orphaned by a prior failed compress
    // rename). Submit text-only and surface the skip count to the UI rather
    // than failing the whole submit with "No readable photo files to upload".
    if (prepared.isEmpty && prep.missingSourceCount > 0) {
      cur = cur.copyWith(
        state: ReportOutboxState.submitting,
        mediaUrls: const <String>[],
        clearLastError: true,
      );
      await _repo.update(cur);
      chistoReportsBreadcrumb(
        'report_outbox',
        'upload_skipped_all_missing',
        data: <String, Object?>{'missing': prep.missingSourceCount},
      );
      return (
        entry: cur,
        uploadTemps: prepared,
        compressionFallbackCount: prep.compressionFallbackCount,
        skippedPhotoCount: prep.missingSourceCount,
      );
    }
    try {
      int uploadTry = 0;
      while (true) {
        uploadTry++;
        try {
          final ReportPhotoUploadOutcome upload = await _api.uploadPhotos(
            prepared,
          );
          cur = cur.copyWith(
            state: ReportOutboxState.submitting,
            mediaUrls: upload.urls,
            clearLastError: true,
          );
          await _repo.update(cur);
          chistoReportsBreadcrumb(
            'report_outbox',
            'upload_ok',
            data: <String, Object?>{
              'n': upload.urls.length,
              'skipped': upload.skippedPhotoCount + prep.missingSourceCount,
              'compressionFallbacks': prep.compressionFallbackCount,
            },
          );
          return (
            entry: cur,
            uploadTemps: prepared,
            compressionFallbackCount: prep.compressionFallbackCount,
            skippedPhotoCount:
                upload.skippedPhotoCount + prep.missingSourceCount,
          );
        } on AppError catch (err) {
          chistoSubmitDebugLog(
            'upload AppError code=${err.code} retryable=${err.retryable} '
            'msg=${err.message}',
            error: err,
          );
          if (uploadTry >= _uploadAutoRetries ||
              classifyReportSubmitError(err) ==
                  ReportOutboxErrorKind.terminal) {
            final ReportOutboxEntry failed = cur.copyWith(
              state: ReportOutboxState.failed,
              lastErrorCode: err.code,
              lastErrorMessage: '',
            );
            await _repo.update(failed);
            deleteReportUploadTempFiles(prepared);
            _emitActiveEntry(failed);
            return (
              entry: failed,
              uploadTemps: prepared,
              compressionFallbackCount: prep.compressionFallbackCount,
              skippedPhotoCount: 0,
            );
          }
          await Future<void>.delayed(
            Duration(milliseconds: backoffMsForAttempt(uploadTry)),
          );
        }
      }
    } catch (err, st) {
      chistoSubmitDebugLog(
        'upload phase non-AppError type=${err.runtimeType}',
        error: err,
        stack: st,
      );
      AppLog.error(
        'report upload phase failed (non-AppError): '
        'type=${err.runtimeType} message=$err',
        error: err,
        stackTrace: st,
        category: 'reports_outbox',
      );
      final ReportOutboxEntry failed = cur.copyWith(
        state: ReportOutboxState.failed,
        lastErrorCode: 'UPLOAD_ERROR',
        lastErrorMessage: '',
      );
      await _repo.update(failed);
      deleteReportUploadTempFiles(prepared);
      _emitActiveEntry(failed);
      return (
        entry: failed,
        uploadTemps: prepared,
        compressionFallbackCount: prep.compressionFallbackCount,
        skippedPhotoCount: 0,
      );
    }
  }
}
