import { NextRequest } from 'next/server';
import { fetchBackendWithRefresh } from '@/lib/auth';

export const dynamic = 'force-dynamic';

export async function DELETE(
  request: NextRequest,
  context: { params: Promise<{ id: string; sessionId: string }> },
) {
  const { id, sessionId } = await context.params;
  if (!id || typeof id !== 'string' || id.trim() === '') {
    return Response.json(
      { code: 'BAD_REQUEST', message: 'Report id is required' },
      { status: 400 },
    );
  }
  if (!sessionId || typeof sessionId !== 'string' || sessionId.trim() === '') {
    return Response.json(
      { code: 'BAD_REQUEST', message: 'Session id is required' },
      { status: 400 },
    );
  }
  const { nextResponse } = await fetchBackendWithRefresh(
    `/reports/${id}/viewers/${encodeURIComponent(sessionId)}`,
    request,
    { method: 'DELETE' },
  );
  return nextResponse;
}
