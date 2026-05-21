import 'package:chisto_mobile/features/home/domain/models/site_history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('siteHistoryEntryKindFromApi maps API kinds', () {
    expect(
      siteHistoryEntryKindFromApi('STATUS_CHANGED'),
      SiteHistoryEntryKind.statusChanged,
    );
    expect(
      siteHistoryEntryKindFromApi('CLEANUP_EVENT_COMPLETED'),
      SiteHistoryEntryKind.cleanupEventCompleted,
    );
    expect(siteHistoryEntryKindFromApi('unknown'), SiteHistoryEntryKind.unknown);
  });
}
