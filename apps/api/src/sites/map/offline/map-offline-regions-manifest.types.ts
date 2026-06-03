import type { OfflineMapRegionDefinition } from './offline-map-regions.config';

export type MapOfflineRegionsManifestResponse = {
  manifestVersion: string;
  generatedAt: string;
  regions: Array<{
    id: string;
    label: string;
    version: number;
    checksumSha256: string;
    bounds: OfflineMapRegionDefinition['bounds'];
    packageSizeBytes?: number;
    updatedAt: string;
  }>;
};

export type MapOfflineRegionDownloadUrlResponse = {
  regionId: string;
  version: number;
  checksumSha256: string;
  downloadUrl: string;
  expiresInSeconds: number;
  expiresAt: string;
};
