import type { AppLocale } from '../../common/i18n/app-locale';
import { normalizeAppLocale } from '../../common/i18n/app-locale';

/** @deprecated Use {@link AppLocale} from `common/i18n/app-locale`. */
export type NotificationLocale = AppLocale;

export function resolveNotificationLocale(raw: string | null | undefined): AppLocale {
  return normalizeAppLocale(raw);
}

function truncate(text: string, max: number): string {
  return text.length > max ? `${text.slice(0, max - 3)}…` : text;
}

type CopyResult = { title: string; body: string };

export function siteUpvoteCopy(locale: AppLocale): CopyResult {
  switch (locale) {
    case 'en':
      return { title: 'New upvote', body: 'Someone upvoted a site you reported.' };
    case 'sq':
      return { title: 'Votë e re', body: 'Dikush votoi një vend që raportuat.' };
    default:
      return { title: 'Ново гласање', body: 'Некој го поддржа локалитетот што го пријавивте.' };
  }
}

export function siteCommentCopy(locale: AppLocale, commentPreview?: string): CopyResult {
  const preview = commentPreview ? truncate(commentPreview, 100) : '';
  switch (locale) {
    case 'en':
      return {
        title: 'New comment',
        body: preview
          ? `New comment on your site: "${preview}"`
          : 'New comment on a site you reported.',
      };
    case 'sq':
      return {
        title: 'Koment i ri',
        body: preview
          ? `Koment i ri në vendin tuaj: „${preview}"`
          : 'Koment i ri në një vend që raportuat.',
      };
    default:
      return {
        title: 'Нов коментар',
        body: preview
          ? `Нов коментар на вашиот локалитет: „${preview}"`
          : 'Нов коментар на локалитет што го пријавивте.',
      };
  }
}

export function reportStatusCopy(locale: AppLocale, statusLabel: string): CopyResult {
  const localized = translateReportStatus(statusLabel, locale);
  switch (locale) {
    case 'en':
      return { title: 'Report status updated', body: `Your report has been ${localized}.` };
    case 'sq':
      return { title: 'Statusi u përditësua', body: `Raporti juaj është ${localized}.` };
    default:
      return { title: 'Статусот е ажуриран', body: `Вашата пријава е ${localized}.` };
  }
}

export function reportMergePrimaryCopy(locale: AppLocale, reportNumber: string): CopyResult {
  switch (locale) {
    case 'en':
      return {
        title: 'Duplicate reports merged',
        body: `Similar submissions were merged into your report ${reportNumber}.`,
      };
    case 'sq':
      return {
        title: 'Raportet e dyfishta u bashkuan',
        body: `Dorëzime të ngjashme u bashkuan në raportin tuaj ${reportNumber}.`,
      };
    default:
      return {
        title: 'Спојување на дупликат пријави',
        body: `Слични пријави се спојуваат во вашата пријава ${reportNumber}.`,
      };
  }
}

export function reportMergeChildCopy(locale: AppLocale, reportNumber: string): CopyResult {
  switch (locale) {
    case 'en':
      return {
        title: 'Your report was merged',
        body: `Your submission was merged into ${reportNumber}.`,
      };
    case 'sq':
      return {
        title: 'Raporti juaj u bashkua',
        body: `Dorëzimi juaj u bashkua me ${reportNumber}.`,
      };
    default:
      return {
        title: 'Вашата пријава е споена',
        body: `Вашата пријава е споена со ${reportNumber}.`,
      };
  }
}

export function reportCoReporterCreditCopy(locale: AppLocale, reportNumber: string): CopyResult {
  switch (locale) {
    case 'en':
      return {
        title: 'Co-reporter credit',
        body: `You are credited as a co-reporter on ${reportNumber}.`,
      };
    case 'sq':
      return {
        title: 'Kredit si bashkë-raportues',
        body: `Jeni kredituar si bashkë-raportues në ${reportNumber}.`,
      };
    default:
      return {
        title: 'Ко-пријавувач',
        body: `Вие сте кредитирани како ко-пријавувач на ${reportNumber}.`,
      };
  }
}

export function reportReceivedUserCopy(locale: AppLocale, reportNumber: string): CopyResult {
  switch (locale) {
    case 'en':
      return {
        title: reportNumber ? `We received ${reportNumber}` : 'We received your report',
        body: reportNumber
          ? `Thank you. We received your report ${reportNumber}. Our team will review it soon.`
          : 'Thank you. We received your report. Our team will review it soon.',
      };
    case 'sq':
      return {
        title: reportNumber ? `E morëm ${reportNumber}` : 'E morëm raportin tuaj',
        body: reportNumber
          ? `Faleminderit. E morëm raportin tuaj ${reportNumber}. Ekipi ynë do ta shqyrtojë së shpejti.`
          : 'Faleminderit. E morëm raportin tuaj. Ekipi ynë do ta shqyrtojë së shpejti.',
      };
    default:
      return {
        title: reportNumber ? `Ја примивме ${reportNumber}` : 'Ја примивме вашата пријава',
        body: reportNumber
          ? `Ви благодариме. Ја примивме вашата пријава ${reportNumber}. Нашиот тим наскоро ќе ја разгледа.`
          : 'Ви благодариме. Ја примивме вашата пријава. Нашиот тим наскоро ќе ја разгледа.',
      };
  }
}

