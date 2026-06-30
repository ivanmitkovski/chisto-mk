import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { notFound } from "next/navigation";
import { HelpArticleShell } from "@/components/organisms/HelpCentre/HelpArticleShell";
import { HelpArticleViewAnalytics } from "@/components/organisms/HelpCentre/HelpArticleViewAnalytics";
import { HELP_ARTICLE_SLUGS, isHelpArticleSlug, type HelpArticleSlug } from "@/lib/help/help-catalog";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";

type Props = { params: Promise<{ locale: string; slug: string }> };

export function generateStaticParams() {
  return HELP_ARTICLE_SLUGS.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale, slug } = await params;
  if (!isHelpArticleSlug(slug)) {
    return {};
  }
  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const t = await getTranslations({ locale, namespace: "helpCentre" });
  const articleTitle = t(`articles.${slug}.title`);
  const title = `${articleTitle} | ${tMeta("siteName")}`;
  const description = t(`articles.${slug}.cardSummary`);

  return buildMarketingMetadata({
    locale,
    path: `/help/${slug}`,
    title,
    description,
    siteName: tMeta("siteName"),
  });
}

export default async function HelpArticlePage({ params }: Props) {
  const { slug } = await params;
  if (!isHelpArticleSlug(slug)) {
    notFound();
  }
  const articleSlug: HelpArticleSlug = slug;
  return (
    <>
      <HelpArticleViewAnalytics slug={articleSlug} />
      <HelpArticleShell slug={articleSlug} />
    </>
  );
}
