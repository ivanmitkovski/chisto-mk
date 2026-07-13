import {
  newsMediaRedirectMaxAgeSeconds,
  resolvePublicApiV1Base,
} from '../../news/services/news-public-media-url';

export { newsMediaRedirectMaxAgeSeconds as shareMediaRedirectMaxAgeSeconds, resolvePublicApiV1Base };

/** Stable share gallery URL — ISR/HTML never embeds expiring S3 signatures. */
export function publicShareMediaUrl(apiV1Base: string, siteId: string, index: number): string {
  const base = apiV1Base.replace(/\/+$/, '');
  return `${base}/sites/${encodeURIComponent(siteId)}/share-media/${index}`;
}

export function publicShareEvidenceUrl(apiV1Base: string, siteId: string, index: number): string {
  const base = apiV1Base.replace(/\/+$/, '');
  return `${base}/sites/${encodeURIComponent(siteId)}/share-evidence/${index}`;
}

export function publicShareAvatarUrl(apiV1Base: string, siteId: string): string {
  const base = apiV1Base.replace(/\/+$/, '');
  return `${base}/sites/${encodeURIComponent(siteId)}/share-avatar`;
}
