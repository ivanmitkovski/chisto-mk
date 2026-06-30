import { NextRequest, NextResponse } from 'next/server';
import {
  ADMIN_AUTH_COOKIE_KEY,
  ADMIN_CSRF_COOKIE_KEY,
  ADMIN_DEVICE_COOKIE_KEY,
  ADMIN_CSRF_HEADER,
  ADMIN_LEGACY_AUTH_COOKIE_KEY,
  ADMIN_LEGACY_REFRESH_COOKIE_KEY,
  ADMIN_REFRESH_COOKIE_KEY,
  ADMIN_REMEMBER_DEVICE_COOKIE_KEY,
} from './auth-constants';
import { executeAdminFetch } from '../api/admin-fetch';
import { getApiBaseUrl } from '../api/api-base-url';

export type AdminTokenPair = {
  accessToken: string;
  refreshToken?: string;
};

export type AdminRefreshResult =
  | { ok: true; tokens: AdminTokenPair }
  | { ok: false; reason: 'network' | 'unauthorized' };

export const ACCESS_COOKIE_MAX_AGE = 15 * 60;
export const REFRESH_COOKIE_STANDARD_MAX_AGE = 7 * 24 * 60 * 60;
export const REFRESH_COOKIE_REMEMBER_MAX_AGE = 30 * 24 * 60 * 60;
const DEVICE_COOKIE_MAX_AGE = 365 * 24 * 60 * 60;
const REMEMBER_DEVICE_COOKIE_VALUE = '1';

const inFlightRefreshes = new Map<string, Promise<AdminRefreshResult>>();

export function resolveRefreshCookieMaxAge(rememberDevice: boolean): number {
  return rememberDevice ? REFRESH_COOKIE_REMEMBER_MAX_AGE : REFRESH_COOKIE_STANDARD_MAX_AGE;
}

export function isRememberDeviceEnabled(request: NextRequest): boolean {
  return request.cookies.get(ADMIN_REMEMBER_DEVICE_COOKIE_KEY)?.value === REMEMBER_DEVICE_COOKIE_VALUE;
}

export async function isRememberDeviceEnabledServer(): Promise<boolean> {
  const { cookies } = await import('next/headers');
  const cookieStore = await cookies();
  return cookieStore.get(ADMIN_REMEMBER_DEVICE_COOKIE_KEY)?.value === REMEMBER_DEVICE_COOKIE_VALUE;
}

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

export async function shouldUseSecureCookieServer(): Promise<boolean> {
  if (process.env.NODE_ENV === 'production') return true;
  const { headers } = await import('next/headers');
  const headerStore = await headers();
  return headerStore.get('x-forwarded-proto') === 'https';
}

