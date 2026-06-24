import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { notFound } from "next/navigation";
import { CTASection } from "@/components/organisms/CTASection";
import { NewsArticle } from "@/components/organisms/NewsPage";
import { getAllNewsSlugs, getNewsPostBySlug, getRelatedNewsPosts } from "@/data/news-posts";
import { estimateReadMinutesFromParagraphBlocks } from "@/lib/news/reading-time";
import { isLaunchPageVisible } from "@/config/launch";
import { routing, type AppLocale } from "@/i18n/routing";
import { getSiteUrl } from "@/lib/site-url";

type Props = { params: Promise<{ locale: string; slug: string }> };

export const dynamicParams = true;
export const revalidate = 60;

export async function generateStaticParams() {
  const slugs = await getAllNewsSlugs();
  return slugs.map((slug) => ({ slug }));
}

function coverImageForMeta(coverImage?: string): string | undefined {
  if (!coverImage) return undefined;
  if (coverImage.startsWith('http://') || coverImage.startsWith('https://')) {
    return coverImage;
  }
  return undefined;
}

function newsArticleJsonLd(opts: {
  siteUrl: string;
  locale: AppLocale;
  slug: string;
  headline: string;
  description: string;
  datePublished: string;
  coverImage?: string;
}): string {
  const pageUrl = `${opts.siteUrl}/${opts.locale}/news/${opts.slug}`;
  const image = coverImageForMeta(opts.coverImage);
  return JSON.stringify({
    '@context': 'https://schema.org',
    '@type': 'NewsArticle',
    headline: opts.headline,
    description: opts.description,
    datePublished: opts.datePublished,
    ...(image ? { image: [image] } : {}),
    mainEntityOfPage: { '@type': 'WebPage', '@id': pageUrl },
    url: pageUrl,
  });
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  if (!isLaunchPageVisible("news")) {
    return { title: "Not found" };
  }
  const { locale, slug } = await params;
  const post = await getNewsPostBySlug(locale, slug);
  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const siteName = tMeta("siteName");

  if (!post) {
    return { title: siteName };
  }

  const title = `${post.title} | ${siteName}`;
  const description = post.excerpt;
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `/${l}/news/${slug}`]),
  ) as Record<string, string>;

  const siteUrl = getSiteUrl();
  const canonical = `${siteUrl}/${locale}/news/${slug}`;
  const ogImage = coverImageForMeta(post.coverImage);
  const ogImages = ogImage ? [{ url: ogImage }] : undefined;

  return {
    title,
    description,
    alternates: { canonical, languages },
    openGraph: {
      title,
      description,
      type: "article",
      publishedTime: post.publishedAt,
      locale: locale === "mk" ? "mk_MK" : locale === "sq" ? "sq_AL" : "en_US",
      siteName,
      url: canonical,
      ...(ogImages ? { images: ogImages } : {}),
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      ...(ogImages ? { images: ogImages.map((i) => i.url) } : {}),
    },
  };
}

export default async function NewsArticlePage({ params }: Props) {
  if (!isLaunchPageVisible("news")) {
    notFound();
  }
  const { locale, slug } = await params;
  const post = await getNewsPostBySlug(locale, slug);
  if (!post) {
    notFound();
  }

  const relatedPosts = await getRelatedNewsPosts(locale, slug);

  const appLocale = locale as AppLocale;
  const t = await getTranslations("newsPage");
  const readMinutes = estimateReadMinutesFromParagraphBlocks(post.body);
  const siteUrl = getSiteUrl();
  const jsonLd = newsArticleJsonLd({
    siteUrl,
    locale: appLocale,
    slug,
    headline: post.title,
    description: post.excerpt,
    datePublished: post.publishedAt,
    ...(post.coverImage !== undefined && post.coverImage !== ""
      ? { coverImage: post.coverImage }
      : {}),
  });

  return (
    <>
      <NewsArticle
        locale={appLocale}
        post={post}
        relatedPosts={relatedPosts}
        categoryLabel={t(`newsCategory.${post.category}`)}
        relatedCategoryLabel={(category) => t(`newsCategory.${category}`)}
        jsonLd={jsonLd}
        copy={{
          badge: t("badge"),
          backToNews: t("backToNews"),
          readingTime: t("readingTime", { minutes: readMinutes }),
          relatedTitle: t("relatedTitle"),
          share: {
            copyLink: t("share.copyLink"),
            copyLinkAria: t("share.copyLinkAria"),
            copied: t("share.copied"),
            share: t("share.share"),
            shareAria: t("share.shareAria"),
          },
        }}
      />
      <CTASection />
    </>
  );
}
