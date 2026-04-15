import { ApiError, apiFetch } from './api';
import { ADMIN_AUTH_COOKIE_KEY } from '@/features/auth/lib/auth-constants';
import { refreshAdminAccessTokenInBrowser } from '@/features/auth/lib/admin-auth';

export function getAdminTokenFromDocumentCookie(): string | null {
  if (typeof document === 'undefined') {
    return null;
  }
  const match = document.cookie.match(new RegExp(`(?:^|;\\s*)${encodeURIComponent(ADMIN_AUTH_COOKIE_KEY)}=([^;]*)`));
  return match ? decodeURIComponent(match[1]) : null;
}

export async function adminBrowserFetch<TResponse>(
  path: string,
  options: {
    method?: 'GET' | 'POST' | 'PATCH' | 'DELETE';
    body?: unknown;
  } = {},
): Promise<TResponse> {
  const token = getAdminTokenFromDocumentCookie();
  if (!token) {
    throw new Error('Not signed in');
  }

  const run = (authToken: string) =>
    apiFetch<TResponse>(path, {
      method: options.method ?? 'GET',
      body: options.body,
      authToken,
    });

  try {
    return await run(token);
  } catch (error) {
    if (error instanceof ApiError && error.status === 401) {
      const next = await refreshAdminAccessTokenInBrowser();
      if (next) {
        return await run(next);
      }
    }
    throw error;
  }
}
