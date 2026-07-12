/**
 * Trusted iframe origins for news embeds.
 * Keep in sync with `NEWS_EMBED_FRAME_SRC_ORIGINS` in
 * `@chisto/news-content` (`packages/news-content/src/sanitize/embed-allowlist.ts`).
 * Parity is enforced by `content-security-policy.test.ts`.
 *
 * Intentionally duplicated here so `next.config.ts` does not import the
 * workspace package (Vercel landing builds resolve `require` to
 * `@chisto/news-content/dist/...`, which is not built in that pipeline).
 */
export const LANDING_NEWS_EMBED_FRAME_SRC_ORIGINS = [
  'https://www.youtube.com',
  'https://youtube.com',
  'https://www.youtube-nocookie.com',
  'https://youtube-nocookie.com',
  'https://player.vimeo.com',
  'https://vimeo.com',
] as const;

/**
 * Landing CSP without nonces so pages stay statically generated (nonce CSP forces
 * dynamic rendering). `script-src 'unsafe-inline'` is required by Next.js
 * hydration inline scripts; JSON-LD blocks are inert data and unaffected.
 * Production Web Analytics loads same-origin `/_vercel/insights/script.js`
 * (requires Analytics enabled in the Vercel project + a redeploy).
 * va.vercel-scripts.com is used by @vercel/analytics in development/debug mode.
 * `unsafe-eval` is dev-only: webpack HMR and eval source maps need it.
 *
 * `frame-src` allows news article YouTube/Vimeo embeds (sanitized via
 * `@chisto/news-content`); origins must stay aligned with the shared allowlist.
 */
export function buildLandingContentSecurityPolicy(isDev: boolean): string {
  const frameSrc = ["'self'", ...LANDING_NEWS_EMBED_FRAME_SRC_ORIGINS].join(' ');

  return [
    "default-src 'self'",
    `script-src 'self' 'unsafe-inline'${isDev ? " 'unsafe-eval'" : ''} https://va.vercel-scripts.com`,
    "style-src 'self' 'unsafe-inline'",
    // News covers may come from any HTTPS CDN host the admin configures; images are low-risk.
    "img-src 'self' data: blob: https:",
    "font-src 'self'",
    // 'self' covers /_vercel/insights/{view,event}; CDN used in local debug mode.
    "connect-src 'self' https://*.amazonaws.com https://*.cloudfront.net https://va.vercel-scripts.com",
    `frame-src ${frameSrc}`,
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    'upgrade-insecure-requests',
  ].join('; ');
}
