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

  const languages = Object.fromEntries(
    routing.locales.map((l) => [
      l,
      `${base}/${l}${normalizedPath === "/" ? "" : normalizedPath}`,
    ]),
  ) as Record<string, string>;
  languages["x-default"] = `${base}/${routing.defaultLocale}${normalizedPath === "/" ? "" : normalizedPath}`;

  const ogLocale = locale === "mk" ? "mk_MK" : locale === "sq" ? "sq_AL" : "en_US";

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
