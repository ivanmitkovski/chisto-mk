/// <reference types="jest" />
import * as fs from 'fs';
import * as path from 'path';

describe('share count distinct sharers migration', () => {
  it('dedupes events, adds unique index, and backfills sharesCount', () => {
    const migrationsDir = path.join(__dirname, '../../prisma/migrations');
    const dedupeSql = fs.readFileSync(
      path.join(migrationsDir, '20260608150000_share_count_distinct_sharers/migration.sql'),
      'utf8',
    );
    const uniqueIndexSql = fs.readFileSync(
      path.join(
        migrationsDir,
        '20260608150100_site_share_event_site_user_unique/migration.sql',
      ),
      'utf8',
    );

    expect(dedupeSql).toContain('DELETE FROM "SiteShareEvent"');
    expect(dedupeSql).toContain('ROW_NUMBER() OVER');
    expect(dedupeSql).toContain('UPDATE "Site"');
    expect(dedupeSql).toContain('"sharesCount"');
    expect(dedupeSql).toContain('UPDATE "MapSiteProjection"');

    expect(uniqueIndexSql).toContain('"SiteShareEvent_siteId_userId_key"');
    expect(uniqueIndexSql).toContain('CREATE UNIQUE INDEX CONCURRENTLY');
  });
});
