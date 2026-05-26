import { describe, expect, it, vi, afterEach } from 'vitest';
import { NextRequest, NextResponse } from 'next/server';
import {
  ADMIN_AUTH_COOKIE_KEY,
  ADMIN_CSRF_COOKIE_KEY,
  ADMIN_CSRF_HEADER,
  ADMIN_REFRESH_COOKIE_KEY,
} from '@/features/auth/lib/auth-constants';
import {
  clearAdminAuthCookies,
  ensureAdminCsrfCookie,
  refreshAdminTokens,
  setAdminAuthCookies,
  verifyAdminCsrf,
} from './admin-session';

function requestWithCookies(cookie: string, init: RequestInit = {}) {
  const headers = new Headers(init.headers);
  headers.set('cookie', cookie);
  const requestInit: RequestInit = {
    headers,
  };
  if (init.method) requestInit.method = init.method;
  return new NextRequest(new Request('https://admin.chisto.mk/dashboard', requestInit));
}

describe('admin session helpers', () => {
  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it('requires matching csrf cookie and header for mutations', () => {
    const request = requestWithCookies(`${ADMIN_CSRF_COOKIE_KEY}=csrf-token`, {
      method: 'PATCH',
      headers: { [ADMIN_CSRF_HEADER]: 'csrf-token' },
    });

    expect(verifyAdminCsrf(request)).toBe(true);
  });

  it('rejects mismatched csrf values for mutations', () => {
    const request = requestWithCookies(`${ADMIN_CSRF_COOKIE_KEY}=csrf-token`, {
      method: 'POST',
      headers: { [ADMIN_CSRF_HEADER]: 'wrong-token' },
    });

    expect(verifyAdminCsrf(request)).toBe(false);
  });

  it('sets auth cookies as HttpOnly and csrf as browser readable', () => {
    const request = requestWithCookies('');
    const response = NextResponse.json({ ok: true });

    setAdminAuthCookies(response, { accessToken: 'access', refreshToken: 'refresh' }, request);
    ensureAdminCsrfCookie(request, response);

    const setCookie = response.headers.getSetCookie().join('\n');
    expect(setCookie).toContain(ADMIN_AUTH_COOKIE_KEY);
    expect(setCookie).toContain(ADMIN_REFRESH_COOKIE_KEY);
    expect(setCookie).toContain('HttpOnly');
    expect(setCookie).toContain(ADMIN_CSRF_COOKIE_KEY);
  });

  it('clears auth cookies with expired Set-Cookie headers', () => {
    const request = requestWithCookies('');
    const response = NextResponse.json({ ok: true });

    clearAdminAuthCookies(response, request);

    const setCookie = response.headers.getSetCookie().join('\n');
    expect(setCookie).toContain(ADMIN_AUTH_COOKIE_KEY);
    expect(setCookie).toContain('Max-Age=0');
  });

  it('deduplicates concurrent refreshes for the same refresh token', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ accessToken: 'new-access', refreshToken: 'new-refresh' }),
    });
    vi.stubGlobal('fetch', fetchMock);

    await Promise.all([refreshAdminTokens('refresh-1'), refreshAdminTokens('refresh-1')]);

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});
