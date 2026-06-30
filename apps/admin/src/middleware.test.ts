import { afterEach, describe, expect, it, vi } from 'vitest';
import { NextRequest } from 'next/server';
import { ADMIN_AUTH_COOKIE_KEY, ADMIN_CSRF_COOKIE_KEY, ADMIN_REFRESH_COOKIE_KEY } from '@/lib/auth/auth-constants';
import { REFRESH_COOKIE_STANDARD_MAX_AGE } from '@/lib/auth/admin-session';

function makeJwt(expMs: number): string {
  const payload = { exp: Math.floor(expMs / 1000) };
  const encoded = Buffer.from(JSON.stringify(payload)).toString('base64url');
  return `header.${encoded}.sig`;
}

function dashboardRequest(cookie: string): NextRequest {
  return new NextRequest(new Request('https://admin.chisto.mk/dashboard', {
    headers: { cookie },
  }));
}

describe('middleware dashboard auth', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('redirects to login when access token is missing and refresh is unauthorized', async () => {
    vi.spyOn(await import('@/lib/auth/admin-session'), 'refreshAdminTokens').mockResolvedValue({
      ok: false,
      reason: 'unauthorized',
    });

    const { middleware } = await import('./middleware');
    const response = await middleware(
      dashboardRequest(`${ADMIN_REFRESH_COOKIE_KEY}=stale-refresh`),
    );

    expect(response.status).toBe(307);
    expect(response.headers.get('location')).toContain('/login');
    expect(response.headers.getSetCookie().join('\n')).toContain('Max-Age=0');
  });

  it('redirects to login when proactive refresh is unauthorized for an expiring token', async () => {
    const expiringToken = makeJwt(Date.now() + 30_000);
    vi.spyOn(await import('@/lib/auth/admin-session'), 'refreshAdminTokens').mockResolvedValue({
      ok: false,
      reason: 'unauthorized',
    });

    const { middleware } = await import('./middleware');
    const response = await middleware(
      dashboardRequest(
        `${ADMIN_AUTH_COOKIE_KEY}=${expiringToken}; ${ADMIN_REFRESH_COOKIE_KEY}=refresh-token`,
      ),
    );

    expect(response.status).toBe(307);
    expect(response.headers.get('location')).toContain('/login');
    expect(response.headers.getSetCookie().join('\n')).toContain('Max-Age=0');
  });

  it('continues when proactive refresh fails with network error but access token is still valid', async () => {
    const expiringToken = makeJwt(Date.now() + 30_000);
    vi.spyOn(await import('@/lib/auth/admin-session'), 'refreshAdminTokens').mockResolvedValue({
      ok: false,
      reason: 'network',
    });

    const { middleware } = await import('./middleware');
    const response = await middleware(
      dashboardRequest(
        `${ADMIN_AUTH_COOKIE_KEY}=${expiringToken}; ${ADMIN_REFRESH_COOKIE_KEY}=refresh-token`,
      ),
    );

    expect(response.status).toBe(200);
    expect(response.headers.get('location')).toBeNull();
    expect(response.headers.getSetCookie().join('\n')).toContain(ADMIN_CSRF_COOKIE_KEY);
  });

  it('continues to dashboard when refresh fails with network and no access token', async () => {
    vi.spyOn(await import('@/lib/auth/admin-session'), 'refreshAdminTokens').mockResolvedValue({
      ok: false,
      reason: 'network',
    });

    const { middleware } = await import('./middleware');
    const response = await middleware(
      dashboardRequest(`${ADMIN_REFRESH_COOKIE_KEY}=refresh-token`),
    );

    expect(response.status).toBe(200);
    expect(response.headers.get('location')).toBeNull();
  });

  it('does not redirect from login when access token is expired', async () => {
    const expiredToken = makeJwt(Date.now() - 60_000);
    const request = new NextRequest(new Request('https://admin.chisto.mk/login', {
      headers: { cookie: `${ADMIN_AUTH_COOKIE_KEY}=${expiredToken}` },
    }));

    const { middleware } = await import('./middleware');
    const response = await middleware(request);

    expect(response.status).toBe(200);
    expect(response.headers.get('location')).toBeNull();
  });

  it('redirects from login to dashboard when access token is valid', async () => {
    const validToken = makeJwt(Date.now() + 60_000);
    const request = new NextRequest(new Request('https://admin.chisto.mk/login', {
      headers: { cookie: `${ADMIN_AUTH_COOKIE_KEY}=${validToken}` },
    }));

    const { middleware } = await import('./middleware');
    const response = await middleware(request);

    expect(response.status).toBe(307);
    expect(response.headers.get('location')).toContain('/dashboard');
    expect(response.headers.getSetCookie().join('\n')).toContain(ADMIN_CSRF_COOKIE_KEY);
    expect(response.headers.getSetCookie().join('\n')).toContain(`Max-Age=${REFRESH_COOKIE_STANDARD_MAX_AGE}`);
  });
});
