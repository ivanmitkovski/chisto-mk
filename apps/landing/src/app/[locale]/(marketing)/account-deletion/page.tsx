import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { getTranslations } from "next-intl/server";
import { routing } from "@/i18n/routing";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t("data.title");
  const description = t("data.description");
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `/${l}/account-deletion`]),
  ) as Record<string, string>;

  return {
    title,
    description,
    alternates: { languages },
    robots: { index: true, follow: true },
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

export default async function AccountDeletionPage({ params }: Props) {
  const { locale } = await params;
  redirect(`/${locale}/data#account-deletion`);
}
