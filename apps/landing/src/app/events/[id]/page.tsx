import type { Metadata } from "next";
import Link from "next/link";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import { defaultLocale, isLocale, type Locale } from "@/i18n/config";
import { eventShareStrings } from "./event-share-strings";

type Props = { params: Promise<{ id: string }> };

function apiBase(): string {
  const raw = process.env.NEXT_PUBLIC_CHISTO_API_URL?.trim();
  const b = raw && raw.length > 0 ? raw : "https://api.chisto.mk";
  return b.replace(/\/+$/, "");
}

type ShareCard = {
  id: string;
  title: string;
  siteLabel: string;
  scheduledAt: string;
  endAt: string | null;
  lifecycleStatus: string;
};

async function loadShareCard(id: string): Promise<ShareCard | null> {
  const res = await fetch(`${apiBase()}/events/${encodeURIComponent(id)}/share-card`, {
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
  return `${dtf.format(start)} — ${dtf.format(end)}`;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const card = await loadShareCard(id);
  if (!card) {
    return { title: "Chisto.mk" };
  }
  return {
    title: `${card.title} · Chisto.mk`,
    description: `${card.siteLabel} · ${card.title}`,
    robots: { index: true, follow: true },
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

  const appUniversal = `https://chisto.mk/app/events/detail/${encodeURIComponent(id)}`;
  const webHome = `https://chisto.mk/${uiLocale}`;

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
      <p style={{ fontSize: 13, color: "#64748b", marginBottom: 8 }}>Chisto.mk</p>
      <h1 style={{ fontSize: "1.5rem", margin: "0 0 8px", color: "#0f172a" }}>{card.title}</h1>
      <p style={{ color: "#475569", margin: "0 0 8px" }}>{card.siteLabel}</p>
      <p style={{ color: "#64748b", margin: "0 0 24px" }}>
        {t.schedulePrefix}: {scheduleLine(card, uiLocale)}
      </p>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
        <Link
          href={appUniversal}
          style={{
            display: "inline-block",
            padding: "12px 20px",
            background: "#0d9488",
            color: "#fff",
            borderRadius: 8,
            textDecoration: "none",
            fontWeight: 600,
          }}
        >
          {t.openInApp}
        </Link>
        <a
          href={webHome}
          style={{
            display: "inline-block",
            padding: "12px 20px",
            border: "1px solid #cbd5e1",
            borderRadius: 8,
            textDecoration: "none",
            color: "#0f172a",
          }}
        >
          {t.getTheApp}
        </a>
      </div>
      <p style={{ marginTop: 28, fontSize: 14 }}>
        <a href={webHome} style={{ color: "#0f766e" }}>
          {t.signInCta}
        </a>
      </p>
    </main>
  );
}
