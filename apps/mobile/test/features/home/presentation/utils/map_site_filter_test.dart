import 'package:chisto_mobile/features/home/presentation/providers/map_filter_notifier.dart';
import 'package:chisto_mobile/features/home/presentation/utils/map_site_filter.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/map_status_codes.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
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
}
