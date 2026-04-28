import 'package:chisto_mobile/core/app_theme.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/utils/site_image_resolver.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/site_stats_row.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('site gallery returns all provided images', () {
    final site = PollutionSite(
      id: 'site_1',
      title: 'Title',
      description: 'Desc',
      statusLabel: 'Verified',
      statusColor: Colors.green,
      distanceKm: -1,
      score: 1,
      participantCount: 0,
      mediaUrls: const <String>[
        'assets/images/content/people_cleaning.png',
        'assets/images/content/people_cleaning.png',
      ],
    );

    expect(siteGalleryImageProviders(site).length, 2);
  });

  testWidgets('shows compact token for unknown distance', (tester) async {
    final site = PollutionSite(
      id: 'site_1',
      title: 'Title',
      description: 'Desc',
      statusLabel: 'Verified',
      statusColor: Colors.green,
      distanceKm: -1,
      score: 1,
      participantCount: 0,
      mediaUrls: const <String>['assets/images/content/people_cleaning.png'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SiteStatsRow(site: site),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
  });
}
