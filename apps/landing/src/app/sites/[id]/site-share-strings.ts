import type { ShareLocale } from "@/i18n/config";

export type SiteShareCopy = {
  openInApp: string;
  getTheApp: string;
  exploreCta: string;
  statusPrefix: string;
  loadingLabel: string;
  errorTitle: string;
  errorBody: string;
  retry: string;
  categoryLabel: string;
  severityLabel: string;
  cleanupEffortLabel: string;
  locationLabel: string;
  viewOnMap: string;
  reportedBy: string;
  reporterDeleted: string;
  reporterAnonymous: string;
  upvotes: string;
  comments: string;
  shares: string;
  saves: string;
  engagementLabel: string;
  upcomingCleanups: string;
  participants: string;
  cleanupEvidence: string;
  cleanedNoEvidenceBody: string;
  noPhotos: string;
  photoUnavailable: string;
  openPhoto: string;
  photoCount: string;
  statusExplainer: Record<string, { title: string; body: string }>;
  closeLightbox: string;
  previousPhoto: string;
  nextPhoto: string;
};

const STATUS_EXPLAINERS: Record<
  ShareLocale,
  Record<string, { title: string; body: string }>
> = {
  mk: {
    VERIFIED: {
      title: "Потврдена локација",
      body: "Модераторите ја потврдија оваа загадена локација. Отворете ја во апликацијата за акција.",
    },
    CLEANUP_SCHEDULED: {
      title: "Чистење е закажано",
      body: "За оваа локација е закажан настан за чистење. Придружете се преку апликацијата.",
    },
    IN_PROGRESS: {
      title: "Чистење во тек",
      body: "Волонтерите моментално ја чистат оваа локација.",
    },
    CLEANED: {
      title: "Локацијата е исчистена",
      body: "Оваа локација е обележана како исчистена. Погледнете ги доказите подолу.",
    },
    DISPUTED: {
      title: "Оспорена локација",
      body: "Статусот на оваа локација е оспорен и се преиспитува.",
    },
  },
  en: {
    VERIFIED: {
      title: "Verified site",
      body: "Moderators confirmed this pollution site. Open the app to take action.",
    },
    CLEANUP_SCHEDULED: {
      title: "Cleanup scheduled",
      body: "A cleanup event is planned for this site. Join from the app.",
    },
    IN_PROGRESS: {
      title: "Cleanup in progress",
      body: "Volunteers are currently cleaning this site.",
    },
    CLEANED: {
      title: "Site cleaned",
      body: "This site is marked as cleaned. See cleanup evidence below.",
    },
    DISPUTED: {
      title: "Disputed site",
      body: "This site’s status is disputed and under review.",
    },
  },
  sq: {
    VERIFIED: {
      title: "Vend i verifikuar",
      body: "Moderatorët e konfirmuan këtë vend ndotjeje. Hapni aplikacionin për të vepruar.",
    },
    CLEANUP_SCHEDULED: {
      title: "Pastrim i planifikuar",
      body: "Një ngjarje pastrimi është planifikuar. Bashkohuni nga aplikacioni.",
    },
    IN_PROGRESS: {
      title: "Pastrim në progres",
      body: "Vullnetarët po e pastrojnë këtë vend.",
    },
    CLEANED: {
      title: "Vend i pastruar",
      body: "Ky vend është shënuar si i pastruar. Shihni evidencën më poshtë.",
    },
    DISPUTED: {
      title: "Vend i kontestuar",
      body: "Statusi i këtij vendi është kontestuar dhe në rishikim.",
    },
  },
  sr: {
    VERIFIED: {
      title: "Потврђена локација",
      body: "Модератори су потврдили ову локацију загађења. Отворите апликацију за акцију.",
    },
    CLEANUP_SCHEDULED: {
      title: "Чишћење заказано",
      body: "За ову локацију је заказан догађај чишћења. Придружите се преко апликације.",
    },
    IN_PROGRESS: {
      title: "Чишћење у току",
      body: "Волонтери тренутно чисте ову локацију.",
    },
    CLEANED: {
      title: "Локација очишћена",
      body: "Ова локација је означена као очишћена. Погледајте доказе испод.",
    },
    DISPUTED: {
      title: "Оспорена локација",
      body: "Статус ове локације је оспорен и преиспитује се.",
    },
  },
  rom: {
    VERIFIED: {
      title: "Verified site",
      body: "Moderators confirmed this pollution site. Open the app to take action.",
    },
    CLEANUP_SCHEDULED: {
      title: "Cleanup scheduled",
      body: "A cleanup event is planned for this site. Join from the app.",
    },
    IN_PROGRESS: {
      title: "Cleanup in progress",
      body: "Volunteers are currently cleaning this site.",
    },
    CLEANED: {
      title: "Site cleaned",
      body: "This site is marked as cleaned. See cleanup evidence below.",
    },
    DISPUTED: {
      title: "Disputed site",
      body: "This site’s status is disputed and under review.",
    },
  },
};

