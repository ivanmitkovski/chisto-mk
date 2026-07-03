import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { notFound } from "next/navigation";
import { CTASection } from "@/components/organisms/CTASection";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { NewsArticle } from "@/components/organisms/NewsPage";
import { NewsArticleViewAnalytics } from "@/components/organisms/NewsPage/NewsArticleViewAnalytics";
import { NewsFetchErrorPanel } from "@/components/organisms/NewsPage/NewsFetchErrorPanel";
import { getAllNewsSlugs, getNewsPostBySlug, getRelatedNewsPosts } from "@/data/news-posts";
import { estimateReadMinutesFromParagraphBlocks } from "@/lib/news/reading-time";
import { NewsFetchError } from "@/lib/news/news-fetch-error";
import { isLaunchPageVisible } from "@/config/launch";
import { routing, type AppLocale } from "@/i18n/routing";
import { getSiteUrl } from "@/lib/site-url";

type Props = { params: Promise<{ locale: string; slug: string }> };

export const dynamicParams = true;
export const revalidate = 60;

export async function generateStaticParams() {
  try {
    const slugs = await getAllNewsSlugs();
    return slugs.map((slug) => ({ slug }));
  } catch (error) {
    if (error instanceof NewsFetchError) return [];
    throw error;
  }
}

function coverImageForMeta(coverImage?: string): string | undefined {
  if (!coverImage) return undefined;
  if (coverImage.startsWith("http://") || coverImage.startsWith("https://")) {
    return coverImage;
  }
  return undefined;
}

function schemaLanguage(locale: AppLocale): string {
  return locale === "mk" ? "mk-MK" : locale === "sq" ? "sq-AL" : "en";
}

function newsArticleJsonLd(opts: {
  siteUrl: string;
  locale: AppLocale;
  slug: string;
  headline: string;
  description: string;
  datePublished: string;
  dateModified?: string;
  publisherName: string;
  articleSection: string;
  coverImage?: string;
  breadcrumb: Array<{ name: string; item: string }>;
}): string {
  const pageUrl = `${opts.siteUrl}/${opts.locale}/news/${opts.slug}`;
  const image = coverImageForMeta(opts.coverImage);
  const logoUrl = `${opts.siteUrl}/icon.png`;
  const inLanguage = schemaLanguage(opts.locale);

  const article: Record<string, unknown> = {
    "@type": "NewsArticle",
    headline: opts.headline,
    description: opts.description,
    datePublished: opts.datePublished,
    inLanguage,
    articleSection: opts.articleSection,
    author: {
      "@type": "Organization",
      name: opts.publisherName,
      url: opts.siteUrl,
    },
    publisher: {
      "@type": "Organization",
      name: opts.publisherName,
      url: opts.siteUrl,
      logo: {
        "@type": "ImageObject",
        url: logoUrl,
      },
    },
    ...(opts.dateModified ? { dateModified: opts.dateModified } : {}),
    ...(image ? { image: [image] } : {}),
    mainEntityOfPage: { "@type": "WebPage", "@id": pageUrl },
    url: pageUrl,
  };

  const breadcrumbLd = {
    "@type": "BreadcrumbList",
    itemListElement: opts.breadcrumb.map((b, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: b.name,
      item: b.item,
    })),
  };

  return JSON.stringify({
    "@context": "https://schema.org",
    "@graph": [article, breadcrumbLd],
  }).replace(/</g, "\\u003c");
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  if (!isLaunchPageVisible("news")) {
    return { title: "Not found" };
  }
  const { locale, slug } = await params;
  setRequestLocale(locale);
  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const siteName = tMeta("siteName");

  let post;
  try {
    post = await getNewsPostBySlug(locale, slug);
  } catch (error) {
    if (error instanceof NewsFetchError) {
      return { title: siteName };
    }
    throw error;
  }

  if (!post) {
    notFound();
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
      ...(post.updatedAt ? { modifiedTime: post.updatedAt } : {}),
      locale: locale === "mk" ? "mk_MK" : locale === "sq" ? "sq_AL" : "en_US",
      siteName,
      url: canonical,
      ...(ogImages ? { images: ogImages } : {}),
    },
    twitter: {
      card: ogImages ? "summary_large_image" : "summary",
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
  setRequestLocale(locale);
  const t = await getTranslations({ locale, namespace: "newsPage" });

  let post;
  try {
    post = await getNewsPostBySlug(locale, slug);
  } catch (error) {
    if (error instanceof NewsFetchError) {
      return (
        <>
          <Section>
            <Container>
              <NewsFetchErrorPanel
                title={t("errorTitle")}
                body={t("errorBody")}
                retryLabel={t("errorRetry")}
              />
            </Container>
          </Section>
          <CTASection />
        </>
      );
    }
    throw error;
  }

  if (!post) {
    notFound();
  }

  const relatedPosts = await getRelatedNewsPosts(locale, slug);

  const appLocale = locale as AppLocale;
  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const readMinutes = estimateReadMinutesFromParagraphBlocks(post.body);
  const siteUrl = getSiteUrl();
  const categoryLabel = t(`newsCategory.${post.category}`);
  const jsonLd = newsArticleJsonLd({
    siteUrl,
    locale: appLocale,
    slug,
    headline: post.title,
    description: post.excerpt,
    datePublished: post.publishedAt,
    ...(post.updatedAt ? { dateModified: post.updatedAt } : {}),
    publisherName: tMeta("siteName"),
    articleSection: categoryLabel,
    ...(post.coverImage !== undefined && post.coverImage !== ""
      ? { coverImage: post.coverImage }
      : {}),
    breadcrumb: [
      { name: t("breadcrumbHome"), item: `${siteUrl}/${appLocale}` },
      { name: t("breadcrumbNews"), item: `${siteUrl}/${appLocale}/news` },
      { name: post.title, item: `${siteUrl}/${appLocale}/news/${slug}` },
    ],
  });

  return (
    <>
      <NewsArticleViewAnalytics slug={slug} />
      <NewsArticle
        locale={appLocale}
        post={post}
        relatedPosts={relatedPosts}
        categoryLabel={categoryLabel}
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
            copyLinkFailed: t("share.copyLinkFailed"),
            share: t("share.share"),
            shareAria: t("share.shareAria"),
          },
          imageUnavailable: t("imageUnavailable"),
          videoUnavailable: t("videoUnavailable"),
          galleryClose: t("galleryClose"),
          galleryPrevious: t("galleryPrevious"),
          galleryNext: t("galleryNext"),
          galleryUnavailable: t("galleryUnavailable"),
          galleryAriaLabel: t("galleryAriaLabel"),
          breadcrumbHome: t("breadcrumbHome"),
          breadcrumbNews: t("breadcrumbNews"),
          breadcrumbAriaLabel: t("breadcrumbAriaLabel"),
          updatedLabel: (date) => t("updatedLabel", { date }),
        }}
      />
      <CTASection />
    </>
  );
}
