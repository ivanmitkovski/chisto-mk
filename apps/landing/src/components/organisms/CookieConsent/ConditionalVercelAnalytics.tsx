"use client";

import { Analytics } from "@vercel/analytics/next";
import { useEffect, useState } from "react";
import { useCookieConsent } from "@/contexts/CookieConsentContext";
import { isVercelInsightsScriptReady } from "@/lib/analytics/vercel-insights-ready";

/**
 * Loads Vercel Web Analytics only after explicit opt-in (EU-style).
 * Also waits until `/_vercel/insights/script.js` is actually JS on this deployment —
 * otherwise the package logs a console error and the browser blocks HTML-as-script.
 */
export function ConditionalVercelAnalytics() {
  const { ready, decided, analytics } = useCookieConsent();
  const [mounted, setMounted] = useState(false);
  const [insightsReady, setInsightsReady] = useState(false);

  useEffect(() => setMounted(true), []);

  useEffect(() => {
    if (!mounted || !ready || !decided || !analytics) {
      setInsightsReady(false);
      return;
    }

    let cancelled = false;

    void (async () => {
      const ok = await isVercelInsightsScriptReady();
      if (!cancelled) setInsightsReady(ok);
    })();

    return () => {
      cancelled = true;
    };
  }, [mounted, ready, decided, analytics]);

  if (!mounted || !ready || !decided || !analytics || !insightsReady) return null;
  return <Analytics />;
}
