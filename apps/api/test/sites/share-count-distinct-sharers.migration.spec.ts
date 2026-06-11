/// <reference types="jest" />
import * as fs from 'fs';
import * as path from 'path';

describe('share count distinct sharers migration', () => {
  it('dedupes events, adds unique index, and backfills sharesCount', () => {
    const sql = fs.readFileSync(
      path.join(
        __dirname,
        '../../prisma/migrations/20260608150000_share_count_distinct_sharers/migration.sql',
      ),
      'utf8',
    );
    expect(sql).toContain('DELETE FROM "SiteShareEvent"');
    expect(sql).toContain('ROW_NUMBER() OVER');
    expect(sql).toContain('"SiteShareEvent_siteId_userId_key"');
    expect(sql).toContain('UPDATE "Site"');
    expect(sql).toContain('"sharesCount"');
    expect(sql).toContain('UPDATE "MapSiteProjection"');
  });
});
