export const COOKIE_CONSENT_STORAGE_KEY = "chisto_cookie_consent_v1";

export type StoredCookieConsent = {
  v: 1;
  analytics: boolean;
  ts: number;
};

export function parseStoredConsent(raw: string | null): StoredCookieConsent | null {
  if (!raw) return null;
  try {
    const o = JSON.parse(raw) as Partial<StoredCookieConsent>;
    if (o.v !== 1 || typeof o.analytics !== "boolean") return null;
    return { v: 1, analytics: o.analytics, ts: typeof o.ts === "number" ? o.ts : Date.now() };
  } catch {
    return null;
  }
}

export function serializeConsent(analytics: boolean): string {
  return JSON.stringify({ v: 1, analytics, ts: Date.now() } satisfies StoredCookieConsent);
}
