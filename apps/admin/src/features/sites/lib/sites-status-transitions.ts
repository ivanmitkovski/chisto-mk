export const SITE_STATUS_TRANSITIONS: Record<string, string[]> = {
  REPORTED: ['VERIFIED', 'DISPUTED'],
  VERIFIED: ['CLEANUP_SCHEDULED', 'DISPUTED'],
  CLEANUP_SCHEDULED: ['IN_PROGRESS', 'DISPUTED'],
  IN_PROGRESS: ['CLEANED', 'DISPUTED'],
  CLEANED: ['DISPUTED'],
  DISPUTED: ['REPORTED', 'VERIFIED'],
};

export function isAllowedSiteStatusTransition(fromStatus: string, toStatus: string): boolean {
  const allowed = SITE_STATUS_TRANSITIONS[fromStatus] ?? [];
  return allowed.includes(toStatus);
}

export function countSitesEligibleForBulkStatus(
  sites: ReadonlyArray<{ status: string }>,
  targetStatus: string,
): number {
  return sites.filter((site) => isAllowedSiteStatusTransition(site.status, targetStatus)).length;
}
