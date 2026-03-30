import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { AboutPage } from "@/components/organisms/AboutPage";
import { CTASection } from "@/components/organisms/CTASection";
import { routing } from "@/i18n/routing";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t("about.title");
  const description = t("about.description");
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `/${l}/about`]),
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

export default async function AboutRoute() {
  return (
    <>
      <AboutPage />
      <CTASection />
    </>
  );
}
