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
  let body: {
    id?: unknown;
    token?: unknown;
    password?: unknown;
    phoneNumber?: unknown;
    totpCode?: unknown;
  };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ code: 'BAD_REQUEST', message: 'Invalid JSON body.' }, { status: 400 });
  }

  const id = typeof body.id === 'string' ? body.id.trim() : '';
  const token = typeof body.token === 'string' ? body.token : '';
  const password = typeof body.password === 'string' ? body.password : '';
  const phoneNumber = typeof body.phoneNumber === 'string' ? body.phoneNumber.trim() : '';
  const totpCode = typeof body.totpCode === 'string' ? body.totpCode.trim() : '';

  if (!id || !token || !password || !phoneNumber) {
    return NextResponse.json(
      { code: 'BAD_REQUEST', message: 'Invite id, token, password, and phone number are required.' },
      { status: 400 },
    );
  }

  const deviceId = getOrCreateAdminDeviceId(request);
  const acceptLanguage = await getServerAcceptLanguage();
  const backendBody: {
    id: string;
    token: string;
    password: string;
    phoneNumber: string;
    deviceId: string;
    totpCode?: string;
  } = { id, token, password, phoneNumber, deviceId };
  if (totpCode) {
    backendBody.totpCode = totpCode;
  }
  let backendResponse: Response;
  try {
    backendResponse = await fetchBackendResponse('/admin/invites/accept', {
      method: 'POST',
      body: backendBody,
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

  const payload = (await backendResponse.json().catch(() => ({}))) as AuthResponse & {
    backupCodes?: string[];
  };
  const response = NextResponse.json(payload, { status: backendResponse.status });

  if (backendResponse.ok && payload.accessToken) {
    setAdminAuthCookies(response, payload, request, { rememberDevice: true, deviceId });
  }
  ensureAdminCsrfCookie(request, response);
  return response;
}
