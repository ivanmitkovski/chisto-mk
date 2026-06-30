import { afterEach, describe, expect, it, vi } from 'vitest';
import { NextRequest } from 'next/server';
import { ADMIN_AUTH_COOKIE_KEY, ADMIN_CSRF_COOKIE_KEY, ADMIN_CSRF_HEADER, ADMIN_REFRESH_COOKIE_KEY, ADMIN_REMEMBER_DEVICE_COOKIE_KEY } from '@/lib/auth/auth-constants';
import { REFRESH_COOKIE_REMEMBER_MAX_AGE } from './admin-session';
import {
  createBackendProxyHeaders,
  fetchBackendWithRefresh,
  proxyBackendWithRefresh,
  readProxyRequestBody,
} from './admin-api-with-refresh';

function expectSameBinaryBody(actual: unknown, expected: Buffer | Uint8Array) {
  expect(actual).toBeInstanceOf(Uint8Array);
  const actualBytes = actual as Uint8Array;
  const expectedBytes = expected instanceof Buffer ? new Uint8Array(expected) : expected;
  expect(actualBytes.length).toBe(expectedBytes.length);
  expect(Buffer.from(actualBytes).equals(Buffer.from(expectedBytes))).toBe(true);
}

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

describe('readProxyRequestBody', () => {
  it('returns undefined for GET', async () => {
    const request = new NextRequest('https://admin.chisto.mk/api/proxy/admin/users', {
      method: 'GET',
    });
    expect(await readProxyRequestBody(request)).toBeUndefined();
  });

  it('returns text for JSON POST', async () => {
    const request = new NextRequest('https://admin.chisto.mk/api/proxy/admin/users', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ ok: true }),
    });
    expect(await readProxyRequestBody(request)).toBe('{"ok":true}');
  });

  it('returns binary buffer for multipart POST', async () => {
    const boundary = '----testboundary';
    const payload = `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="a.png"\r\nContent-Type: image/png\r\n\r\n\x89PNG\r\n\x1a\n--${boundary}--\r\n`;
    const bytes = new TextEncoder().encode(payload);
    const request = new NextRequest('https://admin.chisto.mk/api/proxy/admin/news/media', {
      method: 'POST',
      headers: { 'content-type': `multipart/form-data; boundary=${boundary}` },
      body: bytes,
    });
    const body = await readProxyRequestBody(request);
    expect(body).toBeInstanceOf(Buffer);
    expect((body as Buffer).length).toBe(bytes.length);
    expect((body as Buffer).equals(Buffer.from(bytes))).toBe(true);
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

  it('forwards multipart body as binary to backend', async () => {
    const boundary = '----proxyboundary';
    const pngMagic = Buffer.from([0x89, 0x50, 0x4e, 0x47]);
    const payload = Buffer.concat([
      Buffer.from(
        `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="cover.png"\r\nContent-Type: image/png\r\n\r\n`,
      ),
      pngMagic,
      Buffer.from(`\r\n--${boundary}--\r\n`),
    ]);

    const fetchMock = vi.fn().mockResolvedValue(new Response(JSON.stringify({ id: 'media-1' }), { status: 201 }));
    vi.stubGlobal('fetch', fetchMock);

    vi.spyOn(await import('./admin-session'), 'verifyAdminCsrf').mockReturnValue(true);
    vi.spyOn(await import('./mutation-rate-limit'), 'checkMutationRateLimit').mockResolvedValue(true);

    const request = new NextRequest(
      'https://admin.chisto.mk/api/proxy/admin/news/posts/p1/media?kind=cover',
      {
        method: 'POST',
        headers: {
          cookie: `${ADMIN_AUTH_COOKIE_KEY}=access-token; ${ADMIN_CSRF_COOKIE_KEY}=csrf-token`,
          'content-type': `multipart/form-data; boundary=${boundary}`,
          [ADMIN_CSRF_HEADER]: 'csrf-token',
        },
        body: payload,
      },
    );

    const response = await proxyBackendWithRefresh('/admin/news/posts/p1/media?kind=cover', request);

    expect(response.status).toBe(201);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const init = fetchMock.mock.calls[0][1] as RequestInit;
    expectSameBinaryBody(init.body, payload);
    const forwardedHeaders = init.headers as Headers;
    expect(forwardedHeaders.get('content-type')).toContain(`boundary=${boundary}`);
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
