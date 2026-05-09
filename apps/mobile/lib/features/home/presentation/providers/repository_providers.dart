import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/location/location_service.dart';
import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/features/home/domain/repositories/feed_analytics_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/feed_sites_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/site_comments_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/site_engagement_repository.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:chisto_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bridge: repositories remain owned by [ServiceLocator]; Riverpod exposes them for DI.
final sitesRepositoryProvider = Provider<SitesRepository>((Ref ref) {
  return ServiceLocator.instance.sitesRepository;
});

final homeAuthStateProvider = Provider<AuthState>((Ref ref) {
  return ServiceLocator.instance.authState;
});

final feedSitesRepositoryProvider = Provider<FeedSitesRepository>((Ref ref) {
  return ref.watch(sitesRepositoryProvider);
});

final siteEngagementRepositoryProvider =
    Provider<SiteEngagementRepository>((Ref ref) {
  return ref.watch(sitesRepositoryProvider);
});

final siteCommentsRepositoryProvider =
    Provider<SiteCommentsRepository>((Ref ref) {
  return ref.watch(sitesRepositoryProvider);
});

final feedAnalyticsRepositoryProvider =
    Provider<FeedAnalyticsRepository>((Ref ref) {
  return ref.watch(sitesRepositoryProvider);
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((Ref ref) {
  return ServiceLocator.instance.notificationsRepository;
});

final locationServiceProvider = Provider<LocationService>((Ref ref) {
  return ServiceLocator.instance.locationService;
});
