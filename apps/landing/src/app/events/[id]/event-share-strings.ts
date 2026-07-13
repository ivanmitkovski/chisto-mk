import type { ShareLocale } from "@/i18n/config";

const TABLE: Record<
  ShareLocale,
  {
    openInApp: string;
    getTheApp: string;
    exploreCta: string;
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
    exploreCta: "Истражи Chisto.mk",
    schedulePrefix: "Термин",
    loadingLabel: "Се вчитува прегледот…",
    errorTitle: "Привремено недостапно",
    errorBody: "Не можевме да го вчитаме прегледот. Обидете се повторно за момент.",
    retry: "Обиди се повторно",
  },
  en: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    exploreCta: "Explore Chisto.mk",
    schedulePrefix: "When",
    loadingLabel: "Loading preview…",
    errorTitle: "Temporarily unavailable",
    errorBody: "We could not load this preview. Please try again in a moment.",
    retry: "Retry",
  },
  sq: {
    openInApp: "Hap në aplikacion",
    getTheApp: "Merr Chisto.mk",
    exploreCta: "Eksploro Chisto.mk",
    schedulePrefix: "Orari",
    loadingLabel: "Duke ngarkuar pamjen…",
    errorTitle: "Përkohësisht i padisponueshëm",
    errorBody: "Nuk mundëm ta ngarkonim këtë pamje. Provoni përsëri pas pak.",
    retry: "Provo përsëri",
  },
  sr: {
    openInApp: "Отвори у апликацији",
    getTheApp: "Преузми Chisto.mk",
    exploreCta: "Истражи Chisto.mk",
    schedulePrefix: "Термин",
    loadingLabel: "Учитавање прегледа…",
    errorTitle: "Привремено недоступно",
    errorBody: "Нисмо могли да учитамо преглед. Покушајте поново за тренутак.",
    retry: "Покушај поново",
  },
  rom: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    exploreCta: "Explore Chisto.mk",
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
