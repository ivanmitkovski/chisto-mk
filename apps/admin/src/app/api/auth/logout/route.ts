import { NextRequest, NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/api-base-url';
import { clearAdminAuthCookies, getAdminRefreshToken } from '@/lib/server/admin-session';

export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  const refreshToken = getAdminRefreshToken(request);
  if (refreshToken) {
    await fetch(`${getApiBaseUrl()}/auth/logout`, {
      method: 'POST',
      headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
      cache: 'no-store',
    }).catch(() => undefined);
  }

  const response = NextResponse.json({ ok: true });
  clearAdminAuthCookies(response, request);
  return response;
}
