/** Per-viewer resolution state exposed on site list/detail responses. */
export type ViewerResolutionStatus = 'none' | 'pending' | 'approved';

export type ViewerResolutionStatusMap = Map<string, 'pending' | 'approved'>;

export function viewerResolutionStatusForSite(
  statusBySite: ViewerResolutionStatusMap,
  siteId: string,
): ViewerResolutionStatus {
  const status = statusBySite.get(siteId);
  if (status === 'approved') return 'approved';
  if (status === 'pending') return 'pending';
  return 'none';
}
