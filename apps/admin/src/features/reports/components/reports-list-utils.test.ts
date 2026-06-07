import { describe, expect, it } from 'vitest';
import { buildReportsUrl } from './reports-list-utils';

describe('buildReportsUrl', () => {
  it('includes duplicatesOnly, sort, and dir query params', () => {
    const url = buildReportsUrl({
      status: 'NEW',
      sort: 'dateReportedAt',
      dir: 'asc',
      duplicatesOnly: true,
      page: 2,
      search: 'park',
      siteId: 'site_123',
    });
    expect(url).toContain('status=NEW');
    expect(url).toContain('sort=dateReportedAt');
    expect(url).toContain('dir=asc');
    expect(url).toContain('duplicatesOnly=true');
    expect(url).toContain('page=2');
    expect(url).toContain('search=park');
    expect(url).toContain('siteId=site_123');
  });

  it('omits empty search and page 1', () => {
    expect(buildReportsUrl({})).toBe('/dashboard/reports');
  });
});
