import { NextRequest, NextResponse } from 'next/server';
import {
  clearAdminAuthCookies,
  ensureAdminCsrfCookie,
  getAdminRefreshToken,
  refreshAdminTokens,
  setAdminAuthCookies,
  verifyAdminCsrf,
} from '@/lib/server/admin-session';

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
  if (!refreshToken) {
    const response = NextResponse.json(
      { code: 'UNAUTHORIZED', message: 'Admin session is not refreshable.' },
      { status: 401 },
    );
    clearAdminAuthCookies(response, request);
    return response;
  }

  const tokens = await refreshAdminTokens(refreshToken);
  if (!tokens) {
    const response = NextResponse.json(
      { code: 'UNAUTHORIZED', message: 'Admin session expired. Please sign in again.' },
      { status: 401 },
    );
    clearAdminAuthCookies(response, request);
    return response;
  }

  const response = NextResponse.json({ ok: true });
  setAdminAuthCookies(response, tokens, request);
  ensureAdminCsrfCookie(request, response);
  return response;
}
