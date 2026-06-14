import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Why a picked file cannot be used as report/event evidence.
enum ReportUploadImageRejection {
  missingOrEmpty,
  unsupportedFormat,
}

/// Result of validating a local image before preview, draft import, or upload prep.
class ReportUploadImageValidation {
  const ReportUploadImageValidation._({
    required this.isSupported,
    this.rejection,
  });

  const ReportUploadImageValidation.supported()
    : this._(isSupported: true);

  const ReportUploadImageValidation.rejected(ReportUploadImageRejection reason)
    : this._(isSupported: false, rejection: reason);

  final bool isSupported;
  final ReportUploadImageRejection? rejection;
}

/// Thrown when [registerPhoto] receives a file that fails validation.
class UnsupportedReportUploadImageException implements Exception {
  UnsupportedReportUploadImageException(this.rejection);

  final ReportUploadImageRejection rejection;

  @override
  String toString() =>
      'UnsupportedReportUploadImageException(rejection: $rejection)';
}

/// Matches API magic-byte allowlist in `detect-allowed-image-mime-from-buffer.ts`,
/// plus HEIC/HEIF which we normalize to JPEG before upload.
enum ReportUploadImageKind {
  jpeg,
  png,
  webp,
  heic,
  unsupported,
}

/// Detects supported upload kinds from the first bytes of [bytes] only.
ReportUploadImageKind detectReportUploadImageKind(Uint8List bytes) {
  if (bytes.length < 3) {
    return ReportUploadImageKind.unsupported;
  }
  // JPEG: FF D8 FF
  if (bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) {
    return ReportUploadImageKind.jpeg;
  }
  // PNG: 89 50 4E 47 0D 0A 1A 0A
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return ReportUploadImageKind.png;
  }
  // WebP: RIFF....WEBP
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return ReportUploadImageKind.webp;
  }
  // HEIC/HEIF (ISO BMFF): ....ftypheic|heix|hevc|mif1
  if (bytes.length >= 12 &&
      bytes[4] == 0x66 &&
      bytes[5] == 0x74 &&
      bytes[6] == 0x79 &&
      bytes[7] == 0x70) {
    final String brand = String.fromCharCodes(bytes.sublist(8, 12));
    switch (brand) {
      case 'heic':
      case 'heix':
      case 'hevc':
      case 'hevx':
      case 'mif1':
      case 'msf1':
        return ReportUploadImageKind.heic;
    }
  }
  return ReportUploadImageKind.unsupported;
}

bool isSupportedReportUploadImageKind(ReportUploadImageKind kind) =>
    kind != ReportUploadImageKind.unsupported;

/// Reads up to 16 bytes and validates using magic bytes (authoritative).
Future<ReportUploadImageValidation> validateReportUploadImage(XFile file) async {
  final File local = File(file.path);
  if (!local.existsSync()) {
    return const ReportUploadImageValidation.rejected(
      ReportUploadImageRejection.missingOrEmpty,
    );
  }
  final int length = local.lengthSync();
  if (length <= 0) {
    return const ReportUploadImageValidation.rejected(
      ReportUploadImageRejection.missingOrEmpty,
    );
  }

  final int readLen = min(16, length);
  final RandomAccessFile handle = await local.open();
  late final Uint8List header;
  try {
    header = await handle.read(readLen);
  } finally {
    await handle.close();
  }

  final ReportUploadImageKind kind = detectReportUploadImageKind(header);
  if (isSupportedReportUploadImageKind(kind)) {
    return const ReportUploadImageValidation.supported();
  }

  final String? mime = file.mimeType?.trim().toLowerCase();
  if (mime == 'image/heic' || mime == 'image/heif') {
    return const ReportUploadImageValidation.supported();
  }

  return const ReportUploadImageValidation.rejected(
    ReportUploadImageRejection.unsupportedFormat,
  );
}

/// Splits a multi-pick result into supported files and a rejection count.
Future<({List<XFile> supported, int unsupportedCount})>
partitionReportUploadImages(List<XFile> files) async {
  if (files.isEmpty) {
    return (supported: <XFile>[], unsupportedCount: 0);
  }
  final List<XFile> supported = <XFile>[];
  var unsupportedCount = 0;
  for (final XFile file in files) {
    final ReportUploadImageValidation validation =
        await validateReportUploadImage(file);
    if (validation.isSupported) {
      supported.add(file);
    } else {
      unsupportedCount++;
    }
  }
  return (supported: supported, unsupportedCount: unsupportedCount);
}
