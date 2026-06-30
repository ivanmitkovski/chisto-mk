/** Remote hosts allowed in next.config `images.remotePatterns`. */
const OPTIMIZABLE_REMOTE_SUFFIXES = [".amazonaws.com", ".cloudfront.net"];

/**
 * Next.js image optimizer can fail on presigned S3/CloudFront URLs.
 * Local and stable public URLs are safe to optimize.
 */
export function shouldUseUnoptimizedNewsImage(src: string): boolean {
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
