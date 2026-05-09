import { getApiBaseUrl } from '@/lib/api';
import { getAdminTokenFromBrowserCookie, refreshAdminAccessTokenInBrowser } from '@/features/auth/lib/admin-auth';
import type { MapClustersResponse, MapEnvelope, MapListApiRow } from '@chisto/map-contracts';

export class MapAdapterError extends Error {
  readonly status: number;
  readonly body: unknown;

  constructor(message: string, options: { status: number; body?: unknown }) {
    super(message);
    this.name = 'MapAdapterError';
    this.status = options.status;
    this.body = options.body;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export type SiteMapRow = MapListApiRow & {
  isCluster?: boolean;
  clusterSiteIds?: string[];
};
type MapResponse = MapEnvelope;

interface CacheEntry {
  etag: string;
  payload: MapResponse;
}

interface ClustersCacheEntry {
  etag: string;
  payload: MapClustersResponse;
}

const etagCache = new Map<string, CacheEntry>();
const clustersEtagCache = new Map<string, ClustersCacheEntry>();
const ETAG_CACHE_MAX_ENTRIES = 200;

function setEtagCache(path: string, entry: CacheEntry): void {
  if (etagCache.has(path)) {
    etagCache.delete(path);
  }
  etagCache.set(path, entry);
  if (etagCache.size <= ETAG_CACHE_MAX_ENTRIES) {
    return;
  }
  const oldestKey = etagCache.keys().next().value as string | undefined;
  if (oldestKey) {
    etagCache.delete(oldestKey);
  }
}

function setClustersEtagCache(path: string, entry: ClustersCacheEntry): void {
  if (clustersEtagCache.has(path)) {
    clustersEtagCache.delete(path);
  }
  clustersEtagCache.set(path, entry);
  if (clustersEtagCache.size <= ETAG_CACHE_MAX_ENTRIES) {
    return;
  }
  const oldestKey = clustersEtagCache.keys().next().value as string | undefined;
  if (oldestKey) {
    clustersEtagCache.delete(oldestKey);
  }
}

/** Clears the in-memory ETag map (Vitest / isolated tests). */
export function clearMapAdapterEtagCacheForTests(): void {
  etagCache.clear();
  clustersEtagCache.clear();
}

async function readErrorBody(response: Response): Promise<unknown> {
  const contentType = response.headers.get('content-type') ?? '';
  if (contentType.includes('application/json')) {
    try {
      return await response.json();
    } catch {
      return null;
    }
  }
  try {
    return await response.text();
  } catch {
    return null;
  }
}

async function fetchWithAuth(
  url: string,
  headers: Record<string, string>,
): Promise<Response> {
  const token = getAdminTokenFromBrowserCookie();
  if (!token) throw new Error('Not signed in');

  const makeRequest = (authToken: string) =>
    fetch(url, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        Authorization: `Bearer ${authToken}`,
        ...headers,
      },
      cache: 'no-store',
    });

  const response = await makeRequest(token);

  if (response.status === 401) {
    const refreshed = await refreshAdminAccessTokenInBrowser();
    if (refreshed) {
      return makeRequest(refreshed);
    }
  }

  return response;
}

export async function fetchSitesForMap(params: {
  lat: number;
  lng: number;
  radiusKm: number;
  zoom?: number;
  detail?: 'full' | 'lite';
  status?: string;
  includeArchived?: boolean;
}): Promise<MapResponse> {
  const search = new URLSearchParams({
    lat: String(params.lat),
    lng: String(params.lng),
    radiusKm: String(params.radiusKm),
    limit: '200',
    detail: params.detail ?? 'lite',
  });
  if (params.zoom != null) {
    search.set('zoom', String(params.zoom));
  }
  if (params.status) {
    search.set('status', params.status);
  }
  if (params.includeArchived) {
    search.set('includeArchived', 'true');
  }

  const path = `/sites/map?${search.toString()}`;
  const url = `${getApiBaseUrl()}${path}`;

  const requestHeaders: Record<string, string> = {};
  const cached = etagCache.get(path);
  if (cached) {
    requestHeaders['If-None-Match'] = cached.etag;
  }

  const response = await fetchWithAuth(url, requestHeaders);

  if (response.status === 304 && cached) {
    return cached.payload;
  }
  if (response.status === 304 && !cached) {
    throw new MapAdapterError('Map 304 without local ETag cache', { status: 304 });
  }

  if (!response.ok) {
    const body = await readErrorBody(response);
    throw new MapAdapterError(`Map fetch failed with status ${response.status}`, {
      status: response.status,
      body,
    });
  }

  const payload: MapResponse = await response.json();

  const etag = response.headers.get('etag');
  if (etag) {
    setEtagCache(path, { etag, payload });
  }

  return payload;
}


