import { SiteMapSearchDto } from '../../src/sites/dto/site-map-search.dto';
import { SitesSearchService } from '../../src/sites/sites-search.service';

describe('SitesSearchService', () => {
  function makeService() {
    const prisma = {
      $queryRaw: jest.fn(),
      site: {
        findMany: jest.fn(),
      },
    } as unknown as ConstructorParameters<typeof SitesSearchService>[0];
    const service = new SitesSearchService(prisma);
    return { service, prisma };
  }

  it('returns ranked query results with suggestions and geoIntent', async () => {
    const { service, prisma } = makeService();
    (prisma.$queryRaw as jest.Mock).mockResolvedValue([
      {
        id: 'site_1',
        latitude: 41.99,
        longitude: 21.43,
        description: 'Waste near river',
        address: 'Skopje Center',
        status: 'REPORTED',
        score: 0.88,
      },
    ]);

    const out = await service.searchMapSites(
      Object.assign(new SiteMapSearchDto(), { query: 'скопје', limit: 20 }),
    );

    expect(prisma.$queryRaw).toHaveBeenCalled();
    expect(out.items).toHaveLength(1);
    expect(out.suggestions).toEqual(['Skopje Center']);
    expect(out.geoIntent?.label).toBe('Skopje');
  });

  it('falls back to ilike path when full-text query fails', async () => {
    const { service, prisma } = makeService();
    (prisma.$queryRaw as jest.Mock).mockRejectedValue(new Error('missing extension'));
    (prisma.site.findMany as jest.Mock).mockResolvedValue([
      {
        id: 'site_2',
        latitude: 41.2,
        longitude: 20.8,
        description: 'desc',
        address: 'Ohrid',
        status: 'VERIFIED',
      },
    ]);

    const out = await service.searchMapSites(
      Object.assign(new SiteMapSearchDto(), { query: 'ohrid', limit: 5 }),
    );
    expect(prisma.site.findMany).toHaveBeenCalled();
    expect(out.items[0].id).toBe('site_2');
  });

  it('returns empty output for empty query', async () => {
    const { service, prisma } = makeService();
    const out = await service.searchMapSites(
      Object.assign(new SiteMapSearchDto(), { query: '   ', limit: 10 }),
    );
    expect(out).toEqual({ items: [], suggestions: [], geoIntent: null });
    expect(prisma.$queryRaw).not.toHaveBeenCalled();
  });

  it('still runs full-text path when optional map filters are set', async () => {
    const { service, prisma } = makeService();
    (prisma.$queryRaw as jest.Mock).mockResolvedValue([]);
    await service.searchMapSites(
      Object.assign(new SiteMapSearchDto(), {
        query: 'waste',
        limit: 10,
        statuses: ['REPORTED', 'VERIFIED'],
        includeArchived: true,
        pollutionTypes: ['PLASTIC'],
      }),
    );
    expect(prisma.$queryRaw).toHaveBeenCalled();
  });
});
