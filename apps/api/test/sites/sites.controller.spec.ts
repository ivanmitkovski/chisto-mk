/// <reference types="jest" />

import { SitesController } from '../../src/sites/sites.controller';
import { SitesDetailController } from '../../src/sites/sites-detail.controller';
import { SitesMapController } from '../../src/sites/sites-map.controller';
import { SitesMapFacadeService } from '../../src/sites/sites-map-facade.service';
import { SitesAdminService } from '../../src/sites/sites-admin.service';
import { SitesFeedService } from '../../src/sites/sites-feed.service';
import { SiteEngagementService } from '../../src/sites/site-engagement.service';
import { SiteEventsService } from '../../src/admin-realtime/site-events.service';
import { weakEtagForJson } from '../../src/sites/http/map-etag';

describe('SitesController', () => {
  function buildController() {
    const sitesAdmin = {
      create: jest.fn(),
      bulkSites: jest.fn(),
    } as unknown as SitesAdminService;
    const sitesFeed = {
      findAll: jest.fn(async () => ({
        data: [],
        meta: { page: 1, limit: 20, total: 0, nextCursor: null },
      })),
      getFeedVariantForUser: jest.fn(() => 'v1'),
    } as unknown as SitesFeedService;
    const siteEngagement = {
      ingestAttributionEvent: jest.fn(async (input) => ({
        counted: true,
        siteId: 'site_1',
        cid: 'cid_1',
        ...input,
      })),
    } as unknown as SiteEngagementService;
    const siteEvents = {
      getReplaySince: jest.fn(() => []),
      getEvents: jest.fn(),
    } as unknown as SiteEventsService;
    const mapFacade = {
      searchMapSites: jest.fn(),
      getAdminMapTimeline: jest.fn(),
    } as unknown as SitesMapFacadeService;
    return {
      controller: new SitesController(sitesAdmin, sitesFeed, siteEngagement, mapFacade, siteEvents),
      sitesFeed,
      siteEngagement,
    };
  }

  function buildDetailController() {
    const sitesDetail = {} as never;
    const sitesMedia = {} as never;
    const sitesAdmin = {
      updateArchiveStatus: jest.fn(async () => ({ id: 'site_1', isArchivedByAdmin: true })),
    } as unknown as SitesAdminService;
    return {
      detailController: new SitesDetailController(sitesDetail, sitesMedia, sitesAdmin),
      sitesAdmin,
    };
  }

  function buildMapController() {
    const mapFacade = {
      resolveMapDataVersion: jest.fn(),
      findAllForMap: jest.fn(),
      findClustersForMap: jest.fn(),
      findHeatmapForMap: jest.fn(),
      getMapMvtTile: jest.fn(),
    } as unknown as SitesMapFacadeService;
    return { mapController: new SitesMapController(mapFacade), mapFacade };
  }

  it('delegates findAll to SitesFeedService', async () => {
    const { controller, sitesFeed } = buildController();
    const out = await controller.findAll(
      { page: 1, limit: 20, sort: 'hybrid', mode: 'for_you' } as never,
      undefined,
      { setHeader: jest.fn() } as never,
    );
    expect(sitesFeed.findAll).toHaveBeenCalled();
    expect(out.meta.page).toBe(1);
  });

  it('forces CLICK + WEB for click ingestion regardless of payload values', async () => {
    const { controller, siteEngagement } = buildController();
    const req = { ip: '203.0.113.7' } as never;
    await controller.ingestShareClick(
      { token: 'tok', eventType: 'OPEN', source: 'APP' } as never,
      req,
      '198.51.100.10',
      'UA/1.0',
    );

    expect(siteEngagement.ingestAttributionEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        eventType: 'CLICK',
        source: 'WEB',
        ipAddress: '203.0.113.7',
        userAgent: 'UA/1.0',
      }),
    );
  });

  it('forces OPEN + APP for open ingestion regardless of payload values', async () => {
    const { controller, siteEngagement } = buildController();
    const req = { ip: '203.0.113.8' } as never;
    await controller.ingestShareOpen(
      { token: 'tok', eventType: 'CLICK', source: 'WEB' } as never,
      req,
      { userId: 'user_1' } as never,
      '198.51.100.11',
      'UA/2.0',
    );

    expect(siteEngagement.ingestAttributionEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        eventType: 'OPEN',
        source: 'APP',
        ipAddress: '203.0.113.8',
        userAgent: 'UA/2.0',
        openedByUserId: 'user_1',
      }),
    );
  });

  it('returns 304 when map ETag matches If-None-Match header', async () => {
    const { mapController: controller, mapFacade } = buildMapController();
    const query = { lat: 41.6, lng: 21.7, radiusKm: 10, limit: 20 };
    const version = '1:1700000000000';
    (mapFacade as any).resolveMapDataVersion = jest.fn(async () => version);
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
    (mapFacade as any).findAllForMap = jest.fn(async () => body);
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
    expect((mapFacade as any).findAllForMap).not.toHaveBeenCalled();
  });

  it('returns 304 for clusters when ETag matches', async () => {
    const { mapController: controller, mapFacade } = buildMapController();
    const body = {
      data: [{ centerLat: 41.6, centerLng: 21.7, count: 10, siteIds: ['site_1'] }],
      meta: { queryMode: 'viewport', dataVersion: 'abc' },
    };
    (mapFacade as any).findClustersForMap = jest.fn(async () => body);
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
    const { mapController: controller, mapFacade } = buildMapController();
    const body = {
      data: [{ latitude: 41.6, longitude: 21.7, weight: 4 }],
      meta: { queryMode: 'viewport', dataVersion: 'abc' },
    };
    (mapFacade as any).findHeatmapForMap = jest.fn(async () => body);
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

  it('delegates archive moderation mutation to SitesAdminService', async () => {
    const { detailController, sitesAdmin } = buildDetailController();
    await detailController.updateArchiveStatus(
      'site_1',
      { archived: true, reason: 'Municipal cleanup confirmed' } as never,
      { userId: 'admin_1' } as never,
    );
    expect(sitesAdmin.updateArchiveStatus).toHaveBeenCalledWith(
      'site_1',
      { archived: true, reason: 'Municipal cleanup confirmed' },
      { userId: 'admin_1' },
    );
  });
});
