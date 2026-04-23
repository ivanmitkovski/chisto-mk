import type { Locale } from "@/i18n/config";

const TABLE: Record<
  Locale,
  { openInApp: string; getTheApp: string; signInCta: string; schedulePrefix: string }
> = {
  mk: {
    openInApp: "Отвори во апликација",
    getTheApp: "Преземи Chisto.mk",
    signInCta: "Најави се на платформата",
    schedulePrefix: "Термин",
  },
  en: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    signInCta: "Sign in on the web",
    schedulePrefix: "When",
  },
  sq: {
    openInApp: "Hap në aplikacion",
    getTheApp: "Merr Chisto.mk",
    signInCta: "Hyr në platformë",
    schedulePrefix: "Orari",
  },
  sr: {
    openInApp: "Отвори у апликацији",
    getTheApp: "Преузми Chisto.mk",
    signInCta: "Пријава на платформи",
    schedulePrefix: "Термин",
  },
  rom: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    signInCta: "Sign in on the web",
    schedulePrefix: "When",
  },
};

export function eventShareStrings(locale: string) {
  const key = locale as Locale;
  if (key in TABLE) {
    return TABLE[key as Locale];
  }
  return TABLE.mk;
}
