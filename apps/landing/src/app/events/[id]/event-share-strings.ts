import type { ShareLocale } from "@/i18n/config";

const TABLE: Record<
  ShareLocale,
  {
    openInApp: string;
    getTheApp: string;
    signInCta: string;
    schedulePrefix: string;
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
    schedulePrefix: "Термин",
    loadingLabel: "Се вчитува прегледот…",
    errorTitle: "Привремено недостапно",
    errorBody: "Не можевме да го вчитаме прегледот. Обидете се повторно за момент.",
    retry: "Обиди се повторно",
  },
  en: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    signInCta: "Sign in on the web",
    schedulePrefix: "When",
    loadingLabel: "Loading preview…",
    errorTitle: "Temporarily unavailable",
    errorBody: "We could not load this preview. Please try again in a moment.",
    retry: "Retry",
  },
  sq: {
    openInApp: "Hap në aplikacion",
    getTheApp: "Merr Chisto.mk",
    signInCta: "Hyr në platformë",
    schedulePrefix: "Orari",
    loadingLabel: "Duke ngarkuar pamjen…",
    errorTitle: "Përkohësisht i padisponueshëm",
    errorBody: "Nuk mundëm ta ngarkonim këtë pamje. Provoni përsëri pas pak.",
    retry: "Provo përsëri",
  },
  sr: {
    openInApp: "Отвори у апликацији",
    getTheApp: "Преузми Chisto.mk",
    signInCta: "Пријава на платформи",
    schedulePrefix: "Термин",
    loadingLabel: "Loading preview…",
    errorTitle: "Temporarily unavailable",
    errorBody: "We could not load this preview. Please try again in a moment.",
    retry: "Retry",
  },
  rom: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    signInCta: "Sign in on the web",
    schedulePrefix: "When",
    loadingLabel: "Loading preview…",
    errorTitle: "Temporarily unavailable",
    errorBody: "We could not load this preview. Please try again in a moment.",
    retry: "Retry",
  },
};

export function eventShareStrings(locale: string) {
  const key = locale as ShareLocale;
  if (key in TABLE) {
    return TABLE[key];
  }
  return TABLE.mk;
}
