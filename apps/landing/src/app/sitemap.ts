import type { MetadataRoute } from "next";
import { SITEMAP_PATHS, isLaunchPageVisible } from "@/config/launch";
import { HELP_ARTICLE_SLUGS } from "@/lib/help/help-catalog";
import { helpArticleLastModified, helpHubLastModified } from "@/lib/help/help-sitemap-dates";
import { getAllNewsSlugs } from "@/data/news-posts";
import { routing } from "@/i18n/routing";
import { getSiteUrl } from "@/lib/site-url";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = getSiteUrl();
  const lastModified = new Date();
  const entries: MetadataRoute.Sitemap = [];
  const newsSlugs = isLaunchPageVisible('news') ? await getAllNewsSlugs() : [];

  for (const locale of routing.locales) {
    const helpHubModified = helpHubLastModified(locale, lastModified);
    for (const path of SITEMAP_PATHS) {
      const url = `${base}/${locale}${path}`;
      const pathLastModified = path === "/help" ? helpHubModified : lastModified;
      entries.push({
        url,
        lastModified: pathLastModified,
        changeFrequency: path === "" ? "weekly" : "monthly",
        priority: path === "" ? 1 : 0.7,
      });
    }

    if (isLaunchPageVisible("news")) {
      for (const slug of newsSlugs) {
        entries.push({
          url: `${base}/${locale}/news/${slug}`,
          lastModified,
          changeFrequency: "monthly",
          priority: 0.65,
        });
      }
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
