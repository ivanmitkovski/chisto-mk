import 'dart:io';
import 'dart:typed_data';

import 'package:feature_reports/src/data/report_upload_image_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('detectReportUploadImageKind', () {
    test('detects JPEG', () {
      expect(
        detectReportUploadImageKind(
          Uint8List.fromList(<int>[0xff, 0xd8, 0xff, 0xdb]),
        ),
        ReportUploadImageKind.jpeg,
      );
    });

    test('detects PNG', () {
      expect(
        detectReportUploadImageKind(
          Uint8List.fromList(<int>[
            0x89,
            0x50,
            0x4e,
            0x47,
            0x0d,
            0x0a,
            0x1a,
            0x0a,
          ]),
        ),
        ReportUploadImageKind.png,
      );
    });

    test('detects WebP', () {
      final Uint8List bytes = Uint8List(12);
      bytes.setAll(0, <int>[0x52, 0x49, 0x46, 0x46]);
      bytes.setAll(8, <int>[0x57, 0x45, 0x42, 0x50]);
      expect(detectReportUploadImageKind(bytes), ReportUploadImageKind.webp);
    });

    test('detects HEIC ftyp brand', () {
      final Uint8List bytes = Uint8List(12);
      bytes.setAll(4, <int>[0x66, 0x74, 0x79, 0x70]); // ftyp
      bytes.setAll(8, <int>[0x68, 0x65, 0x69, 0x63]); // heic
      expect(detectReportUploadImageKind(bytes), ReportUploadImageKind.heic);
    });

    test('rejects GIF even when extension is .jpg', () {
      expect(
        detectReportUploadImageKind(
          Uint8List.fromList(<int>[
            0x47,
            0x49,
            0x46,
            0x38,
            0x39,
            0x61,
          ]),
        ),
        ReportUploadImageKind.unsupported,
      );
    });
  });

  group('validateReportUploadImage', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('report_upload_image_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<XFile> writeBytes(String name, List<int> bytes) async {
      final File file = File('${tempDir.path}/$name');
      await file.writeAsBytes(bytes);
      return XFile(file.path);
    }

    test('accepts JPEG file', () async {
      final XFile file = await writeBytes(
        'photo.jpg',
        <int>[0xff, 0xd8, 0xff, 0xdb, 0x00],
      );
      final ReportUploadImageValidation validation =
          await validateReportUploadImage(file);
      expect(validation.isSupported, isTrue);
    });

    test('rejects GIF file', () async {
      final XFile file = await writeBytes(
        'photo.gif',
        <int>[0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00],
      );
      final ReportUploadImageValidation validation =
          await validateReportUploadImage(file);
      expect(validation.isSupported, isFalse);
      expect(validation.rejection, ReportUploadImageRejection.unsupportedFormat);
    });

    test('partitionReportUploadImages counts unsupported picks', () async {
      final XFile jpeg = await writeBytes(
        'ok.jpg',
        <int>[0xff, 0xd8, 0xff, 0xdb],
      );
      final XFile gif = await writeBytes(
        'bad.gif',
        <int>[0x47, 0x49, 0x46, 0x38, 0x39, 0x61],
      );
      final ({List<XFile> supported, int unsupportedCount}) partitioned =
          await partitionReportUploadImages(<XFile>[jpeg, gif]);
      expect(partitioned.supported, <XFile>[jpeg]);
      expect(partitioned.unsupportedCount, 1);
    });
  });
}
