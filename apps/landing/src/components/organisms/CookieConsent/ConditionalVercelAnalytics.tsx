"use client";

import { Analytics } from "@vercel/analytics/react";
import { useEffect, useState } from "react";
import { useCookieConsent } from "@/contexts/CookieConsentContext";

/** Loads Vercel Web Analytics only after explicit opt-in (EU-style). */
export function ConditionalVercelAnalytics() {
  const { ready, decided, analytics } = useCookieConsent();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  if (!mounted || !ready || !decided || !analytics) return null;
  return <Analytics />;
}
