import { legacySnapshotGauges } from '../util/prom-registry';
import { p95Ms, trimRollingBuffer } from './percentile.util';

let mapRequestsTotal = 0;
let mapCacheHits = 0;
const mapCacheInvalidationCounts: Record<string, number> = {};
let mapFallbackResponses = 0;
let mapDurationsMs: number[] = [];
let mapCandidatePoolSizes: number[] = [];
let mapSseConnectionsTotal = 0;
let mapSseConnectionsActive = 0;
let mapSseReconnectHints = 0;
let mapSseEventsEmitted = 0;
let mapSseReplayEvents = 0;
let mapCacheEntries = 0;
let mapOutboxDispatched = 0;
let mapOutboxFailed = 0;
let mapOutboxLagMs = 0;
let mapProjectionRowsTotal = 0;
let mapProjectionHotRows = 0;
let mapProjectionStalenessSeconds = 0;
let mapColdSitesArchivedTotal = 0;
let mapOutboxRowsPurgedTotal = 0;
let mapOutboxPendingGauge = 0;
const mapZoomTierRequests: Record<string, number> = {};
const mapDurationByModeZoom: Record<string, number[]> = {};
const mapRequestsByMode: Record<string, number> = {};
const mapCacheHitsByMode: Record<string, number> = {};
let mapQueryRowCounts: number[] = [];

export function recordMapRequest(input: {
  durationMs: number;
  candidatePoolSize: number;
  cacheHit: boolean;
  servedFromFallback?: boolean;
  mode?: 'sites' | 'clusters' | 'heatmap';
  zoomBucket?: 'z_le_8' | 'z_9_12' | 'z_ge_13';
}): void {
  mapRequestsTotal += 1;
  if (input.cacheHit) mapCacheHits += 1;
  if (input.servedFromFallback) mapFallbackResponses += 1;
  mapDurationsMs.push(input.durationMs);
  mapCandidatePoolSizes.push(input.candidatePoolSize);
  mapDurationsMs = trimRollingBuffer(mapDurationsMs);
  mapCandidatePoolSizes = trimRollingBuffer(mapCandidatePoolSizes);
  const mode = input.mode ?? 'sites';
  const bucket = input.zoomBucket ?? 'z_9_12';
  const sliceKey = `${mode}:${bucket}`;
  mapRequestsByMode[sliceKey] = (mapRequestsByMode[sliceKey] ?? 0) + 1;
  if (input.cacheHit) {
    mapCacheHitsByMode[sliceKey] = (mapCacheHitsByMode[sliceKey] ?? 0) + 1;
  }
  const slice = mapDurationByModeZoom[sliceKey] ?? [];
  slice.push(input.durationMs);
  mapDurationByModeZoom[sliceKey] = slice.length > 800 ? slice.slice(-500) : slice;
}

export function recordMapSseConnected(): void {
  mapSseConnectionsTotal += 1;
  mapSseConnectionsActive += 1;
}

export function recordMapSseDisconnected(): void {
  mapSseConnectionsActive = Math.max(0, mapSseConnectionsActive - 1);
}

export function recordMapSseReconnectHint(): void {
  mapSseReconnectHints += 1;
}

export function recordMapSseEventEmitted(): void {
  mapSseEventsEmitted += 1;
}

export function recordMapSseReplayEvents(count: number): void {
  mapSseReplayEvents += Math.max(0, count);
}

export function setMapCacheEntries(size: number): void {
  mapCacheEntries = Math.max(0, size);
}

export function recordMapCacheInvalidation(reason: string): void {
  const key = reason || 'unknown';
  mapCacheInvalidationCounts[key] = (mapCacheInvalidationCounts[key] ?? 0) + 1;
}

export function recordMapOutboxDispatch(input: { failed: boolean; lagMs: number }): void {
  if (input.failed) {
    mapOutboxFailed += 1;
    legacySnapshotGauges.mapOutboxFailed.set(mapOutboxFailed);
  } else {
    mapOutboxDispatched += 1;
  }
  mapOutboxLagMs = Math.max(0, input.lagMs);
}

export function recordMapProjectionSnapshot(input: {
  rowsTotal: number;
  hotRows: number;
  stalenessSeconds: number;
}): void {
  mapProjectionRowsTotal = Math.max(0, input.rowsTotal);
  mapProjectionHotRows = Math.max(0, input.hotRows);
  mapProjectionStalenessSeconds = Math.max(0, input.stalenessSeconds);
}

export function recordMapProjectionHotRefresh(changedRows: number): void {
  mapColdSitesArchivedTotal += Math.max(0, changedRows);
}

export function recordMapOutboxRowsPurged(count: number): void {
  mapOutboxRowsPurgedTotal += Math.max(0, count);
}

export function setMapOutboxPendingCount(count: number): void {
  mapOutboxPendingGauge = Math.max(0, Math.floor(count));
}

export function recordMapZoomTierRequest(tier: 'low' | 'mid' | 'high'): void {
  mapZoomTierRequests[tier] = (mapZoomTierRequests[tier] ?? 0) + 1;
}

export function recordMapQueryRowCount(count: number): void {
  mapQueryRowCounts.push(Math.max(0, count));
  mapQueryRowCounts = trimRollingBuffer(mapQueryRowCounts);
}

export function snapshot() {
  return {
    mapRequestsTotal,
    mapCacheHits,
    mapFallbackResponses,
    mapCacheHitRate:
      mapRequestsTotal > 0 ? Number((mapCacheHits / mapRequestsTotal).toFixed(4)) : 0,
    mapP95Ms: p95Ms(mapDurationsMs),
    mapDurationBuckets: {
      le100: mapDurationsMs.filter((ms) => ms <= 100).length,
      le250: mapDurationsMs.filter((ms) => ms <= 250).length,
      le500: mapDurationsMs.filter((ms) => ms <= 500).length,
      le1000: mapDurationsMs.filter((ms) => ms <= 1000).length,
      gt1000: mapDurationsMs.filter((ms) => ms > 1000).length,
    },
    mapAvgCandidatePoolSize:
      mapCandidatePoolSizes.length > 0
        ? Number(
            (
              mapCandidatePoolSizes.reduce((acc, v) => acc + v, 0) / mapCandidatePoolSizes.length
            ).toFixed(2),
          )
        : 0,
    mapSseConnectionsTotal,
    mapSseConnectionsActive,
    mapSseReconnectHints,
    mapSseEventsEmitted,
    mapSseReplayEvents,
    mapCacheEntries,
    mapCacheInvalidationCounts,
    mapOutboxDispatched,
    mapOutboxFailed,
    mapOutboxLagMs,
    mapProjectionRowsTotal,
    mapProjectionHotRows,
    mapProjectionStalenessSeconds,
    mapColdSitesArchivedTotal,
    mapOutboxRowsPurgedTotal,
    mapZoomTierRequests,
    mapAvgQueryRowCount:
      mapQueryRowCounts.length > 0
        ? Number(
            (mapQueryRowCounts.reduce((acc, v) => acc + v, 0) / mapQueryRowCounts.length).toFixed(
              2,
            ),
          )
        : 0,
    mapRequestsByModeZoom: { ...mapRequestsByMode },
    mapCacheHitsByModeZoom: { ...mapCacheHitsByMode },
    mapModeZoomLatencyP95Ms: Object.fromEntries(
      Object.entries(mapDurationByModeZoom).map(([k, values]) => [k, p95Ms(values)]),
    ),
    mapOutboxPending: mapOutboxPendingGauge,
  };
}
