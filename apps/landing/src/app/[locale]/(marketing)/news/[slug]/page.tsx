import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { notFound } from "next/navigation";
import { CTASection } from "@/components/organisms/CTASection";
import { NewsArticle } from "@/components/organisms/NewsPage";
import { getAllNewsSlugs, getNewsPostBySlug } from "@/data/mock-news";
import { routing, type AppLocale } from "@/i18n/routing";
import { getSiteUrl } from "@/lib/site-url";

type Props = { params: Promise<{ locale: string; slug: string }> };

export function generateStaticParams() {
  return getAllNewsSlugs().map((slug) => ({ slug }));
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
  const image =
    opts.coverImage != null && opts.coverImage.length > 0
      ? [`${opts.siteUrl}${opts.coverImage}`]
      : undefined;
  return JSON.stringify({
    "@context": "https://schema.org",
    "@type": "NewsArticle",
    headline: opts.headline,
    description: opts.description,
    datePublished: opts.datePublished,
    ...(image ? { image } : {}),
    mainEntityOfPage: { "@type": "WebPage", "@id": pageUrl },
    url: pageUrl,
  });
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale, slug } = await params;
  const post = getNewsPostBySlug(locale, slug);
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
  const ogImages =
    post.coverImage != null && post.coverImage.length > 0
      ? [{ url: `${siteUrl}${post.coverImage}` }]
      : undefined;

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
  const { locale, slug } = await params;
  const post = getNewsPostBySlug(locale, slug);
  if (!post) {
    notFound();
  }

  const appLocale = locale as AppLocale;
  const t = await getTranslations("newsPage");
  const siteUrl = getSiteUrl();
  const jsonLd = newsArticleJsonLd({
    siteUrl,
    locale: appLocale,
    slug,
    headline: post.title,
    description: post.excerpt,
    datePublished: post.publishedAt,
    coverImage: post.coverImage,
  });

  return (
    <>
      <NewsArticle
        locale={appLocale}
        post={post}
        categoryLabel={t(`newsCategory.${post.category}`)}
        jsonLd={jsonLd}
        copy={{
          badge: t("badge"),
          backToNews: t("backToNews"),
        }}
      />
      <CTASection />
    </>
  );
}
