import { afterEach, describe, expect, it, vi } from 'vitest';
import { NextRequest } from 'next/server';
import { ADMIN_AUTH_COOKIE_KEY, ADMIN_REFRESH_COOKIE_KEY } from '@/lib/auth/auth-constants';

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
    vi.unstubAllGlobals();
  });

  it('redirects to login when access token is missing and refresh fails', async () => {
    vi.spyOn(await import('@/lib/auth/admin-session'), 'refreshAdminTokens').mockResolvedValue(null);

    const { middleware } = await import('./middleware');
    const response = await middleware(
      dashboardRequest(`${ADMIN_REFRESH_COOKIE_KEY}=stale-refresh`),
    );

    expect(response.status).toBe(307);
    expect(response.headers.get('location')).toContain('/login');
    expect(response.headers.getSetCookie().join('\n')).toContain('Max-Age=0');
  });

  it('redirects to login when proactive refresh fails for an expiring token', async () => {
    const expiringToken = makeJwt(Date.now() + 30_000);
    vi.spyOn(await import('@/lib/auth/admin-session'), 'refreshAdminTokens').mockResolvedValue(null);

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
});
