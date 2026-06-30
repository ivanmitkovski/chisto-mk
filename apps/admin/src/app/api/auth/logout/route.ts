import { NextRequest, NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/api';
import { clearAdminAuthCookies, ensureAdminCsrfCookie, getAdminRefreshToken, verifyAdminCsrf } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  if (!verifyAdminCsrf(request)) {
    const response = NextResponse.json(
      { code: 'CSRF_TOKEN_INVALID', message: 'Invalid CSRF token.' },
      { status: 403 },
    );
    ensureAdminCsrfCookie(request, response);
    return response;
  }

  const refreshToken = getAdminRefreshToken(request);
  if (refreshToken) {
    await fetch(`${getApiBaseUrl()}/auth/logout`, {
      method: 'POST',
      headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
      cache: 'no-store',
    }).catch(() => undefined);
  }

  const response = NextResponse.json({ ok: true });
  clearAdminAuthCookies(response, request);
  return response;
}
