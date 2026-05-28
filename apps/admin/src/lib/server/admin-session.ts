import { NextRequest, NextResponse } from 'next/server';
import {
  ADMIN_AUTH_COOKIE_KEY,
  ADMIN_CSRF_COOKIE_KEY,
  ADMIN_DEVICE_COOKIE_KEY,
  ADMIN_CSRF_HEADER,
  ADMIN_LEGACY_AUTH_COOKIE_KEY,
  ADMIN_LEGACY_REFRESH_COOKIE_KEY,
  ADMIN_REFRESH_COOKIE_KEY,
} from '@/features/auth/lib/auth-constants';
import { getApiBaseUrl } from '@/lib/api-base-url';

export type AdminTokenPair = {
  accessToken: string;
  refreshToken?: string;
};

const ACCESS_COOKIE_MAX_AGE = 15 * 60;
const REFRESH_COOKIE_MAX_AGE = 7 * 24 * 60 * 60;
const DEVICE_COOKIE_MAX_AGE = 365 * 24 * 60 * 60;
const inFlightRefreshes = new Map<string, Promise<AdminTokenPair | null>>();

export function getAdminAccessToken(request: NextRequest): string | null {
  return (
    request.cookies.get(ADMIN_AUTH_COOKIE_KEY)?.value ??
    request.cookies.get(ADMIN_LEGACY_AUTH_COOKIE_KEY)?.value ??
    null
  );
}

export function getAdminRefreshToken(request: NextRequest): string | null {
  return (
    request.cookies.get(ADMIN_REFRESH_COOKIE_KEY)?.value ??
    request.cookies.get(ADMIN_LEGACY_REFRESH_COOKIE_KEY)?.value ??
    null
  );
}

function shouldUseSecureCookie(request: NextRequest): boolean {
  return process.env.NODE_ENV === 'production' || request.nextUrl.protocol === 'https:';
}

function randomToken(): string {
  return crypto.randomUUID().replaceAll('-', '') + crypto.randomUUID().replaceAll('-', '');
}

export function getOrCreateAdminDeviceId(request: NextRequest): string {
  const existing = request.cookies.get(ADMIN_DEVICE_COOKIE_KEY)?.value;
  if (existing && existing.length >= 16) return existing;
  return crypto.randomUUID();
}

export function setAdminDeviceIdCookie(
  response: NextResponse,
  request: NextRequest,
  deviceId: string,
): void {
  response.cookies.set(ADMIN_DEVICE_COOKIE_KEY, deviceId, {
    path: '/',
    maxAge: DEVICE_COOKIE_MAX_AGE,
    sameSite: 'lax',
    secure: shouldUseSecureCookie(request),
    httpOnly: true,
  });
}

export function ensureAdminCsrfCookie(request: NextRequest, response: NextResponse): string {
  const existing = request.cookies.get(ADMIN_CSRF_COOKIE_KEY)?.value;
  const token = existing && existing.length >= 32 ? existing : randomToken();
  response.cookies.set(ADMIN_CSRF_COOKIE_KEY, token, {
    path: '/',
    sameSite: 'lax',
    secure: shouldUseSecureCookie(request),
    httpOnly: false,
  });
  return token;
}

export function verifyAdminCsrf(request: NextRequest): boolean {
  const method = request.method.toUpperCase();
  if (method === 'GET' || method === 'HEAD' || method === 'OPTIONS') {
    return true;
  }
  const cookie = request.cookies.get(ADMIN_CSRF_COOKIE_KEY)?.value;
  const header = request.headers.get(ADMIN_CSRF_HEADER);
  return Boolean(cookie && header && cookie === header);
}

export function setAdminAuthCookies(
  response: NextResponse,
  tokens: AdminTokenPair,
  request: NextRequest,
  options: { rememberDevice?: boolean; deviceId?: string } = {},
): void {
  setAdminDeviceIdCookie(response, request, options.deviceId ?? getOrCreateAdminDeviceId(request));
  response.cookies.set(ADMIN_AUTH_COOKIE_KEY, tokens.accessToken, {
    path: '/',
    maxAge: ACCESS_COOKIE_MAX_AGE,
    sameSite: 'lax',
    secure: shouldUseSecureCookie(request),
    httpOnly: true,
  });

  if (tokens.refreshToken) {
    response.cookies.set(ADMIN_REFRESH_COOKIE_KEY, tokens.refreshToken, {
      path: '/',
      maxAge: options.rememberDevice ? 30 * 24 * 60 * 60 : REFRESH_COOKIE_MAX_AGE,
      sameSite: 'lax',
      secure: shouldUseSecureCookie(request),
      httpOnly: true,
    });
  }

  response.cookies.delete(ADMIN_LEGACY_AUTH_COOKIE_KEY);
  response.cookies.delete(ADMIN_LEGACY_REFRESH_COOKIE_KEY);
}

function expireCookie(
  response: NextResponse,
  request: NextRequest | null,
  name: string,
  options: { httpOnly: boolean },
): void {
  response.cookies.set(name, '', {
    path: '/',
    maxAge: 0,
    expires: new Date(0),
    sameSite: 'lax',
    secure: request ? shouldUseSecureCookie(request) : process.env.NODE_ENV === 'production',
    httpOnly: options.httpOnly,
  });
}

export function clearAdminAuthCookies(response: NextResponse, request: NextRequest | null = null): void {
  expireCookie(response, request, ADMIN_AUTH_COOKIE_KEY, { httpOnly: true });
  expireCookie(response, request, ADMIN_REFRESH_COOKIE_KEY, { httpOnly: true });
  expireCookie(response, request, ADMIN_CSRF_COOKIE_KEY, { httpOnly: false });
  expireCookie(response, request, ADMIN_LEGACY_AUTH_COOKIE_KEY, { httpOnly: false });
  expireCookie(response, request, ADMIN_LEGACY_REFRESH_COOKIE_KEY, { httpOnly: false });
}

export async function refreshAdminTokens(
  refreshToken: string,
  deviceId?: string,
): Promise<AdminTokenPair | null> {
  const refreshKey = `${refreshToken}:${deviceId ?? ''}`;
  const existing = inFlightRefreshes.get(refreshKey);
  if (existing) return existing;

  const refreshPromise = refreshAdminTokensUncached(refreshToken, deviceId).finally(() => {
    inFlightRefreshes.delete(refreshKey);
  });
  inFlightRefreshes.set(refreshKey, refreshPromise);
  return refreshPromise;
}

async function refreshAdminTokensUncached(
  refreshToken: string,
  deviceId?: string,
): Promise<AdminTokenPair | null> {
  const res = await fetch(`${getApiBaseUrl()}/auth/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({
      refreshToken,
      ...(deviceId ? { deviceId } : {}),
    }),
    cache: 'no-store',
  }).catch(() => null);
  if (!res?.ok) return null;
  return (await res.json()) as AdminTokenPair;
}

export function getTokenExpiryMs(token: string): number | null {
  try {
    const parts = token.split('.');
    const encodedPayload = parts[1];
    if (parts.length !== 3 || !encodedPayload) return null;
    const payload = encodedPayload.replace(/-/g, '+').replace(/_/g, '/');
    const decoded = JSON.parse(atob(payload)) as { exp?: number };
    return typeof decoded.exp === 'number' ? decoded.exp * 1000 : null;
  } catch {
    return null;
  }
}
