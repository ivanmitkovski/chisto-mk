import 'dart:convert';
import 'dart:io';

import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_constants.dart';
import 'package:chisto_mobile/features/reports/data/report_photo_upload_prep.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/widget_test_bootstrap.dart';

/// 1×1 baseline JPEG (valid magic bytes) for prep smoke tests.
const String _kTinyJpegBase64 =
    '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAGfAP/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQIAAQU/AP/EABQRAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQMBAT8B/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPwB//9k=';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('prepareReportPhotoPathsForUpload stays within soft budget for tiny JPEG', () async {
    final Directory tmp = await Directory.systemTemp.createTemp('prep_smoke_');
    try {
      final File f = File('${tmp.path}/tiny.jpg');
      await f.writeAsBytes(base64Decode(_kTinyJpegBase64));
      final Stopwatch sw = Stopwatch()..start();
      final List<String> paths = await prepareReportPhotoPathsForUpload(
        <XFile>[XFile(f.path)],
      );
      sw.stop();
      expect(paths, isNotEmpty);
      deleteReportUploadTempFiles(paths);
      expect(
        sw.elapsed,
        lessThan(kReportUploadPrepBudgetPerPhotoSoft),
        reason: 'elapsed=${sw.elapsed.inMilliseconds}ms',
      );
    } finally {
      await tmp.delete(recursive: true);
    }
  });
}
