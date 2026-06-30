import type { ErrorEvent, EventHint } from '@sentry/node';

const SENSITIVE_QUERY = new Set([
  'token',
  'access_token',
  'refresh_token',
  'password',
  'otp',
  'code',
  'email',
  'phone',
]);

export function sentryBeforeSend(event: ErrorEvent, _hint: EventHint): ErrorEvent | null {
  if (event.request?.headers) {
    const headers = { ...event.request.headers };
    for (const key of Object.keys(headers)) {
      if (key.toLowerCase() === 'authorization' || key.toLowerCase() === 'cookie') {
        headers[key] = '[Filtered]';
      }
    }
    event.request = { ...event.request, headers };
  }
  if (event.request?.url) {
    try {
      const url = new URL(event.request.url, 'http://localhost');
      for (const key of [...url.searchParams.keys()]) {
        if (SENSITIVE_QUERY.has(key.toLowerCase())) {
          url.searchParams.set(key, '[Filtered]');
        }
      }
      event.request = { ...event.request, url: url.pathname + url.search };
    } catch {
      // keep original
    }
  }
  if (event.extra && typeof event.extra === 'object') {
    event.extra = scrubRecord(event.extra as Record<string, unknown>);
  }
  if (event.request?.data && typeof event.request.data === 'object') {
    event.request = {
      ...event.request,
      data: scrubRecord(event.request.data as Record<string, unknown>),
    };
  }
  return event;
}

function scrubRecord(input: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(input)) {
    if (SENSITIVE_QUERY.has(key.toLowerCase())) {
      out[key] = '[Filtered]';
      continue;
    }
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      out[key] = scrubRecord(value as Record<string, unknown>);
      continue;
    }
    out[key] = value;
  }
  return out;
}
