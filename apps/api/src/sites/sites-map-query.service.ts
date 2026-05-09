import { Injectable } from '@nestjs/common';
import { loadFeatureFlags } from '../config/feature-flags';
import { ListSitesMapQueryDto } from './dto/list-sites-map-query.dto';
import { MapCacheService } from './map/map-cache.service';
import { MapObservabilityService } from './map/map-observability.service';
import { MapQueryValidatorService } from './map/map-query-validator.service';
import { MapResponseProjectorService } from './map/map-response-projector.service';
import { MapSiteRepositoryService } from './map/map-site-repository.service';

const flags = loadFeatureFlags();

function zoomBucketFromZoom(z: number): 'z_le_8' | 'z_9_12' | 'z_ge_13' {
  if (z <= 8) return 'z_le_8';
  if (z <= 12) return 'z_9_12';
  return 'z_ge_13';
}

@Injectable()
export class SitesMapQueryService {
  constructor(
    private readonly validator: MapQueryValidatorService,
    private readonly cache: MapCacheService,
    private readonly metrics: MapObservabilityService,
    private readonly repository: MapSiteRepositoryService,
    private readonly projector: MapResponseProjectorService,
  ) {}

  async findAllForMap(query: ListSitesMapQueryDto) {
    const startedAt = Date.now();
    this.validator.validateQuery(query);
    const zoom = query.zoom ?? 11;
    const zoomBucket = zoomBucketFromZoom(zoom);
    const tier: 'low' | 'mid' | 'high' = zoom <= 8 ? 'low' : zoom <= 12 ? 'mid' : 'high';
    this.metrics.recordZoomTier(tier);

    const dynamicLimit = tier === 'low' ? 40 : tier === 'mid' ? 80 : Math.min(Math.max(query.limit, 10), 260);
    const cacheKey = this.cache.buildCacheKey([
      query.detail ?? 'full',
      query.status ?? '',
      query.includeArchived ? '1' : '0',
      query.prefetch ? 'prefetch' : 'live',
      dynamicLimit,
      query.radiusKm.toFixed(1),
      query.lat.toFixed(4),
      query.lng.toFixed(4),
      query.minLat?.toFixed(4) ?? '',
      query.maxLat?.toFixed(4) ?? '',
      query.minLng?.toFixed(4) ?? '',
      query.maxLng?.toFixed(4) ?? '',
      zoom,
      tier,
    ]);

    const memoryCached = flags.mapCacheEnabled ? this.cache.getFromMemory(cacheKey) : null;
    if (memoryCached) {
      this.metrics.recordRequest({
        durationMs: Date.now() - startedAt,
        candidatePoolSize: memoryCached.data.length,
        cacheHit: true,
        mode: 'sites',
        zoomBucket,
      });
      return memoryCached;
    }

    const redisCached = flags.mapCacheEnabled ? await this.cache.getFromRedis(cacheKey) : null;
    if (redisCached) {
      await this.cache.set(cacheKey, redisCached);
      this.metrics.recordRequest({
        durationMs: Date.now() - startedAt,
        candidatePoolSize: redisCached.data.length,
        cacheHit: true,
        mode: 'sites',
        zoomBucket,
      });
      return redisCached;
    }

    const fetched = await this.repository.findSites(query, dynamicLimit);

    const response = await this.projector.buildResponse({
      query,
      rows: fetched.rows,
      usedViewportBbox: fetched.usedViewportBbox,
      mapMode: tier === 'low' ? 'clusters' : tier === 'mid' ? 'mixed' : 'sites',
    });

    if (flags.mapCacheEnabled) {
      await this.cache.set(cacheKey, response);
    }

    this.metrics.recordRequest({
      durationMs: Date.now() - startedAt,
      candidatePoolSize: response.data.length,
      cacheHit: false,
      servedFromFallback: fetched.usedFallback,
      mode: 'sites',
      zoomBucket,
    });
    return response;
  }

  async resolveMapDataVersion(query: ListSitesMapQueryDto): Promise<string> {
    this.validator.validateQuery(query);
    const zoom = query.zoom ?? 11;
    const tier: 'low' | 'mid' | 'high' = zoom <= 8 ? 'low' : zoom <= 12 ? 'mid' : 'high';
    const dynamicLimit =
      tier === 'low' ? 40 : tier === 'mid' ? 80 : Math.min(Math.max(query.limit, 10), 260);
    const cacheKey = this.cache.buildCacheKey([
      query.detail ?? 'full',
      query.status ?? '',
      query.includeArchived ? '1' : '0',
      query.prefetch ? 'prefetch' : 'live',
      dynamicLimit,
      query.radiusKm.toFixed(1),
      query.lat.toFixed(4),
      query.lng.toFixed(4),
      query.minLat?.toFixed(4) ?? '',
      query.maxLat?.toFixed(4) ?? '',
      query.minLng?.toFixed(4) ?? '',
      query.maxLng?.toFixed(4) ?? '',
      zoom,
      tier,
    ]);
    const memoryCached = flags.mapCacheEnabled ? this.cache.getFromMemory(cacheKey) : null;
    if (memoryCached) {
      return memoryCached.meta.dataVersion;
    }
    const redisCached = flags.mapCacheEnabled ? await this.cache.getFromRedis(cacheKey) : null;
    if (redisCached) {
      return redisCached.meta.dataVersion;
    }
    return this.repository.resolveDataVersion(query);
  }

  async findClustersForMap(query: ListSitesMapQueryDto): Promise<{
    data: Array<{
      clusterKey: string;
      clusterId: string;
      latitude: number;
      longitude: number;
      count: number;
      siteIds: string[];
    }>;
    meta: { serverTime: string; zoom: number };
  }> {
    const startedAt = Date.now();
    this.validator.validateQuery(query);
    const zoom = query.zoom ?? 11;
    const zoomBucket = zoomBucketFromZoom(zoom);
    this.metrics.recordZoomTier(zoom <= 8 ? 'low' : zoom <= 12 ? 'mid' : 'high');
    const rows = await this.repository.findClusters(query, zoom);
    this.metrics.recordRequest({
      durationMs: Date.now() - startedAt,
      candidatePoolSize: rows.length,
      cacheHit: false,
      mode: 'clusters',
      zoomBucket,
    });
    return {
      data: rows,
      meta: { serverTime: new Date().toISOString(), zoom },
    };
  }

  async findHeatmapForMap(query: ListSitesMapQueryDto): Promise<{
    data: Array<{ cellKey: string; latitude: number; longitude: number; intensity: number }>;
    meta: { serverTime: string; zoom: number };
  }> {
    const startedAt = Date.now();
    this.validator.validateQuery(query);
    const zoom = query.zoom ?? 11;
    const zoomBucket = zoomBucketFromZoom(zoom);
    this.metrics.recordZoomTier(zoom <= 8 ? 'low' : zoom <= 12 ? 'mid' : 'high');
    const rows = await this.repository.findHeatmap(query, zoom);
    this.metrics.recordRequest({
      durationMs: Date.now() - startedAt,
      candidatePoolSize: rows.length,
      cacheHit: false,
      mode: 'heatmap',
      zoomBucket,
    });
    return {
      data: rows,
      meta: { serverTime: new Date().toISOString(), zoom },
    };
  }

  invalidateMapCache(reason: string, siteId?: string): void {
    void this.cache.invalidate(reason, siteId);
  }
}
