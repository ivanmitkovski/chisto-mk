import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/features/home/presentation/widgets/map/map_filter_sheet.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_geo_area_picker_sheet.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('opens geo picker sheet and selects root area', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MapFilterSheet(
            activeStatuses: const <String>{'Reported', 'Verified'},
            activePollutionTypes: const <String>{'Air', 'Water'},
            geoAreaId: null,
            visibleCount: 2,
            totalCount: 3,
            allPollutionTypes: const <String>['Air', 'Water'],
            onToggleStatus: (_) {},
            onTogglePollutionType: (_) {},
            onGeoAreaIdChanged: (v) => selected = v,
            includeArchived: false,
            onIncludeArchivedChanged: (_) {},
            onDismiss: () {},
            onResetFilters: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Whole country'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoSearchTextField), findsOneWidget);

    final Finder optionRows = find.descendant(
      of: find.byType(MapGeoAreaPickerSheet),
      matching: find.byType(InkWell),
    );
    expect(optionRows, findsWidgets);
    expect(selected, isNull);
  });

  testWidgets('selects Skopje municipality from nested picker', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MapFilterSheet(
            activeStatuses: const <String>{'Reported', 'Verified'},
            activePollutionTypes: const <String>{'Air', 'Water'},
            geoAreaId: 'skopje',
            visibleCount: 2,
            totalCount: 3,
            allPollutionTypes: const <String>['Air', 'Water'],
            onToggleStatus: (_) {},
            onTogglePollutionType: (_) {},
            onGeoAreaIdChanged: (v) => selected = v,
            includeArchived: false,
            onIncludeArchivedChanged: (_) {},
            onDismiss: () {},
            onResetFilters: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('All Skopje municipalities'));
    await tester.pumpAndSettle();

    final Finder centarOption = find.descendant(
      of: find.byType(MapGeoAreaPickerSheet),
      matching: find.text('Centar'),
    );
    expect(centarOption, findsWidgets);
    await tester.tap(centarOption.first);
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected, isNot('skopje'));
  });

  testWidgets('calls dismiss callback from close button', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MapFilterSheet(
            activeStatuses: const <String>{'Reported', 'Verified'},
            activePollutionTypes: const <String>{'Air', 'Water'},
            geoAreaId: null,
            visibleCount: 2,
            totalCount: 3,
            allPollutionTypes: const <String>['Air', 'Water'],
            onToggleStatus: (_) {},
            onTogglePollutionType: (_) {},
            onGeoAreaIdChanged: (_) {},
            includeArchived: false,
            onIncludeArchivedChanged: (_) {},
            onDismiss: () => dismissed = true,
            onResetFilters: () {},
          ),
        ),
      ),
    );

    final IconButton closeButton = tester.widget<IconButton>(
      find.byType(IconButton),
    );
    closeButton.onPressed?.call();
    await tester.pump(const Duration(milliseconds: 80));

    expect(dismissed, isTrue);
  });

  testWidgets('shows archived toggle in dedicated visibility section', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: MapFilterSheet(
            activeStatuses: const <String>{'Reported', 'Verified'},
            activePollutionTypes: const <String>{'Air', 'Water'},
            geoAreaId: null,
            visibleCount: 2,
            totalCount: 3,
            allPollutionTypes: const <String>['Air', 'Water'],
            onToggleStatus: (_) {},
            onTogglePollutionType: (_) {},
            onGeoAreaIdChanged: (_) {},
            includeArchived: false,
            onIncludeArchivedChanged: (_) {},
            onDismiss: () {},
            onResetFilters: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Visibility'), findsOneWidget);
    expect(find.text('Show archived sites'), findsOneWidget);
  });
}
