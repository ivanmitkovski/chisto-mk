"use client";

import { track } from "@vercel/analytics";
import { COOKIE_CONSENT_STORAGE_KEY, parseStoredConsent } from "@/lib/cookie-consent";

function analyticsOptIn(): boolean {
  if (typeof window === "undefined") return false;
  try {
    return parseStoredConsent(localStorage.getItem(COOKIE_CONSENT_STORAGE_KEY))?.analytics === true;
  } catch {
    return false;
  }
}

export function trackHelpEvent(name: string, properties?: Record<string, string | number | boolean | null | undefined>) {
  if (!analyticsOptIn()) return;
  track(name, properties);
}
