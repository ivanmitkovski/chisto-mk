import { SitesController } from '../../src/sites/sites.controller';

describe('SitesController map routes', () => {
  function makeController() {
    const sitesService = {
      getMapMvtTile: jest.fn().mockResolvedValue({
        buffer: Buffer.from([0x1a, 0x02, 0x08, 0x01]),
        etag: '"abc"',
      }),
      searchMapSites: jest.fn().mockResolvedValue({ items: [], suggestions: [], geoIntent: null }),
      bulkSites: jest.fn().mockResolvedValue({ updated: 1, siteIds: ['s1'] }),
      getAdminMapTimeline: jest
        .fn()
        .mockResolvedValue({ at: new Date().toISOString(), revisionCount: 0, hint: 'stub' }),
    } as never;
    const siteEventsService = {} as never;
    const controller = new SitesController(sitesService, siteEventsService);
    return { controller, sitesService };
  }

  it('returns mvt tile and sets response headers', async () => {
    const { controller } = makeController();
    const headers = new Map<string, string>();
    let statusCode = 200;
    let sent: unknown;
    const res = {
      setHeader: (k: string, v: string) => headers.set(k, v),
      status: (v: number) => {
        statusCode = v;
        return res;
      },
      send: (b: unknown) => {
        sent = b;
      },
      end: jest.fn(),
    } as never;

    await controller.getMapMvtTile(12, 2236, 1530, undefined, res);
    expect(statusCode).toBe(200);
    expect(headers.get('Content-Type')).toBe('application/vnd.mapbox-vector-tile');
    expect((sent as Uint8Array).length).toBeGreaterThan(0);
  });

  it('returns 304 when etag matches', async () => {
    const { controller } = makeController();
    let statusCode = 200;
    const res = {
      setHeader: jest.fn(),
      status: (v: number) => {
        statusCode = v;
        return res;
      },
      send: jest.fn(),
      end: jest.fn(),
    } as never;
    await controller.getMapMvtTile(12, 2236, 1530, '"abc"', res);
    expect(statusCode).toBe(304);
  });
});
