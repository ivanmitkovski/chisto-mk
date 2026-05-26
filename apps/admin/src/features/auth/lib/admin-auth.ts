import { ApiError } from '@/lib/api';
import {
  ADMIN_AUTH_COOKIE_KEY,
  ADMIN_CSRF_COOKIE_KEY,
  ADMIN_CSRF_HEADER,
  ADMIN_REFRESH_COOKIE_KEY,
} from './auth-constants';
import type { AdminLoginResponse, AuthResponse } from './types';
import { is2FAResponse } from './types';

export { ADMIN_AUTH_COOKIE_KEY, ADMIN_REFRESH_COOKIE_KEY };

function readCookie(name: string): string | null {
  if (typeof document === 'undefined') return null;
  const match = document.cookie.match(
    new RegExp(`(?:^|;\\s*)${encodeURIComponent(name)}=([^;]*)`),
  );
  return match ? decodeURIComponent(match[1]) : null;
}

export function getAdminCsrfHeaders(): Record<string, string> {
  const token = readCookie(ADMIN_CSRF_COOKIE_KEY);
  return token ? { [ADMIN_CSRF_HEADER]: token } : {};
}

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

export function logoutAdmin(): void {
  fetch('/api/auth/logout', {
    method: 'POST',
    headers: getAdminCsrfHeaders(),
    credentials: 'include',
  }).catch(() => {});
}

export async function refreshAdminSession(): Promise<boolean> {
  const response = await fetch('/api/auth/refresh', {
    method: 'POST',
    headers: getAdminCsrfHeaders(),
    credentials: 'include',
  }).catch(() => null);
  return response?.ok === true;
}

