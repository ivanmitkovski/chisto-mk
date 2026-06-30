import { describe, expect, it, vi, afterEach, beforeEach } from 'vitest';
import { ApiError } from '@/lib/api/api';
import { getApiOrigin } from '@/lib/api';
import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import { getOperationsSnapshot } from './operations-adapter';
import { normalizePushStats } from './operations-snapshot';

vi.mock('@/lib/auth/server-api-with-refresh', () => ({
  serverAuthenticatedFetch: vi.fn(),
}));

describe('getOperationsSnapshot', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  beforeEach(() => {
    vi.mocked(serverAuthenticatedFetch).mockResolvedValue({});
  });

  it('requests map health probes on the API origin (not /v1)', async () => {
    await getOperationsSnapshot();
    const origin = getApiOrigin();
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith('/health/map', expect.objectContaining({ baseUrl: origin }));
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith('/health/map-deep', expect.objectContaining({ baseUrl: origin }));
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith('/health/push', expect.objectContaining({ baseUrl: origin }));
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith('/health/email', expect.objectContaining({ baseUrl: origin }));
    expect(origin.endsWith('/v1')).toBe(false);
  });

  it('maps 403 responses to forbidden panel state', async () => {
    vi.mocked(serverAuthenticatedFetch).mockImplementation(async (path: string) => {
      if (path.startsWith('/admin/audit')) {
        throw new ApiError(403, 'FORBIDDEN', 'Forbidden');
      }
      return {};
    });

    const snapshot = await getOperationsSnapshot();
    expect(snapshot.gdprAudit.status).toBe('forbidden');
    expect(snapshot.pushStats.status).toBe('ok');
  });

  it('normalizes legacy push-stats payloads missing outbox totals', () => {
    expect(
      normalizePushStats({
        sendsTotal: 10,
        sendsSuccess: 8,
        sendsFailure: 2,
        queueDepth: 3,
        deadLetterCount: 5,
      }),
    ).toEqual(
      expect.objectContaining({
        outbox: {
          deliveredTotal: 0,
          failedPermanentlyTotal: 5,
          pendingTotal: 3,
        },
      }),
    );
  });

  it('fetches new operations endpoints', async () => {
    await getOperationsSnapshot();
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith(
      '/admin/operations/system-info',
      expect.any(Object),
    );
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith(
      '/admin/operations/workers',
      expect.any(Object),
    );
    expect(serverAuthenticatedFetch).toHaveBeenCalledWith(
      '/admin/comms/email-dead-letters?page=1&limit=5',
      expect.any(Object),
    );
  });
});
