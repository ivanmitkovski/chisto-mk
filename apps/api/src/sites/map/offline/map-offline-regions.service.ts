import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import {
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { S3StorageClient } from '../../../storage/util/s3-storage.client';
import {
  loadOfflineMapRegionsConfig,
  type OfflineMapRegionDefinition,
  type OfflineMapRegionsConfig,
} from './offline-map-regions.config';
import type {
  MapOfflineRegionDownloadUrlResponse,
  MapOfflineRegionsManifestResponse,
} from './map-offline-regions-manifest.types';

@Injectable()
export class MapOfflineRegionsService {
  private readonly logger = new Logger(MapOfflineRegionsService.name);
  private cfg: OfflineMapRegionsConfig = loadOfflineMapRegionsConfig();
  private manifestCache: { expiresAt: number; regions: OfflineMapRegionDefinition[] } | null =
    null;
  private static readonly MANIFEST_CACHE_MS = 60_000;

  constructor(private readonly s3: S3StorageClient) {}

  assertEnabled(): void {
    this.cfg = loadOfflineMapRegionsConfig();
    if (!this.cfg.enabled) {
      throw new NotFoundException({
        code: 'MAP_OFFLINE_REGIONS_DISABLED',
        message:
          'Offline map regions are disabled. Set MAP_OFFLINE_REGIONS=true and configure S3 packages.',
      });
    }
  }

  async getManifest(): Promise<MapOfflineRegionsManifestResponse> {
    this.assertEnabled();
    const regions = await this.loadRegions();
    return {
      manifestVersion: '1',
      generatedAt: new Date().toISOString(),
      regions: regions.map((r) => {
        const entry: MapOfflineRegionsManifestResponse['regions'][number] = {
          id: r.id,
          label: r.label,
          version: r.version,
          checksumSha256: r.checksumSha256,
          bounds: r.bounds,
          updatedAt: r.updatedAt,
        };
        if (r.packageSizeBytes != null) {
          entry.packageSizeBytes = r.packageSizeBytes;
        }
        return entry;
      }),
    };
  }

  async getRegionDownloadUrl(regionId: string): Promise<MapOfflineRegionDownloadUrlResponse> {
    this.assertEnabled();
    const regions = await this.loadRegions();
    const region = regions.find((r) => r.id === regionId);
    if (!region) {
      throw new NotFoundException({
        code: 'MAP_OFFLINE_REGION_NOT_FOUND',
        message: `Offline map region "${regionId}" was not found.`,
      });
    }

    if (!this.s3.enabled) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'Object storage is required for offline region downloads.',
      });
    }

    const client = this.s3.getClientOrNull();
    const bucket = this.s3.bucket;
    if (!client || !bucket) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'Object storage is not configured for this environment.',
      });
    }

    const expiresInSeconds = this.cfg.downloadTtlSeconds;
    const downloadUrl = await getSignedUrl(
      client,
      new GetObjectCommand({
        Bucket: bucket,
        Key: region.s3Key,
      }),
      { expiresIn: expiresInSeconds },
    );

    return {
      regionId: region.id,
      version: region.version,
      checksumSha256: region.checksumSha256,
      downloadUrl,
      expiresInSeconds,
      expiresAt: new Date(Date.now() + expiresInSeconds * 1000).toISOString(),
    };
  }

  private async loadRegions(): Promise<OfflineMapRegionDefinition[]> {
    const now = Date.now();
    if (this.manifestCache && now < this.manifestCache.expiresAt) {
      return this.manifestCache.regions;
    }

    let regions: OfflineMapRegionDefinition[];
    if (this.cfg.manifestJson?.length) {
      regions = this.cfg.manifestJson;
    } else {
      regions = await this.loadManifestFromS3();
    }

    this.manifestCache = { regions, expiresAt: now + MapOfflineRegionsService.MANIFEST_CACHE_MS };
    return regions;
  }

  private async loadManifestFromS3(): Promise<OfflineMapRegionDefinition[]> {
    if (!this.s3.enabled || !this.cfg.manifestS3Key) {
      throw new ServiceUnavailableException({
        code: 'MAP_OFFLINE_MANIFEST_UNAVAILABLE',
        message:
          'Offline map manifest is not configured. Set MAP_OFFLINE_REGIONS_MANIFEST_JSON or upload manifest to S3.',
      });
    }

    const client = this.s3.getClientOrNull();
    const bucket = this.s3.bucket;
    if (!client || !bucket) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'Object storage is not configured for this environment.',
      });
    }

    try {
      const out = await client.send(
        new GetObjectCommand({
          Bucket: bucket,
          Key: this.cfg.manifestS3Key,
        }),
      );
      const body = await out.Body?.transformToString('utf-8');
      if (!body) {
        return [];
      }
      const parsed = JSON.parse(body) as unknown;
      if (!Array.isArray(parsed)) {
        throw new Error('manifest must be a JSON array');
      }
      return parsed as OfflineMapRegionDefinition[];
    } catch (error) {
      this.logger.warn(`Failed to load offline map manifest from S3: ${String(error)}`);
      throw new ServiceUnavailableException({
        code: 'MAP_OFFLINE_MANIFEST_LOAD_FAILED',
        message: 'Failed to load offline map regions manifest.',
      });
    }
  }
}
