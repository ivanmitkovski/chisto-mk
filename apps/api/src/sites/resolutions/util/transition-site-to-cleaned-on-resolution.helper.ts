import { SiteStatus } from '../../../prisma-client';
import type { PrismaService } from '../../../prisma/prisma.service';

const RESOLUTION_CLEANED_FROM: SiteStatus[] = [
  SiteStatus.VERIFIED,
  SiteStatus.CLEANUP_SCHEDULED,
  SiteStatus.IN_PROGRESS,
];

export type SiteCleanedTransitionResult = {
  id: string;
  status: SiteStatus;
  latitude: number;
  longitude: number;
  updatedAt: Date;
  fromStatus: SiteStatus;
} | null;

/**
 * When a resolution is approved, transition site to CLEANED from active pollution states.
 * Skips when site is already CLEANED or not in an eligible state.
 */
export async function transitionSiteToCleanedOnResolution(
  tx: Pick<PrismaService, 'site'>,
  siteId: string,
): Promise<SiteCleanedTransitionResult> {
  const site = await tx.site.findUnique({
    where: { id: siteId },
    select: {
      id: true,
      status: true,
      latitude: true,
      longitude: true,
      updatedAt: true,
    },
  });
  if (!site || site.status === SiteStatus.CLEANED) {
    return null;
  }
  if (!RESOLUTION_CLEANED_FROM.includes(site.status)) {
    return null;
  }
  const fromStatus = site.status;
  const updated = await tx.site.update({
    where: { id: siteId },
    data: { status: SiteStatus.CLEANED },
    select: {
      id: true,
      status: true,
      latitude: true,
      longitude: true,
      updatedAt: true,
    },
  });
  return { ...updated, fromStatus };
}

export function resolutionSubmitAllowedStatuses(): SiteStatus[] {
  return [
    SiteStatus.VERIFIED,
    SiteStatus.CLEANUP_SCHEDULED,
    SiteStatus.IN_PROGRESS,
    SiteStatus.CLEANED,
  ];
}