const TABLE: Record<ShareLocale, Omit<SiteShareCopy, "statusExplainer">> = {
  mk: {
    openInApp: "Отвори во апликација",
    getTheApp: "Преземи Chisto.mk",
    exploreCta: "Истражи Chisto.mk",
    statusPrefix: "Статус",
    loadingLabel: "Се вчитува прегледот…",
    errorTitle: "Привремено недостапно",
    errorBody: "Не можевме да го вчитаме прегледот. Обидете се повторно за момент.",
    retry: "Обиди се повторно",
    categoryLabel: "Категорија",
    severityLabel: "Сериозност",
    cleanupEffortLabel: "Напор за чистење",
    locationLabel: "Локација",
    viewOnMap: "Отвори на карта",
    reportedBy: "Пријавено од",
    reporterDeleted: "Избришан корисник",
    reporterAnonymous: "Анонимен",
    upvotes: "Поддршки",
    comments: "Коментари",
    shares: "Споделувања",
    saves: "Зачувани",
    engagementLabel: "Ангажман",
    upcomingCleanups: "Претстојни чистења",
    participants: "учесници",
    cleanupEvidence: "Докази по чистење",
    cleanedNoEvidenceBody: "Оваа локација е обележана како исчистена.",
    noPhotos: "Нема фотографии",
    photoUnavailable: "Фотографијата е недостапна",
    openPhoto: "Отвори фотографија",
    photoCount: "фото",
    closeLightbox: "Затвори",
    previousPhoto: "Претходна",
    nextPhoto: "Следна",
  },
  en: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    exploreCta: "Explore Chisto.mk",
    statusPrefix: "Status",
    loadingLabel: "Loading preview…",
    errorTitle: "Temporarily unavailable",
    errorBody: "We could not load this preview. Please try again in a moment.",
    retry: "Retry",
    categoryLabel: "Category",
    severityLabel: "Severity",
    cleanupEffortLabel: "Cleanup effort",
    locationLabel: "Location",
    viewOnMap: "View on map",
    reportedBy: "Reported by",
    reporterDeleted: "Deleted user",
    reporterAnonymous: "Anonymous",
    upvotes: "Upvotes",
    comments: "Comments",
    shares: "Shares",
    saves: "Saves",
    engagementLabel: "Engagement",
    upcomingCleanups: "Upcoming cleanups",
    participants: "participants",
    cleanupEvidence: "Cleanup evidence",
    cleanedNoEvidenceBody: "This site is marked as cleaned.",
    noPhotos: "No photos",
    photoUnavailable: "Photo unavailable",
    openPhoto: "Open photo",
    photoCount: "photos",
    closeLightbox: "Close",
    previousPhoto: "Previous",
    nextPhoto: "Next",
  },
  sq: {
    openInApp: "Hap në aplikacion",
    getTheApp: "Merr Chisto.mk",
    exploreCta: "Eksploro Chisto.mk",
    statusPrefix: "Statusi",
    loadingLabel: "Duke ngarkuar pamjen…",
    errorTitle: "Përkohësisht i padisponueshëm",
    errorBody: "Nuk mundëm ta ngarkonim këtë pamje. Provoni përsëri pas pak.",
    retry: "Provo përsëri",
    categoryLabel: "Kategoria",
    severityLabel: "Rëndesia",
    cleanupEffortLabel: "Përpjekja e pastrimit",
    locationLabel: "Vendndodhja",
    viewOnMap: "Shiko në hartë",
    reportedBy: "Raportuar nga",
    reporterDeleted: "Përdorues i fshirë",
    reporterAnonymous: "Anonim",
    upvotes: "Mbështetje",
    comments: "Komente",
    shares: "Ndarje",
    saves: "Ruajtje",
    engagementLabel: "Angazhim",
    upcomingCleanups: "Pastrime të ardhshme",
    participants: "pjesëmarrës",
    cleanupEvidence: "Evidenca e pastrimit",
    cleanedNoEvidenceBody: "Ky vend është shënuar si i pastruar.",
    noPhotos: "Nuk ka foto",
    photoUnavailable: "Fotoja nuk është e disponueshme",
    openPhoto: "Hap foton",
    photoCount: "foto",
    closeLightbox: "Mbyll",
    previousPhoto: "E mëparshmja",
    nextPhoto: "E radhës",
  },
  sr: {
    openInApp: "Отвори у апликацији",
    getTheApp: "Преузми Chisto.mk",
    exploreCta: "Истражи Chisto.mk",
    statusPrefix: "Статус",
    loadingLabel: "Учитавање прегледа…",
    errorTitle: "Привремено недоступно",
    errorBody: "Нисмо могли да учитамо преглед. Покушајте поново за тренутак.",
    retry: "Покушај поново",
    categoryLabel: "Категорија",
    severityLabel: "Озбиљност",
    cleanupEffortLabel: "Напор чишћења",
    locationLabel: "Локација",
    viewOnMap: "Отвори на мапи",
    reportedBy: "Пријавио",
    reporterDeleted: "Обрисани корисник",
    reporterAnonymous: "Анониман",
    upvotes: "Подршке",
    comments: "Коментари",
    shares: "Дељења",
    saves: "Сачувано",
    engagementLabel: "Ангажованост",
    upcomingCleanups: "Предстојећа чишћења",
    participants: "учесника",
    cleanupEvidence: "Докази после чишћења",
    cleanedNoEvidenceBody: "Ова локација је означена као очишћена.",
    noPhotos: "Нема фотографија",
    photoUnavailable: "Фотографија није доступна",
    openPhoto: "Отвори фотографију",
    photoCount: "фото",
    closeLightbox: "Затвори",
    previousPhoto: "Претходна",
    nextPhoto: "Следећа",
  },
  rom: {
    openInApp: "Open in app",
    getTheApp: "Get Chisto.mk",
    exploreCta: "Explore Chisto.mk",
    statusPrefix: "Status",
    loadingLabel: "Loading preview…",
    errorTitle: "Temporarily unavailable",
    errorBody: "We could not load this preview. Please try again in a moment.",
    retry: "Retry",
    categoryLabel: "Category",
    severityLabel: "Severity",
    cleanupEffortLabel: "Cleanup effort",
    locationLabel: "Location",
    viewOnMap: "View on map",
    reportedBy: "Reported by",
    reporterDeleted: "Deleted user",
    reporterAnonymous: "Anonymous",
    upvotes: "Upvotes",
    comments: "Comments",
    shares: "Shares",
    saves: "Saves",
    engagementLabel: "Engagement",
    upcomingCleanups: "Upcoming cleanups",
    participants: "participants",
    cleanupEvidence: "Cleanup evidence",
    cleanedNoEvidenceBody: "This site is marked as cleaned.",
    noPhotos: "No photos",
    photoUnavailable: "Photo unavailable",
    openPhoto: "Open photo",
    photoCount: "photos",
    closeLightbox: "Close",
    previousPhoto: "Previous",
    nextPhoto: "Next",
  },
};

