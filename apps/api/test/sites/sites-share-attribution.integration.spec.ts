import { SitesController } from '../../src/sites/sites.controller';
import { SitesService } from '../../src/sites/sites.service';
import { SiteEventsService } from '../../src/admin-events/site-events.service';

describe('Share attribution controller/service integration', () => {
  it('keeps normalized click/open fields through controller delegation', async () => {
    const sitesService = {
      ingestShareAttributionEvent: jest.fn(async (input) => ({ counted: true, ...input })),
    } as unknown as SitesService;
    const siteEvents = {
      getReplaySince: jest.fn(() => []),
      getEvents: jest.fn(),
    } as unknown as SiteEventsService;
    const controller = new SitesController(sitesService, siteEvents);
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

    expect(sitesService.ingestShareAttributionEvent).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        dto: expect.objectContaining({ eventType: 'CLICK', source: 'WEB' }),
      }),
    );
    expect(sitesService.ingestShareAttributionEvent).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({
        dto: expect.objectContaining({ eventType: 'OPEN', source: 'APP' }),
        openedByUserId: 'u1',
      }),
    );
  });
});
