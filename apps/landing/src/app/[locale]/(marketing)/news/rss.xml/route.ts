import { getTranslations } from "next-intl/server";
import { notFound } from "next/navigation";
import { blocksToEncodedHtml } from "@chisto/news-content";
import { isLaunchPageVisible } from "@/config/launch";
import { fetchNewsPostBySlug, fetchNewsPosts } from "@/lib/news/fetch-news";
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
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return new Date().toUTCString();
  }
  return date.toUTCString();
}

function wrapCdata(html: string): string {
  return html.replace(/]]>/g, "]]]]><![CDATA[>");
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

  const posts = await (async () => {
    try {
      const { items } = await fetchNewsPosts(appLocale, { limit: RSS_LIMIT });
      const fullPosts = await Promise.all(
        items.map(async (item) => {
          try {
            return await fetchNewsPostBySlug(appLocale, item.slug);
          } catch {
            return item;
          }
        }),
      );
      return fullPosts.filter(Boolean);
    } catch (error) {
      console.error('RSS fetchNewsPosts failed', error);
      return [];
    }
  })();

  const items = posts
    .map((post) => {
      if (!post) return '';
      const itemUrl = `${siteUrl}/${appLocale}/news/${post.slug}`;
      const encoded = blocksToEncodedHtml(post.body ?? []);
      return [
        "    <item>",
        `      <title>${escapeXml(post.title)}</title>`,
        `      <link>${escapeXml(itemUrl)}</link>`,
        `      <guid isPermaLink="true">${escapeXml(itemUrl)}</guid>`,
        `      <pubDate>${toRssDate(post.publishedAt)}</pubDate>`,
        `      <description>${escapeXml(post.excerpt)}</description>`,
        encoded ? `      <content:encoded><![CDATA[${wrapCdata(encoded)}]]></content:encoded>` : '',
        "    </item>",
      ]
        .filter(Boolean)
        .join("\n");
    })
    .filter(Boolean)
    .join("\n");

  const xml = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/">',
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
