import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { MapProjectionUpsertRow } from './map-projection-row.types';

@Injectable()
export class MapProjectionWriterService {
  constructor(private readonly prisma: PrismaService) {}

  async deleteBySiteId(siteId: string): Promise<void> {
    await this.prisma.$executeRaw`DELETE FROM "MapSiteProjection" WHERE "siteId" = ${siteId}`;
  }

  async upsert(row: MapProjectionUpsertRow): Promise<void> {
    await this.prisma.$executeRaw`
      INSERT INTO "MapSiteProjection" (
        "siteId","latitude","longitude","status","address","description","thumbnailUrl",
        "pollutionCategory","latestReportTitle","latestReportDescription","latestReportNumber",
        "reportCount","upvotesCount","commentsCount","savesCount","sharesCount",
        "latestReportAt","siteCreatedAt","siteUpdatedAt","projectedAt","isHot","isArchivedByAdmin","archivedAt"
      ) VALUES (
        ${row.siteId},${row.latitude},${row.longitude},${row.status}::"SiteStatus",${row.address},${row.description},${row.thumbnailUrl},
        ${row.pollutionCategory},${row.latestReportTitle},${row.latestReportDescription},${row.latestReportNumber},
        ${row.reportCount},${row.upvotesCount},${row.commentsCount},${row.savesCount},${row.sharesCount},
        ${row.latestReportAt},${row.siteCreatedAt},${row.siteUpdatedAt},NOW(),${row.isHot},${row.isArchivedByAdmin},${row.archivedAt}
      )
      ON CONFLICT ("siteId") DO UPDATE
      SET
        "latitude" = EXCLUDED."latitude",
        "longitude" = EXCLUDED."longitude",
        "status" = EXCLUDED."status",
        "address" = EXCLUDED."address",
        "description" = EXCLUDED."description",
        "thumbnailUrl" = EXCLUDED."thumbnailUrl",
        "pollutionCategory" = EXCLUDED."pollutionCategory",
        "latestReportTitle" = EXCLUDED."latestReportTitle",
        "latestReportDescription" = EXCLUDED."latestReportDescription",
        "latestReportNumber" = EXCLUDED."latestReportNumber",
        "reportCount" = EXCLUDED."reportCount",
        "upvotesCount" = EXCLUDED."upvotesCount",
        "commentsCount" = EXCLUDED."commentsCount",
        "savesCount" = EXCLUDED."savesCount",
        "sharesCount" = EXCLUDED."sharesCount",
        "latestReportAt" = EXCLUDED."latestReportAt",
        "siteCreatedAt" = EXCLUDED."siteCreatedAt",
        "siteUpdatedAt" = EXCLUDED."siteUpdatedAt",
        "projectedAt" = NOW(),
        "isHot" = EXCLUDED."isHot",
        "isArchivedByAdmin" = EXCLUDED."isArchivedByAdmin",
        "archivedAt" = EXCLUDED."archivedAt";
    `;
  }
}
