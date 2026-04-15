export const locales = ["mk", "en", "sq", "rom", "sr"] as const;
export type Locale = (typeof locales)[number];

export const defaultLocale: Locale = "mk";

/** Language names shown in the UI (always in Macedonian). */
export const languageNamesMk: Record<Locale, string> = {
  mk: "Македонски",
  en: "Англиски",
  sq: "Албански",
  rom: "Ромски",
  sr: "Српски",
};

/** Native-language labels for the language picker (each in its own script). */
export const languageOptionLabels: Record<Locale, string> = {
  mk: "Македонски",
  en: "English",
  sq: "Shqip",
  rom: "Romani",
  sr: "Српски",
};

export function isLocale(s: string): s is Locale {
  return locales.includes(s as Locale);
}
