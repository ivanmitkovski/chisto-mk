import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { notFound } from "next/navigation";
import { CTASection } from "@/components/organisms/CTASection";
import { NewsLanding } from "@/components/organisms/NewsPage";
import { NewsHubViewAnalytics } from "@/components/organisms/NewsPage/NewsHubViewAnalytics";
import { isLaunchPageVisible } from "@/config/launch";
import {
  getNewsHubPosts,
  getNewsPosts,
  NEWS_HUB_PAGE_SIZE,
  type NewsCategory,
} from "@/data/news-posts";
import { NewsFetchError } from "@/lib/news/news-fetch-error";
import { newsHubRedirectPath } from "@/lib/news/news-hub-page";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";
import { buildCollectionPageJsonLd } from "@/lib/seo/webpage-json-ld";
import { redirect, type AppLocale } from "@/i18n/routing";
import { getSiteUrl } from "@/lib/site-url";

import { parseNewsHubCategory } from "@/lib/news/news-hub-params";

type Props = {
  params: Promise<{ locale: string }>;
  searchParams: Promise<{ page?: string; category?: string }>;
};

function parsePage(value: string | undefined): number {
  const n = Number.parseInt(value ?? "1", 10);
  return Number.isFinite(n) && n > 0 ? n : 1;
}

export async function generateMetadata({ params, searchParams }: Props): Promise<Metadata> {
  if (!isLaunchPageVisible("news")) {
    return { title: "Not found" };
  }
  const { locale } = await params;
  const { page: pageParam, category: categoryParam } = await searchParams;
  const page = parsePage(pageParam);
  const activeCategory = parseNewsHubCategory(categoryParam);
  const isFilteredHub = page > 1 || activeCategory != null;

  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t("news.title");
  const description = t("news.description");
  const baseMeta = buildMarketingMetadata({
    locale,
    path: "/news",
    title,
    description,
    siteName: t("siteName"),
  });
  const siteUrl = getSiteUrl().replace(/\/$/, "");
  const canonical = `${siteUrl}/${locale}/news`;

  let ogImageUrl = `${siteUrl}/icon.png`;
  try {
    const { items } = await getNewsPosts(locale, { limit: 1 });
    const featured = items.find((p) => p.featured) ?? items[0];
    if (featured?.coverImage?.startsWith("http")) {
      ogImageUrl = featured.coverImage;
    }
  } catch {
    // Keep brand fallback when news fetch fails during metadata generation.
  }

  return {
    ...baseMeta,
    ...(isFilteredHub
      ? {
          robots: {
            index: false,
            follow: true,
            googleBot: {
              index: false,
              follow: true,
            },
          },
        }
      : {}),
    alternates: {
      ...baseMeta.alternates,
      canonical,
      types: {
        "application/rss+xml": `${canonical}/rss.xml`,
      },
    },
    openGraph: {
      ...baseMeta.openGraph,
      images: [{ url: ogImageUrl }],
    },
    twitter: {
      ...baseMeta.twitter,
      images: [ogImageUrl],
    },
  };
}

export default async function NewsPage({ params, searchParams }: Props) {
  if (!isLaunchPageVisible("news")) {
    notFound();
  }
  const { locale } = await params;
  const { page: pageParam, category: categoryParam } = await searchParams;
  const page = parsePage(pageParam);
  const activeCategory = parseNewsHubCategory(categoryParam);
  const appLocale = locale as AppLocale;

  let posts: Awaited<ReturnType<typeof getNewsHubPosts>>["items"] = [];
  let total = 0;
  let fetchError = false;
  try {
    const result = await getNewsHubPosts(locale, page, activeCategory);
    posts = result.items;
    total = result.total;
  } catch (error) {
    if (error instanceof NewsFetchError) {
      fetchError = true;
    } else {
      throw error;
    }
  }

  if (!fetchError) {
    const redirectPath = newsHubRedirectPath(page, total, NEWS_HUB_PAGE_SIZE, activeCategory);
    if (redirectPath) {
      redirect({ href: redirectPath, locale: appLocale });
    }
  }

  const totalPages = Math.max(1, Math.ceil(total / NEWS_HUB_PAGE_SIZE));
  const t = await getTranslations("newsPage");
  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const siteUrl = getSiteUrl().replace(/\/$/, "");

  const categoryLabel = (c: NewsCategory) => t(`newsCategory.${c}`);

  const collectionJsonLd = buildCollectionPageJsonLd({
    locale,
    path: "/news",
    name: tMeta("news.title"),
    description: tMeta("news.description"),
    siteName: tMeta("siteName"),
    items: posts.map((post) => ({
      name: post.title,
      url: `${siteUrl}/${locale}/news/${post.slug}`,
    })),
  });

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(collectionJsonLd) }}
      />
      <NewsHubViewAnalytics />
      <NewsLanding
        locale={appLocale}
        posts={posts}
        page={page}
        totalPages={totalPages}
        {...(activeCategory ? { activeCategory } : {})}
        fetchError={fetchError}
        categoryLabel={categoryLabel}
        copy={{
          badge: t("badge"),
          title: t("title"),
          lead: t("lead"),
          featuredLabel: t("featuredLabel"),
          latestHeading: t("latestHeading"),
          readMore: t("readMore"),
          emptyTitle: t("emptyTitle"),
          emptyBody: t("emptyBody"),
          contactCta: t("contactCta"),
          errorTitle: t("errorTitle"),
          errorBody: t("errorBody"),
          errorRetry: t("errorRetry"),
          filterAll: t("filterAll"),
          loadingLabel: t("loadingLabel"),
          paginationPrev: t("paginationPrev"),
          paginationNext: t("paginationNext"),
          paginationPage: (current, totalCount) => t("paginationPage", { current, total: totalCount }),
        }}
      />
      <CTASection />
    </>
  );
}
