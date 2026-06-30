import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_sections.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_timeline_rows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'buildSiteHistoryTimelineRows interleaves section headers and entries',
    () {
      final DateTime now = DateTime(2026, 5, 20, 14);
      final List<SiteHistoryEntry> items = <SiteHistoryEntry>[
        SiteHistoryEntry(
          id: '1',
          kind: SiteHistoryEntryKind.siteCreated,
          occurredAt: now,
        ),
        SiteHistoryEntry(
          id: '2',
          kind: SiteHistoryEntryKind.reportSubmitted,
          occurredAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final List<SiteHistoryTimelineRow> rows = buildSiteHistoryTimelineRows(
        items: items,
        now: now,
        sectionLabelFor: (SiteHistorySection section) => section.bucket.name,
      );

      expect(rows, hasLength(4));
      expect(rows[0].kind, SiteHistoryTimelineRowKind.sectionHeader);
      expect(rows[1].kind, SiteHistoryTimelineRowKind.entry);
      expect(rows[2].kind, SiteHistoryTimelineRowKind.sectionHeader);
      expect(rows[3].kind, SiteHistoryTimelineRowKind.entry);
      expect(rows.first.showLineAbove, isFalse);
      expect(rows.last.showLineBelow, isFalse);
      expect(rows[1].showLineAbove, isTrue);
      expect(rows[1].showLineBelow, isTrue);
    },
  );
}