export async function fetchClustersForMap(params: {
  lat: number;
  lng: number;
  radiusKm: number;
  zoom?: number;
  status?: string;
  includeArchived?: boolean;
}): Promise<MapClustersResponse> {
  const search = new URLSearchParams({
    lat: String(params.lat),
    lng: String(params.lng),
    radiusKm: String(params.radiusKm),
    limit: '200',
  });
  if (params.zoom != null) {
    search.set('zoom', String(params.zoom));
  }
  if (params.status) {
    search.set('status', params.status);
  }
  if (params.includeArchived) {
    search.set('includeArchived', 'true');
  }

  const path = `/sites/map/clusters?${search.toString()}`;
  const url = `${getApiBaseUrl()}${path}`;

  const requestHeaders: Record<string, string> = {};
  const cached = clustersEtagCache.get(path);
  if (cached) {
    requestHeaders['If-None-Match'] = cached.etag;
  }

  const response = await fetchWithAuth(url, requestHeaders);
  if (response.status === 304 && cached) {
    return cached.payload;
  }
  if (response.status === 304 && !cached) {
    throw new MapAdapterError('Map clusters 304 without local ETag cache', { status: 304 });
  }
  if (!response.ok) {
    const body = await readErrorBody(response);
    throw new MapAdapterError(`Map cluster fetch failed with status ${response.status}`, {
      status: response.status,
      body,
    });
  }
  const raw = (await response.json()) as {
    data: Array<{
      clusterKey?: string;
      clusterId?: string;
      id?: string;
      latitude: number;
      longitude: number;
      count: number;
      siteIds: string[];
    }>;
    meta: { serverTime?: string; zoom?: number };
  };
  const normalized = {
    data: raw.data.map((bucket) => ({
      id:
        bucket.clusterId ??
        bucket.id ??
        bucket.clusterKey ??
        `${bucket.latitude}:${bucket.longitude}`,
      latitude: bucket.latitude,
      longitude: bucket.longitude,
      count: bucket.count,
      siteIds: bucket.siteIds,
    })),
    meta: {
      queryMode: 'viewport',
      dataVersion: `${raw.meta.serverTime ?? Date.now().toString()}:${raw.meta.zoom ?? 'z'}`,
    },
  } satisfies MapClustersResponse;
  const etag = response.headers.get('etag');
  if (etag) {
    setClustersEtagCache(path, { etag, payload: normalized });
  }
  return normalized;
}

let mapBroadcastChannel: BroadcastChannel | null = null;
let mapBroadcastRefCount = 0;

/** Share ETag cache invalidations across admin tabs (same origin). */
export function registerMapAdapterBroadcastSync(): () => void {
  if (typeof window === 'undefined' || typeof BroadcastChannel === 'undefined') {
    return () => undefined;
  }
  if (!mapBroadcastChannel) {
    mapBroadcastChannel = new BroadcastChannel('chisto-map');
    mapBroadcastChannel.onmessage = (ev: MessageEvent<{ type?: string; path?: string }>) => {
      if (ev.data?.type === 'invalidate-path' && ev.data.path) {
        etagCache.delete(ev.data.path);
        clustersEtagCache.delete(ev.data.path);
      }
    };
  }
  mapBroadcastRefCount += 1;
  return () => {
    mapBroadcastRefCount -= 1;
    if (mapBroadcastRefCount <= 0 && mapBroadcastChannel) {
      mapBroadcastChannel.close();
      mapBroadcastChannel = null;
    }
  };
}

export function postMapAdapterInvalidatePath(path: string): void {
  if (typeof window === 'undefined' || typeof BroadcastChannel === 'undefined') {
    return;
  }
  try {
    const ch = new BroadcastChannel('chisto-map');
    ch.postMessage({ type: 'invalidate-path', path });
    ch.close();
  } catch {
    // ignore
  }
}
