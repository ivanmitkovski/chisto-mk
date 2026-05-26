import { NextRequest, NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/api-base-url';
import {
  clearAdminAuthCookies,
  ensureAdminCsrfCookie,
  getAdminAccessToken,
  getAdminRefreshToken,
  refreshAdminTokens,
  setAdminAuthCookies,
} from '@/lib/server/admin-session';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  let accessToken = getAdminAccessToken(request);
  const refreshToken = getAdminRefreshToken(request);

  if (!accessToken && refreshToken) {
    const refreshed = await refreshAdminTokens(refreshToken);
    if (refreshed) {
      accessToken = refreshed.accessToken;
    }
  }

  if (!accessToken) {
    const response = NextResponse.json({ code: 'UNAUTHORIZED', message: 'Not signed in.' }, { status: 401 });
    ensureAdminCsrfCookie(request, response);
    return response;
  }

  const run = (token: string) =>
    fetch(`${getApiBaseUrl()}/admin/events`, {
      headers: {
        Accept: 'text/event-stream',
        Authorization: `Bearer ${token}`,
      },
      cache: 'no-store',
    });

  let backendResponse = await run(accessToken);
  let refreshedTokens: Awaited<ReturnType<typeof refreshAdminTokens>> = null;
  if (backendResponse.status === 401 && refreshToken) {
    refreshedTokens = await refreshAdminTokens(refreshToken);
    if (refreshedTokens) {
      backendResponse = await run(refreshedTokens.accessToken);
    }
  }

  if (backendResponse.status === 401 && !refreshedTokens) {
    const response = NextResponse.json(
      { code: 'UNAUTHORIZED', message: 'Admin session expired. Please sign in again.' },
      { status: 401 },
    );
    clearAdminAuthCookies(response, request);
    ensureAdminCsrfCookie(request, response);
    return response;
  }

  const response = new NextResponse(backendResponse.body, {
    status: backendResponse.status,
    headers: {
      'content-type': backendResponse.headers.get('content-type') ?? 'text/event-stream',
      'cache-control': 'no-store',
    },
  });

  if (refreshedTokens) {
    setAdminAuthCookies(response, refreshedTokens, request);
  }
  ensureAdminCsrfCookie(request, response);
  return response;
}