function isAdminTokenPair(value: unknown): value is AdminTokenPair {
  if (typeof value !== 'object' || value === null) return false;
  const record = value as Record<string, unknown>;
  return typeof record.accessToken === 'string' && record.accessToken.length > 0;
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

function setRememberDeviceCookie(response: NextResponse, request: NextRequest): void {
  response.cookies.set(ADMIN_REMEMBER_DEVICE_COOKIE_KEY, REMEMBER_DEVICE_COOKIE_VALUE, {
    path: '/',
    maxAge: REFRESH_COOKIE_REMEMBER_MAX_AGE,
    sameSite: 'lax',
    secure: shouldUseSecureCookie(request),
    httpOnly: true,
  });
}

export function resolveCsrfCookieMaxAge(rememberDevice: boolean): number {
  return rememberDevice ? REFRESH_COOKIE_REMEMBER_MAX_AGE : REFRESH_COOKIE_STANDARD_MAX_AGE;
}

export function ensureAdminCsrfCookie(
  request: NextRequest,
  response: NextResponse,
  options: { rememberDevice?: boolean } = {},
): string {
  const rememberDevice =
    options.rememberDevice !== undefined
      ? options.rememberDevice
      : isRememberDeviceEnabled(request);
  const existing = request.cookies.get(ADMIN_CSRF_COOKIE_KEY)?.value;
  const token = existing && existing.length >= 32 ? existing : randomToken();
  response.cookies.set(ADMIN_CSRF_COOKIE_KEY, token, {
    path: '/',
    maxAge: resolveCsrfCookieMaxAge(rememberDevice),
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
  const rememberDevice =
    options.rememberDevice !== undefined
      ? options.rememberDevice
      : isRememberDeviceEnabled(request);

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
      maxAge: resolveRefreshCookieMaxAge(rememberDevice),
      sameSite: 'lax',
      secure: shouldUseSecureCookie(request),
      httpOnly: true,
    });
  }

  if (options.rememberDevice === true) {
    setRememberDeviceCookie(response, request);
  } else if (options.rememberDevice === false) {
    expireCookie(response, request, ADMIN_REMEMBER_DEVICE_COOKIE_KEY, { httpOnly: true });
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
  expireCookie(response, request, ADMIN_REMEMBER_DEVICE_COOKIE_KEY, { httpOnly: true });
  expireCookie(response, request, ADMIN_CSRF_COOKIE_KEY, { httpOnly: false });
  expireCookie(response, request, ADMIN_LEGACY_AUTH_COOKIE_KEY, { httpOnly: false });
  expireCookie(response, request, ADMIN_LEGACY_REFRESH_COOKIE_KEY, { httpOnly: false });
}

export async function refreshAdminTokens(
  refreshToken: string,
  deviceId?: string,
): Promise<AdminRefreshResult> {
  const refreshKey = `${refreshToken}:${deviceId ?? ''}`;
  const existing = inFlightRefreshes.get(refreshKey);
  if (existing) return existing;

  const refreshPromise = refreshAdminTokensUncached(refreshToken, deviceId).finally(() => {
    inFlightRefreshes.delete(refreshKey);
  });
  inFlightRefreshes.set(refreshKey, refreshPromise);
  return refreshPromise;
}

const REFRESH_MAX_ATTEMPTS = 3;
const REFRESH_TIMEOUT_MS = 15_000;

function refreshAttemptDelayMs(attempt: number): number {
  return 200 * attempt + Math.floor(Math.random() * 250);
}

function isRefreshTransientHttpStatus(status: number): boolean {
  return status === 429 || status === 502 || status === 503 || status === 504;
}

async function refreshAdminTokensUncached(
  refreshToken: string,
  deviceId?: string,
): Promise<AdminRefreshResult> {
  const url = `${getApiBaseUrl()}/auth/refresh`;
  const body = JSON.stringify({
    refreshToken,
    ...(deviceId ? { deviceId } : {}),
  });

  for (let attempt = 1; attempt <= REFRESH_MAX_ATTEMPTS; attempt += 1) {
    let res: Response;
    try {
      res = await executeAdminFetch(
        url,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          body,
          cache: 'no-store',
        },
        {
          path: '/auth/refresh',
          timeoutMs: REFRESH_TIMEOUT_MS,
          method: 'POST',
          retryOnGatewayError: false,
          requestId: crypto.randomUUID(),
        },
      );
    } catch {
      if (attempt < REFRESH_MAX_ATTEMPTS) {
        await new Promise((resolve) => setTimeout(resolve, refreshAttemptDelayMs(attempt)));
        continue;
      }
      return { ok: false, reason: 'network' };
    }

    if (res.ok) {
      const payload = (await res.json().catch(() => null)) as unknown;
      if (!isAdminTokenPair(payload)) return { ok: false, reason: 'unauthorized' };
      return { ok: true, tokens: payload };
    }

    if (isRefreshTransientHttpStatus(res.status) && attempt < REFRESH_MAX_ATTEMPTS) {
      await new Promise((resolve) => setTimeout(resolve, refreshAttemptDelayMs(attempt)));
      continue;
    }

    if (isRefreshTransientHttpStatus(res.status)) {
      return { ok: false, reason: 'network' };
    }

    return { ok: false, reason: 'unauthorized' };
  }

  return { ok: false, reason: 'network' };
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
