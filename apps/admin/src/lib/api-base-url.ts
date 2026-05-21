function normalizeBaseUrl(raw: string): string {
  const t = raw.trim();
  const withoutSlash = t.endsWith('/') ? t.slice(0, -1) : t;
  if (withoutSlash.endsWith('/v1')) return withoutSlash;
  return `${withoutSlash}/v1`;
}

/**
 * API origin for HTTP calls. On the server / Edge, `SERVER_API_BASE_URL` (or `API_BASE_URL`)
 * is read at **runtime** — unlike `NEXT_PUBLIC_*`, which is inlined at **build** time.
 * Set both to the same value in Vercel if dashboard RSC cannot reach the API after a bad build.
 */
export function getApiBaseUrl(): string {
  if (typeof window === 'undefined') {
    const serverOnly =
      process.env.SERVER_API_BASE_URL?.trim() || process.env.API_BASE_URL?.trim();
    if (serverOnly) return normalizeBaseUrl(serverOnly);
  }

  const raw = process.env.NEXT_PUBLIC_API_BASE_URL?.trim();
  if (!raw) return normalizeBaseUrl('http://localhost:3000');
  return normalizeBaseUrl(raw);
}

/** Host without `/v1` — for routes excluded from the API global prefix (e.g. `/health`). */
export function getApiOrigin(): string {
  const base = getApiBaseUrl();
  return base.endsWith('/v1') ? base.slice(0, -3) : base;
}

export function getApiBaseUrlMisconfigurationHint(): string | null {
  const base = getApiBaseUrl();
  const looksLocal = base.includes('localhost') || base.includes('127.0.0.1');
  if (!looksLocal) return null;
  if (process.env.VERCEL === '1' || process.env.NODE_ENV === 'production') {
    return ' The effective API base URL is still localhost. Set NEXT_PUBLIC_API_BASE_URL and redeploy, or set SERVER_API_BASE_URL (same value, server-only) so RSC picks it up at runtime without relying on the baked NEXT_PUBLIC value.';
  }
  return null;
}
