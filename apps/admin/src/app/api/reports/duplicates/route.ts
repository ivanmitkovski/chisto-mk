import { NextRequest } from 'next/server';
import { fetchBackendWithRefresh } from '@/lib/admin-api-with-refresh';

export async function GET(request: NextRequest) {
  const search = request.nextUrl.search;
  const { nextResponse } = await fetchBackendWithRefresh(`/reports/duplicates${search}`, request);
  return nextResponse;
}
