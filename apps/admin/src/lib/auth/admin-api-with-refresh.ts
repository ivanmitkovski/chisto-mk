import { NextRequest, NextResponse } from 'next/server';
import { bffConnectionErrorResponse } from '@/lib/api/bff-route-utils';
import { executeAdminFetch, type HttpMethod } from '@/lib/api/admin-fetch';
import { getApiBaseUrl } from '../api/api-base-url';
import {
  clearAdminAuthCookies,
  ensureAdminCsrfCookie,
  getAdminAccessToken,
  getAdminRefreshToken,
  getOrCreateAdminDeviceId,
  refreshAdminTokens,
  setAdminAuthCookies,
  verifyAdminCsrf,
} from './admin-session';
import { checkMutationRateLimit } from './mutation-rate-limit';

type RequestInitWithBody = RequestInit & { body?: unknown };
const FORWARDED_HEADER_ALLOWLIST = new Set([
  'accept',
  'accept-language',
  'content-type',
  'if-match',
  'if-none-match',
  'idempotency-key',
  'x-idempotency-key',
]);

const DEFAULT_TIMEOUT_MS = 30_000;

export async function createBackendProxyHeaders(
  request: NextRequest,
  accessToken: string | null,
): Promise<Headers> {
  const headers = new Headers();
  request.headers.forEach((value, key) => {
    const normalized = key.toLowerCase();
    if (FORWARDED_HEADER_ALLOWLIST.has(normalized)) {
      headers.set(key, value);
    }
  });
  headers.set('Accept', headers.get('Accept') ?? 'application/json');
  const acceptLanguage = headers.get('Accept-Language')?.trim();
  if (!acceptLanguage || acceptLanguage === '*') {
    const { getServerAcceptLanguage } = await import('../i18n/server-locale');
    headers.set('Accept-Language', await getServerAcceptLanguage());
  }
  if (accessToken) {
    headers.set('Authorization', `Bearer ${accessToken}`);
  }
  headers.set('X-Request-Id', request.headers.get('x-request-id') ?? crypto.randomUUID());
  if (
    request.method !== 'GET' &&
    request.method !== 'HEAD' &&
    !headers.has('X-Idempotency-Key') &&
    !headers.has('Idempotency-Key')
  ) {
    headers.set('X-Idempotency-Key', crypto.randomUUID());
  }
  return headers;
}

async function executeBackendFetch(
  path: string,
  request: NextRequest,
  init: RequestInitWithBody,
): Promise<Response> {
  const url = `${getApiBaseUrl()}${path}`;
  const headers: Record<string, string> = {
    Accept: 'application/json',
    ...((init.headers as Record<string, string>) ?? {}),
  };
  headers['X-Request-Id'] =
    headers['X-Request-Id'] ?? request.headers.get('x-request-id') ?? crypto.randomUUID();
  const accessToken = getAdminAccessToken(request);
  if (accessToken) {
    headers.Authorization = `Bearer ${accessToken}`;
  }
  if (init.body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }
  const method = (init.method?.toUpperCase() ?? 'GET') as HttpMethod;
  if (
    method !== 'GET' &&
    !headers['X-Idempotency-Key'] &&
    !headers['Idempotency-Key']
  ) {
    headers['X-Idempotency-Key'] = crypto.randomUUID();
  }

  const { body: bodyVal, ...restInit } = init;
  const fetchInit: RequestInit = {
    ...restInit,
    headers,
    cache: 'no-store',
  };
  if (bodyVal !== undefined) {
    (fetchInit as RequestInit & { body: string }).body =
      typeof bodyVal === 'string' ? bodyVal : JSON.stringify(bodyVal);
  }

  return executeAdminFetch(url, fetchInit, {
    path,
    timeoutMs: DEFAULT_TIMEOUT_MS,
    method,
    retryOnGatewayError: method === 'GET',
    requestId: headers['X-Request-Id'],
  });
}

