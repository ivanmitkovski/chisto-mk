"use client";

import { Analytics } from "@vercel/analytics/next";
import { useEffect, useState } from "react";
import { useCookieConsent } from "@/contexts/CookieConsentContext";

/**
 * Loads Vercel Web Analytics only after explicit opt-in (EU-style).
 * Production serves the collector from `/_vercel/insights/*`, which exists only
 * after Web Analytics is enabled on the Vercel project and a new deploy ships.
 */
export function ConditionalVercelAnalytics() {
  const { ready, decided, analytics } = useCookieConsent();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  if (!mounted || !ready || !decided || !analytics) return null;
  return <Analytics />;
}
