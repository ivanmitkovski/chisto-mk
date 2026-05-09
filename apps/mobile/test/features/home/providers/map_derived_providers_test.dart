import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_derived_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_filter_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_sites_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_status_codes.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

import '../support/test_pollution_site.dart';

class _FakeMapSitesNotifier extends MapSitesNotifier {
  _FakeMapSitesNotifier(this._value);

  final MapSitesState _value;

  @override
  MapSitesState build() => _value;
}

class _FakeMapFilterNotifier extends MapFilterNotifier {
  _FakeMapFilterNotifier(this._value);

  final MapFilterState _value;

  @override
  MapFilterState build() => _value;
}

void main() {
  test('filters by workflow status labels', () {
    final PollutionSite siteA = buildTestPollutionSite(
      id: 'site_a',
      statusLabel: 'Reported',
    );
    final PollutionSite siteB = buildTestPollutionSite(
      id: 'site_b',
      statusLabel: 'Verified',
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        mapSitesNotifierProvider.overrideWith(
          () => _FakeMapSitesNotifier(MapSitesState(sites: <PollutionSite>[siteA, siteB])),
        ),
        mapFilterNotifierProvider.overrideWith(
          () => _FakeMapFilterNotifier(
            MapFilterState(
              activeStatuses: const <String>{mapStatusReported},
              activePollutionTypes: reportPollutionTypeCodes.toSet(),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final List<PollutionSite> filtered = container.read(mapFilteredSitesProvider);
    expect(filtered.length, 1);
    expect(filtered.single.id, 'site_a');
  });

  test('filters by geographic bounds', () {
    final PollutionSite inBitola = buildTestPollutionSite(
      id: 'in_bitola',
      statusLabel: 'Reported',
      latitude: 41.03,
      longitude: 21.34,
    );
    final PollutionSite inSkopje = buildTestPollutionSite(
      id: 'in_skopje',
      statusLabel: 'Reported',
      latitude: 42.0,
      longitude: 21.43,
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        mapSitesNotifierProvider.overrideWith(
          () => _FakeMapSitesNotifier(
            MapSitesState(sites: <PollutionSite>[inBitola, inSkopje]),
          ),
        ),
        mapFilterNotifierProvider.overrideWith(
          () => _FakeMapFilterNotifier(
            MapFilterState(
              activeStatuses: const <String>{
                mapStatusReported,
                mapStatusVerified,
                mapStatusCleanupScheduled,
                mapStatusInProgress,
                mapStatusCleaned,
                mapStatusDisputed,
              },
              activePollutionTypes: reportPollutionTypeCodes.toSet(),
              geoAreaId: 'bitola',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final List<PollutionSite> filtered = container.read(mapFilteredSitesProvider);
    expect(filtered.length, 1);
    expect(filtered.single.id, 'in_bitola');
  });
}
