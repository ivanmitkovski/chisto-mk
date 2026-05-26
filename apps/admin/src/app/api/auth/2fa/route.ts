import { NextRequest, NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/api-base-url';
import { ensureAdminCsrfCookie, setAdminAuthCookies } from '@/lib/server/admin-session';
import type { AuthResponse } from '@/features/auth/lib/types';

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

  const backendResponse = await fetch(`${getApiBaseUrl()}/auth/admin/2fa/complete-login`, {
    method: 'POST',
    headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
    body: JSON.stringify({ tempToken, code }),
    cache: 'no-store',
  });
  const payload = (await backendResponse.json().catch(() => ({}))) as AuthResponse | Record<string, unknown>;
  const response = NextResponse.json(payload, { status: backendResponse.status });

  if (backendResponse.ok) {
    setAdminAuthCookies(response, payload as AuthResponse, request, {
      rememberDevice: body.rememberDevice === true,
    });
  }
  ensureAdminCsrfCookie(request, response);
  return response;
}
