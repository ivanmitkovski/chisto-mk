import { SiteStatus } from '../prisma-client';
import type { PrismaService } from '../prisma/prisma.service';

/**
 * When the first report for a site is approved, transition site from REPORTED → VERIFIED.
 * Only updates when site is REPORTED; does not overwrite DISPUTED or other statuses.
 */
export async function transitionSiteToVerifiedIfFirstApproved(
  tx: Pick<PrismaService, 'site'>,
  siteId: string,
): Promise<{
  id: string;
  status: SiteStatus;
  latitude: number;
  longitude: number;
  updatedAt: Date;
} | null> {
  const site = await tx.site.findUnique({
    where: { id: siteId },
    select: { id: true, status: true, latitude: true, longitude: true },
  });
  if (!site || site.status !== SiteStatus.REPORTED) {
    return null;
  }

  const updated = await tx.site.update({
    where: { id: siteId },
    data: { status: SiteStatus.VERIFIED },
    select: { id: true, status: true, latitude: true, longitude: true, updatedAt: true },
  });
  return updated;
}
