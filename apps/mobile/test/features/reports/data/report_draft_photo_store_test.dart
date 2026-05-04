import 'dart:io';

import 'package:chisto_mobile/features/reports/data/outbox/report_draft_photo_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

void main() {
  test('importPhoto deletePhoto prune clearAll', () async {
    final Directory root = await Directory.systemTemp.createTemp('draft_photo_');
    final ReportDraftPhotoStore store = ReportDraftPhotoStore(
      rootOverride: Directory(p.join(root.path, 'managed')),
    );

    final File src = File(p.join(root.path, 'src.jpg'));
    await src.writeAsBytes(<int>[1, 2, 3, 4]);

    final String rel = await store.importPhoto(XFile(src.path));
    expect(rel.startsWith(ReportDraftPhotoStore.relativeRoot), isTrue);

    final String abs = await store.absolutePath(rel);
    expect(await File(abs).exists(), isTrue);
    expect(await store.isManagedPath(abs), isTrue);

    final List<String> kept = await store.prune(<String>[rel, 'missing.jpg']);
    expect(kept, <String>[rel]);

    await store.deletePhoto(rel);
    expect(await File(abs).exists(), isFalse);

    final String rel2 = await store.importPhoto(XFile(src.path));
    await store.clearAll();
    expect(await File(await store.absolutePath(rel2)).exists(), isFalse);

    await root.delete(recursive: true);
  });
}
