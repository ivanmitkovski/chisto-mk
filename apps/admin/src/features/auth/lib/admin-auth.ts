import { apiFetch } from '@/lib/api';
import { getApiBaseUrl } from '@/lib/api-base-url';
import type { AdminLoginResponse, AuthResponse } from './types';
import { is2FAResponse } from './types';

export { ADMIN_AUTH_COOKIE_KEY, ADMIN_REFRESH_COOKIE_KEY } from './auth-constants';

import {
  ADMIN_AUTH_COOKIE_KEY,
  ADMIN_REFRESH_COOKIE_KEY,
} from './auth-constants';

/** Client-side only: reads the admin token from document.cookie. Returns null if not found or not in browser. */
export function getAdminTokenFromBrowserCookie(): string | null {
  if (typeof document === 'undefined') return null;
  const match = document.cookie.match(
    new RegExp(`(?:^|;\\s*)${encodeURIComponent(ADMIN_AUTH_COOKIE_KEY)}=([^;]*)`),
  );
  return match ? decodeURIComponent(match[1]) : null;
}

export type LoginAdminResult =
  | { success: true }
  | { requiresTotp: true; tempToken: string; expiresIn: number };

export async function loginAdmin(email: string, password: string): Promise<LoginAdminResult> {
  const response = await apiFetch<AdminLoginResponse>('/auth/admin/login', {
    method: 'POST',
    body: { email, password },
  });

  if (is2FAResponse(response)) {
    return {
      requiresTotp: true,
      tempToken: response.tempToken,
      expiresIn: response.expiresIn,
    };
  }

  if (typeof document !== 'undefined') {
    setAuthCookies(response);
  }

  return { success: true };
}

export async function completeTotpLogin(tempToken: string, code: string): Promise<void> {
  const response = await apiFetch<AuthResponse>('/auth/admin/2fa/complete-login', {
    method: 'POST',
    body: { tempToken, code },
  });

  if (typeof document !== 'undefined') {
    setAuthCookies(response);
  }
}

function setAuthCookies(response: AuthResponse): void {
  const secureFlag = window.location.protocol === 'https:' ? '; Secure' : '';
  const refreshMaxAge = 7 * 24 * 60 * 60; // 7 days for refresh token
  const accessMaxAge = 15 * 60; // 15 min, aligned with JWT access expiry

  const accessName = encodeURIComponent(ADMIN_AUTH_COOKIE_KEY);
  const accessValue = encodeURIComponent(response.accessToken);
  document.cookie = `${accessName}=${accessValue}; Path=/; Max-Age=${accessMaxAge}; SameSite=Lax${secureFlag}`;

  if (response.refreshToken) {
    const refreshName = encodeURIComponent(ADMIN_REFRESH_COOKIE_KEY);
    const refreshValue = encodeURIComponent(response.refreshToken);
    document.cookie = `${refreshName}=${refreshValue}; Path=/; Max-Age=${refreshMaxAge}; SameSite=Lax${secureFlag}`;
  }
}

export function logoutAdmin(): void {
  if (typeof document !== 'undefined') {
    const refreshToken = getAdminRefreshFromBrowserCookie();
    if (refreshToken) {
      fetch(`${getApiBaseUrl()}/auth/logout`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken }),
      }).catch(() => {});
    }
    const clearAttrs = 'Path=/; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT';
    document.cookie = `${ADMIN_AUTH_COOKIE_KEY}=; ${clearAttrs}`;
    document.cookie = `${ADMIN_REFRESH_COOKIE_KEY}=; ${clearAttrs}`;
  }
}

function getAdminRefreshFromBrowserCookie(): string | null {
  if (typeof document === 'undefined') return null;
  const match = document.cookie.match(
    new RegExp(`(?:^|;\\s*)${encodeURIComponent(ADMIN_REFRESH_COOKIE_KEY)}=([^;]*)`),
  );
  return match ? decodeURIComponent(match[1]) : null;
}

