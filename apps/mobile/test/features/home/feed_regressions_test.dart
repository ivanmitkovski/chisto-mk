import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/utils/site_image_resolver.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/site_stats_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('site gallery returns all provided images', () {
    const site = PollutionSite(
      id: 'site_1',
      title: 'Title',
      description: 'Desc',
      statusLabel: 'Verified',
      statusColor: Colors.green,
      distanceKm: -1,
      score: 1,
      participantCount: 0,
      mediaUrls: <String>[
        'assets/images/content/people_cleaning.png',
        'assets/images/content/people_cleaning.png',
      ],
    );

    expect(siteGalleryImageProviders(site).length, 2);
  });

  testWidgets('shows compact token for unknown distance', (tester) async {
    const site = PollutionSite(
      id: 'site_1',
      title: 'Title',
      description: 'Desc',
      statusLabel: 'Verified',
      statusColor: Colors.green,
      distanceKm: -1,
      score: 1,
      participantCount: 0,
      mediaUrls: <String>['assets/images/content/people_cleaning.png'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(body: SiteStatsRow(site: site)),
      ),
    );

    expect(find.text('Not available'), findsOneWidget);
  });
}
