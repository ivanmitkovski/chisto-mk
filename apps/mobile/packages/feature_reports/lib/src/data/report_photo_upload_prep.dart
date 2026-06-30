import 'dart:io';

import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:feature_reports/src/data/report_photo_prep_result.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

export 'package:feature_reports/src/data/report_photo_prep_result.dart';

/// Substring in temp paths produced by [prepareReportPhotoPathsForUpload]; used to delete temps after upload.
const String kReportUploadTempMarker = 'chisto_report_upload_';

/// Best-effort in-place JPEG recompression for a managed draft photo path.
///
/// **Atomicity:** the compressed bytes are written to a *sibling* path in the
/// same directory as [absolutePath] and renamed over the original (a POSIX
/// atomic replace). If rename fails (e.g. transient FS error), we fall back to
/// `bytes copy + temp delete`. The original is **never** removed before the
/// replacement is in place, so a failure cannot orphan the wizard photo.
///
/// A previous implementation deleted the original first and then `rename`d the
/// compressed temp from `getTemporaryDirectory()` into the managed folder,
/// which fails with `FileSystemException: Cannot copy ... cross-device link`
/// on devices that mount the cache and documents dirs on different volumes —
/// leaving the wizard pointing at a deleted file and surfacing as
/// "No readable photo files to upload." on submit.
Future<void> compressManagedReportDraftPhotoInPlace(String absolutePath) async {
  final File inFile = File(absolutePath);
  if (!inFile.existsSync()) {
    return;
  }
  final Directory parent = inFile.parent;
  final String siblingPath = p.join(
    parent.path,
    '.${kReportUploadTempMarker}draft_eager_'
    '${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  try {
    final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
      absolutePath,
      siblingPath,
      quality: 85,
      minWidth: 2048,
      minHeight: 2048,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) {
      return;
    }
    final File outFile = File(compressed.path);
    if (!outFile.existsSync()) {
      return;
    }
    final int len = await outFile.length();
    if (len <= 0) {
      _bestEffortDelete(outFile);
      return;
    }
    try {
      await outFile.rename(absolutePath);
      return;
    } on Object catch (e, st) {
      AppLog.warn(
        'report_photo_prep: rename compressed file failed; '
        'falling back to byte copy',
        error: e,
        stackTrace: st,
      );
    }
    try {
      final IOSink sink = inFile.openWrite(mode: FileMode.write);
      try {
        await outFile.openRead().pipe(sink);
        await sink.flush();
      } finally {
        await sink.close();
      }
    } on Object catch (e, st) {
      AppLog.warn(
        'report_photo_prep: byte-copy fallback failed; original preserved',
        error: e,
        stackTrace: st,
      );
    } finally {
      _bestEffortDelete(outFile);
    }
  } catch (_) {
    // Keep original bytes on failure; clean up the sibling if it leaked.
    _bestEffortDelete(File(siblingPath));
  }
}

void _bestEffortDelete(File f) {
  try {
    if (f.existsSync()) {
      f.deleteSync();
    }
  } on Object {
    // Ignored — best-effort cleanup.
  }
}

/// Converts each picker file to a JPEG under the app temp directory when possible.
///
/// iOS (and some Android) cameras return HEIC/HEIF; the API only accepts jpeg, png,
/// and webp after magic-byte verification. Compression normalizes to JPEG.
///
/// [onPrepProgress] is invoked after each photo is prepared as `(completed, total)`.
Future<ReportPhotoPrepResult> prepareReportPhotoPathsForUpload(
  List<XFile> photos, {
  void Function(int completed, int total)? onPrepProgress,
}) async {
  if (photos.isEmpty) {
    return const ReportPhotoPrepResult(paths: <String>[]);
  }
  final Stopwatch prepWatch = Stopwatch()..start();
  final Directory tempDir = await getTemporaryDirectory();
  final int ts = DateTime.now().millisecondsSinceEpoch;
  final List<String> out = <String>[];
  int compressionFallbackCount = 0;
  int missingSourceCount = 0;
  final int total = photos.length;
  int index = 0;
  for (final XFile x in photos) {
    final String inPath = File(x.path).absolute.path;
    final File inFile = File(inPath);
    if (!inFile.existsSync() || inFile.lengthSync() <= 0) {
      missingSourceCount++;
      AppLog.warn(
        'report_photo_prep: source photo missing/empty; dropping from upload',
        category: 'reports_outbox',
      );
      chistoReportsBreadcrumb(
        'report_outbox',
        'photo_prep_source_missing',
        data: <String, Object?>{'pathLen': inPath.length},
      );
      onPrepProgress?.call(out.length, total);
      index++;
      continue;
    }
    final String targetPath =
        '${tempDir.path}/$kReportUploadTempMarker${ts}_$index.jpg';
    index++;
    var usedFallback = false;
    try {
      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        inPath,
        targetPath,
        quality: 85,
        minWidth: 2048,
        minHeight: 2048,
        format: CompressFormat.jpeg,
      );
      if (compressed != null) {
        final File f = File(compressed.path);
        if (f.existsSync() && f.lengthSync() > 0) {
          out.add(f.path);
          onPrepProgress?.call(out.length, total);
          continue;
        }
      }
      usedFallback = true;
    } catch (_) {
      usedFallback = true;
    }
    if (usedFallback) {
      compressionFallbackCount++;
      chistoReportsBreadcrumb(
        'report_outbox',
        'photo_prep_compression_fallback',
        data: <String, Object?>{
          'pathKind': inPath.contains('.') ? 'file' : 'unknown',
        },
      );
    }
    out.add(inPath);
    onPrepProgress?.call(out.length, total);
  }
  prepWatch.stop();
  chistoReportsBreadcrumb(
    'report_outbox',
    'photo_prep_batch',
    data: <String, Object?>{
      'count': total,
      'compressionFallbacks': compressionFallbackCount,
      'elapsedMs': prepWatch.elapsedMilliseconds,
    },
  );
  return ReportPhotoPrepResult(
    paths: out,
    compressionFallbackCount: compressionFallbackCount,
    missingSourceCount: missingSourceCount,
  );
}

/// Best-effort removal of JPEG temps created by [prepareReportPhotoPathsForUpload].
void deleteReportUploadTempFiles(List<String> paths) {
  for (final String p in paths) {
    if (!p.contains(kReportUploadTempMarker)) continue;
    try {
      final File f = File(p);
      if (f.existsSync()) {
        f.deleteSync();
      }
    } on Object catch (e, st) {
      AppLog.warn(
        'report_photo_prep: delete upload temp failed',
        error: e,
        stackTrace: st,
      );
    }
  }
}
