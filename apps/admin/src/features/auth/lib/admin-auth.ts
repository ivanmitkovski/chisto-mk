import { ApiError } from '@/lib/api';
import { getAdminCsrfHeaders } from '@/lib/auth/csrf-headers';
import {
  ADMIN_AUTH_COOKIE_KEY,
  ADMIN_REFRESH_COOKIE_KEY,
} from './auth-constants';
import type { AdminLoginResponse, AuthResponse } from './types';
import { is2FAResponse } from './types';

export { ADMIN_AUTH_COOKIE_KEY, ADMIN_REFRESH_COOKIE_KEY };
export { getAdminCsrfHeaders };

export type LoginAdminResult =
  | { success: true }
  | { requiresTotp: true; tempToken: string; expiresIn: number };

export async function loginAdmin(
  email: string,
  password: string,
  options: { rememberDevice?: boolean } = {},
): Promise<LoginAdminResult> {
  const response = await fetchAdminAuth<AdminLoginResponse>('/api/auth/login', {
    email,
    password,
    rememberDevice: options.rememberDevice === true,
  });

  if (is2FAResponse(response)) {
    return {
      requiresTotp: true,
      tempToken: response.tempToken,
      expiresIn: response.expiresIn,
    };
  }

  return { success: true };
}

export async function completeTotpLogin(
  tempToken: string,
  code: string,
  options: { rememberDevice?: boolean } = {},
): Promise<void> {
  await fetchAdminAuth<AuthResponse>('/api/auth/2fa', {
    tempToken,
    code,
    rememberDevice: options.rememberDevice === true,
  });
}

async function fetchAdminAuth<TResponse>(
  path: string,
  body: Record<string, unknown>,
): Promise<TResponse> {
  const response = await fetch(path, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...getAdminCsrfHeaders(),
    },
    credentials: 'include',
    body: JSON.stringify(body),
  });
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
        : `Request failed with status ${response.status}`;
    const details =
      payload.details ?? (payload.retryAfterSeconds != null ? { retryAfterSeconds: payload.retryAfterSeconds } : undefined);
    throw new ApiError(response.status, code, message, details);
  }

  return payload as TResponse;
}

/** Clears admin session cookies via the Next.js auth route. */
export async function logoutAdmin(): Promise<void> {
  try {
    await fetch('/api/auth/logout', {
      method: 'POST',
      headers: getAdminCsrfHeaders(),
      credentials: 'include',
    });
  } catch {
    // Still redirect — route may have partially cleared cookies.
  }
}

/** Ends the session and reloads login so middleware sees cleared cookies. */
export async function signOutAndRedirectToLogin(): Promise<void> {
  await logoutAdmin();
  window.location.assign('/login');
}

export type RefreshSessionOutcome = 'ok' | 'unauthorized' | 'transient';

async function refreshAdminSessionOnce(): Promise<RefreshSessionOutcome> {
  const response = await fetch('/api/auth/refresh', {
    method: 'POST',
    headers: getAdminCsrfHeaders(),
    credentials: 'include',
  }).catch(() => null);

  if (response?.ok === true) return 'ok';
  if (response?.status === 401) return 'unauthorized';
  if (
    response?.status === 403 ||
    response?.status === 429 ||
    response?.status === 503 ||
    response == null
  ) {
    return 'transient';
  }
  return 'unauthorized';
}

export async function refreshAdminSession(): Promise<RefreshSessionOutcome> {
  const first = await refreshAdminSessionOnce();
  if (first !== 'transient') return first;
  return refreshAdminSessionOnce();
}

