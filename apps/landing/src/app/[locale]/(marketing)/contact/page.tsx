import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { ContactForm } from "@/components/organisms/ContactForm";
import { CTASection } from "@/components/organisms/CTASection";
import { routing } from "@/i18n/routing";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  const title = t("contact.title");
  const description = t("contact.description");
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `/${l}/contact`]),
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

export default function ContactPage() {
  return (
    <>
      <ContactForm />
      <CTASection />
    </>
  );
}
