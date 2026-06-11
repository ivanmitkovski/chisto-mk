import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/eco_event_filter.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';
import 'package:feature_events/src/presentation/widgets/events_feed/events_filter_preview_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_events_repository.dart';

void main() {
  test('debounces preview fetch and caches identical draft', () async {
    final RecordingEventsRepository repository = RecordingEventsRepository();
    final EventsFilterPreviewController controller =
        EventsFilterPreviewController(
          repository: repository,
          activeChip: EcoEventFilter.all,
          initialDraft: const EcoEventSearchParams(),
          debounce: const Duration(milliseconds: 50),
        );

    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(repository.fetchEventsSnapshotCallCount, 1);

    controller.updateDraft(
      const EcoEventSearchParams(
        statuses: <EcoEventStatus>{EcoEventStatus.upcoming},
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repository.fetchEventsSnapshotCallCount, 1);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(repository.fetchEventsSnapshotCallCount, 2);

    controller.updateDraft(
      const EcoEventSearchParams(
        statuses: <EcoEventStatus>{EcoEventStatus.upcoming},
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(repository.fetchEventsSnapshotCallCount, 2);

    controller.dispose();
  });
}
