import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import { defaultLocale, isLocale, type Locale } from "@/i18n/config";
import { SharePageShell } from "@/components/layout/SharePageLayout/SharePageShell";
import { chistoApiBase, chistoPublicSiteBase } from "@/lib/share-api";
import { homeDownloadSectionUrl } from "@/lib/store-links";
import { eventShareStrings } from "./event-share-strings";

type Props = { params: Promise<{ id: string }> };

type ShareCard = {
  id: string;
  title: string;
  siteLabel: string;
  scheduledAt: string;
  endAt: string | null;
  lifecycleStatus: string;
};

async function loadShareCard(id: string): Promise<ShareCard | null> {
  const res = await fetch(`${chistoApiBase()}/events/${encodeURIComponent(id)}/share-card`, {
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

function scheduleLine(card: ShareCard, locale: Locale): string {
  const start = new Date(card.scheduledAt);
  const end = card.endAt != null ? new Date(card.endAt) : null;
  const dtf = new Intl.DateTimeFormat(locale === "mk" ? "mk-MK" : locale === "sq" ? "sq-MK" : "en-GB", {
    dateStyle: "medium",
    timeStyle: "short",
  });
  if (end == null || Number.isNaN(end.getTime())) {
    return dtf.format(start);
  }
  return `${dtf.format(start)} · ${dtf.format(end)}`;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const card = await loadShareCard(id);
  if (!card) {
    return { title: "Chisto.mk" };
  }
  const description = `${card.siteLabel} · ${card.title}`;
  const canonical = `${chistoPublicSiteBase()}/events/${encodeURIComponent(id)}`;
  const ogLocale = "mk_MK";
  return {
    title: `${card.title} · Chisto.mk`,
    description,
    alternates: { canonical },
    robots: { index: true, follow: true },
    openGraph: {
      type: "website",
      url: canonical,
      siteName: "Chisto.mk",
      locale: ogLocale,
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

export default async function EventSharePage({ params }: Props) {
  const { id } = await params;
  const card = await loadShareCard(id);
  if (!card) {
    notFound();
  }

  const h = await headers();
  const rawLocale = h.get("x-locale");
  const uiLocale: Locale = rawLocale && isLocale(rawLocale) ? rawLocale : defaultLocale;
  const t = eventShareStrings(uiLocale);

  const siteBase = chistoPublicSiteBase();
  const appUniversal = `${siteBase}/app/events/detail/${encodeURIComponent(id)}`;
  const webHome = `${siteBase}/${uiLocale}`;
  const downloadUrl = homeDownloadSectionUrl(siteBase, uiLocale);
  const schedule = scheduleLine(card, uiLocale);
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Event",
    name: card.title,
    eventAttendanceMode: "https://schema.org/OfflineEventAttendanceMode",
    eventStatus: "https://schema.org/EventScheduled",
    location: { "@type": "Place", name: card.siteLabel, address: { "@type": "PostalAddress", addressCountry: "MK" } },
    startDate: card.scheduledAt,
    ...(card.endAt ? { endDate: card.endAt } : {}),
    organizer: { "@type": "Organization", name: "Chisto.mk", url: "https://chisto.mk" },
  };

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <SharePageShell
        homeHref={webHome}
        homeLabel={t.signInCta}
        title={card.title}
        lines={[card.siteLabel, `${t.schedulePrefix}: ${schedule}`]}
        primary={{ href: appUniversal, label: t.openInApp }}
        secondary={{ href: downloadUrl, label: t.getTheApp }}
        footerLink={{ href: webHome, label: t.signInCta }}
      />
    </>
  );
}
