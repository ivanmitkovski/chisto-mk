import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_search_controller.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_pollution_site.dart';

void main() {
  test('ranks prefix match before contains match', () async {
    final MapSearchController controller = MapSearchController(
      initialLocalPool: <PollutionSite>[
        buildTestPollutionSite(id: 'waste-alpha'),
        buildTestPollutionSite(id: 'alpha-site'),
      ],
      remoteSearch: (_) async => const SiteMapSearchResponse(items: <PollutionSite>[]),
    );
    addTearDown(controller.dispose);

    controller.updateQuery('Alpha');
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(controller.state.localResults.first.id, 'alpha-site');
  });
}
