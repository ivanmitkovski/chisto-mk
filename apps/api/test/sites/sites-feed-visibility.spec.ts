import { SiteFeedSort } from '../../src/sites/dto/list-sites-query.dto';
import { SitesFeedCandidatesService } from '../../src/sites/services/sites-feed-candidates.service';
import { SiteStatus } from '../../src/prisma-client';

function flattenWhere(where: unknown): string {
  return JSON.stringify(where);
}

describe('SitesFeedCandidatesService site visibility', () => {
  it('excludes other users REPORTED sites for anonymous feed queries', async () => {
    const findMany = jest.fn(async () => []);
    const prisma = { site: { findMany } } as never;
    const service = new SitesFeedCandidatesService(prisma);

    await service.loadCandidateSites(
      { page: 1, limit: 20, sort: SiteFeedSort.HYBRID, status: 'VERIFIED' } as never,
      undefined,
    );

    expect(findMany).toHaveBeenCalled();
    const where = (findMany.mock.calls[0] as any[])[0].where;
    expect(flattenWhere(where)).toContain('"not":"REPORTED"');
  });

  it('allows own REPORTED sites when viewer requests status=REPORTED', async () => {
    const findMany = jest.fn(async () => []);
    const prisma = { site: { findMany } } as never;
    const service = new SitesFeedCandidatesService(prisma);

    await service.loadCandidateSites(
      { page: 1, limit: 20, sort: SiteFeedSort.HYBRID, status: 'REPORTED' } as never,
      { userId: 'reporter-1' } as never,
    );

    const where = (findMany.mock.calls[0] as any[])[0].where;
    const text = flattenWhere(where);
    expect(text).toContain('"status":"REPORTED"');
    expect(text).toContain('"reporterId":"reporter-1"');
    expect(text).toContain(`"not":"${SiteStatus.REPORTED}"`);
  });

  it('includes visibility OR clause for authenticated viewers without status filter', async () => {
    const findMany = jest.fn(async () => []);
    const prisma = { site: { findMany } } as never;
    const service = new SitesFeedCandidatesService(prisma);

    await service.loadCandidateSites(
      { page: 1, limit: 20, sort: SiteFeedSort.HYBRID } as never,
      { userId: 'viewer-1' } as never,
    );

    const where = (findMany.mock.calls[0] as any[])[0].where;
    const text = flattenWhere(where);
    expect(text).toContain('"OR"');
    expect(text).toContain('"reporterId":"viewer-1"');
    expect(text).toContain(`"not":"${SiteStatus.REPORTED}"`);
  });
});
