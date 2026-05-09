import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/features/home/presentation/providers/map_filter_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_status_codes.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

void main() {
  test('toggleStatus keeps at least one active', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final MapFilterNotifier notifier =
        container.read(mapFilterNotifierProvider.notifier);
    notifier.toggleStatus(mapStatusReported);
    notifier.toggleStatus(mapStatusVerified);
    notifier.toggleStatus(mapStatusCleanupScheduled);
    notifier.toggleStatus(mapStatusInProgress);
    notifier.toggleStatus(mapStatusCleaned);
    notifier.toggleStatus(mapStatusDisputed);
    final Set<String> statuses = container.read(mapFilterNotifierProvider).activeStatuses;
    expect(statuses.length, 1);
  });

  test('resetAllFilters restores defaults', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final MapFilterNotifier notifier =
        container.read(mapFilterNotifierProvider.notifier);
    notifier.togglePollutionType('ILLEGAL_LANDFILL');
    notifier.setGeoAreaId('bitola');
    notifier.resetAllFilters();
    final MapFilterState state = container.read(mapFilterNotifierProvider);
    expect(
      state.activeStatuses,
      equals(<String>{
        mapStatusReported,
        mapStatusVerified,
        mapStatusCleanupScheduled,
        mapStatusInProgress,
        mapStatusCleaned,
        mapStatusDisputed,
      }),
    );
    expect(state.activePollutionTypes, equals(reportPollutionTypeCodes.toSet()));
    expect(state.geoAreaId, isNull);
  });
}