export function siteShareStrings(locale: string): SiteShareCopy {
  const key = (locale in TABLE ? locale : "mk") as ShareLocale;
  return {
    ...TABLE[key],
    statusExplainer: STATUS_EXPLAINERS[key],
  };
}

export function formatSiteStatus(status: string, locale: ShareLocale): string {
  const labels: Record<string, Record<ShareLocale, string>> = {
    VERIFIED: { mk: "Потврдено", en: "Verified", sq: "Verifikuar", sr: "Потврђено", rom: "Verified" },
    CLEANUP_SCHEDULED: {
      mk: "Закажано чистење",
      en: "Cleanup scheduled",
      sq: "Pastrim i planifikuar",
      sr: "Заказано чишћење",
      rom: "Cleanup scheduled",
    },
    IN_PROGRESS: { mk: "Во тек", en: "In progress", sq: "Në progres", sr: "У току", rom: "In progress" },
    CLEANED: { mk: "Исчистено", en: "Cleaned", sq: "Pastrur", sr: "Очишћено", rom: "Cleaned" },
    DISPUTED: { mk: "Оспорено", en: "Disputed", sq: "I kontestuar", sr: "Оспорено", rom: "Disputed" },
  };
  const row = labels[status];
  if (row && locale in row) {
    return row[locale];
  }
  return status.replace(/_/g, " ").toLowerCase();
}

