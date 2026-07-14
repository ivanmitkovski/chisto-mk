import type { Metadata } from "next";
import { headers } from "next/headers";
import { AppOpenHandoff, type AppHandoffCopy } from "@/components/app-handoff/AppOpenHandoff";
import { defaultLocale, resolveShareLocale, type ShareLocale } from "@/i18n/config";
import { isAppDeepLinkPath } from "@/lib/app-deep-link";
import { chistoPublicSiteBase } from "@/lib/share-api";
import { APP_STORE_APP_ID } from "@/lib/store-links";

export const dynamic = "force-dynamic";

type Props = {
  params: Promise<{ slug?: string[] }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

function handoffCopy(locale: ShareLocale): AppHandoffCopy {
  switch (locale) {
    case "en":
      return {
        opening: "Opening Chisto.mk…",
        title: "Open in the app",
        body: "Continue in the Chisto.mk app for the full map, reports, and actions. If the app does not open, download it below.",
        openApp: "Open in app",
        explore: "Explore Chisto.mk",
      };
    case "sq":
      return {
        opening: "Po hapet Chisto.mk…",
        title: "Hap në aplikacion",
        body: "Vazhdo në aplikacionin Chisto.mk për hartën, raportet dhe veprimet. Nëse aplikacioni nuk hapet, shkarkoje më poshtë.",
        openApp: "Hap në aplikacion",
        explore: "Eksploro Chisto.mk",
      };
    case "sr":
      return {
        opening: "Отварање Chisto.mk…",
        title: "Отвори у апликацији",
        body: "Настави у апликацији Chisto.mk за мапу, пријаве и акције. Ако се апликација не отвори, преузми је испод.",
        openApp: "Отвори у апликацији",
        explore: "Истражи Chisto.mk",
      };
    case "rom":
      return {
        opening: "Opening Chisto.mk…",
        title: "Open in the app",
        body: "Continue in the Chisto.mk app. If it does not open, download it below.",
        openApp: "Open in app",
        explore: "Explore Chisto.mk",
      };
    default:
      return {
        opening: "Се отвора Chisto.mk…",
        title: "Отвори во апликација",
        body: "Продолжи во апликацијата Chisto.mk за мапа, пријави и акции. Ако апликацијата не се отвори, преземи ја подолу.",
        openApp: "Отвори во апликација",
        explore: "Истражи Chisto.mk",
      };
  }
}

function searchParamsToQuery(searchParams: Record<string, string | string[] | undefined>): string {
  const qs = new URLSearchParams();
  for (const [key, value] of Object.entries(searchParams)) {
    if (value === undefined) continue;
    if (Array.isArray(value)) {
      for (const item of value) {
        qs.append(key, item);
      }
    } else {
      qs.set(key, value);
    }
  }
  const encoded = qs.toString();
  return encoded ? `?${encoded}` : "";
}

function buildHttpsAppUrl(slug: string[] | undefined, query: string): string {
  const base = chistoPublicSiteBase().replace(/\/$/, "");
  const path = slug?.length ? `/app/${slug.map(encodeURIComponent).join("/")}` : "/app";
  return `${base}${path}${query}`;
}

export async function generateMetadata({ params, searchParams }: Props): Promise<Metadata> {
  const { slug } = await params;
  const sp = await searchParams;
  const httpsUrl = buildHttpsAppUrl(slug, searchParamsToQuery(sp));
  return {
    title: "Open Chisto.mk",
    robots: { index: false, follow: false },
    other: {
      "apple-itunes-app": `app-id=${APP_STORE_APP_ID}, app-argument=${httpsUrl}`,
    },
  };
}

export default async function AppDeepLinkHandoffPage({ params, searchParams }: Props) {
  const { slug } = await params;
  const sp = await searchParams;
  const query = searchParamsToQuery(sp);
  const httpsUrl = buildHttpsAppUrl(slug, query);

  const pathOnly = new URL(httpsUrl).pathname;
  if (!isAppDeepLinkPath(pathOnly)) {
    // Should be unreachable under /app/*, but keep the contract explicit.
    return null;
  }

  const h = await headers();
  const locale = resolveShareLocale(h.get("x-locale"));
  const marketingLocale = locale === "sr" || locale === "rom" ? defaultLocale : locale;
  const exploreHref = `${chistoPublicSiteBase().replace(/\/$/, "")}/${marketingLocale}`;

  return (
    <AppOpenHandoff httpsUrl={httpsUrl} exploreHref={exploreHref} copy={handoffCopy(locale)} />
  );
}
