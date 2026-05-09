import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_location_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/providers/map_sites_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_map_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/test_pollution_site.dart';

class _FakeMapSitesNotifier extends MapSitesNotifier {
  _FakeMapSitesNotifier(this.site);
  final PollutionSite site;

  @override
  MapSitesState build() {
    return MapSitesState(sites: <PollutionSite>[site]);
  }

  @override
  void setActive(bool active) {}

  @override
  void updateViewport(query) {}

  @override
  void requestSync({required bool immediate}) {}
}

class _FakeMapLocationNotifier extends MapLocationNotifier {
  @override
  MapLocationState build() =>
      const MapLocationState(userLocation: null, isLocating: false);

  @override
  Future<void> tryInitialLocate() async {}

  @override
  Future<bool> startForegroundTracking() async => true;

  @override
  Future<void> stopForegroundTracking() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('mounts full map screen and opens actions menu', (
    WidgetTester tester,
  ) async {
    final PollutionSite site = buildTestPollutionSite(id: 'integration-site');

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          mapSitesNotifierProvider.overrideWith(() => _FakeMapSitesNotifier(site)),
          mapLocationNotifierProvider.overrideWith(_FakeMapLocationNotifier.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PollutionMapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 350));

    expect(find.byType(PollutionMapScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Open actions menu'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Center map on my location'), findsOneWidget);
  });
}
