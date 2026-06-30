import type { Request, Response, NextFunction } from 'express';

const UNPREFIXED = new Set(['/health', '/metrics', '/api/docs', '/api/docs-json']);

/** Rewrite unprefixed legacy paths to `/v1/*` during grace period; emit version headers. */
export function apiVersionMiddleware(req: Request, res: Response, next: NextFunction): void {
  res.setHeader('X-API-Version', 'v1');
  const raw = req.url ?? '/';
  const [pathOnly, query = ''] = raw.split('?');
  const path = pathOnly || '/';
  if (!UNPREFIXED.has(path) && !path.startsWith('/v1')) {
    res.setHeader('Deprecation', 'true');
    res.setHeader('Link', `<${'/v1' + path}>; rel="successor-version"`);
    const q = query ? `?${query}` : '';
    req.url = `/v1${path.startsWith('/') ? path : `/${path}`}${q}`;
  }
  next();
}
