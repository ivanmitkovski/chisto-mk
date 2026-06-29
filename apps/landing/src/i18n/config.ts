/** Routed marketing locales (must match `i18n/routing.ts`). */
export const locales = ["mk", "en", "sq"] as const;
export type Locale = (typeof locales)[number];

/** Share-landing copy fallbacks when Accept-Language is sr/rom (not routed on marketing). */
export type ShareLocale = Locale | "sr" | "rom";

export const defaultLocale: Locale = "mk";

/** Language names shown in the UI (always in Macedonian). */
export const languageNamesMk: Record<Locale, string> = {
  mk: "Македонски",
  en: "Англиски",
  sq: "Албански",
};

/** Native-language labels for the language picker (each in its own script). */
export const languageOptionLabels: Record<Locale, string> = {
  mk: "Македонски",
  en: "English",
  sq: "Shqip",
};

export function isLocale(s: string): s is Locale {
  return locales.includes(s as Locale);
}

/** Resolve share-page locale from cookie/header; falls back to sr/rom copy when needed. */
export function resolveShareLocale(s: string | null | undefined): ShareLocale {
  if (s && isLocale(s)) return s;
  if (s === "sr" || s === "rom") return s;
  return defaultLocale;
}
