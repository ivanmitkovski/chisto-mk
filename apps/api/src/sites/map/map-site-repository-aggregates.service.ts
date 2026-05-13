import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { loadFeatureFlags } from '../../config/feature-flags';
import { PrismaService } from '../../prisma/prisma.service';
import { ListSitesMapQueryDto } from '../dto/list-sites-map-query.dto';
import { MapQueryValidatorService } from './map-query-validator.service';
import { resolveMapSiteBounds } from './map-site-repository-bounds.util';

@Injectable()
export class MapSiteRepositoryAggregatesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly validator: MapQueryValidatorService,
  ) {}

  async findClusters(
    query: ListSitesMapQueryDto,
    zoom: number,
  ): Promise<
    Array<{
      clusterKey: string;
      clusterId: string;
      latitude: number;
      longitude: number;
      count: number;
      siteIds: string[];
    }>
  > {
    const flags = loadFeatureFlags();
    const bucketDivisor = Math.max(8, Math.floor(26 - zoom));
    const bounds = resolveMapSiteBounds(query, this.validator);
    const statusFragment = query.status ? Prisma.sql`AND "status" = ${query.status}::"SiteStatus"` : Prisma.empty;
    const includeArchived = query.includeArchived === true;
    const archivedFilter = includeArchived ? Prisma.empty : Prisma.sql`AND "isArchivedByAdmin" = false`;
    const hotProjectionFilter = flags.mapUseProjection
      ? Prisma.sql`AND "isHot" = true`
      : Prisma.empty;

    const table = flags.mapUseProjection
      ? Prisma.sql`"MapSiteProjection"`
      : Prisma.sql`"Site"`;

    const idCol = flags.mapUseProjection ? Prisma.sql`"siteId"` : Prisma.sql`"id"`;
    const usePostgis = flags.mapPostgisEnabled;
    const geoWhere = usePostgis
      ? Prisma.sql`ST_Intersects(
          "geo",
          ST_MakeEnvelope(${bounds.minLng}, ${bounds.minLat}, ${bounds.maxLng}, ${bounds.maxLat}, 4326)::geography
        )`
      : Prisma.sql`"latitude" BETWEEN ${bounds.minLat} AND ${bounds.maxLat}
        AND "longitude" BETWEEN ${bounds.minLng} AND ${bounds.maxLng}`;
    return this.prisma.$queryRaw<
      Array<{
        clusterKey: string;
        clusterId: string;
        latitude: number;
        longitude: number;
        count: number;
        siteIds: string[];
      }>
    >`
      SELECT
        CONCAT(FLOOR(("latitude" + 90.0) * ${bucketDivisor}), ':', FLOOR(("longitude" + 180.0) * ${bucketDivisor})) AS "clusterKey",
        md5(string_agg(${idCol}::text, '|' ORDER BY ${idCol}::text)) AS "clusterId",
        AVG("latitude")::float AS "latitude",
        AVG("longitude")::float AS "longitude",
        COUNT(*)::int AS "count",
        ARRAY_AGG(${idCol} ORDER BY ${flags.mapUseProjection ? Prisma.sql`"siteUpdatedAt"` : Prisma.sql`"updatedAt"`} DESC) AS "siteIds"
      FROM ${table}
      WHERE ${geoWhere}
        ${hotProjectionFilter}
        ${statusFragment}
        ${archivedFilter}
      GROUP BY 1
      ORDER BY "count" DESC
      LIMIT 400
    `;
  }

  async findHeatmap(
    query: ListSitesMapQueryDto,
    zoom: number,
  ): Promise<Array<{ cellKey: string; latitude: number; longitude: number; intensity: number }>> {
    const flags = loadFeatureFlags();
    const bucketDivisor = Math.max(10, Math.floor(30 - zoom));
    const bounds = resolveMapSiteBounds(query, this.validator);
    const statusFragment = query.status ? Prisma.sql`AND "status" = ${query.status}::"SiteStatus"` : Prisma.empty;
    const includeArchived = query.includeArchived === true;
    const archivedFilter = includeArchived ? Prisma.empty : Prisma.sql`AND "isArchivedByAdmin" = false`;
    const hotProjectionFilter = flags.mapUseProjection
      ? Prisma.sql`AND "isHot" = true`
      : Prisma.empty;
    const table = flags.mapUseProjection
      ? Prisma.sql`"MapSiteProjection"`
      : Prisma.sql`"Site"`;

    const usePostgis = flags.mapPostgisEnabled;
    const geoWhere = usePostgis
      ? Prisma.sql`ST_Intersects(
          "geo",
          ST_MakeEnvelope(${bounds.minLng}, ${bounds.minLat}, ${bounds.maxLng}, ${bounds.maxLat}, 4326)::geography
        )`
      : Prisma.sql`"latitude" BETWEEN ${bounds.minLat} AND ${bounds.maxLat}
        AND "longitude" BETWEEN ${bounds.minLng} AND ${bounds.maxLng}`;

    return this.prisma.$queryRaw<
      Array<{ cellKey: string; latitude: number; longitude: number; intensity: number }>
    >`
      SELECT
        CONCAT(FLOOR(("latitude" + 90.0) * ${bucketDivisor}), ':', FLOOR(("longitude" + 180.0) * ${bucketDivisor})) AS "cellKey",
        AVG("latitude")::float AS "latitude",
        AVG("longitude")::float AS "longitude",
        COUNT(*)::int AS "intensity"
      FROM ${table}
      WHERE ${geoWhere}
        ${hotProjectionFilter}
        ${statusFragment}
        ${archivedFilter}
      GROUP BY 1
      ORDER BY "intensity" DESC
      LIMIT 1200
    `;
  }
}
