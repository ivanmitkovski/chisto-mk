import { beforeEach, describe, expect, it, vi } from 'vitest';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';
import { apiFetch } from '@/lib/api';
import { getApiOrigin } from '@/lib/api-base-url';
import { getOperationsSnapshot } from './operations-adapter';

vi.mock('@/lib/api', () => ({
  apiFetch: vi.fn(),
}));

vi.mock('@/features/auth/lib/admin-auth-server', () => ({
  getAdminAuthTokenFromCookies: vi.fn(),
}));

describe('getOperationsSnapshot', () => {
  beforeEach(() => {
    vi.mocked(getAdminAuthTokenFromCookies).mockResolvedValue('admin-token');
    vi.mocked(apiFetch).mockResolvedValue({});
  });

  it('requests map health probes on the API origin (not /v1)', async () => {
    await getOperationsSnapshot();

    const origin = getApiOrigin();
    expect(apiFetch).toHaveBeenCalledWith(
      '/health/map',
      expect.objectContaining({ authToken: 'admin-token', baseUrl: origin }),
    );
    expect(apiFetch).toHaveBeenCalledWith(
      '/health/map-deep',
      expect.objectContaining({ authToken: 'admin-token', baseUrl: origin }),
    );
    expect(origin.endsWith('/v1')).toBe(false);
  });
});
