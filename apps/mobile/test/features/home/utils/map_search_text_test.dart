import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/models/site_report.dart';
import 'package:feature_home/src/presentation/utils/map_search_text.dart';
import 'package:feature_home/src/presentation/utils/pollution_site_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foldMapSearchText matches Latin and Cyrillic place names', () {
    expect(foldMapSearchText('Bitola'), foldMapSearchText('Битола'));
  });

  test('pollutionSiteMatchesSearchTerms searches report fields', () {
    final PollutionSite site = PollutionSite(
      id: 's1',
      title: 'River bank',
      description: 'Description',
      statusLabel: 'Reported',
      statusCode: 'REPORTED',
      statusColor: Colors.red,
      distanceKm: 1,
      score: 1,
      participantCount: 0,
      firstReport: SiteReport(
        id: 'r1',
        reporterName: 'Ana',
        reportedAt: DateTime(2024, 1, 1),
        title: 'Bitola dump',
        description: 'Plastic waste',
      ),
    );

    expect(
      pollutionSiteMatchesSearchTerms(site, mapSearchTerms('bitola')),
      isTrue,
    );
    expect(
      pollutionSiteMatchesSearchTerms(site, mapSearchTerms('plastic')),
      isTrue,
    );
  });

  test('mapSearchTitleRank prefers exact and prefix matches', () {
    expect(mapSearchTitleRank('Bitola', 'bitola'), 0);
    expect(mapSearchTitleRank('Bitola center', 'bitola'), 1);
    expect(mapSearchTitleRank('North Bitola', 'bitola'), 2);
  });
}
