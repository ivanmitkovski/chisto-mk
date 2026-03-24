import { NextRequest } from 'next/server';
import { fetchBackendWithRefresh } from '@/lib/admin-api-with-refresh';

export async function PATCH(
  request: NextRequest,
  context: { params: Promise<{ id: string }> },
) {
  const { id } = await context.params;
  if (!id || typeof id !== 'string' || id.trim() === '') {
    return Response.json(
      { code: 'BAD_REQUEST', message: 'Report id is required' },
      { status: 400 },
    );
  }
  let body: string;
  try {
    body = JSON.stringify(await request.json());
  } catch {
    return Response.json(
      { code: 'BAD_REQUEST', message: 'Invalid JSON body' },
      { status: 400 },
    );
  }
  const { nextResponse } = await fetchBackendWithRefresh(
    `/reports/${id}/status`,
    request,
    { method: 'PATCH', body },
  );
  return nextResponse;
}
