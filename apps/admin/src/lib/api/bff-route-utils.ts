import { NextRequest, NextResponse } from 'next/server';
import { ApiConnectionError, getApiConnectionErrorMessage } from '@/lib/api';
import { ensureAdminCsrfCookie } from '@/lib/auth';

export function isFetchTimeout(error: unknown): boolean {
  const cause =
    error instanceof ApiConnectionError && error.cause instanceof Error ? error.cause : error;
  return (
    (cause instanceof DOMException && cause.name === 'TimeoutError') ||
    (cause instanceof Error && cause.name === 'TimeoutError')
  );
}

export function bffConnectionErrorResponse(request: NextRequest, error: unknown): NextResponse {
  const isTimeout = isFetchTimeout(error);
  const response = NextResponse.json(
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
  ensureAdminCsrfCookie(request, response);
  return response;
}
