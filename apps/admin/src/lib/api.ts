type HttpMethod = 'GET' | 'POST' | 'PATCH' | 'DELETE';

/** Resolve at call time so server components see env correctly; trim trailing slash. */
export function getApiBaseUrl(): string {
  const raw = process.env.NEXT_PUBLIC_API_BASE_URL?.trim();
  if (!raw) return 'http://localhost:3000';
  return raw.endsWith('/') ? raw.slice(0, -1) : raw;
}

export class ApiConnectionError extends Error {
  readonly code = 'API_CONNECTION_FAILED';

  constructor(message: string, options?: { cause?: unknown }) {
    super(message, options);
    this.name = 'ApiConnectionError';
  }
}

/** Extra hint when production build still points at localhost (misconfigured deploy). */
export function getApiBaseUrlMisconfigurationHint(): string | null {
  const base = getApiBaseUrl();
  const looksLocal = base.includes('localhost') || base.includes('127.0.0.1');
  if (!looksLocal) return null;
  if (process.env.VERCEL === '1' || process.env.NODE_ENV === 'production') {
    return ' The deployed app is still using a localhost API URL — set NEXT_PUBLIC_API_BASE_URL to https://api.chisto.mk (or your API URL) in Vercel Environment Variables and redeploy.';
  }
  return null;
}

type FetchOptions = {
  method?: HttpMethod;
  headers?: Record<string, string>;
  body?: unknown;
  authToken?: string | null;
  cache?: RequestCache;
};

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

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly details?: unknown;

  constructor(status: number, code: string, message: string, details?: unknown) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export async function apiFetch<TResponse>(path: string, options: FetchOptions = {}): Promise<TResponse> {
  const base = getApiBaseUrl();
  const url = `${base}${path}`;

  const headers: Record<string, string> = {
    Accept: 'application/json',
    ...(options.headers ?? {}),
  };

  if (options.body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }

  if (options.authToken) {
    headers.Authorization = `Bearer ${options.authToken}`;
  }

  let response: Response;
  try {
    response = await fetch(url, {
      method: options.method ?? 'GET',
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : null,
      cache: options.cache ?? 'no-store',
    });
  } catch (cause) {
    throw new ApiConnectionError(`Network request to API failed (${path})`, { cause });
  }

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

  const code = payload && typeof payload.code === 'string' ? payload.code : 'HTTP_ERROR';
  const message =
    payload && typeof payload.message === 'string'
      ? payload.message
      : `Request to ${path} failed with status ${response.status}`;
  const details = payload?.details ?? (payload?.retryAfterSeconds != null ? { retryAfterSeconds: payload.retryAfterSeconds } : undefined);

  throw new ApiError(response.status, code, message, details);
}

