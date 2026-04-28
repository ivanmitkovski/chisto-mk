import 'package:chisto_mobile/features/home/domain/repositories/feed_analytics_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/feed_sites_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/site_comments_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/site_engagement_repository.dart';

export 'sites_repository_types.dart';

/// Single mobile HTTP implementation ([ApiSitesRepository]) implements all narrow contracts.
abstract interface class SitesRepository
    implements FeedSitesRepository, SiteEngagementRepository, SiteCommentsRepository, FeedAnalyticsRepository {
  /// [getSitesForMap] JSON shape: `full` (default API) vs `lite` (smaller payload, map-optimized).
  static const String mapDetailFull = FeedSitesRepository.mapDetailFull;
  static const String mapDetailLite = FeedSitesRepository.mapDetailLite;
}
