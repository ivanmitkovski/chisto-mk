import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Substring in temp paths produced by [prepareReportPhotoPathsForUpload]; used to delete temps after upload.
const String kReportUploadTempMarker = 'chisto_report_upload_';

/// Converts each picker file to a JPEG under the app temp directory when possible.
///
/// iOS (and some Android) cameras return HEIC/HEIF; the API only accepts jpeg, png,
/// and webp after magic-byte verification. Compression normalizes to JPEG.
Future<List<String>> prepareReportPhotoPathsForUpload(
  List<XFile> photos,
) async {
  if (photos.isEmpty) return <String>[];
  final Directory tempDir = await getTemporaryDirectory();
  final int ts = DateTime.now().millisecondsSinceEpoch;
  final List<String> out = <String>[];
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
          continue;
        }
      }
    } catch (_) {
      // Fall through to original path
    }
    out.add(inPath);
  }
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
