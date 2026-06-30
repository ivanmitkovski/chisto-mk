import compression from 'compression';
import type { Request, Response } from 'express';

export function pathFromRequest(req: Request): string {
  const raw =
    'originalUrl' in req && typeof req.originalUrl === 'string'
      ? req.originalUrl
      : (req.url ?? '');
  return raw.split('?')[0] ?? '';
}

/**
 * Express compression filter. Skips Socket.IO and SSE (text/event-stream) so
 * long-lived streams are not gzip-buffered (breaks heartbeats and client watchdogs).
 */
export function shouldCompressResponse(req: Request, res: Response): boolean {
  const path = pathFromRequest(req);
  if (path.includes('/socket.io')) {
    return false;
  }
  if (path.endsWith('/sites/events')) {
    return false;
  }
  const accept = req.headers.accept;
  if (typeof accept === 'string' && accept.includes('text/event-stream')) {
    return false;
  }
  const contentType = res.getHeader('Content-Type');
  if (typeof contentType === 'string' && contentType.includes('text/event-stream')) {
    return false;
  }
  return compression.filter(req, res);
}
