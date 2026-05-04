import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { distanceInMeters } from '../../common/utils/distance';
import { SITE_NEARBY_RADIUS_METERS } from '../reports.constants';

export type EarliestReportOnSite = {
  id: string;
  createdAt: Date;
  reporterId: string | null;
  siteId: string;
};

/** Caps bounding-box site candidates to avoid unbounded reads in dense areas. */
const MAX_SITE_CANDIDATES = 80;

@Injectable()
export class NearbySiteForReportSubmitResolver {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Finds an existing site within [SITE_NEARBY_RADIUS_METERS] of the given point
   * and returns the site id of the earliest report anchor, or null when a new site should be created.
   */
  async resolveEarliestReportAnchor(
    latitude: number,
    longitude: number,
  ): Promise<EarliestReportOnSite | null> {
    const metersPerDegreeLat = 111_320;
    const deltaLat = SITE_NEARBY_RADIUS_METERS / metersPerDegreeLat;
    const metersPerDegreeLng =
      Math.cos((latitude * Math.PI) / 180) * metersPerDegreeLat || metersPerDegreeLat;
    const deltaLng = SITE_NEARBY_RADIUS_METERS / metersPerDegreeLng;

    const candidateSites = await this.prisma.site.findMany({
      where: {
        latitude: { gte: latitude - deltaLat, lte: latitude + deltaLat },
        longitude: { gte: longitude - deltaLng, lte: longitude + deltaLng },
      },
      take: MAX_SITE_CANDIDATES,
      orderBy: { updatedAt: 'desc' },
      select: {
        id: true,
        latitude: true,
        longitude: true,
        reports: {
          orderBy: { createdAt: 'asc' },
          take: 1,
          select: { id: true, createdAt: true, reporterId: true },
        },
      },
    });

    const nearbySites = candidateSites.filter((site) => {
      const dist = distanceInMeters(latitude, longitude, site.latitude, site.longitude);
      return dist <= SITE_NEARBY_RADIUS_METERS;
    });

    let primaryReport: EarliestReportOnSite | null = null;
    for (const site of nearbySites) {
      const firstReport = site.reports[0];
      if (firstReport && (!primaryReport || firstReport.createdAt < primaryReport.createdAt)) {
        primaryReport = {
          id: firstReport.id,
          createdAt: firstReport.createdAt,
          reporterId: firstReport.reporterId,
          siteId: site.id,
        };
      }
    }

    return primaryReport;
  }
}
