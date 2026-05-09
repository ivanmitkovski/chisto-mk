import {
  clearMapAdapterEtagCacheForTests,
  fetchClustersForMap,
  fetchSitesForMap,
  MapAdapterError,
} from './map-adapter';
import { describe, expect, it, vi, beforeEach } from 'vitest';

vi.mock('@/lib/api', () => ({
  getApiBaseUrl: () => 'http://localhost:3000/api',
}));

const { refreshMock } = vi.hoisted(() => ({
  refreshMock: vi.fn(async () => null),
}));
vi.mock('@/features/auth/lib/admin-auth', () => ({
  getAdminTokenFromBrowserCookie: () => 'test-token',
  refreshAdminAccessTokenInBrowser: refreshMock,
}));

const mockPayload = {
  data: [],
  meta: { signedMediaExpiresAt: '2026-01-01T00:00:00.000Z' },
};

beforeEach(() => {
  vi.restoreAllMocks();
  clearMapAdapterEtagCacheForTests();
  global.fetch = vi.fn();
});

describe('fetchSitesForMap', () => {
  it('builds map endpoint query with required params', async () => {
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      status: 200,
      headers: new Headers(),
      json: async () => mockPayload,
    });

    const result = await fetchSitesForMap({
      lat: 41.99,
      lng: 21.43,
      radiusKm: 20,
      status: 'REPORTED',
    });

    expect(result).toMatchObject({
      data: [],
      meta: expect.objectContaining({ signedMediaExpiresAt: expect.any(String) }),
    });

    expect(global.fetch).toHaveBeenCalledWith(
      'http://localhost:3000/api/sites/map?lat=41.99&lng=21.43&radiusKm=20&limit=200&detail=lite&status=REPORTED',
      expect.objectContaining({
        method: 'GET',
        headers: expect.objectContaining({
          Authorization: 'Bearer test-token',
        }),
      }),
    );
  });

  it('sends If-None-Match on subsequent requests and returns cached payload on 304', async () => {
    const etag = '"abc123"';

    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: true,
      status: 200,
      headers: new Headers({ etag }),
      json: async () => mockPayload,
    });

    await fetchSitesForMap({ lat: 41.0, lng: 21.0, radiusKm: 10 });

    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: false,
      status: 304,
      headers: new Headers(),
      json: async () => null,
    });

    const cached = await fetchSitesForMap({ lat: 41.0, lng: 21.0, radiusKm: 10 });

    expect(cached).toEqual(mockPayload);

    const secondCall = (global.fetch as ReturnType<typeof vi.fn>).mock.calls[1];
    expect(secondCall[1].headers['If-None-Match']).toBe(etag);
  });

  it('adds includeArchived=true when requested', async () => {
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      status: 200,
      headers: new Headers(),
      json: async () => mockPayload,
    });

    await fetchSitesForMap({
      lat: 41.99,
      lng: 21.43,
      radiusKm: 20,
      includeArchived: true,
    });

    expect(global.fetch).toHaveBeenCalledWith(
      'http://localhost:3000/api/sites/map?lat=41.99&lng=21.43&radiusKm=20&limit=200&detail=lite&includeArchived=true',
      expect.any(Object),
    );
  });

  it('retries with refreshed token after 401', async () => {
    refreshMock.mockResolvedValueOnce('new-token');
    (global.fetch as ReturnType<typeof vi.fn>)
      .mockResolvedValueOnce({
        ok: false,
        status: 401,
        headers: new Headers(),
        json: async () => ({ message: 'expired' }),
      })
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        headers: new Headers(),
        json: async () => mockPayload,
      });

    await fetchSitesForMap({ lat: 41.99, lng: 21.43, radiusKm: 20 });

    const secondCall = (global.fetch as ReturnType<typeof vi.fn>).mock.calls[1];
    expect(secondCall[1].headers.Authorization).toBe('Bearer new-token');
  });

  it('fetches cluster payload shape', async () => {
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      status: 200,
      headers: new Headers(),
      json: async () => ({
        data: [
          {
            id: 'bucket-1',
            latitude: 41.99,
            longitude: 21.43,
            count: 12,
            siteIds: ['s1', 's2'],
          },
        ],
        meta: { serverTime: '2026-01-01T00:00:00.000Z', zoom: 8 },
      }),
    });
    const result = await fetchClustersForMap({
      lat: 41.99,
      lng: 21.43,
      radiusKm: 20,
      zoom: 8,
    });

    expect(result.data[0]).toMatchObject({
      id: 'bucket-1',
      count: 12,
      siteIds: ['s1', 's2'],
    });
    expect(result.meta.queryMode).toBe('viewport');
  });

  it('throws MapAdapterError on rate-limited map response', async () => {
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: false,
      status: 429,
      headers: new Headers({ 'content-type': 'application/json' }),
      json: async () => ({ message: 'limited' }),
    });

    let err: unknown;
    try {
      await fetchSitesForMap({ lat: 41.99, lng: 21.43, radiusKm: 20 });
    } catch (e) {
      err = e;
    }
    expect(err).toBeInstanceOf(MapAdapterError);
    expect((err as MapAdapterError).status).toBe(429);
    expect((err as MapAdapterError).body).toEqual({ message: 'limited' });
  });

  it('returns cached cluster rows on 304 using stored envelope', async () => {
    const etag = '"cls-etag"';
    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: true,
      status: 200,
      headers: new Headers({ etag }),
      json: async () => ({
        data: [
          {
            id: 'bucket-1',
            latitude: 41.99,
            longitude: 21.43,
            count: 4,
            siteIds: ['s1', 's2', 's3', 's4'],
          },
        ],
        meta: { serverTime: '2026-01-01T00:00:00.000Z', zoom: 8 },
      }),
    });
    const first = await fetchClustersForMap({
      lat: 41.99,
      lng: 21.43,
      radiusKm: 120,
      zoom: 8,
    });
    expect(first.data[0]?.count).toBe(4);

    (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: false,
      status: 304,
      headers: new Headers(),
      json: async () => null,
    });
    const second = await fetchClustersForMap({
      lat: 41.99,
      lng: 21.43,
      radiusKm: 120,
      zoom: 8,
    });
    expect(second.data[0]?.count).toBe(4);
    expect((global.fetch as ReturnType<typeof vi.fn>).mock.calls[1][1].headers['If-None-Match']).toBe(etag);
  });
});
