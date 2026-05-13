import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { computeMvtTileEtag } from './map-mvt-tile-screen.util';
import { tile2lat, tile2lon } from './map-mvt-tile-bounds.util';
import type { MvtTileResult } from './map-mvt-tiles.types';

@Injectable()
export class MapMvtTilesPostgisService {
  constructor(private readonly prisma: PrismaService) {}

  async generateTile(z: number, x: number, y: number): Promise<MvtTileResult> {
    const minLon = tile2lon(x, z);
    const maxLon = tile2lon(x + 1, z);
    const maxLat = tile2lat(y, z);
    const minLat = tile2lat(y + 1, z);

    let mvtBuffer: Buffer;
    let maxUpdated: Date | null;
    let rowCount: number;

    if (z >= 13) {
      const result = await this.prisma.$queryRaw<[{ mvt: Buffer; max_updated: Date | null; cnt: number }]>`
        WITH tile_sites AS (
          SELECT
            "siteId",
            "status",
            "pollutionCategory",
            "isHot",
            "siteUpdatedAt",
            ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326) AS geom
          FROM "MapSiteProjection"
          WHERE "latitude" BETWEEN ${minLat} AND ${maxLat}
            AND "longitude" BETWEEN ${minLon} AND ${maxLon}
            AND "isArchivedByAdmin" = false
        )
        SELECT
          COALESCE(
            ST_AsMVT(q, 'sites', 4096, 'mvtgeom'),
            ''::bytea
          ) AS mvt,
          (SELECT MAX("siteUpdatedAt") FROM tile_sites) AS max_updated,
          (SELECT COUNT(*)::int FROM tile_sites) AS cnt
        FROM (
          SELECT
            "siteId",
            "status",
            "pollutionCategory",
            "isHot"::int AS "isHot",
            ST_AsMVTGeom(
              geom,
              ST_MakeEnvelope(${minLon}, ${minLat}, ${maxLon}, ${maxLat}, 4326),
              4096, 64, true
            ) AS mvtgeom
          FROM tile_sites
        ) q
        WHERE mvtgeom IS NOT NULL
      `;
      mvtBuffer = Buffer.isBuffer(result[0].mvt)
        ? result[0].mvt
        : Buffer.from(result[0].mvt as unknown as Uint8Array);
      maxUpdated = result[0].max_updated;
      rowCount = result[0].cnt;
    } else {
      const bucketDivisor = Math.max(8, Math.floor(26 - z));
      const result = await this.prisma.$queryRaw<[{ mvt: Buffer; max_updated: Date | null; cnt: number }]>`
        WITH tile_clusters AS (
          SELECT
            AVG("latitude")::float AS lat,
            AVG("longitude")::float AS lon,
            COUNT(*)::int AS point_count,
            MAX("siteUpdatedAt") AS max_upd
          FROM "MapSiteProjection"
          WHERE "latitude" BETWEEN ${minLat} AND ${maxLat}
            AND "longitude" BETWEEN ${minLon} AND ${maxLon}
            AND "isArchivedByAdmin" = false
          GROUP BY
            FLOOR(("latitude" + 90.0) * ${bucketDivisor}),
            FLOOR(("longitude" + 180.0) * ${bucketDivisor})
        )
        SELECT
          COALESCE(
            ST_AsMVT(q, 'clusters', 4096, 'mvtgeom'),
            ''::bytea
          ) AS mvt,
          (SELECT MAX(max_upd) FROM tile_clusters) AS max_updated,
          (SELECT COALESCE(SUM(point_count), 0)::int FROM tile_clusters) AS cnt
        FROM (
          SELECT
            point_count,
            ST_AsMVTGeom(
              ST_SetSRID(ST_MakePoint(lon, lat), 4326),
              ST_MakeEnvelope(${minLon}, ${minLat}, ${maxLon}, ${maxLat}, 4326),
              4096, 64, true
            ) AS mvtgeom
          FROM tile_clusters
        ) q
        WHERE mvtgeom IS NOT NULL
      `;
      mvtBuffer = Buffer.isBuffer(result[0].mvt)
        ? result[0].mvt
        : Buffer.from(result[0].mvt as unknown as Uint8Array);
      maxUpdated = result[0].max_updated;
      rowCount = result[0].cnt;
    }

    return {
      buffer: mvtBuffer,
      etag: computeMvtTileEtag(z, x, y, maxUpdated, rowCount),
    };
  }
}
