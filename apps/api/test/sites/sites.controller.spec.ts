/// <reference types="jest" />

import { SitesController } from '../../src/sites/sites.controller';
import { SitesService } from '../../src/sites/sites.service';
import { SiteEventsService } from '../../src/admin-events/site-events.service';
import { weakEtagForJson } from '../../src/sites/http/map-etag';

describe('SitesController', () => {
  function buildController() {
    const sitesService = {
      findAll: jest.fn(async () => ({
        data: [],
        meta: { page: 1, limit: 20, total: 0, nextCursor: null },
      })),
      getFeedVariantForUser: jest.fn(() => 'v1'),
      ingestShareAttributionEvent: jest.fn(async (input) => ({
        counted: true,
        siteId: 'site_1',
        cid: 'cid_1',
        ...input,
      })),
      updateArchiveStatus: jest.fn(async () => ({ id: 'site_1', isArchivedByAdmin: true })),
    } as unknown as SitesService;
    const siteEvents = {
      getReplaySince: jest.fn(() => []),
      getEvents: jest.fn(),
    } as unknown as SiteEventsService;
    return { controller: new SitesController(sitesService, siteEvents), sitesService };
  }

  it('delegates findAll to SitesService', async () => {
    const { controller, sitesService } = buildController();
    const out = await controller.findAll(
      { page: 1, limit: 20, sort: 'hybrid', mode: 'for_you' } as never,
      undefined,
      { setHeader: jest.fn() } as never,
    );
    expect(sitesService.findAll).toHaveBeenCalled();
    expect(out.meta.page).toBe(1);
  });

  it('forces CLICK + WEB for click ingestion regardless of payload values', async () => {
    const { controller, sitesService } = buildController();
    const req = { ip: '203.0.113.7' } as never;
    await controller.ingestShareClick(
      { token: 'tok', eventType: 'OPEN', source: 'APP' } as never,
      req,
      '198.51.100.10',
      'UA/1.0',
    );

    expect(sitesService.ingestShareAttributionEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        dto: expect.objectContaining({ eventType: 'CLICK', source: 'WEB' }),
        ipAddress: '203.0.113.7',
        userAgent: 'UA/1.0',
      }),
    );
  });

  it('forces OPEN + APP for open ingestion regardless of payload values', async () => {
    const { controller, sitesService } = buildController();
    const req = { ip: '203.0.113.8' } as never;
    await controller.ingestShareOpen(
      { token: 'tok', eventType: 'CLICK', source: 'WEB' } as never,
      req,
      { userId: 'user_1' } as never,
      '198.51.100.11',
      'UA/2.0',
    );

    expect(sitesService.ingestShareAttributionEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        dto: expect.objectContaining({ eventType: 'OPEN', source: 'APP' }),
        ipAddress: '203.0.113.8',
        userAgent: 'UA/2.0',
        openedByUserId: 'user_1',
      }),
    );
  });

  it('returns 304 when map ETag matches If-None-Match header', async () => {
    const { controller, sitesService } = buildController();
    const query = { lat: 41.6, lng: 21.7, radiusKm: 10, limit: 20 };
    const version = '1:1700000000000';
    (sitesService as any).resolveMapDataVersion = jest.fn(async () => version);
    const etag = weakEtagForJson({
      kind: 'map',
      version,
      query: {
        detail: undefined,
        status: null,
        includeArchived: false,
        lat: query.lat,
        lng: query.lng,
        radiusKm: query.radiusKm,
        minLat: null,
        maxLat: null,
        minLng: null,
        maxLng: null,
        zoom: null,
        limit: query.limit,
      },
    });
    const body = {
      data: [{ id: 'site_1', updatedAt: '2026-01-01T00:00:00.000Z' }],
      meta: { dataVersion: version, queryMode: 'radius' },
    };
    (sitesService as any).findAllForMap = jest.fn(async () => body);
    const res = {
      setHeader: jest.fn(),
      status: jest.fn(),
    } as never;
    const out = await controller.findAllForMap(
      query as never,
      etag,
      res,
    );
    expect(out).toBeUndefined();
    expect((res as any).status).toHaveBeenCalledWith(304);
    expect((sitesService as any).findAllForMap).not.toHaveBeenCalled();
  });

  it('returns 304 for clusters when ETag matches', async () => {
    const { controller, sitesService } = buildController();
    const body = {
      data: [{ centerLat: 41.6, centerLng: 21.7, count: 10, siteIds: ['site_1'] }],
      meta: { queryMode: 'viewport', dataVersion: 'abc' },
    };
    (sitesService as any).findClustersForMap = jest.fn(async () => body);
    const etag = weakEtagForJson(body);
    const res = { setHeader: jest.fn(), status: jest.fn() } as never;
    const out = await controller.findClustersForMap(
      { lat: 41.6, lng: 21.7, radiusKm: 10, limit: 20 } as never,
      etag,
      res,
    );
    expect(out).toBeUndefined();
    expect((res as any).status).toHaveBeenCalledWith(304);
  });

  it('sets cache headers for heatmap responses', async () => {
    const { controller, sitesService } = buildController();
    const body = {
      data: [{ latitude: 41.6, longitude: 21.7, weight: 4 }],
      meta: { queryMode: 'viewport', dataVersion: 'abc' },
    };
    (sitesService as any).findHeatmapForMap = jest.fn(async () => body);
    const res = { setHeader: jest.fn(), status: jest.fn() } as never;
    const out = await controller.findHeatmapForMap(
      { lat: 41.6, lng: 21.7, radiusKm: 10, limit: 20 } as never,
      undefined,
      res,
    );
    expect(out).toEqual(body);
    expect((res as any).setHeader).toHaveBeenCalledWith(
      'Cache-Control',
      'private, max-age=4, stale-while-revalidate=20',
    );
    expect((res as any).setHeader).toHaveBeenCalledWith('ETag', weakEtagForJson(body));
  });

  it('delegates archive moderation mutation to SitesService', async () => {
    const { controller, sitesService } = buildController();
    await controller.updateArchiveStatus(
      'site_1',
      { archived: true, reason: 'Municipal cleanup confirmed' } as never,
      { userId: 'admin_1' } as never,
    );
    expect(sitesService.updateArchiveStatus).toHaveBeenCalledWith(
      'site_1',
      { archived: true, reason: 'Municipal cleanup confirmed' },
      { userId: 'admin_1' },
    );
  });
});
