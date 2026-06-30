import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/providers/feed_providers.dart';

/// Mirrors [_statusForLoadedResult] for unit tests without production exports.
FeedSitesViewStatus feedStatusForLoadedResult({
  required List<PollutionSite> sites,
  required bool locationAvailable,
  required bool isStaleFallback,
}) {
  if (sites.isEmpty && !locationAvailable) {
    return FeedSitesViewStatus.noLocation;
  }
  if (isStaleFallback) {
    return FeedSitesViewStatus.staleData;
  }
  if (sites.isEmpty) {
    return FeedSitesViewStatus.empty;
  }
  return FeedSitesViewStatus.freshData;
}
