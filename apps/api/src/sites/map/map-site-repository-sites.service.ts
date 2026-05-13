import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { loadFeatureFlags } from '../../config/feature-flags';
import { PrismaService } from '../../prisma/prisma.service';
import { ListSitesMapQueryDto } from '../dto/list-sites-map-query.dto';
import { MapQueryValidatorService } from './map-query-validator.service';
import { MapProjectionRow } from './map-types';
import { resolveMapSiteBounds } from './map-site-repository-bounds.util';

type FallbackSiteRow = {
  id: string;
  latitude: number;
  longitude: number;
  address: string | null;
  description: string | null;
  status: string;
  createdAt: Date;
  updatedAt: Date;
  upvotesCount: number;
  commentsCount: number;
  savesCount: number;
  sharesCount: number;
  reports: Array<{
    title: string;
    description: string | null;
    mediaUrls: string[];
    category: string | null;
    createdAt: Date;
    reportNumber: string | null;
  }>;
  _count: { reports: number };
};

@Injectable()
export class MapSiteRepositorySitesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly validator: MapQueryValidatorService,
  ) {}

  async findSites(
    query: ListSitesMapQueryDto,
    limit: number,
  ): Promise<{ rows: MapProjectionRow[]; usedViewportBbox: boolean; usedFallback: boolean }> {
    const flags = loadFeatureFlags();
    if (!flags.mapUseProjection) {
      return this.findSitesFromCanonical(query, limit);
    }
    const bounds = resolveMapSiteBounds(query, this.validator);
    const statusFilter = query.status
      ? Prisma.sql`AND "status" = ${query.status}::"SiteStatus"`
      : Prisma.empty;
    const includeArchived = query.includeArchived === true;
    const archivedFilter = includeArchived ? Prisma.empty : Prisma.sql`AND "isArchivedByAdmin" = false`;
    const hotProjectionFilter = Prisma.sql`AND "isHot" = true`;
    const usePostgis = flags.mapPostgisEnabled;
    const geoWhere = usePostgis
      ? this.validator.hasViewportBounds(query)
        ? Prisma.sql`AND ST_Intersects(
            "geo",
            ST_MakeEnvelope(${bounds.minLng}, ${bounds.minLat}, ${bounds.maxLng}, ${bounds.maxLat}, 4326)::geography
          )`
        : Prisma.sql`AND ST_DWithin(
            "geo",
            ST_SetSRID(ST_MakePoint(${query.lng}, ${query.lat}), 4326)::geography,
            ${Math.min(500_000, Math.round((query.radiusKm ?? 80) * 1000))}
          )`
      : Prisma.sql`AND "latitude" BETWEEN ${bounds.minLat} AND ${bounds.maxLat}
          AND "longitude" BETWEEN ${bounds.minLng} AND ${bounds.maxLng}`;

    const rows = await this.prisma.$queryRaw<MapProjectionRow[]>`
      SELECT
        "siteId",
        "latitude",
        "longitude",
        "address",
        "description",
        "status"::text as "status",
        "thumbnailUrl",
        "pollutionCategory",
        "latestReportTitle",
        "latestReportDescription",
        "latestReportNumber",
        "latestReportAt",
        "reportCount",
        "upvotesCount",
        "commentsCount",
        "savesCount",
        "sharesCount",
        "siteCreatedAt",
        "siteUpdatedAt"
      FROM "MapSiteProjection"
      WHERE 1=1
        ${geoWhere}
        ${hotProjectionFilter}
        ${statusFilter}
        ${archivedFilter}
      ORDER BY "siteUpdatedAt" DESC
      LIMIT ${limit}
    `;
    return { rows, usedViewportBbox: true, usedFallback: false };
  }

  async resolveDataVersion(query: ListSitesMapQueryDto): Promise<string> {
    const flags = loadFeatureFlags();
    const bounds = resolveMapSiteBounds(query, this.validator);
    const statusFilter = query.status
      ? Prisma.sql`AND "status" = ${query.status}::"SiteStatus"`
      : Prisma.empty;
    const includeArchived = query.includeArchived === true;
    const archivedFilter = includeArchived
      ? Prisma.empty
      : Prisma.sql`AND "isArchivedByAdmin" = false`;
    const hotProjectionFilter = Prisma.sql`AND "isHot" = true`;

    if (flags.mapUseProjection) {
      const usePostgis = flags.mapPostgisEnabled;
      const geoWhere = usePostgis
        ? this.validator.hasViewportBounds(query)
          ? Prisma.sql`AND ST_Intersects(
              "geo",
              ST_MakeEnvelope(${bounds.minLng}, ${bounds.minLat}, ${bounds.maxLng}, ${bounds.maxLat}, 4326)::geography
            )`
          : Prisma.sql`AND ST_DWithin(
              "geo",
              ST_SetSRID(ST_MakePoint(${query.lng}, ${query.lat}), 4326)::geography,
              ${Math.min(500_000, Math.round((query.radiusKm ?? 80) * 1000))}
            )`
        : Prisma.sql`AND "latitude" BETWEEN ${bounds.minLat} AND ${bounds.maxLat}
            AND "longitude" BETWEEN ${bounds.minLng} AND ${bounds.maxLng}`;
      const [row] = await this.prisma.$queryRaw<
        Array<{ count: number; latestUpdatedAt: Date | null }>
      >`
        SELECT
          COUNT(*)::int AS "count",
          MAX("siteUpdatedAt") AS "latestUpdatedAt"
        FROM "MapSiteProjection"
        WHERE 1=1
          ${geoWhere}
          ${hotProjectionFilter}
          ${statusFilter}
          ${archivedFilter}
      `;
      return `${row?.count ?? 0}:${row?.latestUpdatedAt?.getTime() ?? 0}`;
    }

    const [row] = await this.prisma.$queryRaw<
      Array<{ count: number; latestUpdatedAt: Date | null }>
    >`
      SELECT
        COUNT(*)::int AS "count",
        MAX("updatedAt") AS "latestUpdatedAt"
      FROM "Site"
      WHERE "latitude" BETWEEN ${bounds.minLat} AND ${bounds.maxLat}
        AND "longitude" BETWEEN ${bounds.minLng} AND ${bounds.maxLng}
        ${statusFilter}
        ${archivedFilter}
    `;
    return `${row?.count ?? 0}:${row?.latestUpdatedAt?.getTime() ?? 0}`;
  }

  private async findSitesFromCanonical(
    query: ListSitesMapQueryDto,
    limit: number,
  ): Promise<{ rows: MapProjectionRow[]; usedViewportBbox: boolean; usedFallback: boolean }> {
    const where: Prisma.SiteWhereInput = query.status ? { status: query.status } : {};
    if (!query.includeArchived) {
      (where as Record<string, unknown>).isArchivedByAdmin = false;
    }
    const b = resolveMapSiteBounds(query, this.validator);
    where.latitude = { gte: b.minLat, lte: b.maxLat };
    where.longitude = { gte: b.minLng, lte: b.maxLng };

    const rows = await this.prisma.site.findMany({
      where,
      orderBy: [{ updatedAt: 'desc' }],
      take: limit,
      select: {
        id: true,
        latitude: true,
        longitude: true,
        address: true,
        description: true,
        status: true,
        createdAt: true,
        updatedAt: true,
        upvotesCount: true,
        commentsCount: true,
        savesCount: true,
        sharesCount: true,
        reports: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: {
            title: true,
            description: true,
            mediaUrls: true,
            category: true,
            createdAt: true,
            reportNumber: true,
          },
        },
        _count: { select: { reports: true } },
      },
    });

    const mapped: MapProjectionRow[] = (rows as FallbackSiteRow[]).map((site) => {
      const latest = site.reports[0];
      return {
        siteId: site.id,
        latitude: site.latitude,
        longitude: site.longitude,
        address: site.address,
        description: site.description,
        status: site.status,
        thumbnailUrl: latest?.mediaUrls?.[0] ?? null,
        pollutionCategory: latest?.category ?? null,
        latestReportTitle: latest?.title ?? null,
        latestReportDescription: latest?.description ?? null,
        latestReportNumber: latest?.reportNumber ?? null,
        latestReportAt: latest?.createdAt ?? null,
        reportCount: site._count.reports,
        upvotesCount: site.upvotesCount,
        commentsCount: site.commentsCount,
        savesCount: site.savesCount,
        sharesCount: site.sharesCount,
        siteCreatedAt: site.createdAt,
        siteUpdatedAt: site.updatedAt,
      };
    });

    return { rows: mapped, usedViewportBbox: false, usedFallback: true };
  }
}
