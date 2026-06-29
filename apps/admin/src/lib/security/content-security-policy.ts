import { NEWS_EMBED_FRAME_SRC_ORIGINS } from '@chisto/news-content';

/** Carto basemap tiles (Leaflet); explicit hosts avoid widening connect-src to untrusted origins. */
const CARTO_TILE_HOSTS = [
  'https://a.basemaps.cartocdn.com',
  'https://b.basemaps.cartocdn.com',
  'https://c.basemaps.cartocdn.com',
] as const;

const S3_MEDIA_HOSTS = [
  'https://chisto-dev-media.s3.eu-central-1.amazonaws.com',
  'https://chisto-prod-media.s3.eu-central-1.amazonaws.com',
] as const;

const FRAME_SRC = ["'self'", ...NEWS_EMBED_FRAME_SRC_ORIGINS].join(' ');

/**
 * Per-request CSP for the admin app. Call from middleware (Edge) so `getApiBaseUrl()` matches
 * server/middleware runtime env. Next.js reads `Content-Security-Policy` on the incoming request
 * and applies `nonce` to framework script tags when `script-src` includes `'nonce-…'`.
 */
export function buildAdminContentSecurityPolicy(nonce: string, isDev: boolean): string {
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
    `media-src 'self' blob: https: ${S3_MEDIA_HOSTS.join(' ')}`,
    `connect-src 'self' ${CARTO_TILE_HOSTS.join(' ')}`,
    `frame-src ${FRAME_SRC}`,
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
  ].join('; ');
}

export function buildAdminReportOnlyContentSecurityPolicy(nonce: string, isDev: boolean): string {
  const scriptSrc = [
    "'self'",
    `'nonce-${nonce}'`,
    "'strict-dynamic'",
    ...(isDev ? ["'unsafe-eval'" as const] : []),
  ].join(' ');

  return [
    "default-src 'self'",
    `script-src ${scriptSrc}`,
    "style-src 'self'",
    `img-src 'self' data: blob: ${S3_MEDIA_HOSTS.join(' ')} ${CARTO_TILE_HOSTS.join(' ')}`,
    `media-src 'self' blob: ${S3_MEDIA_HOSTS.join(' ')}`,
    `connect-src 'self' ${CARTO_TILE_HOSTS.join(' ')}`,
    `frame-src ${FRAME_SRC}`,
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "require-trusted-types-for 'script'",
    "report-uri /api/security/csp-report",
  ].join('; ');
}
