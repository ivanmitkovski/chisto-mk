import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { notFound } from "next/navigation";
import { AboutPage } from "@/components/organisms/AboutPage";
import { CTASection } from "@/components/organisms/CTASection";
import { isLaunchPageVisible } from "@/config/launch";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  if (!isLaunchPageVisible("about")) {
    return { title: "Not found" };
  }
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  return buildMarketingMetadata({
    locale,
    path: "/about",
    title: t("about.title"),
    description: t("about.description"),
    siteName: t("siteName"),
  });
}

export default async function AboutRoute() {
  if (!isLaunchPageVisible("about")) {
    notFound();
  }
  return (
    <>
      <AboutPage />
      <CTASection />
    </>
  );
}
