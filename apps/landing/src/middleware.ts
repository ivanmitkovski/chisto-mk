import createMiddleware from "next-intl/middleware";
import { type NextRequest, NextResponse } from "next/server";
import {
  defaultLocale,
  isLocale,
  resolveShareLocale,
  type ShareLocale,
} from "./i18n/config";
import { routing } from "./i18n/routing";
import {
  isAppDeepLinkPath,
  stripLocalePrefixedAppPath,
} from "./lib/app-deep-link";

const intlMiddleware = createMiddleware(routing);

/** Prisma cuid or legacy UUID — public share landings use either shape. */
const SHARE_RESOURCE_ID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$|^c[a-z0-9]{8,32}$/i;

function isPublicSharePath(pathname: string): boolean {
  const segments = pathname.split("/").filter(Boolean);
  if (segments.length !== 2) return false;
  const [kind, id] = segments;
  if (kind !== "events" && kind !== "sites") return false;
  return SHARE_RESOURCE_ID.test(id);
}

/** Share landings + `/app/*` handoff — never locale-prefix (breaks AASA / App Links). */
function bypassesIntlLocale(pathname: string): boolean {
  return isPublicSharePath(pathname) || isAppDeepLinkPath(pathname);
}

/** Cookie → Accept-Language → default (includes share-only sr/rom). */
function resolveShareRequestLocale(request: NextRequest): ShareLocale {
  const cookieLocale = request.cookies.get("NEXT_LOCALE")?.value;
  if (cookieLocale) {
    const fromCookie = resolveShareLocale(cookieLocale);
    if (cookieLocale === fromCookie || isLocale(cookieLocale)) {
      return fromCookie;
    }
  }
  const accept = request.headers.get("accept-language");
  if (accept) {
    for (const part of accept.split(",")) {
      const tag = part.trim().split(";")[0]?.toLowerCase();
      if (!tag) continue;
      const primary = tag.split("-")[0];
      if (!primary) continue;
      const resolved = resolveShareLocale(primary);
      if (primary === "sr" || primary === "rom" || isLocale(primary)) {
        return resolved;
      }
    }
  }
  return defaultLocale;
}

export default function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;

  // Platform routes (Web Analytics / Speed Insights). Never run next-intl here —
  // a rewrite or locale redirect would serve HTML for `/_vercel/insights/script.js`.
  if (pathname.startsWith("/_vercel")) {
    return NextResponse.next();
  }

  // Heal `/mk/app/...` (locale middleware used to prefix these → 404 + AASA miss).
  const strippedApp = stripLocalePrefixedAppPath(pathname);
  if (strippedApp) {
    const url = request.nextUrl.clone();
    url.pathname = strippedApp;
    return NextResponse.redirect(url);
  }

  if (bypassesIntlLocale(pathname)) {
    const requestHeaders = new Headers(request.headers);
    requestHeaders.set("x-locale", resolveShareRequestLocale(request));
    return NextResponse.next({
      request: { headers: requestHeaders },
    });
  }

  return intlMiddleware(request);
}

export const config = {
  // Keep `_vercel` out of the matcher too (defense in depth with the early return).
  matcher: ["/", "/((?!api|_next|_vercel|.*\\..*).*)"],
};
