import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma, Site } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { distanceInMeters } from '../common/utils/distance';
import { ObservabilityStore } from '../observability/observability.store';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { ListSitesMapQueryDto } from './dto/list-sites-map-query.dto';

type MapSiteRow = Prisma.SiteGetPayload<{
  select: {
    id: true;
    latitude: true;
    longitude: true;
    address: true;
    description: true;
    status: true;
    createdAt: true;
    updatedAt: true;
    upvotesCount: true;
    commentsCount: true;
    savesCount: true;
    sharesCount: true;
    _count: { select: { reports: true } };
    reports: {
      orderBy: { createdAt: 'desc' };
      take: 1;
      select: {
        title: true;
        description: true;
        mediaUrls: true;
        category: true;
        createdAt: true;
        reportNumber: true;
      };
    };
  };
}>;

type MapSiteLiteRow = Prisma.SiteGetPayload<{
  select: {
    id: true;
    latitude: true;
    longitude: true;
    address: true;
    description: true;
    status: true;
    createdAt: true;
    updatedAt: true;
    reports: {
      orderBy: { createdAt: 'desc' };
      take: 1;
      select: { mediaUrls: true };
    };
  };
}>;

/** JSON row shape for GET /sites/map (full and lite payloads share this envelope). */
type MapListApiRow = Site & {
  reportCount: number;
  latestReportTitle: string | null;
  latestReportDescription: string | null;
  latestReportCategory: string | null;
  latestReportCreatedAt: string | null;
  latestReportNumber: string | null;
  latestReportMediaUrls?: string[];
  upvotesCount: number;
  commentsCount: number;
  savesCount: number;
  sharesCount: number;
  distanceKm?: number;
};

const MAP_SITE_LITE_SELECT = {
  id: true,
  latitude: true,
  longitude: true,
  address: true,
  description: true,
  status: true,
  createdAt: true,
  updatedAt: true,
  reports: {
    orderBy: { createdAt: 'desc' },
    take: 1,
    select: { mediaUrls: true },
  },
} as const;

const MAP_SITE_FIND_SELECT = {
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
  _count: { select: { reports: true } },
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
} as const;

@Injectable()
export class SitesMapQueryService {
  private static readonly MAP_SIGNED_MEDIA_CLIENT_BUFFER_MS = 55 * 60 * 1000;

  private readonly mapCacheTtlMs = 4_000;
  private readonly mapResponseCache = new Map<
    string,
    {
      cachedAt: number;
      value: {
        data: Array<
          Site & {
            reportCount: number;
            latestReportTitle: string | null;
            latestReportDescription: string | null;
            latestReportCategory: string | null;
            latestReportCreatedAt: string | null;
            latestReportNumber: string | null;
            latestReportMediaUrls?: string[];
            upvotesCount: number;
            commentsCount: number;
            savesCount: number;
            sharesCount: number;
            distanceKm?: number;
          }
        >;
        meta: { signedMediaExpiresAt: string };
      };
    }
  >();
  private readonly mapCacheSiteIndex = new Map<string, Set<string>>();
  private postgisMapSupport: boolean | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

