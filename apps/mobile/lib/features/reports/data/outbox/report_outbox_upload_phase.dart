import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_error_classifier.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';
import 'package:chisto_mobile/features/reports/data/report_photo_upload_prep.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';

/// Photo upload loop for the outbox (pending/uploading → submitting or failed).
class ReportOutboxUploadPhase {
  ReportOutboxUploadPhase({
    required ReportOutboxRepository repository,
    required ReportsApiRepository reportsApi,
    required void Function(ReportOutboxEntry? entry) emitActiveEntry,
    required int uploadAutoRetries,
    void Function(int completed, int total)? onUploadPrepProgress,
    void Function()? onUploadPrepProgressClear,
  })  : _repo = repository,
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

  Future<({ReportOutboxEntry entry, List<String> uploadTemps})> run(
    ReportOutboxEntry e,
  ) async {
    if (e.draft.photos.isEmpty) {
      final ReportOutboxEntry next = e.copyWith(
        state: ReportOutboxState.submitting,
        clearMediaUrls: true,
      );
      await _repo.update(next);
      return (entry: next, uploadTemps: <String>[]);
    }
    if (e.mediaUrls != null && e.mediaUrls!.isNotEmpty) {
      final ReportOutboxEntry next = e.copyWith(state: ReportOutboxState.submitting);
      await _repo.update(next);
      return (entry: next, uploadTemps: <String>[]);
    }

    ReportOutboxEntry cur = e.copyWith(state: ReportOutboxState.uploading);
    await _repo.update(cur);

    final List<String> prepared;
    try {
      prepared = await prepareReportPhotoPathsForUpload(
        cur.draft.photos,
        onPrepProgress: _onUploadPrepProgress,
      );
    } finally {
      _onUploadPrepProgressClear?.call();
    }
    try {
      int uploadTry = 0;
      while (true) {
        uploadTry++;
        try {
          final List<String> urls = await _api.uploadPhotos(prepared);
          cur = cur.copyWith(
            state: ReportOutboxState.submitting,
            mediaUrls: urls,
            clearLastError: true,
          );
          await _repo.update(cur);
          chistoReportsBreadcrumb(
            'report_outbox',
            'upload_ok',
            data: <String, Object?>{'n': urls.length},
          );
          return (entry: cur, uploadTemps: prepared);
        } on AppError catch (err) {
          if (uploadTry >= _uploadAutoRetries ||
              classifyReportSubmitError(err) == ReportOutboxErrorKind.terminal) {
            final ReportOutboxEntry failed = cur.copyWith(
              state: ReportOutboxState.failed,
              lastErrorCode: err.code,
              lastErrorMessage: err.message,
            );
            await _repo.update(failed);
            deleteReportUploadTempFiles(prepared);
            _emitActiveEntry(failed);
            return (entry: failed, uploadTemps: prepared);
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
      return (entry: failed, uploadTemps: prepared);
    }
  }
}
