import 'dart:io';

import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/serialization/safe_json.dart';
import 'package:feature_reports/src/data/report_multipart_parts_result.dart';

/// Client timeout for report image multipart uploads.
const Duration kReportMediaUploadTimeout = Duration(seconds: 90);

/// Matches API upload validation: magic bytes are authoritative; `application/octet-stream` is allowed.
String reportMimeTypeForUploadPath(String p) {
  final String lower = p.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return 'application/octet-stream';
}

String reportUploadFileNameForPath(String path, int index) {
  final String lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'report_$index.png';
  if (lower.endsWith('.webp')) return 'report_$index.webp';
  return 'report_$index.jpg';
}

ReportMultipartPartsResult reportMultipartPartsForLocalPaths(
  List<String> filePaths,
) {
  final List<MultipartFileData> parts = <MultipartFileData>[];
  int index = 0;
  int skippedMissing = 0;
  int skippedOversized = 0;
  for (final String path in filePaths) {
    final File f = File(path);
    if (!f.existsSync()) {
      skippedMissing++;
      continue;
    }
    const int maxBytes = 12 * 1024 * 1024;
    final int fileLen = f.lengthSync();
    if (fileLen <= 0) {
      skippedMissing++;
      continue;
    }
    if (fileLen > maxBytes) {
      skippedOversized++;
      continue;
    }
    final List<int> bytes = f.readAsBytesSync();
    if (bytes.isEmpty) {
      skippedMissing++;
      continue;
    }
    parts.add(
      MultipartFileData(
        field: 'files',
        bytes: bytes,
        fileName: reportUploadFileNameForPath(path, index),
        mimeType: reportMimeTypeForUploadPath(path),
      ),
    );
    index++;
  }
  return ReportMultipartPartsResult(
    parts: parts,
    skippedMissingCount: skippedMissing,
    skippedOversizedCount: skippedOversized,
  );
}

List<String> urlsFromReportsUploadResponse(Map<String, dynamic> json) {
  Map<String, dynamic> map = json;
  final Object? data = json['data'];
  if (data is Map<String, dynamic> && data['urls'] != null) {
    map = data;
  }
  final List<dynamic> urls = safeAsList(map['urls']) ?? <dynamic>[];
  return urls
      .whereType<String>()
      .map<String>((String u) => u.trim())
      .where((String u) => u.isNotEmpty)
      .toList();
}
