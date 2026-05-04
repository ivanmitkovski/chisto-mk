import 'dart:io';

import 'package:chisto_mobile/features/reports/data/outbox/report_draft_photo_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('importPhoto copies via tmp then rename; absolutePath resolves', () async {
    final Directory root = await Directory.systemTemp.createTemp('report_draft_photo_');
    try {
      final ReportDraftPhotoStore store = ReportDraftPhotoStore(rootOverride: root);
      final File src = File('${root.path}/source.jpg');
      await src.writeAsBytes(<int>[1, 2, 3, 4]);

      final String rel = await store.importPhoto(XFile(src.path));
      expect(rel.startsWith('${ReportDraftPhotoStore.relativeRoot}/'), isTrue);

      final String abs = await store.absolutePath(rel);
      expect(await File(abs).exists(), isTrue);
      expect(await File(abs).length(), 4);

      await store.deletePhoto(rel);
      expect(await File(abs).exists(), isFalse);
    } finally {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    }
  });
}
