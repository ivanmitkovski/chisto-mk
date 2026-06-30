import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { HelpHub } from "@/components/organisms/HelpCentre/HelpHub";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";

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

export default function HelpPage() {
  return <HelpHub />;
}
