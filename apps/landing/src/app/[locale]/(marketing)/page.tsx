import type { Metadata } from "next";
import Script from "next/script";
import { getTranslations } from "next-intl/server";
import { Hero } from "@/components/organisms/Hero";
import { HowItWorks } from "@/components/organisms/HowItWorks";
import { Features } from "@/components/organisms/Features";
import { FAQ } from "@/components/organisms/FAQ";
import { CTASection } from "@/components/organisms/CTASection";
import { LatestNewsSection } from "@/components/organisms/NewsPage";
import { getAppStoreUrl } from "@/lib/store-links";
import { getSocialProfileUrls } from "@/lib/social-links";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";
import { LEGAL_PUBLIC_DEFAULTS } from "@/lib/legal/legal-public-config";
import { type AppLocale } from "@/i18n/routing";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  return buildMarketingMetadata({
    locale,
    path: "/",
    title: t("home.title"),
    description: t("home.description"),
    siteName: t("siteName"),
  });
}

export default async function HomePage({ params }: Props) {
  const { locale } = await params;
  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const siteName = tMeta("siteName");
  const tFaq = await getTranslations({ locale, namespace: "faq" });
  const appStoreUrl = getAppStoreUrl();
  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL?.trim() || LEGAL_PUBLIC_DEFAULTS.siteUrl;

  const faqItems = tFaq.raw("items") as { title: string; content: string }[];
  const socialProfileUrls = getSocialProfileUrls();

  const jsonLdBlocks: Record<string, unknown>[] = [
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      name: siteName,
      url: siteUrl,
      inLanguage: ["mk", "en", "sq"],
    },
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      name: LEGAL_PUBLIC_DEFAULTS.legalEntityName,
      url: siteUrl,
      logo: `${siteUrl}/brand/chisto-mark-green.svg`,
      ...(socialProfileUrls.length > 0 ? { sameAs: socialProfileUrls } : {}),
      contactPoint: {
        "@type": "ContactPoint",
        email: LEGAL_PUBLIC_DEFAULTS.contactEmail,
        contactType: "customer support",
        availableLanguage: ["Macedonian", "English", "Albanian"],
      },
    },
    {
      "@context": "https://schema.org",
      "@type": "FAQPage",
      mainEntity: faqItems.map((item) => ({
        "@type": "Question",
        name: item.title,
        acceptedAnswer: {
          "@type": "Answer",
          text: item.content,
        },
      })),
    },
  ];

  if (appStoreUrl) {
    jsonLdBlocks.push({
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      name: siteName,
      operatingSystem: "iOS",
      applicationCategory: "LifestyleApplication",
      offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
      downloadUrl: appStoreUrl,
    });
  }

  return (
    <>
      <Script id="download-hash-scroll-boot" strategy="beforeInteractive">
        {`(function(){var h="#download";if(location.hash!==h)return;history.scrollRestoration="manual";function s(){if(location.hash!==h)return;scrollTo(0,0);}s();addEventListener("load",s,{once:true});})();`}
      </Script>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdBlocks) }}
      />
      <Hero />
      <HowItWorks />
      <Features />
      <LatestNewsSection locale={locale as AppLocale} />
      <FAQ />
      <CTASection />
    </>
  );
}
