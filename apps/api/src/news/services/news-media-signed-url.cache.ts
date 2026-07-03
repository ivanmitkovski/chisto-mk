import { presignedUrlExpiresAtMs } from '../../storage/services/report-media-signed-url.service';

export type CachedNewsSignedUrl = {
  url: string;
  credentialExpiresAt: number | null;
};

export function serializeCachedNewsSignedUrl(entry: CachedNewsSignedUrl): string {
  return JSON.stringify(entry);
}

export function parseCachedNewsSignedUrl(raw: string): CachedNewsSignedUrl | null {
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as { url?: unknown; credentialExpiresAt?: unknown };
    if (typeof parsed.url !== 'string' || parsed.url.length === 0) {
      return null;
    }
    const credentialExpiresAt =
      typeof parsed.credentialExpiresAt === 'number' && Number.isFinite(parsed.credentialExpiresAt)
        ? parsed.credentialExpiresAt
        : null;
    return { url: parsed.url, credentialExpiresAt };
  } catch {
    // Legacy Redis entries stored the raw URL string.
    return { url: raw, credentialExpiresAt: null };
  }
}

export function isPresignedUrlStillValid(url: string, nowMs: number, cacheSkewMs: number): boolean {
  const expiry = presignedUrlExpiresAtMs(url);
  if (expiry == null) {
    return false;
  }
  return expiry > nowMs + cacheSkewMs;
}

/** Session-token URLs must not be served from cache without credential expiry metadata. */
export function isCachedNewsSignedUrlStillValid(
  entry: CachedNewsSignedUrl,
  nowMs: number,
  cacheSkewMs: number,
): boolean {
  if (!isPresignedUrlStillValid(entry.url, nowMs, cacheSkewMs)) {
    return false;
  }

  if (entry.credentialExpiresAt != null) {
    return entry.credentialExpiresAt > nowMs + cacheSkewMs;
  }

  try {
    const url = new URL(entry.url);
    if (url.searchParams.has('X-Amz-Security-Token')) {
      return false;
    }
  } catch {
    return false;
  }

  return true;
}

export function cacheEntryExpiresAtMs(
  url: string,
  credentialExpiresAtMs: number | null,
  nowMs: number,
  expiresInSeconds: number,
  cacheSkewMs: number,
): number {
  const urlExpiry = presignedUrlExpiresAtMs(url);
  const signedExpiry = nowMs + expiresInSeconds * 1000 - cacheSkewMs;
  let expiresAt = urlExpiry != null ? Math.min(urlExpiry - cacheSkewMs, signedExpiry) : signedExpiry;
  if (credentialExpiresAtMs != null) {
    expiresAt = Math.min(expiresAt, credentialExpiresAtMs - cacheSkewMs);
  }
  return expiresAt;
}

export function effectivePresignTtlSeconds(
  desiredTtlSeconds: number,
  credentialExpiresAtMs: number | null,
  nowMs: number,
  cacheSkewMs: number,
): number {
  if (credentialExpiresAtMs == null) {
    return desiredTtlSeconds;
  }
  const maxByCredential = Math.floor((credentialExpiresAtMs - nowMs - cacheSkewMs) / 1000);
  if (maxByCredential < 60) {
    return Math.max(60, maxByCredential);
  }
  return Math.min(desiredTtlSeconds, maxByCredential);
}
