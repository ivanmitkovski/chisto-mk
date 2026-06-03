/// <reference types="jest" />

import { SiteMapSearchDto } from '../../../src/sites/dto/site-map-search.dto';
import { TypesenseClientService } from '../../../src/sites/search/typesense/typesense-client.service';
import { TypesenseSitesSearchService } from '../../../src/sites/search/typesense/typesense-sites-search.service';

describe('TypesenseSitesSearchService', () => {
  it('maps Typesense hits to RawSearchRow and loads latest report media', async () => {
    const search = jest.fn().mockResolvedValue({
      hits: [
        {
          document: {
            id: 'site_1',
            latitude: 41.99,
            longitude: 21.43,
            description: 'River waste',
            address: 'Skopje',
            status: 'VERIFIED',
          },
          text_match: 0.91,
        },
      ],
    });
    const typesense = {
      isEnabled: () => true,
      getClientOrNull: () => ({
        collections: () => ({
          documents: () => ({
            search,
          }),
        }),
      }),
      getConfig: () => ({ collection: 'map_sites' }),
    } as unknown as TypesenseClientService;

    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([
        { siteId: 'site_1', mediaUrls: ['reports/a.jpg'] },
      ]),
    } as never;

    const service = new TypesenseSitesSearchService(typesense, prisma);
    const rows = await service.search(
      Object.assign(new SiteMapSearchDto(), { query: 'skopje', limit: 10 }),
      null,
    );

    expect(search).toHaveBeenCalledWith(
      expect.objectContaining({
        q: 'skopje',
        filter_by: expect.stringContaining('status:!=REPORTED'),
      }),
    );
    expect(rows).toHaveLength(1);
    expect(rows[0].id).toBe('site_1');
    expect(rows[0].score).toBe(0.91);
    expect(rows[0].latestReportMediaUrls).toEqual(['reports/a.jpg']);
  });
});
