/// <reference types="jest" />

import {
  buildAuthenticatedUser,
  buildCleanupEventRow,
  buildReportRow,
  buildSiteRow,
  buildUserRow,
} from './index';

describe('test factories', () => {
  it('builds consistent defaults', () => {
    expect(buildUserRow().email).toContain('@test.chisto.mk');
    expect(buildSiteRow().latitude).toBeGreaterThan(41);
    expect(buildCleanupEventRow().status).toBeDefined();
    expect(buildReportRow().siteId).toBe('site_row_1');
    expect(buildAuthenticatedUser().role).toBeDefined();
  });
});
