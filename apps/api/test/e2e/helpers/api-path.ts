const UNPREFIXED = new Set(['/health', '/metrics', '/api/docs']);

/** Prefix paths for Nest global prefix `v1` (health/metrics excluded). */
export function apiPath(path: string): string {
  const normalized = path.startsWith('/') ? path : `/${path}`;
  if (normalized.startsWith('/v1/') || UNPREFIXED.has(normalized.split('?')[0] ?? normalized)) {
    return normalized;
  }
  return `/v1${normalized}`;
}
