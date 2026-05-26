import { ApiError } from './api';
import { getAdminCsrfHeaders } from '@/features/auth/lib/admin-auth';

export async function adminBrowserFetch<TResponse>(
  path: string,
  options: {
    method?: 'GET' | 'POST' | 'PATCH' | 'DELETE';
    body?: unknown;
  } = {},
): Promise<TResponse> {
  const init: RequestInit = {
    method: options.method ?? 'GET',
    headers: {
      Accept: 'application/json',
      ...(options.body !== undefined ? { 'Content-Type': 'application/json' } : {}),
      ...(options.method && options.method !== 'GET' ? getAdminCsrfHeaders() : {}),
    },
    credentials: 'include',
  };
  if (options.body !== undefined) {
    init.body = JSON.stringify(options.body);
  }

  const response = await fetch(`/api/proxy${path}`, init);

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
      payload.details ?? (payload.retryAfterSeconds != null ? { retryAfterSeconds: payload.retryAfterSeconds } : undefined);
    throw new ApiError(response.status, code, message, details);
  }

  return payload as TResponse;
}
