import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/site_defaults.dart';

/// Whether a map preview row needs detail hydration for reporter-owned pending sites.
bool mapPreviewNeedsHydration(PollutionSite site) {
  if (site.statusCode != 'REPORTED') {
    return false;
  }
  final String? imageUrl = site.primaryImageUrl;
  if (imageUrl == null || imageUrl.isEmpty) {
    return true;
  }
  return isApiDefaultPollutionSiteTitle(site.title);
}
