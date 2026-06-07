import { getAdminCsrfHeaders } from '@/lib/auth/csrf-headers';
import { recoverFromUnauthorized } from '@/lib/auth/client-auth-recovery';
import { ApiConnectionError, ApiError } from './api';

async function adminBrowserFetchOnce<TResponse>(
  path: string,
  options: {
    method?: 'GET' | 'POST' | 'PATCH' | 'DELETE';
    body?: unknown;
    requestId?: string;
    idempotencyKey?: string;
  } = {},
): Promise<TResponse> {
  const requestId = options.requestId ?? crypto.randomUUID();
  const init: RequestInit = {
    method: options.method ?? 'GET',
    headers: {
      Accept: 'application/json',
      'X-Request-Id': requestId,
      ...(options.body !== undefined ? { 'Content-Type': 'application/json' } : {}),
      ...(options.method && options.method !== 'GET' ? getAdminCsrfHeaders() : {}),
      ...(options.idempotencyKey ? { 'X-Idempotency-Key': options.idempotencyKey } : {}),
    },
    credentials: 'include',
    signal: AbortSignal.timeout(30_000),
  };
  if (options.body !== undefined) {
    init.body = JSON.stringify(options.body);
  }

  let response: Response;
  try {
    response = await fetch(`/api/proxy${path}`, init);
  } catch (cause) {
    throw new ApiConnectionError(`Network request to admin API failed (${path})`, { cause });
  }

  const payload = (await response.json().catch(() => ({}))) as {
    code?: unknown;
    message?: unknown;
    details?: unknown;
    retryAfterSeconds?: number;
  };
  if (!response.ok) {
    const code = typeof payload.code === 'string' ? payload.code : 'HTTP_ERROR';
    const message =
      typeof payload.message === 'string'
        ? payload.message
        : `Request to ${path} failed with status ${response.status}`;
    const details =
      payload.details ??
      (payload.retryAfterSeconds != null ? { retryAfterSeconds: payload.retryAfterSeconds } : undefined);
    const responseRequestId = response.headers.get('x-request-id') ?? requestId;
    throw new ApiError(response.status, code, message, details, responseRequestId);
  }

  return payload as TResponse;
}

export async function adminBrowserFetch<TResponse>(
  path: string,
  options: {
    method?: 'GET' | 'POST' | 'PATCH' | 'DELETE';
    body?: unknown;
    requestId?: string;
    idempotencyKey?: string;
  } = {},
): Promise<TResponse> {
  try {
    return await adminBrowserFetchOnce<TResponse>(path, options);
  } catch (error) {
    if (error instanceof ApiError && error.status === 401) {
      const shouldRetry = await recoverFromUnauthorized();
      if (shouldRetry) {
        return adminBrowserFetchOnce<TResponse>(path, options);
      }
      throw error;
    }
    throw error;
  }
}
