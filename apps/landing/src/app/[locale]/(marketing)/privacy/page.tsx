import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { LegalLayout, type LegalSection } from "@/components/organisms/LegalLayout";
import {
  getLegalPlaceholderMap,
  substituteLegalSections,
  substituteLegalText,
} from "@/lib/legal/substitute-placeholders";
import { type AppLocale } from "@/i18n/routing";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  return buildMarketingMetadata({
    locale,
    path: "/privacy",
    title: t("privacy.title"),
    description: t("privacy.description"),
    siteName: t("siteName"),
  });
}

export default async function PrivacyPage({ params }: Props) {
  const { locale } = await params;
  const appLocale = locale as AppLocale;
  const t = await getTranslations("privacyPage");
  const map = getLegalPlaceholderMap(appLocale);
  const sections = substituteLegalSections(t.raw("sections") as LegalSection[], map);
  const effectiveLabel = t("effectiveDateLabel").trim();
  const effectiveRaw = t("effectiveDate").trim();
  const showEffectiveDate = effectiveLabel.length > 0 && effectiveRaw.length > 0;

  return (
    <LegalLayout
      badge={t("badge")}
      title={t("title")}
      lastUpdatedLabel={t("lastUpdatedLabel")}
      lastUpdated={substituteLegalText(t("lastUpdated"), map)}
      {...(showEffectiveDate
        ? {
            effectiveDateLabel: effectiveLabel,
            effectiveDate: substituteLegalText(effectiveRaw, map),
          }
        : {})}
      sections={sections}
    />
  );
}
