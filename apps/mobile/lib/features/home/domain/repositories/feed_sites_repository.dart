import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository_types.dart';

/// Feed list, detail, and map queries (read-heavy sites API surface).
abstract class FeedSitesRepository {
  static const String mapDetailFull = 'full';
  static const String mapDetailLite = 'lite';

  /// Paginated sites the current user has saved (`GET /sites/saved`).
  Future<SitesListResult> getSavedSites({
    int page = 1,
    int limit = 24,
    double? latitude,
    double? longitude,
  });

  Future<SitesListResult> getSites({
    double? latitude,
    double? longitude,
    double radiusKm = 10,
    String? status,
    int page = 1,
    int limit = 20,
    String sort = 'hybrid',
    String mode = 'for_you',
    bool explain = false,
    String? cursor,
  });

  Future<MapSitesResult> getSitesForMap({
    required double latitude,
    required double longitude,
    double radiusKm = 80,
    int limit = 200,
    double? minLatitude,
    double? maxLatitude,
    double? minLongitude,
    double? maxLongitude,
    String mapDetail = FeedSitesRepository.mapDetailLite,
    double? zoom,
    String? status,
    bool includeArchived = false,
    bool prefetch = false,
  });

  Future<PollutionSite?> getSiteById(String id);

  Future<SiteMapSearchResponse> searchSitesForMap(SiteMapSearchRequest request);
}
