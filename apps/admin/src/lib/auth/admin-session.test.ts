import { describe, expect, it, vi, afterEach } from 'vitest';
import { NextRequest, NextResponse } from 'next/server';
import {
  ADMIN_AUTH_COOKIE_KEY,
  ADMIN_CSRF_COOKIE_KEY,
  ADMIN_CSRF_HEADER,
  ADMIN_DEVICE_COOKIE_KEY,
  ADMIN_REFRESH_COOKIE_KEY,
  ADMIN_REMEMBER_DEVICE_COOKIE_KEY,
} from '@/lib/auth/auth-constants';
import {
  REFRESH_COOKIE_REMEMBER_MAX_AGE,
  REFRESH_COOKIE_STANDARD_MAX_AGE,
  clearAdminAuthCookies,
  ensureAdminCsrfCookie,
  refreshAdminTokens,
  resolveRefreshCookieMaxAge,
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

  it('sets csrf cookie with remember-aware maxAge', () => {
    const request = requestWithCookies(`${ADMIN_REMEMBER_DEVICE_COOKIE_KEY}=1`);
    const response = NextResponse.json({ ok: true });

    ensureAdminCsrfCookie(request, response);

    const setCookie = response.headers.getSetCookie().join('\n');
    expect(setCookie).toContain(ADMIN_CSRF_COOKIE_KEY);
    expect(setCookie).toContain(`Max-Age=${REFRESH_COOKIE_REMEMBER_MAX_AGE}`);
  });

  it('sets csrf cookie with standard maxAge when remember device is off', () => {
    const request = requestWithCookies('');
    const response = NextResponse.json({ ok: true });

    ensureAdminCsrfCookie(request, response, { rememberDevice: false });

    const setCookie = response.headers.getSetCookie().join('\n');
    expect(setCookie).toContain(`Max-Age=${REFRESH_COOKIE_STANDARD_MAX_AGE}`);
  });

  it('sets remember cookie and 30-day refresh maxAge when rememberDevice is true', () => {
    const request = requestWithCookies('');
    const response = NextResponse.json({ ok: true });

    setAdminAuthCookies(
      response,
      { accessToken: 'access', refreshToken: 'refresh' },
      request,
      { rememberDevice: true },
    );
    ensureAdminCsrfCookie(request, response);

    const setCookie = response.headers.getSetCookie().join('\n');
    expect(setCookie).toContain(ADMIN_REMEMBER_DEVICE_COOKIE_KEY);
    expect(setCookie).toContain(`Max-Age=${REFRESH_COOKIE_REMEMBER_MAX_AGE}`);
  });

  it('preserves remember refresh maxAge when remember cookie is present on refresh', () => {
    const request = requestWithCookies(`${ADMIN_REMEMBER_DEVICE_COOKIE_KEY}=1`);
    const response = NextResponse.json({ ok: true });

    setAdminAuthCookies(response, { accessToken: 'access', refreshToken: 'refresh' }, request);

    const setCookie = response.headers.getSetCookie().join('\n');
    expect(setCookie).toContain(`Max-Age=${REFRESH_COOKIE_REMEMBER_MAX_AGE}`);
    expect(setCookie).not.toContain(`Max-Age=${REFRESH_COOKIE_STANDARD_MAX_AGE}`);
  });

  it('uses standard refresh maxAge when rememberDevice is false at login', () => {
    expect(resolveRefreshCookieMaxAge(false)).toBe(REFRESH_COOKIE_STANDARD_MAX_AGE);
    const request = requestWithCookies('');
    const response = NextResponse.json({ ok: true });
    setAdminAuthCookies(
      response,
      { accessToken: 'access', refreshToken: 'refresh' },
      request,
      { rememberDevice: false },
    );
    const setCookie = response.headers.getSetCookie().join('\n');
    expect(setCookie).toContain(`Max-Age=${REFRESH_COOKIE_STANDARD_MAX_AGE}`);
    expect(setCookie).toContain(`${ADMIN_REMEMBER_DEVICE_COOKIE_KEY}=;`);
    expect(setCookie).toContain(`${ADMIN_REMEMBER_DEVICE_COOKIE_KEY}=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Max-Age=0`);
  });

  it('sets auth cookies as HttpOnly and csrf as browser readable', () => {
    const request = requestWithCookies('');
    const response = NextResponse.json({ ok: true });

    setAdminAuthCookies(response, { accessToken: 'access', refreshToken: 'refresh' }, request);
    ensureAdminCsrfCookie(request, response);

    const setCookie = response.headers.getSetCookie().join('\n');
    expect(setCookie).toContain(ADMIN_AUTH_COOKIE_KEY);
    expect(setCookie).toContain(ADMIN_REFRESH_COOKIE_KEY);
    expect(setCookie).toContain(ADMIN_DEVICE_COOKIE_KEY);
    expect(setCookie).toContain('HttpOnly');
    expect(setCookie).toContain(ADMIN_CSRF_COOKIE_KEY);
  });

  it('clears auth cookies with expired Set-Cookie headers', () => {
    const request = requestWithCookies('');
    const response = NextResponse.json({ ok: true });

    clearAdminAuthCookies(response, request);

    const setCookie = response.headers.getSetCookie().join('\n');
    expect(setCookie).toContain(ADMIN_AUTH_COOKIE_KEY);
    expect(setCookie).toContain(ADMIN_REMEMBER_DEVICE_COOKIE_KEY);
    expect(setCookie).toContain('Max-Age=0');
  });

  it('deduplicates concurrent refreshes for the same refresh token', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ accessToken: 'new-access', refreshToken: 'new-refresh' }),
    });
    vi.stubGlobal('fetch', fetchMock);

    const [first, second] = await Promise.all([
      refreshAdminTokens('refresh-1', 'device-1'),
      refreshAdminTokens('refresh-1', 'device-1'),
    ]);

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(first.ok).toBe(true);
    expect(second.ok).toBe(true);
    expect(fetchMock).toHaveBeenCalledWith(
      expect.stringContaining('/auth/refresh'),
      expect.objectContaining({
        body: JSON.stringify({ refreshToken: 'refresh-1', deviceId: 'device-1' }),
      }),
    );
  });

  it('returns network reason when refresh fetch fails', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('network down')));

    const result = await refreshAdminTokens('refresh-1', 'device-1');
    expect(result).toEqual({ ok: false, reason: 'network' });
  });

  it('returns network reason when backend responds with 503', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(new Response(JSON.stringify({ code: 'UNAVAILABLE' }), { status: 503 })),
    );

    const result = await refreshAdminTokens('refresh-1', 'device-1');
    expect(result).toEqual({ ok: false, reason: 'network' });
  });
});
