import { NextRequest, NextResponse } from 'next/server';
import {
  clearAdminAuthCookies,
  ensureAdminCsrfCookie,
  getAdminRefreshToken,
  getOrCreateAdminDeviceId,
  isRememberDeviceEnabled,
  refreshAdminTokens,
  setAdminAuthCookies,
  verifyAdminCsrf,
} from '@/lib/auth';

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

  const deviceId = getOrCreateAdminDeviceId(request);
  const result = await refreshAdminTokens(refreshToken, deviceId);
  if (!result.ok) {
    if (result.reason === 'network') {
      const response = NextResponse.json(
        { code: 'BACKEND_UNAVAILABLE', message: 'Unable to refresh session. Please try again.' },
        { status: 503 },
      );
      ensureAdminCsrfCookie(request, response);
      return response;
    }
    const response = NextResponse.json(
      { code: 'UNAUTHORIZED', message: 'Admin session expired. Please sign in again.' },
      { status: 401 },
    );
    clearAdminAuthCookies(response, request);
    return response;
  }

  const response = NextResponse.json({ ok: true });
  setAdminAuthCookies(response, result.tokens, request, {
    rememberDevice: isRememberDeviceEnabled(request),
    deviceId,
  });
  ensureAdminCsrfCookie(request, response);
  return response;
}
