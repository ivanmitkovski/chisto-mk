import { SiteMapSearchDto } from '../../../src/sites/dto/site-map-search.dto';
import {
  buildTypesenseFilterBy,
  buildTypesenseSortBy,
} from '../../../src/sites/search/typesense/typesense-sites-search.filters';

describe('typesense-sites-search.filters', () => {
  it('buildTypesenseFilterBy hides REPORTED for anonymous viewers', () => {
    const filter = buildTypesenseFilterBy(
      Object.assign(new SiteMapSearchDto(), { query: 'waste' }),
      null,
    );
    expect(filter).toContain('status:!=REPORTED');
    expect(filter).not.toContain('reporterUserIds');
  });

  it('buildTypesenseFilterBy allows reporter visibility for authenticated viewers', () => {
    const filter = buildTypesenseFilterBy(
      Object.assign(new SiteMapSearchDto(), { query: 'waste' }),
      'user_abc',
    );
    expect(filter).toContain('reporterUserIds:=user_abc');
    expect(filter).toContain('status:!=REPORTED');
  });

  it('buildTypesenseFilterBy applies map search dto filters', () => {
    const filter = buildTypesenseFilterBy(
      Object.assign(new SiteMapSearchDto(), {
        query: 'waste',
        includeArchived: true,
        statuses: ['VERIFIED', 'REPORTED'],
        pollutionTypes: ['PLASTIC'],
      }),
      'user_abc',
    );
    expect(filter).not.toContain('isArchivedByAdmin');
    expect(filter).toContain('status:=[VERIFIED,REPORTED]');
    expect(filter).toContain('pollutionCategories:=[PLASTIC]');
  });

  it('buildTypesenseSortBy adds geo sort when lat/lng provided', () => {
    const sort = buildTypesenseSortBy(
      Object.assign(new SiteMapSearchDto(), { query: 'waste', lat: 41.99, lng: 21.43 }),
    );
    expect(sort).toContain('location(41.99,21.43)');
  });
});
