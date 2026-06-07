import { NextRequest, NextResponse } from 'next/server';
import { ApiConnectionError, getApiConnectionErrorMessage } from '@/lib/api';
import { fetchBackendResponse } from '@/lib/api/admin-fetch';
import { isFetchTimeout } from '@/lib/api/bff-route-utils';
import {
  ensureAdminCsrfCookie,
  getOrCreateAdminDeviceId,
  setAdminAuthCookies,
} from '@/lib/auth';
import type { AuthResponse } from '@/features/auth';
import { getServerAcceptLanguage } from '@/lib/i18n/server-locale';

export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  let body: { tempToken?: unknown; code?: unknown; rememberDevice?: unknown };
  try {
    body = (await request.json()) as { tempToken?: unknown; code?: unknown; rememberDevice?: unknown };
  } catch {
    return NextResponse.json({ code: 'BAD_REQUEST', message: 'Invalid JSON body.' }, { status: 400 });
  }

  const tempToken = typeof body.tempToken === 'string' ? body.tempToken : '';
  const code = typeof body.code === 'string' ? body.code.trim() : '';
  if (!tempToken || !code) {
    return NextResponse.json(
      { code: 'BAD_REQUEST', message: 'Temporary token and code are required.' },
      { status: 400 },
    );
  }

  const deviceId = getOrCreateAdminDeviceId(request);
  const acceptLanguage = await getServerAcceptLanguage();
  let backendResponse: Response;
  try {
    backendResponse = await fetchBackendResponse('/auth/admin/2fa/complete-login', {
      method: 'POST',
      body: { tempToken, code, deviceId },
      retryOnGatewayError: false,
      timeoutMs: 15_000,
      acceptLanguage,
    });
  } catch (error) {
    const isTimeout = isFetchTimeout(error);
    const response = NextResponse.json(
      {
        code: isTimeout
          ? 'BACKEND_TIMEOUT'
          : error instanceof ApiConnectionError
            ? error.code
            : 'API_CONNECTION_FAILED',
        message: getApiConnectionErrorMessage(isTimeout),
      },
      { status: 502 },
    );
    ensureAdminCsrfCookie(request, response);
    return response;
  }

  const payload = (await backendResponse.json().catch(() => ({}))) as AuthResponse | Record<string, unknown>;
  const response = NextResponse.json(payload, { status: backendResponse.status });

  if (backendResponse.ok) {
    setAdminAuthCookies(response, payload as AuthResponse, request, {
      rememberDevice: body.rememberDevice === true,
      deviceId,
    });
  }
  ensureAdminCsrfCookie(request, response);
  return response;
}