  async findAllForMap(query: ListSitesMapQueryDto) {
    const startedAt = Date.now();
    this.validateMapViewportQuery(query);
    const cacheKey = this.buildMapCacheKey(query);
    const cached = this.mapResponseCache.get(cacheKey);
    const nowMs = Date.now();
    if (cached && nowMs - cached.cachedAt <= this.mapCacheTtlMs) {
      ObservabilityStore.recordMapRequest({
        durationMs: Date.now() - startedAt,
        candidatePoolSize: cached.value.data.length,
        cacheHit: true,
      });
      return cached.value;
    }

    const limit = Math.min(Math.max(query.limit, 10), 260);
    const mapTimeoutMs = 4_000;
    const isLite = query.detail === 'lite';
    let sites: MapSiteRow[] | MapSiteLiteRow[];
    let usedPostgisExactGeo = false;
    try {
      const postgisOk = await this.isPostgisMapAvailable();
      if (postgisOk) {
        try {
          sites = await this.withTimeout(
            this.loadMapSitesWithPostgis(query, limit),
            mapTimeoutMs,
            'Map query timed out',
          );
          usedPostgisExactGeo = true;
        } catch {
          sites = await this.withTimeout(
            this.loadMapSitesWithPrismaBounds(query, limit),
            mapTimeoutMs,
            'Map query timed out',
          );
        }
      } else {
        sites = await this.withTimeout(
          this.loadMapSitesWithPrismaBounds(query, limit),
          mapTimeoutMs,
          'Map query timed out',
        );
      }
    } catch (error) {
      if (cached) {
        ObservabilityStore.recordMapRequest({
          durationMs: Date.now() - startedAt,
          candidatePoolSize: cached.value.data.length,
          cacheHit: true,
        });
        return cached.value;
      }
      throw error;
    }

    const data: MapListApiRow[] = (isLite
      ? await this.mapWithConcurrency(sites as MapSiteLiteRow[], 8, async (site) => {
          const firstReport = site.reports[0];
          const signedMedia =
            firstReport != null && firstReport.mediaUrls.length > 0
              ? await this.reportsUploadService.signUrls(firstReport.mediaUrls.slice(0, 1))
              : undefined;
          const distanceKm = this.computeMapDistanceKm(query, site.latitude, site.longitude);
          return {
            id: site.id,
            latitude: site.latitude,
            longitude: site.longitude,
            address: site.address,
            description: site.description,
            status: site.status,
            upvotesCount: 0,
            commentsCount: 0,
            savesCount: 0,
            sharesCount: 0,
            reportCount: firstReport != null ? 1 : 0,
            latestReportTitle: null,
            latestReportDescription: null,
            latestReportCategory: null,
            latestReportCreatedAt: null,
            latestReportNumber: null,
            ...(signedMedia != null && signedMedia.length > 0
              ? { latestReportMediaUrls: signedMedia }
              : {}),
            ...(distanceKm != null ? { distanceKm } : {}),
            createdAt: site.createdAt,
            updatedAt: site.updatedAt,
          } satisfies MapListApiRow;
        })
      : await this.mapWithConcurrency(sites as MapSiteRow[], 8, async (site) => {
          const firstReport = site.reports[0];
          const signedMedia =
            firstReport != null && firstReport.mediaUrls.length > 0
              ? await this.reportsUploadService.signUrls(firstReport.mediaUrls.slice(0, 1))
              : undefined;
          const distanceKm = this.computeMapDistanceKm(query, site.latitude, site.longitude);
          return {
            id: site.id,
            latitude: site.latitude,
            longitude: site.longitude,
            address: site.address,
            description: site.description,
            status: site.status,
            upvotesCount: site.upvotesCount,
            commentsCount: site.commentsCount,
            savesCount: site.savesCount,
            sharesCount: site.sharesCount,
            reportCount: site._count.reports,
            latestReportTitle: firstReport?.title ?? null,
            latestReportDescription: firstReport?.description ?? null,
            latestReportCategory: firstReport?.category ?? null,
            latestReportCreatedAt: firstReport?.createdAt?.toISOString() ?? null,
            latestReportNumber: firstReport?.reportNumber ?? null,
            ...(signedMedia != null && signedMedia.length > 0
              ? { latestReportMediaUrls: signedMedia }
              : {}),
            ...(distanceKm != null ? { distanceKm } : {}),
            createdAt: site.createdAt,
            updatedAt: site.updatedAt,
          } satisfies MapListApiRow;
        })) as MapListApiRow[];

    // Client hint: presigned report media uses ~1h AWS expiry; refresh map before then.
    const signedMediaExpiresAt = new Date(
      Date.now() + SitesMapQueryService.MAP_SIGNED_MEDIA_CLIENT_BUFFER_MS,
    ).toISOString();
    const response = {
      data: usedPostgisExactGeo ? data : this.filterMapRowsToExactRadius(data, query),
      meta: { signedMediaExpiresAt },
    };
    this.mapResponseCache.set(cacheKey, { cachedAt: nowMs, value: response });
    ObservabilityStore.setMapCacheEntries(this.mapResponseCache.size);
    this.indexMapCacheKeySites(
      cacheKey,
      response.data.map((row) => row.id),
    );
    if (this.mapResponseCache.size > 300) {
      const oldestKey = this.mapResponseCache.keys().next().value as string | undefined;
      if (oldestKey) this.removeMapCacheKey(oldestKey);
    }
    ObservabilityStore.recordMapRequest({
      durationMs: Date.now() - startedAt,
      candidatePoolSize: response.data.length,
      cacheHit: false,
    });
    return response;
  }

  private hasMapViewportBounds(query: ListSitesMapQueryDto): boolean {
    return (
      query.minLat != null &&
      query.maxLat != null &&
      query.minLng != null &&
      query.maxLng != null
    );
  }

  private validateMapViewportQuery(query: ListSitesMapQueryDto): void {
    const hasAnyBounds =
      query.minLat != null ||
      query.maxLat != null ||
      query.minLng != null ||
      query.maxLng != null;
    const hasAllBounds = this.hasMapViewportBounds(query);
    if (hasAnyBounds && !hasAllBounds) {
      throw new BadRequestException({
        code: 'INVALID_MAP_VIEWPORT',
        message: 'All map viewport bounds must be provided together.',
      });
    }
    if (hasAllBounds && (query.minLat! > query.maxLat! || query.minLng! > query.maxLng!)) {
      throw new BadRequestException({
        code: 'INVALID_MAP_VIEWPORT',
        message: 'Map viewport bounds are invalid.',
      });
    }
  }

