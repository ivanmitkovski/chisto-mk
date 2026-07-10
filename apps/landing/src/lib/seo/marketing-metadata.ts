import type { Metadata } from "next";
import { routing } from "@/i18n/routing";
import { getSiteUrl } from "@/lib/site-url";

type MarketingMetadataInput = {
  locale: string;
  path: string;
  title: string;
  description: string;
  siteName: string;
};

const OG_LOCALE_BY_APP: Record<string, string> = {
  mk: "mk_MK",
  en: "en_US",
  sq: "sq_AL",
};

/** Absolute hreflang map (mk/en/sq + x-default) for a locale-prefixed path. */
export function absoluteLocaleLanguages(path: string): Record<string, string> {
  const base = getSiteUrl().replace(/\/$/, "");
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  const suffix = normalizedPath === "/" ? "" : normalizedPath;

  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `${base}/${l}${suffix}`]),
  ) as Record<string, string>;
  languages["x-default"] = `${base}/${routing.defaultLocale}${suffix}`;
  return languages;
}

export function ogLocaleForAppLocale(locale: string): string {
  return OG_LOCALE_BY_APP[locale] ?? "en_US";
}

export function alternateOgLocales(locale: string): string[] {
  return Object.entries(OG_LOCALE_BY_APP)
    .filter(([appLocale]) => appLocale !== locale)
    .map(([, og]) => og);
}

export function buildMarketingMetadata({
  locale,
  path,
  title,
  description,
  siteName,
}: MarketingMetadataInput): Metadata {
  const base = getSiteUrl().replace(/\/$/, "");
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  const canonical = `${base}/${locale}${normalizedPath === "/" ? "" : normalizedPath}`;
  const languages = absoluteLocaleLanguages(path);
  const ogLocale = ogLocaleForAppLocale(locale);

  return {
    title,
    description,
    robots: {
      index: true,
      follow: true,
      googleBot: {
        index: true,
        follow: true,
        "max-image-preview": "large",
        "max-snippet": -1,
        "max-video-preview": -1,
      },
    },
    alternates: {
      canonical,
      languages,
    },
    openGraph: {
      title,
      description,
      type: "website",
      locale: ogLocale,
      alternateLocale: alternateOgLocales(locale),
      siteName,
      url: canonical,
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
    },
  };
}
