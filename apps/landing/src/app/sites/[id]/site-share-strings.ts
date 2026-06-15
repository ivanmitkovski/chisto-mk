import type { Locale } from "@/i18n/config";

const TABLE: Record<
  Locale,
  { openInApp: string; getTheApp: string; signInCta: string; statusPrefix: string }
> = {
  mk: {
    openInApp: "Отвори во апликација",
    getTheApp: "Преземи Chisto.mk",
    signInCta: "Најави се на платформата",
    statusPrefix: "Статус",
  },
  en: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    signInCta: "Sign in on the web",
    statusPrefix: "Status",
  },
  sq: {
    openInApp: "Hap në aplikacion",
    getTheApp: "Merr Chisto.mk",
    signInCta: "Hyr në platformë",
    statusPrefix: "Statusi",
  },
  sr: {
    openInApp: "Отвори у апликацији",
    getTheApp: "Преузми Chisto.mk",
    signInCta: "Пријава на платформи",
    statusPrefix: "Статус",
  },
  rom: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    signInCta: "Sign in on the web",
    statusPrefix: "Status",
  },
};

export function siteShareStrings(locale: string) {
  const key = locale as Locale;
  if (key in TABLE) {
    return TABLE[key as Locale];
  }
  return TABLE.mk;
}

export function formatSiteStatus(status: string, locale: Locale): string {
  const labels: Record<string, Record<Locale, string>> = {
    VERIFIED: { mk: "Потврдено", en: "Verified", sq: "Verifikuar", sr: "Потврђено", rom: "Verified" },
    CLEANUP_SCHEDULED: {
      mk: "Заканана чистка",
      en: "Cleanup scheduled",
      sq: "Pastrim i planifikuar",
      sr: "Заказано чишћење",
      rom: "Cleanup scheduled",
    },
    IN_PROGRESS: { mk: "Во тек", en: "In progress", sq: "Në progres", sr: "У току", rom: "In progress" },
    CLEANED: { mk: "Исчистено", en: "Cleaned", sq: "Pastrur", sr: "Очищено", rom: "Cleaned" },
    DISPUTED: { mk: "Оспорено", en: "Disputed", sq: "I kontestuar", sr: "Оспорено", rom: "Disputed" },
  };
  const row = labels[status];
  if (row && locale in row) {
    return row[locale];
  }
  return status.replace(/_/g, " ").toLowerCase();
}
