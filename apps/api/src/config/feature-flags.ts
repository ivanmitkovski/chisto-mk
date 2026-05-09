export interface FeatureFlags {
  mapEtagEnabled: boolean;
  mapSseEnabled: boolean;
  mapCacheEnabled: boolean;
  mapUseProjection: boolean;
  mapPostgisEnabled: boolean;
  mapTileFormatVector: boolean;
  mapSearchTypesense: boolean;
  mapAdminTimeMachine: boolean;
  mapOfflineRegions: boolean;
}

function isTestRuntime(): boolean {
  return (
    process.env.NODE_ENV === 'test' ||
    Boolean(process.env.JEST_WORKER_ID) ||
    Boolean(process.env.VITEST)
  );
}

export function loadFeatureFlags(): FeatureFlags {
  const test = isTestRuntime();
  return {
    mapEtagEnabled: envBool('MAP_ETAG_ENABLED', true),
    mapSseEnabled: envBool('MAP_SSE_ENABLED', true),
    mapCacheEnabled: envBool('MAP_CACHE_ENABLED', true),
    /** Default on in non-test runtimes; Jest/Vitest keep projection off unless overridden. */
    mapUseProjection: envBool('MAP_USE_PROJECTION', !test),
    mapPostgisEnabled: envBool('MAP_POSTGIS_ENABLED', false),
    mapTileFormatVector: envBool('MAP_TILE_FORMAT_VECTOR', false),
    mapSearchTypesense: envBool('MAP_SEARCH_TYPESENSE', false),
    mapAdminTimeMachine: envBool('MAP_ADMIN_TIME_MACHINE', false),
    mapOfflineRegions: envBool('MAP_OFFLINE_REGIONS', false),
  };
}

function envBool(key: string, defaultValue: boolean): boolean {
  const raw = process.env[key]?.toLowerCase().trim();
  if (raw === 'true' || raw === '1') return true;
  if (raw === 'false' || raw === '0') return false;
  return defaultValue;
}
