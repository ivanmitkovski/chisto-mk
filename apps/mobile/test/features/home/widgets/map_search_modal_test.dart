import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/providers/map_derived_providers.dart';
import 'package:feature_home/src/presentation/providers/map_filter_notifier.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:feature_home/src/presentation/widgets/map/search_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/stub_sites_repository.dart';
import '../support/test_pollution_site.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders preview, filters by query, and submits first result', (
    WidgetTester tester,
  ) async {
    final PollutionSite alpha = buildTestPollutionSite(id: 'alpha');
    final PollutionSite beta = buildTestPollutionSite(id: 'beta');
    PollutionSite? tappedSite;

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          mapSearchLocalPoolProvider.overrideWith((Ref ref) {
            return <PollutionSite>[alpha, beta];
          }),
          sitesRepositoryProvider.overrideWithValue(StubSitesRepository()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: MapSearchModal(
              onResultTap: (PollutionSite site) => tappedSite = site,
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('On this map'), findsOneWidget);
    expect(find.text('Site alpha'), findsOneWidget);
    expect(find.text('Site beta'), findsOneWidget);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'x');
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();

    expect(find.text('Keep typing'), findsOneWidget);
    expect(find.text('No matching sites'), findsNothing);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'alpha');
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();

    expect(find.text('Site alpha'), findsOneWidget);
    expect(find.text('Site beta'), findsNothing);
    expect(find.text('1 results'), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tappedSite?.id, 'alpha');
  });

  testWidgets(
    'shows reset filters action when search is empty under non-default filters',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            mapSearchLocalPoolProvider.overrideWith(
              (Ref ref) => const <PollutionSite>[],
            ),
            mapFilterNotifierProvider.overrideWith(MapFilterNotifier.new),
            sitesRepositoryProvider.overrideWithValue(StubSitesRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: MapSearchModal(onResultTap: (_) {}, onDismiss: () {}),
            ),
          ),
        ),
      );

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(MapSearchModal)),
      );
      container.read(mapFilterNotifierProvider.notifier).setGeoAreaId('skopje');

      await tester.enterText(find.byType(CupertinoSearchTextField), 'zz');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      expect(find.text('No matching sites'), findsOneWidget);
      expect(find.text('Reset filters'), findsOneWidget);
    },
  );
}
