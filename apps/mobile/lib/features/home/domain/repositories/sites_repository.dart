import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';

/// Repository for sites API (pollution sites for map/feed).
abstract class SitesRepository {
  /// List sites with optional geo filter. When lat/lng provided, sorts by distance.
  Future<SitesListResult> getSites({
    double? latitude,
    double? longitude,
    double radiusKm = 10,
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Get single site by ID with reports and events.
  Future<PollutionSite?> getSiteById(String id);
}

/// Paginated sites list result.
class SitesListResult {
  const SitesListResult({
    required this.sites,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<PollutionSite> sites;
  final int total;
  final int page;
  final int limit;
}
