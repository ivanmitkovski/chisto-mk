import 'server-only';

import { cookies } from 'next/headers';
import {
  ADMIN_AUTH_COOKIE_KEY,
  ADMIN_DEVICE_COOKIE_KEY,
  ADMIN_LEGACY_AUTH_COOKIE_KEY,
  ADMIN_LEGACY_REFRESH_COOKIE_KEY,
  ADMIN_REFRESH_COOKIE_KEY,
} from '@/lib/auth/auth-constants';
import {
  buildAdminFetchRequest,
  executeAdminFetch,
  parseAdminFetchResponse,
  type AdminFetchOptions,
} from '@/lib/api/admin-fetch';
import { getServerAcceptLanguage } from '@/lib/i18n/server-locale';
import { refreshAdminTokens, shouldUseSecureCookieServer } from './admin-session';

const ACCESS_COOKIE_MAX_AGE = 15 * 60;
const REFRESH_COOKIE_MAX_AGE = 7 * 24 * 60 * 60;

async function readAuthTokensFromCookies(): Promise<{
  accessToken: string | null;
  refreshToken: string | null;
  deviceId: string | null;
}> {
  const cookieStore = await cookies();
  return {
    accessToken:
      cookieStore.get(ADMIN_AUTH_COOKIE_KEY)?.value ??
      cookieStore.get(ADMIN_LEGACY_AUTH_COOKIE_KEY)?.value ??
      null,
    refreshToken:
      cookieStore.get(ADMIN_REFRESH_COOKIE_KEY)?.value ??
      cookieStore.get(ADMIN_LEGACY_REFRESH_COOKIE_KEY)?.value ??
      null,
    deviceId: cookieStore.get(ADMIN_DEVICE_COOKIE_KEY)?.value ?? null,
  };
}

async function persistRefreshedTokens(tokens: {
  accessToken: string;
  refreshToken?: string;
}): Promise<void> {
  const cookieStore = await cookies();
  const secure = await shouldUseSecureCookieServer();
  cookieStore.set(ADMIN_AUTH_COOKIE_KEY, tokens.accessToken, {
    path: '/',
    maxAge: ACCESS_COOKIE_MAX_AGE,
    sameSite: 'lax',
    httpOnly: true,
    secure,
  });

  if (tokens.refreshToken) {
    cookieStore.set(ADMIN_REFRESH_COOKIE_KEY, tokens.refreshToken, {
      path: '/',
      maxAge: REFRESH_COOKIE_MAX_AGE,
      sameSite: 'lax',
      httpOnly: true,
      secure,
    });
  }

  cookieStore.delete(ADMIN_LEGACY_AUTH_COOKIE_KEY);
  cookieStore.delete(ADMIN_LEGACY_REFRESH_COOKIE_KEY);
}

async function clearAuthTokensFromCookies(): Promise<void> {
  const cookieStore = await cookies();
  cookieStore.delete(ADMIN_AUTH_COOKIE_KEY);
  cookieStore.delete(ADMIN_REFRESH_COOKIE_KEY);
  cookieStore.delete(ADMIN_LEGACY_AUTH_COOKIE_KEY);
  cookieStore.delete(ADMIN_LEGACY_REFRESH_COOKIE_KEY);
}

/**
 * Server-side authenticated fetch with automatic token refresh on 401.
 * Drop-in replacement for `apiFetch` + manual cookie token in RSC adapters.
 */
export async function serverAuthenticatedFetch<TResponse>(
  path: string,
  options: Omit<AdminFetchOptions, 'authToken'> = {},
): Promise<TResponse> {
  const { accessToken, refreshToken, deviceId } = await readAuthTokensFromCookies();
  const authToken = accessToken;

  const acceptLanguage = await getServerAcceptLanguage();
  const fetchOptions: AdminFetchOptions = {
    ...options,
    authToken,
    acceptLanguage,
  };

  const timeoutMs = fetchOptions.timeoutMs ?? 30_000;
  const retryOnGatewayError =
    fetchOptions.retryOnGatewayError ?? (fetchOptions.method ?? 'GET') === 'GET';
  const { url, init, requestId, method } = buildAdminFetchRequest(path, fetchOptions);

  let response = await executeAdminFetch(url, init, {
    path,
    timeoutMs,
    method,
    retryOnGatewayError,
    requestId,
  });

  if (response.status === 401 && refreshToken) {
    const refreshed = await refreshAdminTokens(refreshToken, deviceId ?? undefined);
    if (refreshed?.accessToken) {
      await persistRefreshedTokens(refreshed);
      const retryOptions: AdminFetchOptions = {
        ...fetchOptions,
        authToken: refreshed.accessToken,
        requestId,
      };
      const retryRequest = buildAdminFetchRequest(path, retryOptions);
      response = await executeAdminFetch(retryRequest.url, retryRequest.init, {
        path,
        timeoutMs,
        method: retryRequest.method,
        retryOnGatewayError,
        requestId,
      });
    } else {
      await clearAuthTokensFromCookies();
    }
  }

  return parseAdminFetchResponse<TResponse>(response, path, requestId);
}

/** Alias for adapters migrating from `apiFetch`. */
export const serverApiFetch = serverAuthenticatedFetch;
