import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import { defaultLocale, resolveShareLocale, type ShareLocale } from "@/i18n/config";
import { SiteShareView, type SiteShareCard } from "@/components/share/site";
import { chistoApiBase, chistoPublicSiteBase } from "@/lib/share-api";
import { APP_STORE_APP_ID, homeDownloadSectionUrl } from "@/lib/store-links";
import { SiteShareAttribution } from "./SiteShareAttribution";
import { formatSiteStatus, siteShareStrings } from "./site-share-strings";

type Props = {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ st?: string; cid?: string }>;
};

class ShareCardUpstreamError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ShareCardUpstreamError";
  }
}

async function loadShareCard(id: string): Promise<SiteShareCard | null> {
  // Share payloads include media/avatar URLs that must stay current with the API
  // (stable redirects). Avoid long-lived Next fetch cache serving pre-redirect signed URLs.
  const res = await fetch(`${chistoApiBase()}/sites/${encodeURIComponent(id)}/share-card`, {
    cache: "no-store",
  });
  if (res.status === 404) {
    return null;
  }
  if (!res.ok) {
    throw new ShareCardUpstreamError(`share-card upstream ${res.status}`);
  }
  return (await res.json()) as SiteShareCard;
}

function localeFromHeaders(h: Headers): ShareLocale {
  return resolveShareLocale(h.get("x-locale"));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const card = await loadShareCard(id).catch(() => "error" as const);
  if (card === "error" || !card) {
    return { title: "Chisto.mk" };
  }
  const h = await headers();
  const locale = localeFromHeaders(h);
  const statusLabel = formatSiteStatus(card.status, locale);
  const description =
    card.description?.trim() ||
    `${card.siteLabel} · ${statusLabel}`;
  const canonical = `${chistoPublicSiteBase()}/sites/${encodeURIComponent(id)}`;
  // Prefer stable opengraph-image.tsx — signed CDN URLs expire (~15m) and break social previews.
  const appArgument = `${chistoPublicSiteBase()}/app/home/map-focus?siteId=${encodeURIComponent(id)}`;
  return {
    title: `${card.title} · Chisto.mk`,
    description,
    alternates: { canonical },
    robots: { index: false, follow: true },
    other: {
      "apple-itunes-app": `app-id=${APP_STORE_APP_ID}, app-argument=${appArgument}`,
    },
    openGraph: {
      type: "website",
      url: canonical,
      siteName: "Chisto.mk",
      locale: locale === "en" ? "en_GB" : locale === "sq" ? "sq_MK" : "mk_MK",
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
  const { st, cid } = await searchParams;
  const card = await loadShareCard(id);
  if (!card) {
    notFound();
  }

  const h = await headers();
  const uiLocale = localeFromHeaders(h);
  const t = siteShareStrings(uiLocale);

  const siteBase = chistoPublicSiteBase();
  const deepLinkQuery = new URLSearchParams();
  deepLinkQuery.set("siteId", id);
  if (st) deepLinkQuery.set("st", st);
  if (cid) deepLinkQuery.set("cid", cid);
  // Use `/app/...` so Universal Links hand off to the installed app (same-path
  // `/sites/:id` would stay in the browser because the user is already there).
  const appDeepLink = `${siteBase}/app/home/map-focus?${deepLinkQuery.toString()}`;
  const marketingLocale = uiLocale === "sr" || uiLocale === "rom" ? defaultLocale : uiLocale;
  const webHome = `${siteBase}/${marketingLocale}`;
  const downloadUrl = homeDownloadSectionUrl(siteBase, marketingLocale);

  const jsonLd: Record<string, unknown> = {
    "@context": "https://schema.org",
    "@type": "Place",
    name: card.title,
    description: card.description ?? card.siteLabel,
    address: {
      "@type": "PostalAddress",
      addressCountry: "MK",
      name: card.address ?? card.siteLabel,
    },
  };
  if (Number.isFinite(card.latitude) && Number.isFinite(card.longitude)) {
    jsonLd.geo = {
      "@type": "GeoCoordinates",
      latitude: card.latitude,
      longitude: card.longitude,
    };
  }
  if (card.ogImageUrl) {
    jsonLd.image = card.ogImageUrl;
  }

  return (
    <>
      <SiteShareAttribution token={st ?? null} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <SiteShareView
        card={card}
        locale={uiLocale}
        t={t}
        openInAppHref={appDeepLink}
        getAppHref={downloadUrl}
        exploreHref={webHome}
        siteBase={siteBase}
      />
    </>
  );
}
