import { defineRouting } from "next-intl/routing";
import { createNavigation } from "next-intl/navigation";

export const locales = ["mk", "en", "sq"] as const;
export type AppLocale = (typeof locales)[number];

export const routing = defineRouting({
  locales: [...locales],
  defaultLocale: "mk",
  localePrefix: "always",
  // Root `/` must always resolve to Macedonian; do not follow Accept-Language or locale cookie for that.
  localeDetection: false,
});

export const { Link, redirect, usePathname, useRouter } = createNavigation(routing);
