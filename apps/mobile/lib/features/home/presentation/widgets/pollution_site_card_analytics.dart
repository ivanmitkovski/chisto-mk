import 'dart:async';

import 'package:chisto_mobile/core/di/service_locator.dart';

enum PollutionFeedCardEventType {
  like('upvote'),
  save('save'),
  share('share'),
  impression('impression'),
  commentOpen('comment_open'),
  dwellBucket('dwell_bucket'),
  detailOpen('detail_open'),
  ctaOpened('cta_opened'),
  ctaCreateStarted('cta_create_started'),
  ctaJoinStarted('cta_join_started'),
  ctaShareStarted('cta_share_started'),
  ctaDonateStarted('cta_donate_started'),
  ctaCreateFinished('cta_create_finished'),
  ctaJoinFinished('cta_join_finished'),
  ctaShareCancelled('cta_share_cancelled'),
  ctaShareTrackFailed('cta_share_track_failed');

  const PollutionFeedCardEventType(this.apiValue);
  final String apiValue;
}

/// Buckets dwell time on a feed card for analytics payloads.
String feedCardDwellBucketForSeconds(int seconds) {
  if (seconds < 5) return '2_4s';
  if (seconds < 15) return '5_14s';
  if (seconds < 30) return '15_29s';
  return '30s_plus';
}

void trackPollutionFeedCardEvent(
  String siteId, {
  required PollutionFeedCardEventType eventType,
  String? sessionId,
  Map<String, dynamic>? metadata,
  String? feedVariant,
}) {
  if (!ServiceLocator.instance.authState.isAuthenticated) return;
  final Map<String, dynamic>? enrichedMetadata = feedVariant == null
      ? metadata
      : <String, dynamic>{
          ...?metadata,
          'feedVariant': feedVariant,
        };
  unawaited(
    ServiceLocator.instance.sitesRepository.trackFeedEvent(
      siteId,
      eventType: eventType.apiValue,
      sessionId: sessionId,
      metadata: enrichedMetadata,
    ),
  );
}
