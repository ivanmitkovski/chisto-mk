import 'package:chisto_infrastructure/core/location/location_service.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_home/src/domain/repositories/feed_analytics_repository.dart';
import 'package:feature_home/src/domain/repositories/feed_sites_repository.dart';
import 'package:feature_home/src/domain/repositories/site_comments_repository.dart';
import 'package:feature_home/src/domain/repositories/site_engagement_repository.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sitesRepositoryProvider = Provider<SitesRepository>((Ref ref) {
  return ref.watch(appBootstrapProvider).sitesRepository;
});

final feedSitesRepositoryProvider = Provider<FeedSitesRepository>((Ref ref) {
  return ref.watch(sitesRepositoryProvider);
});

final siteEngagementRepositoryProvider = Provider<SiteEngagementRepository>((
  Ref ref,
) {
  return ref.watch(sitesRepositoryProvider);
});

final siteCommentsRepositoryProvider = Provider<SiteCommentsRepository>((
  Ref ref,
) {
  return ref.watch(sitesRepositoryProvider);
});

final feedAnalyticsRepositoryProvider = Provider<FeedAnalyticsRepository>((
  Ref ref,
) {
  return ref.watch(sitesRepositoryProvider);
});

final locationServiceProvider = Provider<LocationService>((Ref ref) {
  return ref.watch(appBootstrapProvider).locationService;
});
