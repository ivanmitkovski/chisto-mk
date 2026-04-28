/// <reference types="jest" />

import { SitesController } from '../../src/sites/sites.controller';
import { SitesService } from '../../src/sites/sites.service';
import { SiteEventsService } from '../../src/admin-events/site-events.service';

describe('SitesController', () => {
  function buildController() {
    const sitesService = {
      findAll: jest.fn(async () => ({
        data: [],
        meta: { page: 1, limit: 20, total: 0, nextCursor: null },
      })),
      ingestShareAttributionEvent: jest.fn(async (input) => ({
        counted: true,
        siteId: 'site_1',
        cid: 'cid_1',
        ...input,
      })),
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
});