export async function fetchBackendWithRefresh(
  path: string,
  request: NextRequest,
  init: RequestInitWithBody = {},
): Promise<{ response: Response; nextResponse: NextResponse }> {
  if (!(await checkMutationRateLimit(request, getAdminAccessToken(request)))) {
    const nextResponse = NextResponse.json(
      { code: 'RATE_LIMITED', message: 'Too many admin requests. Please slow down.' },
      { status: 429 },
    );
    ensureAdminCsrfCookie(request, nextResponse);
    return { response: nextResponse, nextResponse };
  }
  if (!verifyAdminCsrf(request)) {
    const nextResponse = NextResponse.json(
      { code: 'CSRF_TOKEN_INVALID', message: 'Invalid CSRF token.' },
      { status: 403 },
    );
    ensureAdminCsrfCookie(request, nextResponse);
    return { response: nextResponse, nextResponse };
  }

  const refreshToken = getAdminRefreshToken(request);
  const deviceId = getOrCreateAdminDeviceId(request);

  let res: Response;
  try {
    res = await executeBackendFetch(path, request, init);
  } catch (error) {
    const nextResponse = bffConnectionErrorResponse(request, error);
    return { response: nextResponse, nextResponse };
  }

  if (res.status === 401 && refreshToken) {
    const tokens = await refreshAdminTokens(refreshToken, deviceId);
    if (tokens) {
      const retryInit: RequestInitWithBody = {
        ...init,
        headers: {
          ...((init.headers as Record<string, string>) ?? {}),
          Authorization: `Bearer ${tokens.accessToken}`,
        },
      };
      try {
        res = await executeBackendFetch(path, request, retryInit);
      } catch (error) {
        const nextResponse = bffConnectionErrorResponse(request, error);
        return { response: nextResponse, nextResponse };
      }
      const payload = await res.json().catch(() => ({}));
      const nextRes = NextResponse.json(payload, { status: res.status });
      nextRes.headers.set(
        'x-request-id',
        (retryInit.headers as Record<string, string> | undefined)?.['X-Request-Id'] ?? crypto.randomUUID(),
      );
      setAdminAuthCookies(nextRes, tokens, request, { deviceId });
      ensureAdminCsrfCookie(request, nextRes);
      return { response: res, nextResponse: nextRes };
    }
    const nextResponse = NextResponse.json(
      { code: 'UNAUTHORIZED', message: 'Admin session expired. Please sign in again.' },
      { status: 401 },
    );
    clearAdminAuthCookies(nextResponse, request);
    ensureAdminCsrfCookie(request, nextResponse);
    return { response: nextResponse, nextResponse };
  }

  const payload = await res.json().catch(() => ({}));
  const nextResponse = NextResponse.json(payload, { status: res.status });
  nextResponse.headers.set(
    'x-request-id',
    ((init.headers as Record<string, string> | undefined)?.['X-Request-Id'] ??
      request.headers.get('x-request-id') ??
      crypto.randomUUID()) as string,
  );
  if (res.status === 401) {
    clearAdminAuthCookies(nextResponse, request);
  }
  ensureAdminCsrfCookie(request, nextResponse);
  return { response: res, nextResponse };
}

export async function proxyBackendWithRefresh(
  path: string,
  request: NextRequest,
): Promise<NextResponse> {
  const accessToken = getAdminAccessToken(request);
  const refreshToken = getAdminRefreshToken(request);

  if (!accessToken && !refreshToken) {
    const response = NextResponse.json(
      { code: 'UNAUTHORIZED', message: 'Authentication required.' },
      { status: 401 },
    );
    clearAdminAuthCookies(response, request);
    ensureAdminCsrfCookie(request, response);
    return response;
  }

  if (!(await checkMutationRateLimit(request, accessToken))) {
    const response = NextResponse.json(
      { code: 'RATE_LIMITED', message: 'Too many admin requests. Please slow down.' },
      { status: 429 },
    );
    ensureAdminCsrfCookie(request, response);
    return response;
  }
  if (!verifyAdminCsrf(request)) {
    const response = NextResponse.json(
      { code: 'CSRF_TOKEN_INVALID', message: 'Invalid CSRF token.' },
      { status: 403 },
    );
    ensureAdminCsrfCookie(request, response);
    return response;
  }

  const deviceId = getOrCreateAdminDeviceId(request);
  const headers = await createBackendProxyHeaders(request, accessToken);

  const body =
    request.method === 'GET' || request.method === 'HEAD' ? undefined : await request.text();
  const method = request.method.toUpperCase() as HttpMethod;
  const requestId = headers.get('X-Request-Id') ?? crypto.randomUUID();
  const url = `${getApiBaseUrl()}${path}`;

  const buildInit = (): RequestInit => {
    const init: RequestInit = {
      method: request.method,
      headers,
      cache: 'no-store',
    };
    if (body !== undefined) {
      init.body = body;
    }
    return init;
  };

  let backendResponse: Response;
  try {
    backendResponse = await executeAdminFetch(url, buildInit(), {
      path,
      timeoutMs: DEFAULT_TIMEOUT_MS,
      method,
      retryOnGatewayError: method === 'GET',
      requestId,
    });
  } catch (error) {
    return bffConnectionErrorResponse(request, error);
  }

  let refreshedTokens: Awaited<ReturnType<typeof refreshAdminTokens>> = null;
  if (backendResponse.status === 401 && refreshToken) {
    refreshedTokens = await refreshAdminTokens(refreshToken, deviceId);
    if (refreshedTokens) {
      headers.set('Authorization', `Bearer ${refreshedTokens.accessToken}`);
      try {
        backendResponse = await executeAdminFetch(url, buildInit(), {
          path,
          timeoutMs: DEFAULT_TIMEOUT_MS,
          method,
          retryOnGatewayError: method === 'GET',
          requestId,
        });
      } catch (error) {
        return bffConnectionErrorResponse(request, error);
      }
    } else {
      const response = NextResponse.json(
        { code: 'UNAUTHORIZED', message: 'Admin session expired. Please sign in again.' },
        { status: 401 },
      );
      clearAdminAuthCookies(response, request);
      ensureAdminCsrfCookie(request, response);
      return response;
    }
  }

  const responseHeaders = new Headers();
  const contentType = backendResponse.headers.get('content-type');
  const etag = backendResponse.headers.get('etag');
  if (contentType) responseHeaders.set('content-type', contentType);
  if (etag) responseHeaders.set('etag', etag);

  const response = new NextResponse(backendResponse.body, {
    status: backendResponse.status,
    headers: responseHeaders,
  });
  response.headers.set('x-request-id', requestId);
  if (refreshedTokens) {
    setAdminAuthCookies(response, refreshedTokens, request, { deviceId });
  } else if (backendResponse.status === 401) {
    clearAdminAuthCookies(response, request);
  }
  ensureAdminCsrfCookie(request, response);
  return response;
}
