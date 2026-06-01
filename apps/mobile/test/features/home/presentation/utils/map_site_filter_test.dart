import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/providers/map_filter_notifier.dart';
import 'package:feature_home/src/presentation/utils/map_site_filter.dart';
import 'package:feature_home/src/presentation/widgets/map/map_status_codes.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_pollution_site.dart';

void main() {
  test('pollutionSiteMatchesMapFilter respects active status set', () {
    final MapFilterState filter = MapFilterState(
      activeStatuses: <String>{mapStatusReported},
      activePollutionTypes: reportPollutionTypeCodes.toSet(),
      geoAreaId: null,
      includeArchived: false,
    );
    final cleaned = buildTestPollutionSite(
      id: '1',
      statusCode: mapStatusCleaned,
      statusLabel: 'Cleaned',
    );
    expect(pollutionSiteMatchesMapFilter(cleaned, filter), isFalse);
    final reported = buildTestPollutionSite(
      id: '2',
      statusCode: mapStatusReported,
      statusLabel: 'Reported',
    );
    expect(pollutionSiteMatchesMapFilter(reported, filter), isTrue);
  });

  test('mapFilterPreviewCount matches filter rules', () {
    final sites = <PollutionSite>[
      buildTestPollutionSite(id: '1', statusCode: mapStatusReported),
      buildTestPollutionSite(id: '2', statusCode: mapStatusCleaned),
    ];
    final MapFilterState filter = MapFilterState(
      activeStatuses: <String>{mapStatusReported},
      activePollutionTypes: reportPollutionTypeCodes.toSet(),
    );
    expect(mapFilterPreviewCount(sites, filter), 1);
  });

  test('pollutionSiteMatchesMapFilter hides archived unless toggled on', () {
    final MapFilterState hidden = MapFilterState(
      activeStatuses: mapFilterDefaultStatuses,
      activePollutionTypes: reportPollutionTypeCodes.toSet(),
      includeArchived: false,
    );
    final MapFilterState visible = hidden.copyWith(includeArchived: true);
    final archived = buildTestPollutionSite(
      id: '3',
      statusCode: mapStatusArchived,
      statusLabel: 'Archived',
    );
    expect(pollutionSiteMatchesMapFilter(archived, hidden), isFalse);
    expect(pollutionSiteMatchesMapFilter(archived, visible), isTrue);
  });
}
