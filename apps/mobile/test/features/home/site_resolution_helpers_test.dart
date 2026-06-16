import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/models/site_resolution_viewer_status.dart';
import 'package:feature_home/src/presentation/utils/site_resolution_helpers.dart';
import 'package:feature_home/src/presentation/widgets/feed_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedFilter.resolved', () {
    test('feed filter enum includes resolved', () {
      expect(FeedFilter.values, contains(FeedFilter.resolved));
    });
  });

  group('site_resolution_helpers', () {
    test('isPollutionSiteResolved is true for CLEANED', () {
      expect(isPollutionSiteResolved(_site(statusCode: 'CLEANED')), isTrue);
    });

    test('canSubmitSiteResolution is false for REPORTED', () {
      expect(canSubmitSiteResolution(_site(statusCode: 'REPORTED')), isFalse);
    });

    const PollutionSite base = PollutionSite(
      id: 'site-1',
      title: 'Test',
      description: 'Desc',
      statusLabel: 'Verified',
      statusCode: 'VERIFIED',
      statusColor: Color(0xFF000000),
      distanceKm: 1,
      score: 0,
      participantCount: 0,
    );

    test('hasMyPendingResolution is true only for pending status', () {
      expect(
        hasMyPendingResolution(
          base.copyWith(
            viewerResolutionStatus: SiteResolutionViewerStatus.pending,
          ),
        ),
        isTrue,
      );
      expect(
        hasMyPendingResolution(
          base.copyWith(
            viewerResolutionStatus: SiteResolutionViewerStatus.approved,
          ),
        ),
        isFalse,
      );
      expect(hasMyPendingResolution(base), isFalse);
    });

    test('canSubmitSiteResolution blocks pending submissions', () {
      expect(
        canSubmitSiteResolution(
          base.copyWith(
            viewerResolutionStatus: SiteResolutionViewerStatus.pending,
          ),
        ),
        isFalse,
      );
      expect(canSubmitSiteResolution(base), isTrue);
    });
  });
}

PollutionSite _site({required String statusCode}) {
  return PollutionSite(
    id: 'site-1',
    title: 'Test site',
    description: 'Desc',
    statusLabel: statusCode,
    statusCode: statusCode,
    statusColor: Colors.green,
    distanceKm: 1,
    score: 0,
    participantCount: 0,
  );
}
