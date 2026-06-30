import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import { defaultLocale, isLocale, type Locale } from "@/i18n/config";
import { SharePageShell } from "@/components/layout/SharePageLayout/SharePageShell";
import { chistoApiBase, chistoPublicSiteBase } from "@/lib/share-api";
import { homeDownloadSectionUrl } from "@/lib/store-links";
import { SiteShareAttribution } from "./SiteShareAttribution";
import { formatSiteStatus, siteShareStrings } from "./site-share-strings";

type Props = {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ st?: string; cid?: string }>;
};

type ShareCard = {
  id: string;
  title: string;
  siteLabel: string;
  status: string;
};

async function loadShareCard(id: string): Promise<ShareCard | null> {
  const res = await fetch(`${chistoApiBase()}/sites/${encodeURIComponent(id)}/share-card`, {
    next: { revalidate: 120 },
  });
  if (res.status === 404) {
    return null;
  }
  if (!res.ok) {
    return null;
  }
  return (await res.json()) as ShareCard;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const card = await loadShareCard(id);
  if (!card) {
    return { title: "Chisto.mk" };
  }
  const description = `${card.siteLabel} · ${card.title}`;
  const canonical = `${chistoPublicSiteBase()}/sites/${encodeURIComponent(id)}`;
  return {
    title: `${card.title} · Chisto.mk`,
    description,
    alternates: { canonical },
    robots: { index: false, follow: true },
    openGraph: {
      type: "website",
      url: canonical,
      siteName: "Chisto.mk",
      locale: "mk_MK",
      title: card.title,
      description,
    },
    twitter: {
      card: "summary_large_image",
      title: card.title,
      description,
    },
  };
}

export default async function SiteSharePage({ params, searchParams }: Props) {
  const { id } = await params;
  const { st } = await searchParams;
  const card = await loadShareCard(id);
  if (!card) {
    notFound();
  }

  const h = await headers();
  const rawLocale = h.get("x-locale");
  const uiLocale: Locale = rawLocale && isLocale(rawLocale) ? rawLocale : defaultLocale;
  const t = siteShareStrings(uiLocale);

  const siteBase = chistoPublicSiteBase();
  const appDeepLink = `${siteBase}/sites/${encodeURIComponent(id)}${st ? `?st=${encodeURIComponent(st)}` : ""}`;
  const webHome = `${siteBase}/${uiLocale}`;
  const downloadUrl = homeDownloadSectionUrl(siteBase, uiLocale);
  const statusLabel = formatSiteStatus(card.status, uiLocale);
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Place",
    name: card.title,
    description: card.siteLabel,
    address: { "@type": "PostalAddress", addressCountry: "MK", name: card.siteLabel },
  };

  return (
    <>
      <SiteShareAttribution token={st ?? null} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <SharePageShell
        homeHref={webHome}
        homeLabel={t.signInCta}
        title={card.title}
        lines={[card.siteLabel, `${t.statusPrefix}: ${statusLabel}`]}
        primary={{ href: appDeepLink, label: t.openInApp }}
        secondary={{ href: downloadUrl, label: t.getTheApp }}
        footerLink={{ href: webHome, label: t.signInCta }}
      />
    </>
  );
}
