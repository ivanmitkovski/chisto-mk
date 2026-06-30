export {
  getApiBaseUrl,
  getApiBaseUrlMisconfigurationHint,
  getApiConnectionErrorMessage,
  getApiOrigin,
  isLocalApiBaseUrl,
} from './api-base-url';

export class ApiConnectionError extends Error {
  readonly code = 'API_CONNECTION_FAILED';

  constructor(message: string, options?: { cause?: unknown }) {
    super(message, options);
    this.name = 'ApiConnectionError';
  }
}

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly details?: unknown;
  readonly requestId?: string;

  constructor(
    status: number,
    code: string,
    message: string,
    details?: unknown,
    requestId?: string,
  ) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.details = details;
    if (requestId !== undefined) {
      this.requestId = requestId;
    }
  }
}

export async function apiFetch<TResponse>(
  path: string,
  options: import('./admin-fetch').AdminFetchOptions = {},
): Promise<TResponse> {
  const { adminFetchCore } = await import('./admin-fetch');
  return adminFetchCore<TResponse>(path, options);
}

