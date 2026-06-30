import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/providers/map_derived_providers.dart';
import 'package:feature_home/src/presentation/providers/map_search_controller.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:feature_home/src/presentation/widgets/map/search_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/stub_sites_repository.dart';
import '../support/test_pollution_site.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('MapSearchModal golden empty preview en', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        mapSearchLocalPoolProvider.overrideWith((Ref ref) {
          return <PollutionSite>[
            buildTestPollutionSite(id: 'alpha'),
            buildTestPollutionSite(id: 'beta'),
          ];
        }),
        sitesRepositoryProvider.overrideWithValue(StubSitesRepository()),
      ],
    );
    final ProviderSubscription<MapSearchState> searchSub = container.listen(
      mapSearchControllerProvider,
      (_, __) {},
    );
    addTearDown(() {
      searchSub.close();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 720),
              devicePixelRatio: 1,
              textScaler: TextScaler.noScaling,
              disableAnimations: true,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: MapSearchModal(onResultTap: (_) {}, onDismiss: () {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(MapSearchModal),
      matchesGoldenFile('__goldens__/map_search_modal_empty_preview_en.png'),
    );
    await tester.pump(const Duration(milliseconds: 300));
  });
}
