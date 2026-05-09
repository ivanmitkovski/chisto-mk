import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_location_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_sites_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_map_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

import '../../shared/widget_test_bootstrap.dart';
import 'support/test_pollution_site.dart';

class _A11yMapSitesNotifier extends MapSitesNotifier {
  _A11yMapSitesNotifier(this.site);
  final PollutionSite site;

  @override
  MapSitesState build() => MapSitesState(sites: <PollutionSite>[site]);

  @override
  void setActive(bool active) {}

  @override
  void updateViewport(query) {}

  @override
  void requestSync({required bool immediate}) {}
}

class _A11yMapLocationNotifier extends MapLocationNotifier {
  @override
  MapLocationState build() => const MapLocationState(userLocation: null);

  @override
  Future<void> tryInitialLocate() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('full map screen keeps key semantics and tap targets', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final PollutionSite site = buildTestPollutionSite(id: 'a11y-site');
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          mapSitesNotifierProvider.overrideWith(() => _A11yMapSitesNotifier(site)),
          mapLocationNotifierProvider.overrideWith(_A11yMapLocationNotifier.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const PollutionMapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      expect(find.bySemanticsLabel('Pollution map. Tap pins to view site details.'), findsOneWidget);
      expect(find.bySemanticsLabel('Search sites'), findsOneWidget);
      expect(find.bySemanticsLabel('Open actions menu'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });
}
