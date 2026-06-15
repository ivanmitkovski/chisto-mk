import type { Metadata } from "next";
import Link from "next/link";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import { defaultLocale, isLocale, type Locale } from "@/i18n/config";
import { chistoApiBase, chistoPublicSiteBase } from "@/lib/share-api";
import { SiteShareAttribution } from "./SiteShareAttribution";
import { formatSiteStatus, siteShareStrings } from "./site-share-strings";
import styles from "./site-share-page.module.css";

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
    robots: { index: true, follow: true },
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
  const statusLabel = formatSiteStatus(card.status, uiLocale);
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Place",
    name: card.title,
    description: card.siteLabel,
    address: { "@type": "PostalAddress", addressCountry: "MK", name: card.siteLabel },
  };

  return (
    <main
      style={{
        fontFamily: "var(--font-sans), system-ui, sans-serif",
        padding: 24,
        maxWidth: 560,
        margin: "0 auto",
        lineHeight: 1.5,
      }}
    >
      <SiteShareAttribution token={st ?? null} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <p style={{ fontSize: 13, color: "#64748b", marginBottom: 8 }}>Chisto.mk</p>
      <h1 style={{ fontSize: "1.5rem", margin: "0 0 8px", color: "#0f172a" }}>{card.title}</h1>
      <p style={{ color: "#475569", margin: "0 0 8px" }}>{card.siteLabel}</p>
      <p style={{ color: "#64748b", margin: "0 0 24px" }}>
        {t.statusPrefix}: {statusLabel}
      </p>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
        <Link href={appDeepLink} className={styles.linkPrimary}>
          {t.openInApp}
        </Link>
        <a href={webHome} className={styles.linkSecondary}>
          {t.getTheApp}
        </a>
      </div>
      <p style={{ marginTop: 28, fontSize: 14 }}>
        <a href={webHome} className={styles.textLink}>
          {t.signInCta}
        </a>
      </p>
    </main>
  );
}
