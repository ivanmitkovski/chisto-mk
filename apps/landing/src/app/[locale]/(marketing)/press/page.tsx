import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { notFound } from "next/navigation";
import { Badge } from "@/components/atoms/Badge";
import { Container } from "@/components/layout/Container";
import { Section } from "@/components/layout/Section";
import { CTASection } from "@/components/organisms/CTASection";
import { isLaunchPageVisible } from "@/config/launch";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";
import { LEGAL_PUBLIC_DEFAULTS } from "@/lib/legal/legal-public-config";
import { getSiteUrl } from "@/lib/site-url";
import { MarketingReveal } from "@/components/molecules/MarketingReveal";
import { PressAssetDownloads } from "@/components/organisms/PressPage/PressAssetDownloads";

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  if (!isLaunchPageVisible("press")) {
    return { title: "Not found" };
  }
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  return buildMarketingMetadata({
    locale,
    path: "/press",
    title: t("press.title"),
    description: t("press.description"),
    siteName: t("siteName"),
  });
}

export default async function PressPage({ params }: Props) {
  if (!isLaunchPageVisible("press")) {
    notFound();
  }
  const { locale } = await params;
  const t = await getTranslations("pressPage");
  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const contactEmail = process.env.NEXT_PUBLIC_CONTACT_EMAIL?.trim() || LEGAL_PUBLIC_DEFAULTS.contactEmail;
  const siteUrl = getSiteUrl().replace(/\/$/, "");
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "WebPage",
    name: tMeta("press.title"),
    description: tMeta("press.description"),
    url: `${siteUrl}/${locale}/press`,
    isPartOf: {
      "@type": "WebSite",
      name: tMeta("siteName"),
      url: `${siteUrl}/${locale}`,
    },
    publisher: {
      "@type": "Organization",
      name: tMeta("siteName"),
      url: siteUrl,
    },
  };

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <Section className="relative overflow-hidden mesh-section-features">
        <div
          className="pointer-events-none absolute inset-0 pattern-diagonal-soft opacity-25"
          aria-hidden
        />
        <Container className="relative z-10">
          <MarketingReveal>
            <Badge>{t("badge")}</Badge>
            <h1 className="mt-3 max-w-copy text-section-title font-bold text-gray-900">{t("title")}</h1>
            <p className="mt-6 max-w-2xl text-lg leading-relaxed text-gray-600">{t("lead")}</p>
          </MarketingReveal>

          <div className="mt-14 grid gap-12 md:grid-cols-2 md:gap-16">
            <MarketingReveal>
              <h2 className="text-sm font-bold uppercase tracking-[0.12em] text-gray-900">
                {t("assetsTitle")}
              </h2>
              <div className="mt-5">
                <PressAssetDownloads />
              </div>
            </MarketingReveal>
            <MarketingReveal>
              <h2 className="text-sm font-bold uppercase tracking-[0.12em] text-gray-900">
                {t("inquiriesTitle")}
              </h2>
              <p className="mt-5 text-gray-600 leading-relaxed">
                {t("inquiriesLead")}{" "}
                <a
                  href={`mailto:${contactEmail}`}
                  className="font-semibold text-primary underline-offset-4 hover:underline"
                >
                  {contactEmail}
                </a>
              </p>
              <h3 className="mt-10 text-sm font-bold uppercase tracking-[0.12em] text-gray-900">
                {t("boilerplateTitle")}
              </h3>
              <p className="mt-4 rounded-xl border border-gray-100 bg-gray-50/80 p-4 text-sm leading-relaxed text-gray-700">
                {t("boilerplate")}
              </p>
            </MarketingReveal>
          </div>
        </Container>
      </Section>
      <CTASection />
    </>
  );
}
