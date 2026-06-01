import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/providers/site_history_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dedupeSiteHistoryItemsForTesting keeps first occurrence by id', () {
    final DateTime at = DateTime.utc(2026, 6, 1);
    final SiteHistoryEntry first = SiteHistoryEntry(
      id: 'entry-1',
      kind: SiteHistoryEntryKind.reportSubmitted,
      occurredAt: at,
    );
    final SiteHistoryEntry duplicate = SiteHistoryEntry(
      id: 'entry-1',
      kind: SiteHistoryEntryKind.reportSubmitted,
      occurredAt: at,
      note: 'duplicate',
    );
    final SiteHistoryEntry second = SiteHistoryEntry(
      id: 'entry-2',
      kind: SiteHistoryEntryKind.siteCreated,
      occurredAt: at,
    );

    expect(
      dedupeSiteHistoryItemsForTesting(<SiteHistoryEntry>[
        first,
        duplicate,
        second,
      ]),
      <SiteHistoryEntry>[first, second],
    );
  });
}
