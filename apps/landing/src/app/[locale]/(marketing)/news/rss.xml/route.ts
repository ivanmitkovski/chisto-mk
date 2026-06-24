import { getTranslations } from "next-intl/server";
import { notFound } from "next/navigation";
import { isLaunchPageVisible } from "@/config/launch";
import { fetchNewsPosts } from "@/lib/news/fetch-news";
import { getSiteUrl } from "@/lib/site-url";
import type { AppLocale } from "@/i18n/routing";

const RSS_LIMIT = 20;

function escapeXml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function toRssDate(iso: string): string {
  return new Date(iso).toUTCString();
}

type RouteContext = { params: Promise<{ locale: string }> };

export async function GET(_request: Request, context: RouteContext) {
  if (!isLaunchPageVisible("news")) {
    notFound();
  }

  const { locale } = await context.params;
  const appLocale = locale as AppLocale;
  const siteUrl = getSiteUrl();
  const channelUrl = `${siteUrl}/${appLocale}/news`;
  const t = await getTranslations({ locale: appLocale, namespace: "newsPage" });
  const tMeta = await getTranslations({ locale: appLocale, namespace: "metadata" });

  const posts = (await fetchNewsPosts(appLocale)).slice(0, RSS_LIMIT);

  const items = posts
    .map((post) => {
      const itemUrl = `${siteUrl}/${appLocale}/news/${post.slug}`;
      return [
        "    <item>",
        `      <title>${escapeXml(post.title)}</title>`,
        `      <link>${escapeXml(itemUrl)}</link>`,
        `      <guid isPermaLink="true">${escapeXml(itemUrl)}</guid>`,
        `      <pubDate>${toRssDate(post.publishedAt)}</pubDate>`,
        `      <description>${escapeXml(post.excerpt)}</description>`,
        "    </item>",
      ].join("\n");
    })
    .join("\n");

  const xml = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">',
    "  <channel>",
    `    <title>${escapeXml(`${t("title")} | ${tMeta("siteName")}`)}</title>`,
    `    <link>${escapeXml(channelUrl)}</link>`,
    `    <description>${escapeXml(t("lead"))}</description>`,
    `    <language>${appLocale}</language>`,
    `    <atom:link href="${escapeXml(`${channelUrl}/rss.xml`)}" rel="self" type="application/rss+xml" />`,
    `    <lastBuildDate>${toRssDate(new Date().toISOString())}</lastBuildDate>`,
    items,
    "  </channel>",
    "</rss>",
  ].join("\n");

  return new Response(xml, {
    headers: {
      "Content-Type": "application/rss+xml; charset=utf-8",
      "Cache-Control": "public, max-age=60, s-maxage=600, stale-while-revalidate=86400",
    },
  });
}
