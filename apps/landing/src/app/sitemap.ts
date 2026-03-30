import type { MetadataRoute } from "next";
import { getAllNewsSlugs } from "@/data/mock-news";
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
] as const;

export default function sitemap(): MetadataRoute.Sitemap {
  const base = getSiteUrl();
  const lastModified = new Date();
  const entries: MetadataRoute.Sitemap = [];

  const newsSlugs = getAllNewsSlugs();

  for (const locale of routing.locales) {
    for (const path of PATHS) {
      const url = `${base}/${locale}${path}`;
      entries.push({
        url,
        lastModified,
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
  }

  return entries;
}
