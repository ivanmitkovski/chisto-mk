/**
 * Stable public media URLs for news covers/inline assets.
 * HTML/ISR caches these forever; each request 302s to a freshly signed S3 URL.
 */
export function resolvePublicApiV1Base(raw: string | undefined | null): string {
  const fallback = 'https://api.chisto.mk/v1';
  const cleaned = raw?.trim().replace(/\/+$/, '');
  if (!cleaned) return fallback;
  if (cleaned.endsWith('/v1')) return cleaned;
  return `${cleaned}/v1`;
}

export function publicNewsMediaUrl(apiV1Base: string, mediaId: string): string {
  const base = apiV1Base.replace(/\/+$/, '');
  return `${base}/news/media/${encodeURIComponent(mediaId)}`;
}

/**
 * Browser/CDN cache for the 302 Location must stay under the signed-URL TTL
 * so a cached redirect never points at an already-expired S3 signature.
 */
export function newsMediaRedirectMaxAgeSeconds(
  signedUrlTtlSeconds: number,
  options?: { maxCapSeconds?: number; skewSeconds?: number },
): number {
  const maxCap = options?.maxCapSeconds ?? 120;
  const skew = options?.skewSeconds ?? 60;
  if (!Number.isFinite(signedUrlTtlSeconds) || signedUrlTtlSeconds <= 0) {
    return 0;
  }
  return Math.max(0, Math.min(maxCap, Math.floor(signedUrlTtlSeconds) - skew));
}
