import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { ApiError } from './api';
import { adminFetchCore, executeAdminFetch } from './admin-fetch';

describe('adminFetchCore', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('throws ApiError with requestId from response header', async () => {
    vi.mocked(fetch).mockResolvedValue(
      new Response(JSON.stringify({ code: 'NOT_FOUND', message: 'Missing' }), {
        status: 404,
        headers: { 'content-type': 'application/json', 'x-request-id': 'req-abc' },
      }),
    );

    await expect(adminFetchCore('/reports/1')).rejects.toMatchObject({
      status: 404,
      code: 'NOT_FOUND',
      requestId: 'req-abc',
    } satisfies Partial<ApiError>);
  });

  it('retries idempotent GET on 503', async () => {
    vi.mocked(fetch)
      .mockResolvedValueOnce(new Response('', { status: 503 }))
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ ok: true }), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        }),
      );

    const result = await adminFetchCore<{ ok: boolean }>('/health');
    expect(result.ok).toBe(true);
    expect(fetch).toHaveBeenCalledTimes(2);
  });
});

describe('executeAdminFetch', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('applies AbortSignal timeout', async () => {
    vi.mocked(fetch).mockImplementation((_url, init) => {
      const signal = init?.signal;
      return new Promise((_resolve, reject) => {
        signal?.addEventListener('abort', () => {
          reject(new DOMException('Timeout', 'TimeoutError'));
        });
      });
    });

    await expect(
      executeAdminFetch(
        'http://example.test/v1/reports',
        { method: 'GET' },
        {
          path: '/reports',
          timeoutMs: 5,
          method: 'GET',
          retryOnGatewayError: false,
          requestId: 'req-1',
        },
      ),
    ).rejects.toThrow();
  });
});
