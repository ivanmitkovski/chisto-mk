import { describe, expect, it, vi, beforeEach } from 'vitest';

vi.mock('@/lib/auth/server-api-with-refresh', () => ({
  serverAuthenticatedFetch: vi.fn(async (path: string) => ({ path })),
}));

import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import { getSiteResolutionsForSite, getSiteResolutionsPage } from './resolutions-adapter';

describe('resolutions-adapter', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('lists resolutions from /sites/admin/resolutions', async () => {
    await getSiteResolutionsPage({ page: 2, limit: 25, status: 'PENDING' });
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith(
      '/sites/admin/resolutions?page=2&limit=25&status=PENDING',
      { method: 'GET' },
    );
  });

  it('loads site-scoped resolutions from /sites/admin/resolutions', async () => {
    await getSiteResolutionsForSite('c1234567890abcdefghijklmn');
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith(
      '/sites/admin/resolutions?siteId=c1234567890abcdefghijklmn&limit=50',
      { method: 'GET' },
    );
  });
});
