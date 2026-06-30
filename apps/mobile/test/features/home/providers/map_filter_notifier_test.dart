import 'package:feature_home/src/presentation/providers/map_filter_notifier.dart';
import 'package:feature_home/src/presentation/widgets/map/map_status_codes.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggleStatus keeps at least one active', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final MapFilterNotifier notifier = container.read(
      mapFilterNotifierProvider.notifier,
    );
    notifier.toggleStatus(mapStatusReported);
    notifier.toggleStatus(mapStatusVerified);
    notifier.toggleStatus(mapStatusCleanupScheduled);
    notifier.toggleStatus(mapStatusInProgress);
    notifier.toggleStatus(mapStatusCleaned);
    notifier.toggleStatus(mapStatusDisputed);
    final Set<String> statuses = container
        .read(mapFilterNotifierProvider)
        .activeStatuses;
    expect(statuses.length, 1);
  });

  test('resetAllFilters restores defaults', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final MapFilterNotifier notifier = container.read(
      mapFilterNotifierProvider.notifier,
    );
    notifier.togglePollutionType('ILLEGAL_LANDFILL');
    notifier.setGeoAreaId('bitola');
    notifier.resetAllFilters();
    final MapFilterState state = container.read(mapFilterNotifierProvider);
    expect(state.activeStatuses, equals(mapFilterDefaultStatuses));
    expect(
      state.activePollutionTypes,
      equals(reportPollutionTypeCodes.toSet()),
    );
    expect(state.geoAreaId, isNull);
  });

  test('applyFilters replaces entire state atomically', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final MapFilterNotifier notifier = container.read(
      mapFilterNotifierProvider.notifier,
    );
    notifier.applyFilters(
      const MapFilterState(
        activeStatuses: <String>{mapStatusReported},
        activePollutionTypes: <String>{'WATER_POLLUTION'},
        geoAreaId: 'skopje',
        includeArchived: true,
      ),
    );
    final MapFilterState state = container.read(mapFilterNotifierProvider);
    expect(state.activeStatuses, equals(<String>{mapStatusReported}));
    expect(state.activePollutionTypes, equals(<String>{'WATER_POLLUTION'}));
    expect(state.geoAreaId, 'skopje');
    expect(state.includeArchived, isTrue);
  });
}
