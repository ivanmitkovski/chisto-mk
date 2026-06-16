import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { LegalLayout, type LegalSection } from "@/components/organisms/LegalLayout";
import {
  getLegalPlaceholderMap,
  substituteLegalSections,
  substituteLegalText,
} from "@/lib/legal/substitute-placeholders";
import { routing, type AppLocale } from "@/i18n/routing";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t("privacy.title");
  const description = t("privacy.description");
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `/${l}/privacy`]),
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
