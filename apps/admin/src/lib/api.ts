const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000';

type HttpMethod = 'GET' | 'POST' | 'PATCH';

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
  const url = `${API_BASE_URL}${path}`;

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

  const response = await fetch(
    url,
    {
      method: options.method ?? 'GET',
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : null,
      cache: options.cache ?? 'no-store',
    },
  );

  if (response.ok) {
    const payload = await parseJsonSafe(response);
    return payload as TResponse;
  }

  const payload = (await parseJsonSafe(response)) as
    | {
        code?: unknown;
        message?: unknown;
        details?: unknown;
      }
    | null;

  const code = payload && typeof payload.code === 'string' ? payload.code : 'HTTP_ERROR';
  const message =
    payload && typeof payload.message === 'string'
      ? payload.message
      : `Request to ${path} failed with status ${response.status}`;

  throw new ApiError(response.status, code, message, payload?.details);
}

