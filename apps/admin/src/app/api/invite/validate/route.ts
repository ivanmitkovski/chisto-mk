import { NextRequest, NextResponse } from 'next/server';
import { ApiConnectionError, getApiConnectionErrorMessage } from '@/lib/api';
import { fetchBackendResponse } from '@/lib/api/admin-fetch';
import { isFetchTimeout } from '@/lib/api/bff-route-utils';
import { checkPublicRouteRateLimit } from '@/lib/auth/public-route-rate-limit';
import { getServerAcceptLanguage } from '@/lib/i18n/server-locale';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  if (!checkPublicRouteRateLimit(request, 'invite:validate')) {
    return NextResponse.json(
      { code: 'RATE_LIMITED', message: 'Too many requests. Please try again later.' },
      { status: 429 },
    );
  }

  const id = request.nextUrl.searchParams.get('id')?.trim() ?? '';
  const token = request.nextUrl.searchParams.get('token')?.trim() ?? '';
  if (!id || !token) {
    return NextResponse.json(
      { code: 'BAD_REQUEST', message: 'Invite id and token are required.' },
      { status: 400 },
    );
  }

  const query = new URLSearchParams({ id, token });
  const acceptLanguage = await getServerAcceptLanguage();
  try {
    const backendResponse = await fetchBackendResponse(
      `/admin/invites/validate?${query.toString()}`,
      {
        method: 'GET',
        retryOnGatewayError: false,
        timeoutMs: 15_000,
        acceptLanguage,
      },
    );
    const payload = await backendResponse.json().catch(() => ({}));
    return NextResponse.json(payload, { status: backendResponse.status });
  } catch (error) {
    const isTimeout = isFetchTimeout(error);
    return NextResponse.json(
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
  }
}
