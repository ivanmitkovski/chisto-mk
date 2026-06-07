import { NextRequest, NextResponse } from 'next/server';
import { bffConnectionErrorResponse } from '@/lib/api/bff-route-utils';
import { executeAdminFetch } from '@/lib/api/admin-fetch';
import { getApiBaseUrl } from '@/lib/api';
import {
  clearAdminAuthCookies,
  ensureAdminCsrfCookie,
  getAdminAccessToken,
  getAdminRefreshToken,
  getOrCreateAdminDeviceId,
  refreshAdminTokens,
  setAdminAuthCookies,
} from '@/lib/auth';

export const dynamic = 'force-dynamic';

const SSE_TIMEOUT_MS = 60_000;

export async function GET(request: NextRequest) {
  let accessToken = getAdminAccessToken(request);
  const refreshToken = getAdminRefreshToken(request);
  const deviceId = getOrCreateAdminDeviceId(request);
  let refreshedTokens: Awaited<ReturnType<typeof refreshAdminTokens>> = null;

  if (!accessToken && refreshToken) {
    refreshedTokens = await refreshAdminTokens(refreshToken, deviceId);
    if (refreshedTokens) {
      accessToken = refreshedTokens.accessToken;
    }
  }

  if (!accessToken) {
    const response = NextResponse.json({ code: 'UNAUTHORIZED', message: 'Not signed in.' }, { status: 401 });
    ensureAdminCsrfCookie(request, response);
    return response;
  }

  const run = async (token: string) => {
    const url = `${getApiBaseUrl()}/admin/events`;
    const requestId = request.headers.get('x-request-id') ?? crypto.randomUUID();
    return executeAdminFetch(
      url,
      {
        method: 'GET',
        headers: {
          Accept: 'text/event-stream',
          Authorization: `Bearer ${token}`,
        },
        cache: 'no-store',
      },
      {
        path: '/admin/events',
        timeoutMs: SSE_TIMEOUT_MS,
        method: 'GET',
        retryOnGatewayError: false,
        requestId,
      },
    );
  };

  let backendResponse: Response;
  try {
    backendResponse = await run(accessToken);
  } catch (error) {
    return bffConnectionErrorResponse(request, error);
  }

  if (backendResponse.status === 401 && refreshToken) {
    refreshedTokens = await refreshAdminTokens(refreshToken, deviceId);
    if (refreshedTokens) {
      try {
        backendResponse = await run(refreshedTokens.accessToken);
      } catch (error) {
        return bffConnectionErrorResponse(request, error);
      }
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
    setAdminAuthCookies(response, refreshedTokens, request, { deviceId });
  }
  ensureAdminCsrfCookie(request, response);
  return response;
}
