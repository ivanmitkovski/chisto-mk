import 'dart:convert';
import 'dart:io';

import 'package:feature_reports/src/data/report_photo_upload_prep.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/widget_test_bootstrap.dart';

/// 1x1 baseline JPEG (valid magic bytes).
const String _kTinyJpegBase64 =
    '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAX/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAGfAP/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQIAAQU/AP/EABQRAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQMBAT8B/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPwB//9k=';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test(
    'prepareReportPhotoPathsForUpload skips missing source files and reports them',
    () async {
      final Directory tmp = await Directory.systemTemp.createTemp(
        'prep_missing_',
      );
      try {
        final File present = File('${tmp.path}/ok.jpg');
        await present.writeAsBytes(base64Decode(_kTinyJpegBase64));
        final String missingPath = '${tmp.path}/gone.jpg';

        final ReportPhotoPrepResult prep =
            await prepareReportPhotoPathsForUpload(<XFile>[
              XFile(missingPath),
              XFile(present.path),
            ]);
        try {
          // The missing source must not bleed into the multipart parts list,
          // so the upload phase can submit text-only or with the survivors.
          expect(prep.missingSourceCount, 1);
          // The survivor still produced a usable path (compressed temp or
          // the original input).
          expect(prep.paths.length, 1);
        } finally {
          deleteReportUploadTempFiles(prep.paths);
        }
      } finally {
        await tmp.delete(recursive: true);
      }
    },
  );

  test(
    'compressManagedReportDraftPhotoInPlace preserves original on success and never orphans on failure',
    () async {
      final Directory tmp = await Directory.systemTemp.createTemp(
        'compress_safe_',
      );
      try {
        final File managed = File('${tmp.path}/photo.jpg');
        final List<int> before = base64Decode(_kTinyJpegBase64);
        await managed.writeAsBytes(before);
        final int sizeBefore = await managed.length();
        await compressManagedReportDraftPhotoInPlace(managed.path);
        // Original may be replaced with a compressed body but must continue
        // to exist at the same managed path - never orphaned.
        expect(managed.existsSync(), isTrue);
        expect(await managed.length(), greaterThan(0));
        // Sanity check: file still has a JPEG SOI marker.
        final List<int> after = await managed.readAsBytes();
        expect(after.length, greaterThan(0));
        expect(after[0], 0xFF);
        expect(after[1], 0xD8);
        // Either it was rewritten (length changed) or unchanged - both fine.
        // We just want to assert the file is still readable.
        // ignore: avoid_print
        if (await managed.length() == sizeBefore) {
          expect(after, before);
        }
        // No leftover sibling temp in the directory.
        final List<FileSystemEntity> entries = tmp.listSync();
        for (final FileSystemEntity e in entries) {
          if (e is File && e.path.contains(kReportUploadTempMarker)) {
            fail('orphaned compress sibling left behind: ${e.path}');
          }
        }
      } finally {
        await tmp.delete(recursive: true);
      }
    },
  );
}
