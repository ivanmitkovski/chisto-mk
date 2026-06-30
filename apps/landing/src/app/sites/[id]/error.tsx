"use client";

import { useEffect, useState } from "react";
import { defaultLocale, isLocale, type Locale } from "@/i18n/config";
import { siteShareStrings } from "./site-share-strings";
import { SharePageError } from "@/components/layout/SharePageLayout/SharePageError";

export default function SiteShareError({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const [locale, setLocale] = useState<Locale>(defaultLocale);

  useEffect(() => {
    const match = document.cookie.match(/NEXT_LOCALE=([^;]+)/);
    const fromCookie = match?.[1];
    if (fromCookie && isLocale(fromCookie)) {
      setLocale(fromCookie);
    }
  }, []);

  const t = siteShareStrings(locale);
  return <SharePageError title={t.errorTitle} body={t.errorBody} retryLabel={t.retry} reset={reset} />;
}
