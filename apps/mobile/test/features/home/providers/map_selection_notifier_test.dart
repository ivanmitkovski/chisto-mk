import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_selection_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';

import '../support/test_pollution_site.dart';

class _FakeSitesRepository implements SitesRepository {
  _FakeSitesRepository(this.site);
  final PollutionSite? site;

  @override
  Future<PollutionSite?> getSiteById(String id) async => site;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('select and deselect update selection state', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final PollutionSite site = buildTestPollutionSite(id: 'a');
    final MapSelectionNotifier notifier =
        container.read(mapSelectionNotifierProvider.notifier);
    notifier.select(site);
    expect(container.read(mapSelectionNotifierProvider).selected?.id, 'a');
    notifier.deselect();
    expect(container.read(mapSelectionNotifierProvider).selected, isNull);
  });

  test('resolveSiteAndPoint fetches from repository when absent locally', () async {
    final PollutionSite site = buildTestPollutionSite(id: 'remote');
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sitesRepositoryProvider.overrideWithValue(_FakeSitesRepository(site)),
      ],
    );
    addTearDown(container.dispose);
    final result = await container
        .read(mapSelectionNotifierProvider.notifier)
        .resolveSiteAndPoint('remote');
    expect(result, isNotNull);
    expect(result!.point, isA<LatLng>());
  });
}
