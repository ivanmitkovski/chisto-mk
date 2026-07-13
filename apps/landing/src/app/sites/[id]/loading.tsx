import { headers } from "next/headers";
import { defaultLocale, isLocale, type Locale } from "@/i18n/config";
import { siteShareStrings } from "@/app/sites/[id]/site-share-strings";

export default async function SiteShareLoading() {
  const h = await headers();
  const rawLocale = h.get("x-locale");
  const uiLocale: Locale = rawLocale && isLocale(rawLocale) ? rawLocale : defaultLocale;
  const t = siteShareStrings(uiLocale);
  return (
    <main className="min-h-dvh bg-[#F4F5F7] px-4 py-10 font-sans" aria-busy="true" aria-label={t.loadingLabel}>
      <div className="mx-auto max-w-2xl">
        <div className="mb-6 h-7 w-36 animate-pulse rounded-md bg-gray-200/80" />
        <div className="overflow-hidden rounded-[24px] border border-[#E5E7ED]/90 bg-white p-4 shadow-[var(--shadow-card)] sm:p-6">
          <div className="aspect-video w-full animate-pulse rounded-[22px] bg-[#F0F1F7]" />
          <div className="mt-5 h-6 w-28 animate-pulse rounded-full bg-[#F0F1F7]" />
          <div className="mt-4 flex gap-2">
            <div className="h-6 w-20 animate-pulse rounded-full bg-[#F0F1F7]" />
            <div className="h-6 w-24 animate-pulse rounded-full bg-[#F0F1F7]" />
            <div className="h-6 w-16 animate-pulse rounded-full bg-[#F0F1F7]" />
          </div>
          <div className="mt-5 h-8 w-3/4 animate-pulse rounded-md bg-[#F0F1F7]" />
          <div className="mt-3 h-4 w-full animate-pulse rounded-md bg-[#F0F1F7]" />
          <div className="mt-2 h-4 w-5/6 animate-pulse rounded-md bg-[#F0F1F7]" />
          <div className="mt-6 space-y-3">
            <div className="h-5 w-full animate-pulse rounded-md bg-[#F0F1F7]" />
            <div className="h-5 w-full animate-pulse rounded-md bg-[#F0F1F7]" />
            <div className="h-5 w-2/3 animate-pulse rounded-md bg-[#F0F1F7]" />
          </div>
        </div>
        <span className="sr-only">{t.loadingLabel}</span>
      </div>
    </main>
  );
}
