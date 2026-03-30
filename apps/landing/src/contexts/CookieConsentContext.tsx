"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  COOKIE_CONSENT_STORAGE_KEY,
  parseStoredConsent,
  serializeConsent,
} from "@/lib/cookie-consent";

export const OPEN_COOKIE_PREFERENCES_EVENT = "chisto:open-cookie-preferences";

type CookieConsentContextValue = {
  /** True after localStorage has been read (client only). */
  ready: boolean;
  /** User has made an initial choice (accept/reject/customize saved). */
  decided: boolean;
  /** Optional analytics / measurement tools allowed. */
  analytics: boolean;
  acceptAll: () => void;
  rejectNonEssential: () => void;
  savePreferences: (analytics: boolean) => void;
  openPreferences: () => void;
  preferencesOpen: boolean;
  setPreferencesOpen: (open: boolean) => void;
};

const CookieConsentContext = createContext<CookieConsentContextValue | null>(null);

export function CookieConsentProvider({ children }: { children: ReactNode }) {
  const [ready, setReady] = useState(false);
  const [decided, setDecided] = useState(false);
  const [analytics, setAnalytics] = useState(false);
  const [preferencesOpen, setPreferencesOpen] = useState(false);

  useEffect(() => {
    const stored = parseStoredConsent(localStorage.getItem(COOKIE_CONSENT_STORAGE_KEY));
    if (stored) {
      setAnalytics(stored.analytics);
      setDecided(true);
    }
    setReady(true);
  }, []);

  useEffect(() => {
    const onOpen = () => setPreferencesOpen(true);
    window.addEventListener(OPEN_COOKIE_PREFERENCES_EVENT, onOpen as EventListener);
    return () => window.removeEventListener(OPEN_COOKIE_PREFERENCES_EVENT, onOpen as EventListener);
  }, []);

  const persist = useCallback((allowAnalytics: boolean) => {
    localStorage.setItem(COOKIE_CONSENT_STORAGE_KEY, serializeConsent(allowAnalytics));
    setAnalytics(allowAnalytics);
    setDecided(true);
    setPreferencesOpen(false);
    window.dispatchEvent(new CustomEvent("chisto:cookie-consent-changed"));
  }, []);

  const value = useMemo<CookieConsentContextValue>(
    () => ({
      ready,
      decided,
      analytics,
      acceptAll: () => persist(true),
      rejectNonEssential: () => persist(false),
      savePreferences: (a) => persist(a),
      openPreferences: () => setPreferencesOpen(true),
      preferencesOpen,
      setPreferencesOpen,
    }),
    [ready, decided, analytics, persist, preferencesOpen],
  );

  return (
    <CookieConsentContext.Provider value={value}>{children}</CookieConsentContext.Provider>
  );
}

export function useCookieConsent() {
  const ctx = useContext(CookieConsentContext);
  if (!ctx) {
    throw new Error("useCookieConsent must be used within CookieConsentProvider");
  }
  return ctx;
}
