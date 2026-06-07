import { NextRequest } from 'next/server';
import { proxyBackendWithRefresh } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  return proxyBackendWithRefresh('/auth/me', request);
}

export async function PATCH(request: NextRequest) {
  return proxyBackendWithRefresh('/auth/me', request);
}
