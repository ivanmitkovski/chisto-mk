import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_derived_providers.dart';
import 'package:chisto_mobile/features/home/presentation/providers/repository_providers.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/search_modal.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
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

  testWidgets('renders bottom-sheet search and filters by query', (tester) async {
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

    expect(find.text('Search pollution sites'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'alpha');
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();

    expect(find.text('Site alpha'), findsOneWidget);
    expect(find.text('Site beta'), findsNothing);

    await tester.tap(find.text('Site alpha'));
    await tester.pump();
    expect(tappedSite?.id, 'alpha');
  });
}
