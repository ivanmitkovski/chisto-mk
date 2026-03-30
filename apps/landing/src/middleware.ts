import createMiddleware from "next-intl/middleware";
import { routing } from "./i18n/routing";

export default createMiddleware(routing);

export const config = {
  // Include `/` so the default-locale redirect runs; the catch-all alone can miss the root on some Next versions.
  matcher: ["/", "/((?!api|_next|_vercel|.*\\..*).*)"],
};
