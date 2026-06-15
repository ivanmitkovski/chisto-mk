/// Viewer's own site resolution state from GET /sites and GET /sites/:id.
enum SiteResolutionViewerStatus {
  none,
  pending,
  approved,
}

SiteResolutionViewerStatus siteResolutionViewerStatusFromApi(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'pending':
      return SiteResolutionViewerStatus.pending;
    case 'approved':
      return SiteResolutionViewerStatus.approved;
    default:
      return SiteResolutionViewerStatus.none;
  }
}

String siteResolutionViewerStatusToApi(SiteResolutionViewerStatus status) {
  switch (status) {
    case SiteResolutionViewerStatus.pending:
      return 'pending';
    case SiteResolutionViewerStatus.approved:
      return 'approved';
    case SiteResolutionViewerStatus.none:
      return 'none';
  }
}
