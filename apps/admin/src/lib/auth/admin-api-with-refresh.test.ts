import { afterEach, describe, expect, it, vi } from 'vitest';
import { NextRequest } from 'next/server';
import { ADMIN_AUTH_COOKIE_KEY, ADMIN_CSRF_HEADER, ADMIN_REFRESH_COOKIE_KEY, ADMIN_REMEMBER_DEVICE_COOKIE_KEY } from '@/lib/auth/auth-constants';
import { REFRESH_COOKIE_REMEMBER_MAX_AGE } from './admin-session';
import {
  createBackendProxyHeaders,
  fetchBackendWithRefresh,
  proxyBackendWithRefresh,
} from './admin-api-with-refresh';

function requestWithCookies(cookie: string, url = 'https://admin.chisto.mk/api/proxy/admin/users', init: RequestInit = {}) {
  const headers = new Headers(init.headers);
  headers.set('cookie', cookie);
  const requestInit: RequestInit = { headers };
  if (init.method) requestInit.method = init.method;
  return new NextRequest(new Request(url, requestInit));
}

describe('createBackendProxyHeaders', () => {
  it('drops browser/internal headers and keeps only backend-safe headers', async () => {
    const request = new NextRequest('https://admin.chisto.mk/api/proxy/admin/users', {
      method: 'PATCH',
      headers: {
        accept: 'application/json',
        cookie: 'secret=true',
        host: 'admin.chisto.mk',
        [ADMIN_CSRF_HEADER]: 'csrf-token',
        'x-nextjs-data': '1',
        'if-match': '"etag"',
      },
    });

    const headers = await createBackendProxyHeaders(request, 'access-token');

    expect(headers.get('Authorization')).toBe('Bearer access-token');
    expect(headers.get('if-match')).toBe('"etag"');
    expect(headers.get('cookie')).toBeNull();
    expect(headers.get('host')).toBeNull();
    expect(headers.get(ADMIN_CSRF_HEADER)).toBeNull();
    expect(headers.get('x-nextjs-data')).toBeNull();
    expect(headers.get('X-Idempotency-Key')).toBeTruthy();
  });
});

describe('proxyBackendWithRefresh', () => {
  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it('returns 401 when neither access nor refresh token is present', async () => {
    const request = new NextRequest('https://admin.chisto.mk/api/proxy/admin/users');
    const response = await proxyBackendWithRefresh('/admin/users', request);

    expect(response.status).toBe(401);
    const body = (await response.json()) as { code?: string };
    expect(body.code).toBe('UNAUTHORIZED');
    expect(response.headers.getSetCookie().join('\n')).toContain('Max-Age=0');
  });
});

describe('fetchBackendWithRefresh', () => {
  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it('retries once after refreshing tokens on 401', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(new Response(JSON.stringify({ code: 'UNAUTHORIZED' }), { status: 401 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ ok: true }), { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);

    vi.spyOn(await import('./admin-session'), 'refreshAdminTokens').mockResolvedValue({
      ok: true,
      tokens: { accessToken: 'fresh-access', refreshToken: 'fresh-refresh' },
    });

    const request = requestWithCookies(
      `${ADMIN_AUTH_COOKIE_KEY}=stale-access; ${ADMIN_REFRESH_COOKIE_KEY}=refresh-token`,
      'https://admin.chisto.mk/api/auth/me',
    );

    const { nextResponse } = await fetchBackendWithRefresh('/auth/me', request, { method: 'GET' });

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(nextResponse.status).toBe(200);
    expect(nextResponse.headers.getSetCookie().join('\n')).toContain(ADMIN_AUTH_COOKIE_KEY);
  });

  it('preserves remember refresh maxAge after 401 refresh retry', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(new Response(JSON.stringify({ code: 'UNAUTHORIZED' }), { status: 401 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ ok: true }), { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);

    vi.spyOn(await import('./admin-session'), 'refreshAdminTokens').mockResolvedValue({
      ok: true,
      tokens: { accessToken: 'fresh-access', refreshToken: 'fresh-refresh' },
    });

    const request = requestWithCookies(
      `${ADMIN_AUTH_COOKIE_KEY}=stale-access; ${ADMIN_REFRESH_COOKIE_KEY}=refresh-token; ${ADMIN_REMEMBER_DEVICE_COOKIE_KEY}=1`,
      'https://admin.chisto.mk/api/auth/me',
    );

    const { nextResponse } = await fetchBackendWithRefresh('/auth/me', request, { method: 'GET' });

    expect(nextResponse.status).toBe(200);
    expect(nextResponse.headers.getSetCookie().join('\n')).toContain(`Max-Age=${REFRESH_COOKIE_REMEMBER_MAX_AGE}`);
  });

  it('clears auth cookies when refresh fails after 401', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValue(new Response(JSON.stringify({ code: 'UNAUTHORIZED' }), { status: 401 }));
    vi.stubGlobal('fetch', fetchMock);

    vi.spyOn(await import('./admin-session'), 'refreshAdminTokens').mockResolvedValue({
      ok: false,
      reason: 'unauthorized',
    });

    const request = requestWithCookies(
      `${ADMIN_AUTH_COOKIE_KEY}=stale-access; ${ADMIN_REFRESH_COOKIE_KEY}=refresh-token`,
      'https://admin.chisto.mk/api/auth/me',
    );

    const { nextResponse } = await fetchBackendWithRefresh('/auth/me', request, { method: 'GET' });

    expect(nextResponse.status).toBe(401);
    expect(nextResponse.headers.getSetCookie().join('\n')).toContain('Max-Age=0');
  });
});
