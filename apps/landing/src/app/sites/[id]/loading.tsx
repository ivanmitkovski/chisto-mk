import { headers } from "next/headers";
import { defaultLocale, isLocale, type Locale } from "@/i18n/config";
import { siteShareStrings } from "@/app/sites/[id]/site-share-strings";
import { SharePageLoading } from "@/components/layout/SharePageLayout/SharePageLoading";

export default async function SiteShareLoading() {
  const h = await headers();
  const rawLocale = h.get("x-locale");
  const uiLocale: Locale = rawLocale && isLocale(rawLocale) ? rawLocale : defaultLocale;
  const t = siteShareStrings(uiLocale);
  return <SharePageLoading srLabel={t.loadingLabel} />;
}
