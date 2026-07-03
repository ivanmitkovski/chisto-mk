/// <reference types="jest" />

import {
  cacheEntryExpiresAtMs,
  effectivePresignTtlSeconds,
  isCachedNewsSignedUrlStillValid,
  parseCachedNewsSignedUrl,
  serializeCachedNewsSignedUrl,
} from '../../src/news/services/news-media-signed-url.cache';

const CACHE_SKEW_MS = 30_000;
const SESSION_URL =
  'https://bucket.s3.eu-central-1.amazonaws.com/news/cover.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20260703T171557Z&X-Amz-Expires=3600&X-Amz-Security-Token=abc&X-Amz-Signature=deadbeef';

describe('parseCachedNewsSignedUrl', () => {
  it('parses JSON cache entries', () => {
    const raw = serializeCachedNewsSignedUrl({
      url: 'https://example.com/a.png',
      credentialExpiresAt: 1_700_000_000_000,
    });
    expect(parseCachedNewsSignedUrl(raw)).toEqual({
      url: 'https://example.com/a.png',
      credentialExpiresAt: 1_700_000_000_000,
    });
  });

  it('accepts legacy raw URL strings', () => {
    expect(parseCachedNewsSignedUrl('https://example.com/a.png')).toEqual({
      url: 'https://example.com/a.png',
      credentialExpiresAt: null,
    });
  });
});

describe('isCachedNewsSignedUrlStillValid', () => {
  it('rejects legacy session-token URLs without credential expiry', () => {
    const nowMs = Date.UTC(2026, 6, 3, 17, 49, 0);
    expect(
      isCachedNewsSignedUrlStillValid(
        { url: SESSION_URL, credentialExpiresAt: null },
        nowMs,
        CACHE_SKEW_MS,
      ),
    ).toBe(false);
  });

  it('accepts session-token URLs when credentials are still valid', () => {
    const nowMs = Date.UTC(2026, 6, 3, 17, 49, 0);
    expect(
      isCachedNewsSignedUrlStillValid(
        {
          url: SESSION_URL,
          credentialExpiresAt: nowMs + 60 * 60 * 1000,
        },
        nowMs,
        CACHE_SKEW_MS,
      ),
    ).toBe(true);
  });

  it('rejects entries when credential expiry has passed', () => {
    const nowMs = Date.UTC(2026, 6, 3, 18, 30, 0);
    expect(
      isCachedNewsSignedUrlStillValid(
        {
          url: SESSION_URL,
          credentialExpiresAt: Date.UTC(2026, 6, 3, 18, 0, 0),
        },
        nowMs,
        CACHE_SKEW_MS,
      ),
    ).toBe(false);
  });
});

describe('effectivePresignTtlSeconds', () => {
  it('caps presign TTL to credential lifetime', () => {
    const nowMs = Date.UTC(2026, 6, 3, 17, 0, 0);
    expect(
      effectivePresignTtlSeconds(
        3600,
        Date.UTC(2026, 6, 3, 17, 20, 0),
        nowMs,
        CACHE_SKEW_MS,
      ),
    ).toBe(1170);
  });
});

describe('cacheEntryExpiresAtMs', () => {
  it('uses the earliest of URL, presign, and credential expiry', () => {
    const nowMs = Date.UTC(2026, 6, 3, 17, 0, 0);
    const url =
      'https://bucket.s3.eu-central-1.amazonaws.com/key.jpg?X-Amz-Date=20260703T170000Z&X-Amz-Expires=3600';
    const expiresAt = cacheEntryExpiresAtMs(
      url,
      Date.UTC(2026, 6, 3, 17, 15, 0),
      nowMs,
      3600,
      CACHE_SKEW_MS,
    );
    expect(expiresAt).toBe(Date.UTC(2026, 6, 3, 17, 15, 0) - CACHE_SKEW_MS);
  });
});
