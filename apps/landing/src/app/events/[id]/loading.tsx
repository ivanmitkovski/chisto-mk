import { headers } from "next/headers";
import { defaultLocale, isLocale, type Locale } from "@/i18n/config";
import { eventShareStrings } from "@/app/events/[id]/event-share-strings";
import { SharePageLoading } from "@/components/layout/SharePageLayout/SharePageLoading";

export default async function EventShareLoading() {
  const h = await headers();
  const rawLocale = h.get("x-locale");
  const uiLocale: Locale = rawLocale && isLocale(rawLocale) ? rawLocale : defaultLocale;
  const t = eventShareStrings(uiLocale);
  return <SharePageLoading srLabel={t.loadingLabel} />;
}
