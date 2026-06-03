/// <reference types="jest" />

import { SiteMapSearchDto } from '../../src/sites/dto/site-map-search.dto';
import { TypesenseSitesSearchService } from '../../src/sites/search/typesense/typesense-sites-search.service';
import { SitesMapSearchQueryService } from '../../src/sites/services/sites-map-search-query.service';

describe('SitesMapSearchQueryService Typesense routing', () => {
  it('uses Typesense when enabled and falls back to Postgres on failure', async () => {
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([
        {
          id: 'pg_site',
          latitude: 41,
          longitude: 21,
          description: 'pg',
          address: 'addr',
          status: 'VERIFIED',
          score: 0.5,
          latestReportMediaUrls: null,
        },
      ]),
      site: { findMany: jest.fn() },
    };

    const typesenseSearch = {
      isEnabled: () => true,
      search: jest
        .fn()
        .mockRejectedValueOnce(new Error('typesense down'))
        .mockResolvedValueOnce([]),
    } as unknown as TypesenseSitesSearchService;

    const service = new SitesMapSearchQueryService(prisma as never, typesenseSearch);
    const dto = Object.assign(new SiteMapSearchDto(), { query: 'waste', limit: 5 });

    const rows = await service.executeSearch(dto, null);
    expect(prisma.$queryRaw).toHaveBeenCalled();
    expect(rows[0].id).toBe('pg_site');

    await service.executeSearch(dto, null);
    expect(typesenseSearch.search).toHaveBeenCalledTimes(2);
  });
});
