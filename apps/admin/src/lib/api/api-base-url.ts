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

function looksLikeLocalApiHost(base: string): boolean {
  return base.includes('localhost') || base.includes('127.0.0.1');
}

export function isLocalApiBaseUrl(base?: string): boolean {
  return looksLikeLocalApiHost(base ?? getApiBaseUrl());
}

export function getApiBaseUrlMisconfigurationHint(): string | null {
  const base = getApiBaseUrl();
  if (!looksLikeLocalApiHost(base)) return null;
  if (process.env.VERCEL === '1' || process.env.NODE_ENV === 'production') {
    return ' The effective API base URL is still localhost. Set NEXT_PUBLIC_API_BASE_URL and redeploy, or set SERVER_API_BASE_URL (same value, server-only) so RSC picks it up at runtime without relying on the baked NEXT_PUBLIC value.';
  }
  return null;
}

/** BFF 502 copy when the upstream API cannot be reached (login, refresh, proxy). */
export function getApiConnectionErrorMessage(isTimeout: boolean): string {
  if (isLocalApiBaseUrl()) {
    return isTimeout
      ? 'The local API did not respond in time. Ensure PostgreSQL is running (`docker compose up -d postgres`) and the API is up (`pnpm dev:api`).'
      : 'Cannot reach the local API at http://localhost:3000. Start it with `pnpm dev:api` or run `pnpm dev` from the repo root.';
  }

  const origin = getApiOrigin();
  return isTimeout
    ? `The API (${origin}) did not respond in time. Check your network and that the deployed service is healthy.`
    : `Cannot reach the API at ${origin}. Confirm NEXT_PUBLIC_API_BASE_URL / SERVER_API_BASE_URL in the repo root \`.env\` or \`apps/admin/.env.local\`.`;
}