export function formatReportCategory(category: string | null | undefined, locale: ShareLocale): string {
  if (!category) return "";
  const labels: Record<string, Record<ShareLocale, string>> = {
    ILLEGAL_LANDFILL: {
      mk: "Дива депонија",
      en: "Illegal landfill",
      sq: "Deponi ilegale",
      sr: "Дивља депонија",
      rom: "Illegal landfill",
    },
    WATER_POLLUTION: {
      mk: "Загадување на вода",
      en: "Water pollution",
      sq: "Ndotje e ujit",
      sr: "Загађење воде",
      rom: "Water pollution",
    },
    AIR_POLLUTION: {
      mk: "Загадување на воздух",
      en: "Air pollution",
      sq: "Ndotje e ajrit",
      sr: "Загађење ваздуха",
      rom: "Air pollution",
    },
    INDUSTRIAL_WASTE: {
      mk: "Индустриски отпад",
      en: "Industrial waste",
      sq: "Mbetje industriale",
      sr: "Индустријски отпад",
      rom: "Industrial waste",
    },
    OTHER: { mk: "Друго", en: "Other", sq: "Tjetër", sr: "Друго", rom: "Other" },
  };
  return labels[category]?.[locale] ?? category.replace(/_/g, " ").toLowerCase();
}

export function formatSeverity(severity: number | null | undefined, locale: ShareLocale): string {
  if (severity == null || !Number.isFinite(severity)) return "";
  const n = Math.round(severity);
  const tiers: Record<number, Record<ShareLocale, string>> = {
    1: { mk: "Ниско", en: "Low", sq: "E ulët", sr: "Ниско", rom: "Low" },
    2: { mk: "Умерено", en: "Moderate", sq: "Mesatare", sr: "Умерено", rom: "Moderate" },
    3: { mk: "Значајно", en: "Significant", sq: "E rëndësishme", sr: "Значајно", rom: "Significant" },
    4: { mk: "Високо", en: "High", sq: "E lartë", sr: "Високо", rom: "High" },
    5: { mk: "Критично", en: "Critical", sq: "Kritike", sr: "Критично", rom: "Critical" },
  };
  const tier = tiers[n]?.[locale];
  return tier ? `${n}, ${tier}` : String(n);
}

export function formatCleanupEffort(effort: string | null | undefined, locale: ShareLocale): string {
  if (!effort) return "";
  const labels: Record<string, Record<ShareLocale, string>> = {
    ONE_TO_TWO: { mk: "1–2 лица", en: "1-2 people", sq: "1-2 persona", sr: "1–2 особе", rom: "1-2 people" },
    THREE_TO_FIVE: { mk: "3–5 лица", en: "3-5 people", sq: "3-5 persona", sr: "3–5 особа", rom: "3-5 people" },
    SIX_TO_TEN: { mk: "6–10 лица", en: "6-10 people", sq: "6-10 persona", sr: "6–10 особа", rom: "6-10 people" },
    TEN_PLUS: { mk: "10+ лица", en: "10+ people", sq: "10+ persona", sr: "10+ особа", rom: "10+ people" },
    NOT_SURE: { mk: "Непознато", en: "Not sure", sq: "E panjohur", sr: "Непознато", rom: "Not sure" },
  };
  return labels[effort]?.[locale] ?? effort.replace(/_/g, " ").toLowerCase();
}

export function mapsUrl(lat: number, lng: number): string {
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`${lat},${lng}`)}`;
}

export function formatShareDate(iso: string | null | undefined, locale: ShareLocale): string {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const tag = locale === "mk" || locale === "sr" ? "mk-MK" : locale === "sq" ? "sq-MK" : "en-GB";
  return new Intl.DateTimeFormat(tag, { dateStyle: "medium" }).format(d);
}

export function formatEventSchedule(iso: string, locale: ShareLocale): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const tag = locale === "mk" || locale === "sr" ? "mk-MK" : locale === "sq" ? "sq-MK" : "en-GB";
  return new Intl.DateTimeFormat(tag, { dateStyle: "medium", timeStyle: "short" }).format(d);
}
