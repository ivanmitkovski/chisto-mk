import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { computeMvtTileEtag, latToTileY, lonToTileX } from './map-mvt-tile-screen.util';
import { tile2lat, tile2lon } from './map-mvt-tile-bounds.util';
import { encodeMvt } from './map-mvt-wireformat';
import type { MvtTileResult } from './map-mvt-tiles.types';

interface FallbackSiteRow {
  siteId: string;
  latitude: number;
  longitude: number;
  status: string;
  pollutionCategory: string | null;
  isHot: boolean;
  siteUpdatedAt: Date;
}

interface ClusterRow {
  clusterKey: string;
  latitude: number;
  longitude: number;
  count: number;
}

@Injectable()
export class MapMvtTilesFallbackService {
  constructor(private readonly prisma: PrismaService) {}

  async generateTile(z: number, x: number, y: number): Promise<MvtTileResult> {
    const minLon = tile2lon(x, z);
    const maxLon = tile2lon(x + 1, z);
    const maxLat = tile2lat(y, z);
    const minLat = tile2lat(y + 1, z);

    if (z >= 13) {
      const sites = await this.prisma.$queryRaw<FallbackSiteRow[]>(Prisma.sql`
        SELECT
          "siteId",
          "latitude"::float AS "latitude",
          "longitude"::float AS "longitude",
          "status",
          "pollutionCategory",
          "isHot",
          "siteUpdatedAt"
        FROM "MapSiteProjection"
        WHERE "latitude" BETWEEN ${minLat} AND ${maxLat}
          AND "longitude" BETWEEN ${minLon} AND ${maxLon}
          AND "isArchivedByAdmin" = false
      `);

      const maxUpdated = sites.reduce<Date | null>(
        (max, s) => (!max || s.siteUpdatedAt > max ? s.siteUpdatedAt : max),
        null,
      );

      const features = sites.map((s) => ({
        id: s.siteId,
        x: lonToTileX(s.longitude, minLon, maxLon),
        y: latToTileY(s.latitude, minLat, maxLat),
        properties: {
          status: s.status,
          pollutionCategory: s.pollutionCategory ?? '',
          isHot: s.isHot ? 1 : 0,
        },
      }));

      return {
        buffer: encodeMvt('sites', features),
        etag: computeMvtTileEtag(z, x, y, maxUpdated, sites.length),
      };
    }

    const bucketDivisor = Math.max(8, Math.floor(26 - z));
    const clusters = await this.prisma.$queryRaw<ClusterRow[]>(Prisma.sql`
      SELECT
        CONCAT(FLOOR(("latitude" + 90.0) * ${bucketDivisor}), ':', FLOOR(("longitude" + 180.0) * ${bucketDivisor})) AS "clusterKey",
        AVG("latitude")::float AS "latitude",
        AVG("longitude")::float AS "longitude",
        COUNT(*)::int AS "count"
      FROM "MapSiteProjection"
      WHERE "latitude" BETWEEN ${minLat} AND ${maxLat}
        AND "longitude" BETWEEN ${minLon} AND ${maxLon}
        AND "isArchivedByAdmin" = false
      GROUP BY 1
    `);

    const aggResult = await this.prisma.$queryRaw<[{ max_updated: Date | null; cnt: number }]>(Prisma.sql`
      SELECT
        MAX("siteUpdatedAt") AS max_updated,
        COUNT(*)::int AS cnt
      FROM "MapSiteProjection"
      WHERE "latitude" BETWEEN ${minLat} AND ${maxLat}
        AND "longitude" BETWEEN ${minLon} AND ${maxLon}
        AND "isArchivedByAdmin" = false
    `);

    const features = clusters.map((c) => ({
      id: c.clusterKey,
      x: lonToTileX(c.longitude, minLon, maxLon),
      y: latToTileY(c.latitude, minLat, maxLat),
      properties: {
        point_count: c.count,
      },
    }));

    return {
      buffer: encodeMvt('clusters', features),
      etag: computeMvtTileEtag(z, x, y, aggResult[0].max_updated, aggResult[0].cnt),
    };
  }
}
