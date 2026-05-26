import { NextRequest, NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/api-base-url';
import { ensureAdminCsrfCookie, setAdminAuthCookies } from '@/lib/server/admin-session';
import { is2FAResponse, type AdminLoginResponse, type AuthResponse } from '@/features/auth/lib/types';

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

  const backendResponse = await fetch(`${getApiBaseUrl()}/auth/admin/login`, {
    method: 'POST',
    headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
    cache: 'no-store',
  });
  const payload = (await backendResponse.json().catch(() => ({}))) as AdminLoginResponse | Record<string, unknown>;
  const response = NextResponse.json(payload, { status: backendResponse.status });

  if (backendResponse.ok && !is2FAResponse(payload as AdminLoginResponse)) {
    setAdminAuthCookies(response, payload as AuthResponse, request, {
      rememberDevice: body.rememberDevice === true,
    });
  }
  ensureAdminCsrfCookie(request, response);
  return response;
}
