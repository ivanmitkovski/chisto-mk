import { apiFetch } from '@/lib/api';
import { getApiBaseUrl } from '@/lib/api-base-url';
import {
  ADMIN_AUTH_COOKIE_KEY,
  ADMIN_REFRESH_COOKIE_KEY,
} from './auth-constants';
import type { AdminLoginResponse, AuthResponse } from './types';
import { is2FAResponse } from './types';

export { ADMIN_AUTH_COOKIE_KEY, ADMIN_REFRESH_COOKIE_KEY };

const DEFAULT_ACCESS_REFRESH_SKEW_MS = 60_000;

function decodeJwtPayloadJson(token: string): Record<string, unknown> | null {
  const parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    const segment = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const pad = segment.length % 4 === 0 ? '' : '='.repeat(4 - (segment.length % 4));
    const json = atob(segment + pad);
    const parsed: unknown = JSON.parse(json);
    return typeof parsed === 'object' && parsed !== null ? (parsed as Record<string, unknown>) : null;
  } catch {
    return null;
  }
}

/** Milliseconds since Unix epoch for access JWT `exp`, or null if missing or invalid. */
export function getAdminAccessTokenExpiryMs(token: string): number | null {
  const payload = decodeJwtPayloadJson(token);
  if (!payload) return null;
  const exp = payload.exp;
  return typeof exp === 'number' ? exp * 1000 : null;
}

/**
 * True when the access token is expired or within `skewMs` of expiry (requires a parseable `exp`).
 * Used to refresh before browser-side fetches/SSE that would otherwise send a stale JWT.
 */
export function shouldProactivelyRefreshAdminAccessToken(
  token: string,
  skewMs: number = DEFAULT_ACCESS_REFRESH_SKEW_MS,
): boolean {
  const expMs = getAdminAccessTokenExpiryMs(token);
  if (expMs == null) return false;
  return Date.now() >= expMs - skewMs;
}

/**
 * Exchanges the refresh cookie for new tokens and updates `document.cookie`.
 * Returns the new access token, or null if refresh is not possible or fails.
 */
export async function refreshAdminAccessTokenInBrowser(): Promise<string | null> {
  if (typeof document === 'undefined') return null;
  const refreshToken = getAdminRefreshFromBrowserCookie();
  if (!refreshToken) return null;
  try {
    const response = await apiFetch<AuthResponse>('/auth/refresh', {
      method: 'POST',
      body: { refreshToken },
    });
    setAuthCookies(response);
    return response.accessToken;
  } catch {
    return null;
  }
}

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

