import { NextRequest, NextResponse } from 'next/server';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000';

export async function GET(request: NextRequest) {
  const token = await getAdminAuthTokenFromCookies();
  if (!token) {
    return NextResponse.json(
      { code: 'UNAUTHORIZED', message: 'Authentication required' },
      { status: 401 },
    );
  }

  const search = request.nextUrl.search;
  const res = await fetch(`${API_BASE_URL}/reports/duplicates${search}`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  const payload = await res.json().catch(() => ({}));
  if (!res.ok) {
    return NextResponse.json(payload, { status: res.status });
  }

  return NextResponse.json(payload);
}
