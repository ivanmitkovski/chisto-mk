import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { notFound } from "next/navigation";
import { HelpArticleShell } from "@/components/organisms/HelpCentre/HelpArticleShell";
import { HelpArticleViewAnalytics } from "@/components/organisms/HelpCentre/HelpArticleViewAnalytics";
import { HELP_ARTICLE_SLUGS, isHelpArticleSlug, type HelpArticleSlug } from "@/lib/help/help-catalog";
import { routing } from "@/i18n/routing";

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
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `/${l}/help/${slug}`]),
  ) as Record<string, string>;

  return {
    title,
    description,
    alternates: { languages },
    openGraph: {
      title,
      description,
      type: "article",
      locale: locale === "mk" ? "mk_MK" : locale === "sq" ? "sq_AL" : "en_US",
      siteName: tMeta("siteName"),
    },
    twitter: { card: "summary_large_image", title, description },
  };
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
