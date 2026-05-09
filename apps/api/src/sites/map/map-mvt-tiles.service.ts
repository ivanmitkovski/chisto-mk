import { Injectable, NotFoundException } from '@nestjs/common';
import { createHash } from 'crypto';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { loadFeatureFlags } from '../../config/feature-flags';

export interface MvtTileResult {
  buffer: Buffer;
  etag: string;
}

function tile2lon(x: number, z: number): number {
  return (x / Math.pow(2, z)) * 360 - 180;
}

function tile2lat(y: number, z: number): number {
  const n = Math.PI - (2 * Math.PI * y) / Math.pow(2, z);
  return (180 / Math.PI) * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n)));
}

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
export class MapMvtTilesService {
  constructor(private readonly prisma: PrismaService) {}

  async getTileOrThrow(z: number, x: number, y: number): Promise<MvtTileResult> {
    const flags = loadFeatureFlags();
    if (!flags.mapTileFormatVector) {
      throw new NotFoundException({
        code: 'MAP_MVT_DISABLED',
        message: 'Vector tiles are disabled. Set MAP_TILE_FORMAT_VECTOR=true after CDN wiring.',
        details: { z, x, y },
      });
    }

    if (flags.mapPostgisEnabled) {
      return this.generatePostgisTile(z, x, y);
    }
    return this.generateFallbackTile(z, x, y);
  }

  private async generatePostgisTile(z: number, x: number, y: number): Promise<MvtTileResult> {
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
      etag: this.computeEtag(z, x, y, maxUpdated, rowCount),
    };
  }

  private async generateFallbackTile(z: number, x: number, y: number): Promise<MvtTileResult> {
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
        x: this.lonToTileX(s.longitude, minLon, maxLon),
        y: this.latToTileY(s.latitude, minLat, maxLat),
        properties: {
          status: s.status,
          pollutionCategory: s.pollutionCategory ?? '',
          isHot: s.isHot ? 1 : 0,
        },
      }));

      return {
        buffer: encodeMvt('sites', features),
        etag: this.computeEtag(z, x, y, maxUpdated, sites.length),
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
      x: this.lonToTileX(c.longitude, minLon, maxLon),
      y: this.latToTileY(c.latitude, minLat, maxLat),
      properties: {
        point_count: c.count,
      },
    }));

    return {
      buffer: encodeMvt('clusters', features),
      etag: this.computeEtag(
        z, x, y,
        aggResult[0].max_updated,
        aggResult[0].cnt,
      ),
    };
  }

  private lonToTileX(lon: number, minLon: number, maxLon: number): number {
    const extent = 4096;
    return Math.round(((lon - minLon) / (maxLon - minLon)) * extent);
  }

  private latToTileY(lat: number, minLat: number, maxLat: number): number {
    const extent = 4096;
    return Math.round(((maxLat - lat) / (maxLat - minLat)) * extent);
  }

  private computeEtag(
    z: number,
    x: number,
    y: number,
    maxUpdated: Date | null,
    count: number,
  ): string {
    const payload = `${z}:${x}:${y}:${maxUpdated?.toISOString() ?? 'none'}:${count}`;
    return `"${createHash('md5').update(payload).digest('hex')}"`;
  }
}

// --- Minimal MVT protobuf encoder (spec: https://github.com/mapbox/vector-tile-spec) ---

interface MvtFeature {
  id: string;
  x: number;
  y: number;
  properties: Record<string, string | number>;
}

