import { apiFetch } from './api';
import { ADMIN_AUTH_COOKIE_KEY } from '@/features/auth/lib/auth-constants';

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
  return apiFetch<TResponse>(path, {
    method: options.method ?? 'GET',
    body: options.body,
    authToken: token,
  });
}
