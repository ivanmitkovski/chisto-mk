import { getApiBaseUrl } from '@/lib/api-base-url';

/** Carto basemap tiles (Leaflet); explicit hosts avoid widening connect-src to untrusted origins. */
const CARTO_TILE_HOSTS = [
  'https://a.basemaps.cartocdn.com',
  'https://b.basemaps.cartocdn.com',
  'https://c.basemaps.cartocdn.com',
] as const;

/**
 * Per-request CSP for the admin app. Call from middleware (Edge) so `getApiBaseUrl()` matches
 * server/middleware runtime env. Next.js reads `Content-Security-Policy` on the incoming request
 * and applies `nonce` to framework script tags when `script-src` includes `'nonce-…'`.
 */
export function buildAdminContentSecurityPolicy(nonce: string, isDev: boolean): string {
  const apiOrigin = getApiBaseUrl();
  const scriptSrc = [
    "'self'",
    `'nonce-${nonce}'`,
    "'strict-dynamic'",
    ...(isDev ? ["'unsafe-eval'" as const] : []),
  ].join(' ');

  return [
    "default-src 'self'",
    `script-src ${scriptSrc}`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: https: blob:",
    `connect-src 'self' ${apiOrigin} ${CARTO_TILE_HOSTS.join(' ')}`,
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
  ].join('; ');
}
