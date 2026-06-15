import createMiddleware from "next-intl/middleware";
import { type NextRequest, NextResponse } from "next/server";
import { defaultLocale } from "./i18n/config";
import { routing } from "./i18n/routing";

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

export default function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;

  if (isPublicSharePath(pathname)) {
    const requestHeaders = new Headers(request.headers);
    requestHeaders.set("x-locale", defaultLocale);
    return NextResponse.next({
      request: { headers: requestHeaders },
    });
  }

  return intlMiddleware(request);
}

export const config = {
  matcher: ["/", "/((?!api|_next|_vercel|.*\\..*).*)"],
};
