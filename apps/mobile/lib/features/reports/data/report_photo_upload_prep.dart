import 'dart:io';

import 'package:chisto_mobile/core/observability/chisto_sentry.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Substring in temp paths produced by [prepareReportPhotoPathsForUpload]; used to delete temps after upload.
const String kReportUploadTempMarker = 'chisto_report_upload_';

/// Best-effort in-place JPEG recompression for a managed draft photo path.
Future<void> compressManagedReportDraftPhotoInPlace(String absolutePath) async {
  final File inFile = File(absolutePath);
  if (!await inFile.exists()) {
    return;
  }
  try {
    final Directory tempDir = await getTemporaryDirectory();
    final String targetPath =
        '${tempDir.path}/$kReportUploadTempMarker${DateTime.now().millisecondsSinceEpoch}_draft_eager.jpg';
    final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
      absolutePath,
      targetPath,
      quality: 85,
      minWidth: 2048,
      minHeight: 2048,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) {
      return;
    }
    final File outFile = File(compressed.path);
    if (!await outFile.exists()) {
      return;
    }
    final int len = await outFile.length();
    if (len <= 0) {
      return;
    }
    final List<int> bytes = await outFile.readAsBytes();
    try {
      await outFile.delete();
    } catch (_) {}
    await inFile.writeAsBytes(bytes, flush: true);
  } catch (_) {
    // Keep original bytes on failure.
  }
}

/// Converts each picker file to a JPEG under the app temp directory when possible.
///
/// iOS (and some Android) cameras return HEIC/HEIF; the API only accepts jpeg, png,
/// and webp after magic-byte verification. Compression normalizes to JPEG.
///
/// [onPrepProgress] is invoked after each photo is prepared as `(completed, total)`.
Future<List<String>> prepareReportPhotoPathsForUpload(
  List<XFile> photos, {
  void Function(int completed, int total)? onPrepProgress,
}) async {
  if (photos.isEmpty) return <String>[];
  final Stopwatch prepWatch = Stopwatch()..start();
  final Directory tempDir = await getTemporaryDirectory();
  final int ts = DateTime.now().millisecondsSinceEpoch;
  final List<String> out = <String>[];
  final int total = photos.length;
  int index = 0;
  for (final XFile x in photos) {
    final String inPath = File(x.path).absolute.path;
    final String targetPath =
        '${tempDir.path}/$kReportUploadTempMarker${ts}_$index.jpg';
    index++;
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
    } catch (_) {
      // Fall through to original path
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
      'elapsedMs': prepWatch.elapsedMilliseconds,
    },
  );
  return out;
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
    } catch (_) {}
  }
}
