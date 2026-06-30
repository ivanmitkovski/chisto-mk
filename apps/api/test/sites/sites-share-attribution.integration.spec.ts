import { SitesController } from '../../src/sites/controllers/sites.controller';
import { SitesMapFacadeService } from '../../src/sites/services/sites-map-facade.service';
import { SitesAdminService } from '../../src/sites/services/sites-admin.service';
import { SitesFeedService } from '../../src/sites/services/sites-feed.service';
import { SiteEngagementService } from '../../src/sites/services/site-engagement.service';
import { SiteEventsService } from '../../src/admin-realtime/services/site-events.service';

describe('Share attribution controller/service integration', () => {
  it('keeps normalized click/open fields through controller delegation', async () => {
    const sitesAdmin = {} as unknown as SitesAdminService;
    const sitesFeed = {} as unknown as SitesFeedService;
    const siteEngagement = {
      ingestAttributionEvent: jest.fn(async (input) => ({ counted: true, ...input })),
    } as unknown as SiteEngagementService;
    const siteEvents = {
      getReplaySince: jest.fn(() => []),
      getEvents: jest.fn(),
    } as unknown as SiteEventsService;
    const mapFacade = {
      searchMapSites: jest.fn(),
      getAdminMapTimeline: jest.fn(),
    } as unknown as SitesMapFacadeService;
    const sitesSavedList = { listSavedForUser: jest.fn() } as never;
    const sitesAdminList = { list: jest.fn() } as never;
    const controller = new SitesController(
      sitesAdmin,
      sitesAdminList,
      sitesFeed,
      sitesSavedList,
      siteEngagement,
      mapFacade,
      siteEvents,
    );
    const req = { ip: '203.0.113.15' } as never;

    await controller.ingestShareClick(
      { token: 't1', eventType: 'OPEN', source: 'APP' } as never,
      req,
      undefined,
      'UA/4.0',
    );
    await controller.ingestShareOpen(
      { token: 't2', eventType: 'CLICK', source: 'WEB' } as never,
      req,
      { userId: 'u1' } as never,
      undefined,
      'UA/5.0',
    );

    expect(siteEngagement.ingestAttributionEvent).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({ eventType: 'CLICK', source: 'WEB', token: 't1' }),
    );
    expect(siteEngagement.ingestAttributionEvent).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({ eventType: 'OPEN', source: 'APP', token: 't2', openedByUserId: 'u1' }),
    );
  });
});
