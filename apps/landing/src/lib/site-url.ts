/** Canonical production origin (no trailing slash). */
export const PRODUCTION_SITE_URL = "https://www.chisto.mk";

/**
 * Canonical site origin for sitemap, robots, metadata, and absolute URLs (no trailing slash).
 *
 * Priority: NEXT_PUBLIC_SITE_URL → VERCEL_URL (preview/dev only) → production www.
 * Never use ephemeral VERCEL_URL when VERCEL_ENV is production.
 */
export function getSiteUrl(): string {
  const explicit = process.env.NEXT_PUBLIC_SITE_URL?.trim();
  if (explicit) return explicit.replace(/\/$/, "");

  const allowVercelFallback =
    process.env.VERCEL_ENV === "preview" || process.env.NODE_ENV !== "production";
  if (allowVercelFallback) {
    const vercel = process.env.VERCEL_URL?.trim();
    if (vercel) return `https://${vercel.replace(/\/$/, "")}`;
  }

  return PRODUCTION_SITE_URL;
}
