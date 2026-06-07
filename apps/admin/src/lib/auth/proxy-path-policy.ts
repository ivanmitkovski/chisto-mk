/**
 * Allowlisted upstream API path prefixes for the BFF catch-all proxy.
 * Reject path traversal and unknown namespaces before forwarding.
 */
const PROXY_PATH_PREFIXES = [
  '/admin/',
  '/auth/',
  '/sites/',
  '/reports/',
  '/notifications/',
] as const;

export function normalizeProxyPathSegments(segments: string[]): string | null {
  if (segments.length === 0) return null;
  for (const segment of segments) {
    if (!segment || segment === '.' || segment === '..') return null;
    try {
      const decoded = decodeURIComponent(segment);
      if (decoded === '.' || decoded === '..' || decoded.includes('/')) return null;
    } catch {
      return null;
    }
  }
  return `/${segments.map(encodeURIComponent).join('/')}`;
}

export function isProxyPathAllowed(path: string): boolean {
  if (!path.startsWith('/')) return false;
  return PROXY_PATH_PREFIXES.some((prefix) => path.startsWith(prefix));
}
