import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { CTASection } from "@/components/organisms/CTASection";
import { NewsLanding } from "@/components/organisms/NewsPage";
import { getNewsPosts, type NewsCategory } from "@/data/mock-news";
import { routing, type AppLocale } from "@/i18n/routing";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t("news.title");
  const description = t("news.description");
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `/${l}/news`]),
  ) as Record<string, string>;

  return {
    title,
    description,
    alternates: { languages },
    openGraph: {
      title,
      description,
      type: "website",
      locale: locale === "mk" ? "mk_MK" : locale === "sq" ? "sq_AL" : "en_US",
      siteName: t("siteName"),
    },
    twitter: { card: "summary_large_image", title, description },
  };
}

export default async function NewsPage({ params }: Props) {
  const { locale } = await params;
  const appLocale = locale as AppLocale;
  const posts = getNewsPosts(locale);
  const t = await getTranslations("newsPage");

  const categoryLabel = (c: NewsCategory) => t(`newsCategory.${c}`);

  return (
    <>
      <NewsLanding
        locale={appLocale}
        posts={posts}
        categoryLabel={categoryLabel}
        copy={{
          badge: t("badge"),
          title: t("title"),
          lead: t("lead"),
          demoNotice: t("demoNotice"),
          featuredLabel: t("featuredLabel"),
          latestHeading: t("latestHeading"),
          readMore: t("readMore"),
          emptyTitle: t("emptyTitle"),
          emptyBody: t("emptyBody"),
          contactCta: t("contactCta"),
        }}
      />
      <CTASection />
    </>
  );
}
