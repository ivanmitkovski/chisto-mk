import 'package:chisto_infrastructure/core/errors/app_error.dart';
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
              'skipped': upload.skippedPhotoCount,
              'compressionFallbacks': prep.compressionFallbackCount,
            },
          );
          return (
            entry: cur,
            uploadTemps: prepared,
            compressionFallbackCount: prep.compressionFallbackCount,
            skippedPhotoCount: upload.skippedPhotoCount,
          );
        } on AppError catch (err) {
          if (uploadTry >= _uploadAutoRetries ||
              classifyReportSubmitError(err) ==
                  ReportOutboxErrorKind.terminal) {
            final ReportOutboxEntry failed = cur.copyWith(
              state: ReportOutboxState.failed,
              lastErrorCode: err.code,
              lastErrorMessage: err.message,
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
    } catch (err) {
      final ReportOutboxEntry failed = cur.copyWith(
        state: ReportOutboxState.failed,
        lastErrorCode: 'UPLOAD_ERROR',
        lastErrorMessage: '$err',
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
