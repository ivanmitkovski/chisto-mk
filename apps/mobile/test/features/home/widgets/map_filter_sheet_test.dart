import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/primary_button.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/providers/map_filter_notifier.dart';
import 'package:feature_home/src/presentation/widgets/map/map_filter_checklist.dart';
import 'package:feature_home/src/presentation/widgets/map/map_filter_sheet.dart';
import 'package:feature_home/src/presentation/widgets/map/map_status_codes.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../support/test_pollution_site.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ThemeData testTheme() => ThemeData(splashFactory: NoSplash.splashFactory);

  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  MapFilterState defaultState() => MapFilterState(
    activeStatuses: Set<String>.from(mapFilterDefaultStatuses),
    activePollutionTypes: reportPollutionTypeCodes.toSet(),
  );

  testWidgets('expands inline area list with search', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MapFilterSheet(
            current: defaultState(),
            allSites: const <PollutionSite>[],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Whole country'));
    await tester.pumpAndSettle();

    expect(find.text('Search municipalities and areas'), findsOneWidget);
    expect(find.byType(CupertinoSearchTextField), findsOneWidget);
    expect(find.text('Bitola'), findsWidgets);
  });

  testWidgets('applies draft filters from footer button', (tester) async {
    MapFilterState? applied;
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    applied = await MapFilterSheet.show(
                      context,
                      current: defaultState(),
                      allSites: <PollutionSite>[
                        buildTestPollutionSite(id: 'a'),
                      ],
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reported'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byType(PrimaryButton),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(applied, isNotNull);
    expect(applied!.activeStatuses.contains(mapStatusReported), isFalse);
  });

  testWidgets('close discards changes without applying', (tester) async {
    MapFilterState? applied;
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    applied = await MapFilterSheet.show(
                      context,
                      current: defaultState(),
                      allSites: const <PollutionSite>[],
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reported'));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();

    expect(applied, isNull);
  });

  testWidgets('does not show archived status chip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MapFilterSheet(
            current: defaultState(),
            allSites: const <PollutionSite>[],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Archived'), findsNothing);
    expect(find.text('Show archived sites'), findsOneWidget);
  });

  testWidgets('summary chip shelf keeps fixed height when toggling filters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MapFilterSheet(
            current: defaultState(),
            allSites: const <PollutionSite>[],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final double initialShelfHeight = tester
        .getSize(find.byType(MapFilterSummaryChipShelf))
        .height;

    await tester.tap(find.text('Reported'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(MapFilterSummaryChipShelf)).height,
      initialShelfHeight,
    );
    expect(find.text('Reported'), findsWidgets);
  });

  testWidgets('header reset restores draft defaults', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MapFilterSheet(
            current: MapFilterState(
              activeStatuses: const <String>{mapStatusReported},
              activePollutionTypes: reportPollutionTypeCodes.toSet(),
              geoAreaId: 'bitola',
              includeArchived: true,
            ),
            allSites: const <PollutionSite>[],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();

    expect(find.text('Whole country'), findsOneWidget);
    expect(find.text('Show 0 sites'), findsOneWidget);
  });
}
