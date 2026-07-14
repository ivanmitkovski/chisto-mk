import { GOOGLE_PLAY_PACKAGE_ID } from "@/lib/store-links";

/** Paths claimed by AASA / Android App Links and the mobile DeepLinkRouter. */
export function isAppDeepLinkPath(pathname: string): boolean {
  return pathname === "/app" || pathname.startsWith("/app/");
}

const LOCALE_PREFIXED_APP = /^\/(mk|en|sq)(\/app(?:\/.*)?)$/;

/**
 * `/mk/app/...` is never a valid app link (AASA only claims `/app/*`).
 * Returns the locale-stripped pathname when a broken prefixed URL is detected.
 */
export function stripLocalePrefixedAppPath(pathname: string): string | null {
  const match = LOCALE_PREFIXED_APP.exec(pathname);
  return match?.[2] ?? null;
}

/**
 * Convert an https app universal link into the registered custom scheme.
 * `https://www.chisto.mk/app/home/map-focus?siteId=x` → `chisto://app/home/map-focus?siteId=x`
 */
export function httpsAppUrlToCustomScheme(httpsUrl: string): string | null {
  let url: URL;
  try {
    url = new URL(httpsUrl);
  } catch {
    return null;
  }
  if (!isAppDeepLinkPath(url.pathname)) {
    return null;
  }
  const pathAndQuery = `${url.pathname.replace(/^\//, "")}${url.search}`;
  return `chisto://${pathAndQuery}`;
}

/**
 * Android Chrome Intent URL that opens the installed app (or falls back).
 * @see https://developer.chrome.com/docs/android/intents
 */
export function httpsAppUrlToAndroidIntent(
  httpsUrl: string,
  browserFallbackUrl: string,
): string | null {
  let url: URL;
  try {
    url = new URL(httpsUrl);
  } catch {
    return null;
  }
  if (!isAppDeepLinkPath(url.pathname)) {
    return null;
  }
  const hostAndPath = `${url.pathname.replace(/^\//, "")}${url.search}`;
  const fallback = encodeURIComponent(browserFallbackUrl);
  return `intent://${hostAndPath}#Intent;scheme=chisto;package=${GOOGLE_PLAY_PACKAGE_ID};S.browser_fallback_url=${fallback};end`;
}

/** Resolve absolute https app URL from a relative or absolute href. */
export function resolveAppHttpsUrl(href: string, origin: string): string {
  return new URL(href, origin).toString();
}
