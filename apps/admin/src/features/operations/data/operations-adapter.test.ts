import { beforeEach, describe, expect, it, vi } from 'vitest';
import { getApiOrigin } from '@/lib/api';
import { getOperationsSnapshot } from './operations-adapter';

vi.mock('@/lib/auth/server-api-with-refresh', () => ({
  serverAuthenticatedFetch: vi.fn(),
}));

import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';

describe('getOperationsSnapshot', () => {
  beforeEach(() => {
    vi.mocked(serverAuthenticatedFetch).mockResolvedValue({});
  });

  it('requests map health probes on the API origin (not /v1)', async () => {
    await getOperationsSnapshot();

    const origin = getApiOrigin();
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith(
      '/health/map',
      expect.objectContaining({ baseUrl: origin }),
    );
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith(
      '/health/map-deep',
      expect.objectContaining({ baseUrl: origin }),
    );
    expect(origin.endsWith('/v1')).toBe(false);
  });
});
