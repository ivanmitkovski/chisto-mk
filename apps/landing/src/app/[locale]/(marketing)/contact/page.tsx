import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { ContactForm } from "@/components/organisms/ContactForm";
import { CTASection } from "@/components/organisms/CTASection";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";
import { getSiteUrl } from "@/lib/site-url";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  return buildMarketingMetadata({
    locale,
    path: "/contact",
    title: t("contact.title"),
    description: t("contact.description"),
    siteName: t("siteName"),
  });
}

export default async function ContactPage({ params }: Props) {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  const siteUrl = getSiteUrl();
  const pageUrl = `${siteUrl}/${locale}/contact`;
  const jsonLd = JSON.stringify({
    "@context": "https://schema.org",
    "@type": "ContactPage",
    name: t("contact.title"),
    description: t("contact.description"),
    url: pageUrl,
    isPartOf: {
      "@type": "WebSite",
      name: t("siteName"),
      url: siteUrl,
    },
  });

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: jsonLd }} />
      <ContactForm />
      <CTASection />
    </>
  );
}