function encodeMvt(layerName: string, features: MvtFeature[]): Buffer {
  if (features.length === 0) {
    return Buffer.alloc(0);
  }

  const keys: string[] = [];
  const values: (string | number)[] = [];
  const keyIndex = new Map<string, number>();
  const valueIndex = new Map<string | number, number>();

  function getKeyIdx(k: string): number {
    if (keyIndex.has(k)) return keyIndex.get(k)!;
    const idx = keys.length;
    keys.push(k);
    keyIndex.set(k, idx);
    return idx;
  }

  function getValueIdx(v: string | number): number {
    if (valueIndex.has(v)) return valueIndex.get(v)!;
    const idx = values.length;
    values.push(v);
    valueIndex.set(v, idx);
    return idx;
  }

  const encodedFeatures: Buffer[] = [];
  for (const f of features) {
    const tags: number[] = [];
    for (const [k, v] of Object.entries(f.properties)) {
      tags.push(getKeyIdx(k), getValueIdx(v));
    }

    const geomCommands = encodePointGeometry(f.x, f.y);
    const featureBuf = encodeFeatureMessage(tags, geomCommands);
    encodedFeatures.push(featureBuf);
  }

  const encodedKeys = keys.map((k) => encodeStringField(3, k));
  const encodedValues = values.map((v) => encodeValueMessage(v));

  const layerContent = Buffer.concat([
    encodeVarintField(15, 2),
    encodeStringField(1, layerName),
    ...encodedFeatures,
    ...encodedKeys,
    ...encodedValues,
    encodeVarintField(5, 4096),
  ]);

  const layerMsg = encodeLengthDelimited(3, layerContent);
  return layerMsg;
}

function encodePointGeometry(x: number, y: number): number[] {
  const cmdMoveTo = (1 & 0x7) | (1 << 3);
  return [cmdMoveTo, zigzag(x), zigzag(y)];
}

function zigzag(n: number): number {
  return (n << 1) ^ (n >> 31);
}

function encodeFeatureMessage(tags: number[], geometry: number[]): Buffer {
  const parts: Buffer[] = [];

  if (tags.length > 0) {
    const tagBytes = encodePackedVarints(tags);
    parts.push(encodeLengthDelimited(2, tagBytes));
  }

  parts.push(encodeVarintField(3, 1));

  const geomBytes = encodePackedVarints(geometry);
  parts.push(encodeLengthDelimited(4, geomBytes));

  const featureContent = Buffer.concat(parts);
  return encodeLengthDelimited(2, featureContent);
}

function encodeValueMessage(v: string | number): Buffer {
  let inner: Buffer;
  if (typeof v === 'string') {
    inner = encodeStringField(1, v);
  } else if (Number.isInteger(v)) {
    if (v >= 0) {
      inner = encodeVarintField(5, v);
    } else {
      inner = encodeSint64Field(6, v);
    }
  } else {
    inner = encodeDoubleField(3, v);
  }
  return encodeLengthDelimited(4, inner);
}

function encodeVarintField(fieldNumber: number, value: number): Buffer {
  const tag = (fieldNumber << 3) | 0;
  return Buffer.concat([encodeVarint(tag), encodeVarint(value)]);
}

function encodeStringField(fieldNumber: number, value: string): Buffer {
  const tag = (fieldNumber << 3) | 2;
  const strBuf = Buffer.from(value, 'utf-8');
  return Buffer.concat([encodeVarint(tag), encodeVarint(strBuf.length), strBuf]);
}

function encodeLengthDelimited(fieldNumber: number, content: Buffer): Buffer {
  const tag = (fieldNumber << 3) | 2;
  return Buffer.concat([encodeVarint(tag), encodeVarint(content.length), content]);
}

function encodePackedVarints(values: number[]): Buffer {
  const parts = values.map((v) => encodeVarint(v));
  return Buffer.concat(parts);
}

function encodeSint64Field(fieldNumber: number, value: number): Buffer {
  const tag = (fieldNumber << 3) | 0;
  const encoded = (value << 1) ^ (value >> 31);
  return Buffer.concat([encodeVarint(tag), encodeVarint(encoded >>> 0)]);
}

function encodeDoubleField(fieldNumber: number, value: number): Buffer {
  const tag = (fieldNumber << 3) | 1;
  const buf = Buffer.alloc(8);
  buf.writeDoubleLE(value, 0);
  return Buffer.concat([encodeVarint(tag), buf]);
}

function encodeVarint(value: number): Buffer {
  const bytes: number[] = [];
  let v = value >>> 0;
  while (v > 0x7f) {
    bytes.push((v & 0x7f) | 0x80);
    v >>>= 7;
  }
  bytes.push(v & 0x7f);
  return Buffer.from(bytes);
}
