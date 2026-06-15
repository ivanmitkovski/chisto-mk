import 'dart:async';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_home/src/application/home_providers.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';

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
  ctaResolutionStarted('cta_resolution_started'),
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

/// Fire-and-forget feed analytics. Uses [tryReadRoot] so dwell/impression flushes
/// from [State.dispose] remain safe while the widget tree is tearing down (e.g. logout).
void trackPollutionFeedCardEvent(
  String siteId, {
  required PollutionFeedCardEventType eventType,
  String? sessionId,
  Map<String, dynamic>? metadata,
  String? feedVariant,
}) {
  final AuthState? auth = tryReadRoot(authStateProvider);
  if (auth == null || !auth.isAuthenticated) return;
  final SitesRepository? repository = tryReadRoot(sitesRepositoryProvider);
  if (repository == null) return;
  final Map<String, dynamic>? enrichedMetadata = feedVariant == null
      ? metadata
      : <String, dynamic>{...?metadata, 'feedVariant': feedVariant};
  unawaited(
    repository.trackFeedEvent(
      siteId,
      eventType: eventType.apiValue,
      sessionId: sessionId,
      metadata: enrichedMetadata,
    ),
  );
}
