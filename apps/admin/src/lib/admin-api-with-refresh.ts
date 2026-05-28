import { NextRequest, NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/api-base-url';
import {
  clearAdminAuthCookies,
  ensureAdminCsrfCookie,
  getAdminAccessToken,
  getAdminRefreshToken,
  getOrCreateAdminDeviceId,
  refreshAdminTokens,
  setAdminAuthCookies,
  verifyAdminCsrf,
} from '@/lib/server/admin-session';

type RequestInitWithBody = RequestInit & { body?: unknown };
const mutationRateBuckets = new Map<string, { count: number; resetAt: number }>();
const MUTATION_RATE_LIMIT = 120;
const MUTATION_RATE_WINDOW_MS = 60_000;
const FORWARDED_HEADER_ALLOWLIST = new Set([
  'accept',
  'content-type',
  'if-match',
  'if-none-match',
  'idempotency-key',
  'x-idempotency-key',
]);

function checkMutationRateLimit(request: NextRequest): boolean {
  const method = request.method.toUpperCase();
  if (method === 'GET' || method === 'HEAD' || method === 'OPTIONS') return true;
  const forwarded = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim();
  const key = `${forwarded || 'local'}:${getAdminAccessToken(request) ?? 'anon'}`;
  const now = Date.now();
  const bucket = mutationRateBuckets.get(key);
  if (!bucket || bucket.resetAt <= now) {
    mutationRateBuckets.set(key, { count: 1, resetAt: now + MUTATION_RATE_WINDOW_MS });
    return true;
  }
  bucket.count += 1;
  return bucket.count <= MUTATION_RATE_LIMIT;
}

export function createBackendProxyHeaders(request: NextRequest, accessToken: string | null): Headers {
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
    headers.set('Accept-Language', 'en');
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

export async function fetchBackendWithRefresh(
  path: string,
  request: NextRequest,
  init: RequestInitWithBody = {},
): Promise<{ response: Response; nextResponse: NextResponse }> {
  if (!checkMutationRateLimit(request)) {
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

  const accessToken = getAdminAccessToken(request);
  const refreshToken = getAdminRefreshToken(request);
  const deviceId = getOrCreateAdminDeviceId(request);

  const url = `${getApiBaseUrl()}${path}`;
  const headers: Record<string, string> = {
    Accept: 'application/json',
    ...((init.headers as Record<string, string>) ?? {}),
  };
  headers['X-Request-Id'] = headers['X-Request-Id'] ?? request.headers.get('x-request-id') ?? crypto.randomUUID();
  if (accessToken) {
    headers.Authorization = `Bearer ${accessToken}`;
  }
  if (init.body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }
  const method = init.method?.toUpperCase() ?? 'GET';
  if (
    method !== 'GET' &&
    method !== 'HEAD' &&
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

  let res = await fetch(url, fetchInit);

  if (res.status === 401 && refreshToken) {
    const tokens = await refreshAdminTokens(refreshToken, deviceId);
    if (tokens) {
      headers.Authorization = `Bearer ${tokens.accessToken}`;
      res = await fetch(url, fetchInit);
      const payload = await res.json().catch(() => ({}));
      const nextRes = NextResponse.json(payload, { status: res.status });
      nextRes.headers.set('x-request-id', headers['X-Request-Id']);
      setAdminAuthCookies(nextRes, tokens, request, { deviceId });
      ensureAdminCsrfCookie(request, nextRes);
      return { response: res, nextResponse: nextRes };
    }
  }

  const payload = await res.json().catch(() => ({}));
  const nextResponse = NextResponse.json(payload, { status: res.status });
  nextResponse.headers.set('x-request-id', headers['X-Request-Id']);
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
  if (!checkMutationRateLimit(request)) {
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

  const accessToken = getAdminAccessToken(request);
  const refreshToken = getAdminRefreshToken(request);
  const deviceId = getOrCreateAdminDeviceId(request);
  const headers = createBackendProxyHeaders(request, accessToken);

  const body =
    request.method === 'GET' || request.method === 'HEAD' ? undefined : await request.text();
  const run = () => {
    const init: RequestInit = {
      method: request.method,
      headers,
      cache: 'no-store',
    };
    if (body !== undefined) {
      init.body = body;
    }
    return fetch(`${getApiBaseUrl()}${path}`, init);
  };

  let backendResponse = await run();
  let refreshedTokens: Awaited<ReturnType<typeof refreshAdminTokens>> = null;
  if (backendResponse.status === 401 && refreshToken) {
    refreshedTokens = await refreshAdminTokens(refreshToken, deviceId);
    if (refreshedTokens) {
      headers.set('Authorization', `Bearer ${refreshedTokens.accessToken}`);
      backendResponse = await run();
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
  response.headers.set('x-request-id', headers.get('X-Request-Id') ?? crypto.randomUUID());
  if (refreshedTokens) {
    setAdminAuthCookies(response, refreshedTokens, request, { deviceId });
  } else if (backendResponse.status === 401) {
    clearAdminAuthCookies(response, request);
  }
  ensureAdminCsrfCookie(request, response);
  return response;
}
