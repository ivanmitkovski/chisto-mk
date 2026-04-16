import type { MetadataRoute } from "next";
import { getAllNewsSlugs } from "@/data/mock-news";
import { HELP_ARTICLE_SLUGS } from "@/lib/help/help-catalog";
import { helpArticleLastModified, helpHubLastModified } from "@/lib/help/help-sitemap-dates";
import { routing } from "@/i18n/routing";
import { getSiteUrl } from "@/lib/site-url";

const PATHS = [
  "",
  "/about",
  "/contact",
  "/news",
  "/press",
  "/terms",
  "/privacy",
  "/cookies",
  "/data",
  "/help",
] as const;

export default function sitemap(): MetadataRoute.Sitemap {
  const base = getSiteUrl();
  const lastModified = new Date();
  const entries: MetadataRoute.Sitemap = [];

  const newsSlugs = getAllNewsSlugs();

  for (const locale of routing.locales) {
    const helpHubModified = helpHubLastModified(locale, lastModified);
    for (const path of PATHS) {
      const url = `${base}/${locale}${path}`;
      const pathLastModified = path === "/help" ? helpHubModified : lastModified;
      entries.push({
        url,
        lastModified: pathLastModified,
        changeFrequency: path === "" ? "weekly" : "monthly",
        priority: path === "" ? 1 : 0.7,
      });
    }
    for (const slug of newsSlugs) {
      entries.push({
        url: `${base}/${locale}/news/${slug}`,
        lastModified,
        changeFrequency: "monthly",
        priority: 0.65,
      });
    }
    for (const slug of HELP_ARTICLE_SLUGS) {
      entries.push({
        url: `${base}/${locale}/help/${slug}`,
        lastModified: helpArticleLastModified(locale, slug, lastModified),
        changeFrequency: "monthly",
        priority: 0.68,
      });
    }
  }

  return entries;
}
