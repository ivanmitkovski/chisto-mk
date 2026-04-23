import { type NextRequest, NextResponse } from "next/server";
import { defaultLocale, isLocale } from "@/i18n/config";

const shareEventUuid =
  /^\/events\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\/?$/i;

export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;
  const segments = pathname.split("/").filter(Boolean);
  const first = segments[0];

  if (pathname === "/") {
    return NextResponse.redirect(new URL(`/${defaultLocale}`, request.url));
  }

  /** Public event share landing (aligned with mobile `event_share_payload` and app deep links). */
  if (shareEventUuid.test(pathname)) {
    const requestHeaders = new Headers(request.headers);
    requestHeaders.set("x-locale", defaultLocale);
    return NextResponse.next({
      request: { headers: requestHeaders },
    });
  }

  if (!first || !isLocale(first)) {
    return NextResponse.redirect(new URL(`/${defaultLocale}`, request.url));
  }

  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-locale", first);

  return NextResponse.next({
    request: { headers: requestHeaders },
  });
}

export const config = {
  matcher: ["/((?!_next|.*\\..*).*)"],
};
