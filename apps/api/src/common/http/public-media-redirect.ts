import type { Response } from 'express';

/**
 * 302 to a short-lived signed object URL for cross-origin `<img>` embeds.
 * Sets CORP so Helmet's default `same-origin` does not block landing pages.
 */
export function sendPublicMediaRedirect(
  res: Response,
  signedUrl: string,
  maxAgeSeconds: number,
): void {
  res.setHeader(
    'Cache-Control',
    maxAgeSeconds > 0
      ? `public, max-age=${maxAgeSeconds}, stale-while-revalidate=${Math.min(60, maxAgeSeconds)}`
      : 'private, no-store',
  );
  res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
  res.redirect(302, signedUrl);
}
