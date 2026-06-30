import { Injectable } from '@nestjs/common';
import type { MapProjectionUpsertRow, ProjectionSourceSite } from './map-projection-row.types';

@Injectable()
export class MapProjectionDiffService {
  computeUpsertRow(site: ProjectionSourceSite): MapProjectionUpsertRow {
    const latest = site.reports[0];
    const heroUrls = site.heroReport?.mediaUrls ?? [];
    const latestUrls = latest?.mediaUrls ?? [];
    const heroThumbnail =
      heroUrls.find((url) => typeof url === 'string' && url.trim().length > 0)?.trim() ?? null;
    const pendingThumbnail =
      site.status === 'REPORTED'
        ? latestUrls.find((url) => typeof url === 'string' && url.trim().length > 0)?.trim() ?? null
        : null;
    const thumbnail = heroThumbnail ?? pendingThumbnail;
    const isHot =
      site.status !== 'CLEANED' || site.updatedAt.getTime() > Date.now() - 90 * 24 * 60 * 60 * 1000;
    return {
      siteId: site.id,
      latitude: site.latitude,
      longitude: site.longitude,
      status: site.status,
      address: site.address,
      description: site.description,
      thumbnailUrl: thumbnail,
      pollutionCategory: latest?.category ?? null,
      latestReportTitle: latest?.title ?? null,
      latestReportDescription: latest?.description ?? null,
      latestReportNumber: latest?.reportNumber ?? null,
      reportCount: site._count.reports,
      upvotesCount: site.upvotesCount,
      commentsCount: site.commentsCount,
      savesCount: site.savesCount,
      sharesCount: site.sharesCount,
      latestReportAt: latest?.createdAt ?? null,
      siteCreatedAt: site.createdAt,
      siteUpdatedAt: site.updatedAt,
      isHot,
      isArchivedByAdmin: site.isArchivedByAdmin,
      archivedAt: site.archivedAt,
    };
  }
}
