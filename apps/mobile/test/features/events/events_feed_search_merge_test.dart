import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_feed_search_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mergedForChip leaves sheet unchanged for all, nearby, myEvents', () {
    const EcoEventSearchParams sheet = EcoEventSearchParams(
      categories: <EcoEventCategory>{EcoEventCategory.riverAndLake},
      statuses: <EcoEventStatus>{EcoEventStatus.inProgress},
    );
    expect(
      EventsFeedSearchMerge.mergedForChip(sheet, EcoEventFilter.all),
      sheet,
    );
    expect(
      EventsFeedSearchMerge.mergedForChip(sheet, EcoEventFilter.nearby),
      sheet,
    );
    expect(
      EventsFeedSearchMerge.mergedForChip(sheet, EcoEventFilter.myEvents),
      sheet,
    );
  });

  test('mergedForChip upcoming overrides sheet lifecycle', () {
    const EcoEventSearchParams sheet = EcoEventSearchParams(
      statuses: <EcoEventStatus>{EcoEventStatus.completed},
    );
    final EcoEventSearchParams merged =
        EventsFeedSearchMerge.mergedForChip(sheet, EcoEventFilter.upcoming);
    expect(merged.statuses, <EcoEventStatus>{EcoEventStatus.upcoming});
    expect(merged.categories, isEmpty);
  });

  test('mergedForChip past sets completed and cancelled', () {
    const EcoEventSearchParams sheet = EcoEventSearchParams();
    final EcoEventSearchParams merged =
        EventsFeedSearchMerge.mergedForChip(sheet, EcoEventFilter.past);
    expect(
      merged.statuses,
      <EcoEventStatus>{
        EcoEventStatus.completed,
        EcoEventStatus.cancelled,
      },
    );
  });
}
