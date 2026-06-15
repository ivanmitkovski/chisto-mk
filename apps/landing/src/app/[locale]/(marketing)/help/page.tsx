import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { HelpHub } from "@/components/organisms/HelpCentre/HelpHub";
import { routing } from "@/i18n/routing";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t("help.title");
  const description = t("help.description");
  const languages = Object.fromEntries(routing.locales.map((l) => [l, `/${l}/help`])) as Record<string, string>;

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

export default function HelpPage() {
  return <HelpHub />;
}
