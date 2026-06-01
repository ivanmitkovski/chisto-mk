import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:feature_home/src/presentation/widgets/map/map_search_suggestions_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MapSearchSuggestionsSection renders chips and geo intent', (
    WidgetTester tester,
  ) async {
    String? tappedSuggestion;
    SiteMapSearchGeoIntent? tappedGeo;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MapSearchSuggestionsSection(
            suggestions: const <String>['Bitola', 'Skopje center'],
            query: 'bit',
            geoIntent: const SiteMapSearchGeoIntent(
              label: 'Bitola area',
              minLat: 41,
              maxLat: 41.1,
              minLng: 21,
              maxLng: 21.1,
            ),
            onSuggestionTap: (String value) => tappedSuggestion = value,
            onGeoIntentTap: (SiteMapSearchGeoIntent value) => tappedGeo = value,
          ),
        ),
      ),
    );

    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('Bitola'), findsOneWidget);
    expect(find.text('Skopje center'), findsOneWidget);
    expect(find.text('Show area on map'), findsOneWidget);
    expect(find.text('Bitola area'), findsOneWidget);

    await tester.tap(find.text('Skopje center'));
    await tester.pump();
    expect(tappedSuggestion, 'Skopje center');

    await tester.tap(find.text('Bitola area'));
    await tester.pump();
    expect(tappedGeo?.label, 'Bitola area');
  });
}
