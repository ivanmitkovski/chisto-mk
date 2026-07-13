import { isSvgMediaUrl } from "@chisto/news-content";

/** Remote hosts allowed in next.config `images.remotePatterns`. */
const OPTIMIZABLE_REMOTE_SUFFIXES = [".amazonaws.com", ".cloudfront.net"];

export type NewsImageRole = "cover" | "inline";

/** Cover art fills a 21:9 frame; SVG logos stay fully visible. Inline photos fill their frame. */
export function newsImageObjectFitClass(src: string, role: NewsImageRole = "inline"): string {
  if (isSvgMediaUrl(src)) {
    return "object-contain object-center";
  }
  if (role === "cover") {
    return "object-cover object-center";
  }
  return "object-cover object-center";
}

/**
 * Next.js image optimizer can fail on:
 * - SVG assets
 * - Presigned S3/CloudFront URLs
 * - API media redirect URLs (`/news/media/:id` → 302 → S3) — browser must follow redirects
 * Local and stable public CDN URLs are safe to optimize.
 */
export function shouldUseUnoptimizedNewsImage(src: string): boolean {
  if (isSvgMediaUrl(src)) {
    return true;
  }

  if (!src.startsWith("http://") && !src.startsWith("https://")) {
    return false;
  }

  try {
    const url = new URL(src);
    const path = url.pathname.toLowerCase();
    // Stable public media redirects must be loaded by the browser (follow 302 → S3).
    if (/\/news\/media\/[^/]+\/?$/.test(path)) {
      return true;
    }
    if (/\/sites\/[^/]+\/share-(media|evidence)\/\d+\/?$/.test(path) || /\/sites\/[^/]+\/share-avatar\/?$/.test(path)) {
      return true;
    }

    const host = url.hostname.toLowerCase();
    const allowedRemote = OPTIMIZABLE_REMOTE_SUFFIXES.some((suffix) => host.endsWith(suffix));
    if (!allowedRemote) return true;

    const query = url.search.toLowerCase();
    if (
      query.includes("x-amz-signature") ||
      query.includes("x-amz-credential") ||
      query.includes("signature=")
    ) {
      return true;
    }

    return false;
  } catch {
    return true;
  }
}
