import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { HelpHub } from "@/components/organisms/HelpCentre/HelpHub";
import { HELP_ARTICLE_SLUGS } from "@/lib/help/help-catalog";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";
import { buildCollectionPageJsonLd } from "@/lib/seo/webpage-json-ld";
import { getSiteUrl } from "@/lib/site-url";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  return buildMarketingMetadata({
    locale,
    path: "/help",
    title: t("help.title"),
    description: t("help.description"),
    siteName: t("siteName"),
  });
}

export default async function HelpPage({ params }: Props) {
  const { locale } = await params;
  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const tHelp = await getTranslations({ locale, namespace: "helpCentre" });
  const siteUrl = getSiteUrl().replace(/\/$/, "");
  const articles = tHelp.raw("articles") as Record<string, { title?: string; cardTitle?: string }>;

  const items = HELP_ARTICLE_SLUGS.map((slug) => {
    const article = articles[slug];
    const name = article?.title ?? article?.cardTitle ?? slug;
    return {
      name,
      url: `${siteUrl}/${locale}/help/${slug}`,
    };
  });

  const jsonLd = buildCollectionPageJsonLd({
    locale,
    path: "/help",
    name: tMeta("help.title"),
    description: tMeta("help.description"),
    siteName: tMeta("siteName"),
    items,
  });

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <HelpHub />
    </>
  );
}
