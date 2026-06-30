import type { ShareLocale } from "@/i18n/config";

const TABLE: Record<
  ShareLocale,
  {
    openInApp: string;
    getTheApp: string;
    signInCta: string;
    statusPrefix: string;
    loadingLabel: string;
    errorTitle: string;
    errorBody: string;
    retry: string;
  }
> = {
  mk: {
    openInApp: "Отвори во апликација",
    getTheApp: "Преземи Chisto.mk",
    signInCta: "Најави се на платформата",
    statusPrefix: "Статус",
    loadingLabel: "Се вчитува прегледот…",
    errorTitle: "Привремено недостапно",
    errorBody: "Не можевме да го вчитаме прегледот. Обидете се повторно за момент.",
    retry: "Обиди се повторно",
  },
  en: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    signInCta: "Sign in on the web",
    statusPrefix: "Status",
    loadingLabel: "Loading preview…",
    errorTitle: "Temporarily unavailable",
    errorBody: "We could not load this preview. Please try again in a moment.",
    retry: "Retry",
  },
  sq: {
    openInApp: "Hap në aplikacion",
    getTheApp: "Merr Chisto.mk",
    signInCta: "Hyr në platformë",
    statusPrefix: "Statusi",
    loadingLabel: "Duke ngarkuar pamjen…",
    errorTitle: "Përkohësisht i padisponueshëm",
    errorBody: "Nuk mundëm ta ngarkonim këtë pamje. Provoni përsëri pas pak.",
    retry: "Provo përsëri",
  },
  sr: {
    openInApp: "Отвори у апликацији",
    getTheApp: "Преузми Chisto.mk",
    signInCta: "Пријава на платформи",
    statusPrefix: "Статус",
    loadingLabel: "Loading preview…",
    errorTitle: "Temporarily unavailable",
    errorBody: "We could not load this preview. Please try again in a moment.",
    retry: "Retry",
  },
  rom: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    signInCta: "Sign in on the web",
    statusPrefix: "Status",
    loadingLabel: "Loading preview…",
    errorTitle: "Temporarily unavailable",
    errorBody: "We could not load this preview. Please try again in a moment.",
    retry: "Retry",
  },
};

export function siteShareStrings(locale: string) {
  const key = locale as ShareLocale;
  if (key in TABLE) {
    return TABLE[key];
  }
  return TABLE.mk;
}

export function formatSiteStatus(status: string, locale: ShareLocale): string {
  const labels: Record<string, Record<ShareLocale, string>> = {
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