  private buildMapWhere(query: ListSitesMapQueryDto): Prisma.SiteWhereInput {
    const where: Prisma.SiteWhereInput = query.status ? { status: query.status } : {};
    if (this.hasMapViewportBounds(query)) {
      where.latitude = {
        gte: query.minLat!,
        lte: query.maxLat!,
      };
      where.longitude = {
        gte: query.minLng!,
        lte: query.maxLng!,
      };
      return where;
    }

    const radiusMeters = (query.radiusKm ?? 10) * 1000;
    const metersPerDegreeLat = 111_320;
    const deltaLat = radiusMeters / metersPerDegreeLat;
    const metersPerDegreeLng =
      Math.cos((query.lat * Math.PI) / 180) * metersPerDegreeLat || metersPerDegreeLat;
    const deltaLng = radiusMeters / metersPerDegreeLng;
    where.latitude = {
      gte: query.lat - deltaLat,
      lte: query.lat + deltaLat,
    };
    where.longitude = {
      gte: query.lng - deltaLng,
      lte: query.lng + deltaLng,
    };
    return where;
  }

  private async isPostgisMapAvailable(): Promise<boolean> {
    if (this.postgisMapSupport !== null) {
      return this.postgisMapSupport;
    }
    try {
      const rows = await this.prisma.$queryRaw<{ ok: number }[]>`
        SELECT 1::int as ok FROM pg_extension WHERE extname = 'postgis' LIMIT 1
      `;
      this.postgisMapSupport = rows.length > 0;
    } catch {
      this.postgisMapSupport = false;
    }
    return this.postgisMapSupport;
  }

  private async queryMapSiteIdsByPostgis(query: ListSitesMapQueryDto, limit: number): Promise<string[]> {
    const statusFragment = query.status
      ? Prisma.sql`AND s.status = ${query.status}::"SiteStatus"`
      : Prisma.empty;

    if (this.hasMapViewportBounds(query)) {
      const rows = await this.prisma.$queryRaw<{ id: string }[]>`
        SELECT s.id FROM "Site" s
        WHERE s.latitude IS NOT NULL AND s.longitude IS NOT NULL
          AND ST_Within(
            ST_SetSRID(ST_MakePoint(s.longitude, s.latitude), 4326),
            ST_MakeEnvelope(${query.minLng}, ${query.minLat}, ${query.maxLng}, ${query.maxLat}, 4326)
          )
          ${statusFragment}
        ORDER BY ST_Distance(
          ST_SetSRID(ST_MakePoint(s.longitude, s.latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${query.lng}, ${query.lat}), 4326)::geography
        ) ASC NULLS LAST,
        s.id ASC
        LIMIT ${limit}
      `;
      return rows.map((r) => r.id);
    }

    const radiusMeters = (query.radiusKm ?? 10) * 1000;
    const rows = await this.prisma.$queryRaw<{ id: string }[]>`
      SELECT s.id FROM "Site" s
      WHERE s.latitude IS NOT NULL AND s.longitude IS NOT NULL
        AND ST_DWithin(
          ST_SetSRID(ST_MakePoint(s.longitude, s.latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${query.lng}, ${query.lat}), 4326)::geography,
          ${radiusMeters}
        )
        ${statusFragment}
      ORDER BY ST_Distance(
        ST_SetSRID(ST_MakePoint(s.longitude, s.latitude), 4326)::geography,
        ST_SetSRID(ST_MakePoint(${query.lng}, ${query.lat}), 4326)::geography
      ) ASC NULLS LAST,
      s.id ASC
      LIMIT ${limit}
    `;
    return rows.map((r) => r.id);
  }

  private mapSiteSelectForQuery(query: ListSitesMapQueryDto) {
    return query.detail === 'lite' ? MAP_SITE_LITE_SELECT : MAP_SITE_FIND_SELECT;
  }

  private async loadMapSitesWithPostgis(
    query: ListSitesMapQueryDto,
    limit: number,
  ): Promise<MapSiteRow[] | MapSiteLiteRow[]> {
    const ids = await this.queryMapSiteIdsByPostgis(query, limit);
    if (ids.length === 0) {
      return [];
    }
    const select = this.mapSiteSelectForQuery(query);
    const unsorted = await this.prisma.site.findMany({
      where: { id: { in: ids } },
      select,
    });
    const rank = new Map(ids.map((id, i) => [id, i]));
    return [...unsorted].sort((a, b) => (rank.get(a.id) ?? 0) - (rank.get(b.id) ?? 0)) as
      | MapSiteRow[]
      | MapSiteLiteRow[];
  }

