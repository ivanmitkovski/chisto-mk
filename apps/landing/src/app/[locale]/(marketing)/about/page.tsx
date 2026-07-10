import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { notFound } from "next/navigation";
import { AboutPage } from "@/components/organisms/AboutPage";
import { CTASection } from "@/components/organisms/CTASection";
import { isLaunchPageVisible } from "@/config/launch";
import { LEGAL_PUBLIC_DEFAULTS } from "@/lib/legal/legal-public-config";
import { buildMarketingMetadata } from "@/lib/seo/marketing-metadata";
import { getSiteUrl } from "@/lib/site-url";

type Props = { params: Promise<{ locale: string }> };

type Creator = {
  name: string;
  title: string;
  role?: string;
  affiliation?: string;
  linkedinUrl?: string;
  imageSrc?: string;
  bioParagraphs?: string[];
};

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

export default async function AboutRoute({ params }: Props) {
  if (!isLaunchPageVisible("about")) {
    notFound();
  }
  const { locale } = await params;
  const tMeta = await getTranslations({ locale, namespace: "metadata" });
  const tAbout = await getTranslations({ locale, namespace: "aboutPage" });
  const siteUrl = getSiteUrl().replace(/\/$/, "");
  const pageUrl = `${siteUrl}/${locale}/about`;
  const creators = tAbout.raw("creators") as Creator[];

  const people = creators.map((creator) => ({
    "@type": "Person",
    name: creator.name,
    jobTitle: creator.role ? `${creator.title}, ${creator.role}` : creator.title,
    ...(creator.affiliation ? { affiliation: creator.affiliation } : {}),
    ...(creator.linkedinUrl ? { sameAs: [creator.linkedinUrl] } : {}),
    ...(creator.imageSrc
      ? { image: creator.imageSrc.startsWith("http") ? creator.imageSrc : `${siteUrl}${creator.imageSrc}` }
      : {}),
    ...(creator.bioParagraphs?.length
      ? { description: creator.bioParagraphs.join(" ") }
      : {}),
    worksFor: {
      "@type": "Organization",
      name: LEGAL_PUBLIC_DEFAULTS.legalEntityName,
      url: siteUrl,
    },
  }));

  const jsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "AboutPage",
        name: tMeta("about.title"),
        description: tMeta("about.description"),
        url: pageUrl,
        isPartOf: {
          "@type": "WebSite",
          name: tMeta("siteName"),
          url: siteUrl,
        },
        mainEntity: {
          "@type": "Organization",
          name: LEGAL_PUBLIC_DEFAULTS.legalEntityName,
          url: siteUrl,
          logo: `${siteUrl}/icon.png`,
        },
      },
      ...people,
    ],
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <AboutPage />
      <CTASection />
    </>
  );
}
