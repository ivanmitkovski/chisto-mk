import 'dart:convert';

import 'package:chisto_mobile/features/reports/data/outbox/report_draft_json_codec.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('ReportDraftJsonCodec', () {
    test('round-trip preserves relative photo paths and fields', () {
      const String rel = 'report_draft_media/test.jpg';
      final ReportDraft draft = ReportDraft(
        title: 'River',
        description: 'Oil',
        photos: <XFile>[XFile(rel)],
        category: ReportCategory.waterPollution,
        severity: 2,
        latitude: 41.99,
        longitude: 21.43,
        address: 'Skopje',
        cleanupEffort: CleanupEffort.oneToTwo,
      );
      final Map<String, dynamic> encoded = ReportDraftJsonCodec.encode(
        draft: draft,
        title: 'River',
        description: 'Oil',
      );
      expect(encoded['draftCodecVersion'], ReportDraftJsonCodec.kCodecVersion);
      expect(encoded['photos'], <String>[rel]);

      final ({ReportDraft draft, String title, String description}) decoded =
          ReportDraftJsonCodec.decode(json.encode(encoded));
      expect(decoded.title, 'River');
      expect(decoded.description, 'Oil');
      expect(decoded.draft.photos.single.path, rel);
      expect(decoded.draft.category, ReportCategory.waterPollution);
      expect(decoded.draft.severity, 2);
      expect(decoded.draft.latitude, 41.99);
      expect(decoded.draft.longitude, 21.43);
      expect(decoded.draft.address, 'Skopje');
      expect(decoded.draft.cleanupEffort, CleanupEffort.oneToTwo);
    });
  });
}