  private async loadMapSitesWithPrismaBounds(
    query: ListSitesMapQueryDto,
    limit: number,
  ): Promise<MapSiteRow[] | MapSiteLiteRow[]> {
    const where = this.buildMapWhere(query);
    const select = this.mapSiteSelectForQuery(query);
    const rows = await this.prisma.site.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit,
      select,
    });
    return rows as MapSiteRow[] | MapSiteLiteRow[];
  }

  private computeMapDistanceKm(
    query: ListSitesMapQueryDto,
    latitude: number | null,
    longitude: number | null,
  ): number | undefined {
    if (latitude == null || longitude == null) {
      return undefined;
    }
    return distanceInMeters(query.lat, query.lng, latitude, longitude) / 1000;
  }

  private filterMapRowsToExactRadius<
    T extends { id: string; latitude: number | null; longitude: number | null; distanceKm?: number },
  >(rows: T[], query: ListSitesMapQueryDto): T[] {
    const radiusMeters = (query.radiusKm ?? 10) * 1000;
    return rows.filter((row) => {
      if (this.hasMapViewportBounds(query)) {
        return (
          row.latitude != null &&
          row.longitude != null &&
          row.latitude >= query.minLat! &&
          row.latitude <= query.maxLat! &&
          row.longitude >= query.minLng! &&
          row.longitude <= query.maxLng!
        );
      }
      if (row.distanceKm == null) {
        return false;
      }
      return row.distanceKm * 1000 <= radiusMeters;
    });
  }

  private buildMapCacheKey(query: ListSitesMapQueryDto): string {
    return [
      query.detail ?? 'full',
      query.status ?? '',
      query.limit,
      query.radiusKm.toFixed(1),
      query.lat.toFixed(4),
      query.lng.toFixed(4),
      query.minLat?.toFixed(4) ?? '',
      query.maxLat?.toFixed(4) ?? '',
      query.minLng?.toFixed(4) ?? '',
      query.maxLng?.toFixed(4) ?? '',
    ].join('|');
  }

  private indexMapCacheKeySites(cacheKey: string, siteIds: string[]): void {
    for (const siteId of siteIds) {
      const set = this.mapCacheSiteIndex.get(siteId) ?? new Set<string>();
      set.add(cacheKey);
      this.mapCacheSiteIndex.set(siteId, set);
    }
  }

  private removeMapCacheKey(cacheKey: string): void {
    const cached = this.mapResponseCache.get(cacheKey);
    if (cached) {
      for (const row of cached.value.data) {
        const keys = this.mapCacheSiteIndex.get(row.id);
        if (!keys) continue;
        keys.delete(cacheKey);
        if (keys.size === 0) this.mapCacheSiteIndex.delete(row.id);
      }
    }
    this.mapResponseCache.delete(cacheKey);
    ObservabilityStore.setMapCacheEntries(this.mapResponseCache.size);
  }

  invalidateMapCache(reason: string, siteId?: string): void {
    ObservabilityStore.recordFeedCacheInvalidation(`map_${reason}`);
    if (siteId) {
      const keys = this.mapCacheSiteIndex.get(siteId);
      if (keys && keys.size > 0) {
        for (const key of [...keys]) {
          this.removeMapCacheKey(key);
        }
        this.mapCacheSiteIndex.delete(siteId);
        return;
      }
    }
    this.mapResponseCache.clear();
    this.mapCacheSiteIndex.clear();
    ObservabilityStore.setMapCacheEntries(0);
  }

  private async withTimeout<T>(promise: Promise<T>, timeoutMs: number, message: string): Promise<T> {
    let timer: NodeJS.Timeout | null = null;
    try {
      return await Promise.race<T>([
        promise,
        new Promise<T>((_, reject) => {
          timer = setTimeout(() => reject(new Error(message)), timeoutMs);
        }),
      ]);
    } finally {
      if (timer) clearTimeout(timer);
    }
  }

  private async mapWithConcurrency<T, R>(
    input: T[],
    concurrency: number,
    mapper: (item: T) => Promise<R>,
  ): Promise<R[]> {
    const results = new Array<R>(input.length);
    let cursor = 0;
    const workers = Array.from({ length: Math.max(1, concurrency) }, async () => {
      while (true) {
        const index = cursor++;
        if (index >= input.length) break;
        results[index] = await mapper(input[index]);
      }
    });
    await Promise.all(workers);
    return results;
  }
}
