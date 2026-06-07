import { getApiBaseUrl } from './api-base-url';

export type HttpMethod = 'GET' | 'POST' | 'PATCH' | 'DELETE';

export type AdminFetchOptions = {
  method?: HttpMethod;
  headers?: Record<string, string>;
  body?: unknown;
  authToken?: string | null;
  cache?: RequestCache;
  /** API origin without `/v1` — required for routes excluded from the global prefix (e.g. `/health/*`). */
  baseUrl?: string;
  /** Request timeout in milliseconds. Defaults to 30_000. */
  timeoutMs?: number;
  /** Retry idempotent GET on 502/503 with jitter. Defaults to true for GET. */
  retryOnGatewayError?: boolean;
  /** Propagate or generate a request id for tracing. */
  requestId?: string;
  /** BCP-47 Accept-Language header for server-side API calls. */
  acceptLanguage?: string;
};

const DEFAULT_TIMEOUT_MS = 30_000;
const MAX_GET_RETRIES = 2;

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function jitterMs(baseMs: number): number {
  return baseMs + Math.floor(Math.random() * 250);
}

async function parseJsonSafe(response: Response): Promise<unknown | null> {
  const contentType = response.headers.get('content-type');
  if (!contentType || !contentType.includes('application/json')) {
    return null;
  }

  try {
    return await response.json();
  } catch {
    return null;
  }
}

export async function executeAdminFetch(
  url: string,
  init: RequestInit,
  options: {
    path: string;
    timeoutMs: number;
    method: HttpMethod;
    retryOnGatewayError: boolean;
    requestId: string;
  },
): Promise<Response> {
  const shouldRetry = options.retryOnGatewayError && options.method === 'GET';
  let attempt = 0;

  while (true) {
    attempt += 1;
    try {
      const response = await fetch(url, {
        ...init,
        signal: AbortSignal.timeout(options.timeoutMs),
      });

      if (
        shouldRetry &&
        attempt <= MAX_GET_RETRIES &&
        (response.status === 502 || response.status === 503)
      ) {
        await sleep(jitterMs(200 * attempt));
        continue;
      }

      return response;
    } catch (cause) {
      const isTimeout =
        cause instanceof DOMException
          ? cause.name === 'TimeoutError'
          : cause instanceof Error && cause.name === 'TimeoutError';

      if (shouldRetry && attempt <= MAX_GET_RETRIES && !isTimeout) {
        await sleep(jitterMs(200 * attempt));
        continue;
      }

      if (typeof window === 'undefined') {
        const { logger } = await import('../observability');
        logger.error('admin_fetch_network_failure', {
          path: options.path,
          url,
          requestId: options.requestId,
          cause:
            cause instanceof Error
              ? { name: cause.name, message: cause.message }
              : String(cause),
        });
      }

      const { ApiConnectionError } = await import('./api');
      throw new ApiConnectionError(`Network request to API failed (${options.path})`, { cause });
    }
  }
}

export async function parseAdminFetchResponse<TResponse>(
  response: Response,
  path: string,
  requestId: string,
): Promise<TResponse> {
  if (response.ok) {
    const payload = await parseJsonSafe(response);
    return payload as TResponse;
  }

  const payload = (await parseJsonSafe(response)) as
    | {
        code?: unknown;
        message?: unknown;
        details?: unknown;
        retryAfterSeconds?: number;
      }
    | null;

  const { ApiError } = await import('./api');
  const code = payload && typeof payload.code === 'string' ? payload.code : 'HTTP_ERROR';
  const message =
    payload && typeof payload.message === 'string'
      ? payload.message
      : `Request to ${path} failed with status ${response.status}`;
  const details =
    payload?.details ??
    (payload?.retryAfterSeconds != null ? { retryAfterSeconds: payload.retryAfterSeconds } : undefined);

  const responseRequestId = response.headers.get('x-request-id') ?? requestId;
  throw new ApiError(response.status, code, message, details, responseRequestId);
}

export function buildAdminFetchRequest(
  path: string,
  options: AdminFetchOptions = {},
): { url: string; init: RequestInit; requestId: string; method: HttpMethod } {
  const base = options.baseUrl ?? getApiBaseUrl();
  const url = `${base}${path}`;
  const method = options.method ?? 'GET';
  const requestId = options.requestId ?? crypto.randomUUID();

  const headers: Record<string, string> = {
    Accept: 'application/json',
    'X-Request-Id': requestId,
    ...(options.headers ?? {}),
  };

  if (
    typeof window === 'undefined' &&
    options.acceptLanguage &&
    !headers['Accept-Language'] &&
    !headers['accept-language']
  ) {
    headers['Accept-Language'] = options.acceptLanguage;
  }

  if (options.body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }

  if (options.authToken) {
    headers.Authorization = `Bearer ${options.authToken}`;
  }

  const init: RequestInit = {
    method,
    headers,
    body: options.body !== undefined ? JSON.stringify(options.body) : null,
    cache: options.cache ?? 'no-store',
  };

  return { url, init, requestId, method };
}

export async function fetchBackendResponse(
  path: string,
  options: AdminFetchOptions = {},
): Promise<Response> {
  const timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const retryOnGatewayError = options.retryOnGatewayError ?? (options.method ?? 'GET') === 'GET';
  const { url, init, requestId, method } = buildAdminFetchRequest(path, options);

  return executeAdminFetch(url, init, {
    path,
    timeoutMs,
    method,
    retryOnGatewayError,
    requestId,
  });
}

export async function adminFetchCore<TResponse>(
  path: string,
  options: AdminFetchOptions = {},
): Promise<TResponse> {
  const timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const retryOnGatewayError = options.retryOnGatewayError ?? (options.method ?? 'GET') === 'GET';
  const { url, init, requestId, method } = buildAdminFetchRequest(path, options);

  const response = await executeAdminFetch(url, init, {
    path,
    timeoutMs,
    method,
    retryOnGatewayError,
    requestId,
  });

  return parseAdminFetchResponse<TResponse>(response, path, requestId);
}
