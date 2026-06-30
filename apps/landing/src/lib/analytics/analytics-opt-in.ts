"use client";

import { COOKIE_CONSENT_STORAGE_KEY, parseStoredConsent } from "@/lib/cookie-consent";

export function analyticsOptIn(): boolean {
  if (typeof window === "undefined") return false;
  try {
    return parseStoredConsent(localStorage.getItem(COOKIE_CONSENT_STORAGE_KEY))?.analytics === true;
  } catch {
    return false;
  }
}
