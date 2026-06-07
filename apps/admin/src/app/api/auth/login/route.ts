import { NextRequest, NextResponse } from 'next/server';
import { ApiConnectionError, getApiConnectionErrorMessage } from '@/lib/api';
import { fetchBackendResponse } from '@/lib/api/admin-fetch';
import {
  ensureAdminCsrfCookie,
  getOrCreateAdminDeviceId,
  setAdminAuthCookies,
} from '@/lib/auth';
import { is2FAResponse, type AdminLoginResponse, type AuthResponse } from '@/features/auth';
import { getServerAcceptLanguage } from '@/lib/i18n/server-locale';

export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  let body: { email?: unknown; password?: unknown; rememberDevice?: unknown };
  try {
    body = (await request.json()) as { email?: unknown; password?: unknown; rememberDevice?: unknown };
  } catch {
    return NextResponse.json({ code: 'BAD_REQUEST', message: 'Invalid JSON body.' }, { status: 400 });
  }

  const email = typeof body.email === 'string' ? body.email.trim() : '';
  const password = typeof body.password === 'string' ? body.password : '';
  if (!email || !password) {
    return NextResponse.json(
      { code: 'BAD_REQUEST', message: 'Email and password are required.' },
      { status: 400 },
    );
  }

  const deviceId = getOrCreateAdminDeviceId(request);
  const acceptLanguage = await getServerAcceptLanguage();
  let backendResponse: Response;
  try {
    backendResponse = await fetchBackendResponse('/auth/admin/login', {
      method: 'POST',
      body: {
        email,
        password,
        deviceId,
        rememberMe: body.rememberDevice === true,
      },
      retryOnGatewayError: false,
      timeoutMs: 15_000,
      acceptLanguage,
    });
  } catch (error) {
    const cause =
      error instanceof ApiConnectionError && error.cause instanceof Error ? error.cause : error;
    const isTimeout =
      (cause instanceof DOMException && cause.name === 'TimeoutError') ||
      (cause instanceof Error && cause.name === 'TimeoutError');

    const response = NextResponse.json(
      {
        code: isTimeout ? 'BACKEND_TIMEOUT' : error instanceof ApiConnectionError ? error.code : 'API_CONNECTION_FAILED',
        message: getApiConnectionErrorMessage(isTimeout),
      },
      { status: 502 },
    );
    ensureAdminCsrfCookie(request, response);
    return response;
  }
  const payload = (await backendResponse.json().catch(() => ({}))) as AdminLoginResponse | Record<string, unknown>;
  const response = NextResponse.json(payload, { status: backendResponse.status });

  if (backendResponse.ok && !is2FAResponse(payload as AdminLoginResponse)) {
    setAdminAuthCookies(response, payload as AuthResponse, request, {
      rememberDevice: body.rememberDevice === true,
      deviceId,
    });
  }
  ensureAdminCsrfCookie(request, response);
  return response;
}
