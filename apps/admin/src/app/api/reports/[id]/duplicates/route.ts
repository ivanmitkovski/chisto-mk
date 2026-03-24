import { NextRequest } from 'next/server';
import { fetchBackendWithRefresh } from '@/lib/admin-api-with-refresh';

export async function GET(
  request: NextRequest,
  context: { params: Promise<{ id: string }> },
) {
  const { id } = await context.params;
  if (!id) {
    return Response.json(
      { code: 'BAD_REQUEST', message: 'Report id is required' },
      { status: 400 },
    );
  }
  const search = request.nextUrl.search;
  const { nextResponse } = await fetchBackendWithRefresh(
    `/reports/${id}/duplicates${search}`,
    request,
  );
  return nextResponse;
}
