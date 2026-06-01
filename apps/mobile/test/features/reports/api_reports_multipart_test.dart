import 'dart:io';

import 'package:feature_reports/src/data/api_reports_multipart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reportMultipartPartsForLocalPaths skips missing and oversized files',
    () {
      final Directory dir = Directory.systemTemp.createTempSync(
        'multipart_test_',
      );
      try {
        final File ok = File('${dir.path}/ok.jpg')
          ..writeAsBytesSync(<int>[1, 2, 3]);
        final File missing = File('${dir.path}/gone.jpg');
        final File huge = File('${dir.path}/huge.jpg')
          ..writeAsBytesSync(List<int>.filled(12 * 1024 * 1024 + 1, 1));

        final result = reportMultipartPartsForLocalPaths(<String>[
          ok.path,
          missing.path,
          huge.path,
        ]);

        expect(result.parts, hasLength(1));
        expect(result.skippedMissingCount, 1);
        expect(result.skippedOversizedCount, 1);
        expect(result.skippedCount, 2);
      } finally {
        dir.deleteSync(recursive: true);
      }
    },
  );
}
