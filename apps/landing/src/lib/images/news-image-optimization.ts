import { isSvgMediaUrl } from "@chisto/news-content";

/** Remote hosts allowed in next.config `images.remotePatterns`. */
const OPTIMIZABLE_REMOTE_SUFFIXES = [".amazonaws.com", ".cloudfront.net"];

export type NewsImageRole = "cover" | "inline";

/** Cover art and SVG assets stay fully visible; inline photos fill their frame. */
export function newsImageObjectFitClass(src: string, role: NewsImageRole = "inline"): string {
  if (role === "cover" || isSvgMediaUrl(src)) {
    return "object-contain object-center";
  }
  return "object-cover object-center";
}

/**
 * Next.js image optimizer can fail on presigned S3/CloudFront URLs.
 * Local and stable public URLs are safe to optimize.
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
