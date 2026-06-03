import { loadFeatureFlags } from '../../../config/feature-flags';

export type OfflineMapRegionBounds = {
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
};

export type OfflineMapRegionDefinition = {
  id: string;
  label: string;
  version: number;
  checksumSha256: string;
  bounds: OfflineMapRegionBounds;
  packageSizeBytes?: number;
  s3Key: string;
  updatedAt: string;
};

export type OfflineMapRegionsConfig = {
  enabled: boolean;
  s3Prefix: string;
  manifestS3Key: string | null;
  manifestJson: OfflineMapRegionDefinition[] | null;
  downloadTtlSeconds: number;
};

export function loadOfflineMapRegionsConfig(): OfflineMapRegionsConfig {
  const flags = loadFeatureFlags();
  const prefixRaw = process.env.MAP_OFFLINE_REGIONS_S3_PREFIX?.trim() || 'map-offline/regions/';
  const s3Prefix = prefixRaw.endsWith('/') ? prefixRaw : `${prefixRaw}/`;
  const manifestKeyRaw = process.env.MAP_OFFLINE_REGIONS_MANIFEST_S3_KEY?.trim();
  const manifestS3Key =
    manifestKeyRaw && manifestKeyRaw.length > 0
      ? manifestKeyRaw
      : `${s3Prefix}manifest.json`;

  const inlineRaw = process.env.MAP_OFFLINE_REGIONS_MANIFEST_JSON?.trim();
  let manifestJson: OfflineMapRegionDefinition[] | null = null;
  if (inlineRaw) {
    try {
      const parsed = JSON.parse(inlineRaw) as unknown;
      if (Array.isArray(parsed)) {
        manifestJson = parsed as OfflineMapRegionDefinition[];
      }
    } catch {
      manifestJson = null;
    }
  }

  const ttlRaw = process.env.MAP_OFFLINE_REGIONS_DOWNLOAD_TTL_SECONDS?.trim();
  const ttlParsed = ttlRaw ? Number.parseInt(ttlRaw, 10) : 3600;
  const downloadTtlSeconds =
    Number.isFinite(ttlParsed) && ttlParsed >= 60 && ttlParsed <= 86400 ? ttlParsed : 3600;

  return {
    enabled: flags.mapOfflineRegions,
    s3Prefix,
    manifestS3Key,
    manifestJson,
    downloadTtlSeconds,
  };
}
