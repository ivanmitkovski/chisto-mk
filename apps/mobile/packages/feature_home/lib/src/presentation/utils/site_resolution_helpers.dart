import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/models/site_resolution_viewer_status.dart';

bool isPollutionSiteResolved(PollutionSite site) {
  final String code = site.statusCode?.trim().toUpperCase() ?? '';
  return code == 'CLEANED';
}

bool canSubmitSiteResolution(PollutionSite site) {
  if (hasMyPendingResolution(site)) {
    return false;
  }
  final String code = site.statusCode?.trim().toUpperCase() ?? '';
  if (code.isEmpty) {
    return true;
  }
  return code != 'REPORTED' && code != 'DISPUTED';
}

bool hasMyPendingResolution(PollutionSite site) =>
    site.viewerResolutionStatus == SiteResolutionViewerStatus.pending;
