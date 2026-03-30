import { type NextRequest, NextResponse } from "next/server";
import { defaultLocale, isLocale } from "@/i18n/config";

export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;
  const segments = pathname.split("/").filter(Boolean);
  const first = segments[0];

  if (pathname === "/") {
    return NextResponse.redirect(new URL(`/${defaultLocale}`, request.url));
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