function translateReportStatus(status: string, locale: AppLocale): string {
  const normalized = status.trim().toLowerCase().replace(/_/g, ' ');
  const table: Record<string, { en: string; mk: string; sq: string }> = {
    approved: { en: 'approved', mk: 'одобрена', sq: 'aprobar' },
    rejected: { en: 'rejected', mk: 'одбиена', sq: 'refuzuar' },
    declined: { en: 'declined', mk: 'одбиена', sq: 'refuzuar' },
    pending: { en: 'pending', mk: 'во тек', sq: 'në pritje' },
    'under review': { en: 'under review', mk: 'во ревизија', sq: 'në shqyrtim' },
    'in review': { en: 'in review', mk: 'во ревизија', sq: 'në shqyrtim' },
  };
  const row = table[normalized];
  if (row) {
    return row[locale];
  }
  return status;
}

export function welcomePushCopy(locale: AppLocale): CopyResult {
  switch (locale) {
    case 'en':
      return {
        title: 'Welcome to Chisto.mk',
        body: 'Thanks for joining. Explore the map, report pollution, and join cleanups near you.',
      };
    case 'sq':
      return {
        title: 'Mirë se vini në Chisto.mk',
        body: 'Faleminderit që u bashkuat. Eksploroni hartën, raportoni ndotjen dhe merrni pjesë në pastrime afër jush.',
      };
    default:
      return {
        title: 'Добредојде на Chisto.mk',
        body: 'Ви благодариме што се приклучивте. Истражете ја мапата, пријавете загадување и приклучете се на чистења.',
      };
  }
}

export function achievementLevelUpCopy(locale: AppLocale, levelDisplayName: string): CopyResult {
  switch (locale) {
    case 'en':
      return {
        title: 'Level up!',
        body: `You reached ${levelDisplayName}. Open your profile to see your points and progress.`,
      };
    case 'sq':
      return {
        title: 'Nivel i ri!',
        body: `Arritët ${levelDisplayName}. Hapni profilin për pikët dhe progresin tuaj.`,
      };
    default:
      return {
        title: 'Ново ниво!',
        body: `Го достигнавте ${levelDisplayName}. Отворете го профилот за поени и напредок.`,
      };
  }
}

export function nearbyReportCopy(locale: AppLocale): CopyResult {
  switch (locale) {
    case 'en':
      return {
        title: 'New report nearby',
        body: 'A pollution report was approved near your home location.',
      };
    case 'sq':
      return {
        title: 'Raport i ri afër',
        body: 'Një raport ndotjeje u miratua afër vendndodhjes suaj të shtëpisë.',
      };
    default:
      return {
        title: 'Нова пријава во близина',
        body: 'Одобрена е пријава за загадување близу вашата домашна локација.',
      };
  }
}

export function siteStatusUpdateCopy(locale: AppLocale, statusLabel: string): CopyResult {
  switch (locale) {
    case 'en':
      return { title: 'Site update', body: `A site you reported is now ${statusLabel}.` };
    case 'sq':
      return { title: 'Përditësim i vendit', body: `Një vend që raportuat tani është ${statusLabel}.` };
    default:
      return { title: 'Ажурирање на локалитет', body: `Локалитет што го пријавивте сега е ${statusLabel}.` };
  }
}

export function adminTestPushCopy(locale: AppLocale): CopyResult {
  switch (locale) {
    case 'en':
      return {
        title: 'Chisto test push',
        body: 'If you see this, push delivery is working.',
      };
    case 'sq':
      return {
        title: 'Test push Chisto',
        body: 'Nëse e shihni këtë, dorëzimi i njoftimeve funksionon.',
      };
    default:
      return {
        title: 'Chisto тест push',
        body: 'Ако го гледате ова, испораката на push работи.',
      };
  }
}

export function formatSiteStatusLabel(
  status: string,
  locale: AppLocale,
): string {
  const key = status.trim().toUpperCase().replace(/\s+/g, '_');
  const labels: Record<string, { en: string; mk: string; sq: string }> = {
    REPORTED: { en: 'reported', mk: 'пријавен', sq: 'raportuar' },
    VERIFIED: { en: 'verified', mk: 'верифициран', sq: 'verifikuar' },
    CLEANUP_SCHEDULED: { en: 'cleanup scheduled', mk: 'закажано чистење', sq: 'pastrim i planifikuar' },
    IN_PROGRESS: { en: 'in progress', mk: 'во тек', sq: 'në progres' },
    CLEANED: { en: 'cleaned', mk: 'очистен', sq: 'pastrur' },
    DISPUTED: { en: 'disputed', mk: 'оспорен', sq: 'kontestuar' },
  };
  const row = labels[key];
  if (row) {
    return row[locale];
  }
  return status;
}
