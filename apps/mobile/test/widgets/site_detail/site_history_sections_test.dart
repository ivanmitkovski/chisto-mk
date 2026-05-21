import 'package:chisto_mobile/features/home/domain/models/site_history_entry.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_sections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 5, 20, 18, 0);

  SiteHistoryEntry entryAt(DateTime at, {String id = 'e'}) {
    return SiteHistoryEntry(
      id: id,
      kind: SiteHistoryEntryKind.siteCreated,
      occurredAt: at,
    );
  }

  test('groupSiteHistoryByBucket splits today, yesterday, this week, month', () {
    final List<SiteHistoryEntry> items = <SiteHistoryEntry>[
      entryAt(DateTime(2026, 5, 20, 10), id: 'today'),
      entryAt(DateTime(2026, 5, 19, 10), id: 'yesterday'),
      entryAt(DateTime(2026, 5, 18, 10), id: 'week'),
      entryAt(DateTime(2026, 4, 2, 10), id: 'april'),
    ];

    final List<SiteHistorySection> sections =
        groupSiteHistoryByBucket(items, now);

    expect(sections, hasLength(4));
    expect(sections[0].bucket, SiteHistorySectionBucket.today);
    expect(sections[0].entries.single.id, 'today');
    expect(sections[1].bucket, SiteHistorySectionBucket.yesterday);
    expect(sections[2].bucket, SiteHistorySectionBucket.thisWeek);
    expect(sections[3].bucket, SiteHistorySectionBucket.earlierMonth);
    expect(sections[3].anchorDate, DateTime(2026, 4));
  });

  test('groupSiteHistoryByBucket treats future occurredAt as now', () {
    final List<SiteHistorySection> sections = groupSiteHistoryByBucket(
      <SiteHistoryEntry>[
        entryAt(DateTime(2027, 1, 1)),
      ],
      now,
    );
    expect(sections.single.bucket, SiteHistorySectionBucket.today);
  });
}
