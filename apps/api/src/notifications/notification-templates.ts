export type NotificationLocale = 'mk' | 'en';

export function resolveNotificationLocale(raw: string | null | undefined): NotificationLocale {
  const s = raw?.trim().toLowerCase();
  return s === 'en' ? 'en' : 'mk';
}

function truncate(text: string, max: number): string {
  return text.length > max ? `${text.slice(0, max - 3)}…` : text;
}

type CopyResult = { title: string; body: string };

export function siteUpvoteCopy(locale: NotificationLocale): CopyResult {
  if (locale === 'en') return { title: 'New upvote', body: 'Someone upvoted a site you reported.' };
  return { title: 'Ново гласање', body: 'Некој го поддржа локалитетот што го пријавивте.' };
}

export function siteCommentCopy(locale: NotificationLocale, commentPreview?: string): CopyResult {
  const preview = commentPreview ? truncate(commentPreview, 100) : '';
  if (locale === 'en') {
    return {
      title: 'New comment',
      body: preview ? `New comment on your site: "${preview}"` : 'New comment on a site you reported.',
    };
  }
  return {
    title: 'Нов коментар',
    body: preview ? `Нов коментар на вашиот локалитет: „${preview}"` : 'Нов коментар на локалитет што го пријавивте.',
  };
}

export function siteUpdateCopy(locale: NotificationLocale, body?: string): CopyResult {
  if (locale === 'en') return { title: 'Site update', body: body ?? 'A site you follow has been updated.' };
  return { title: 'Ажурирање', body: body ?? 'Локалитет што го следите е ажуриран.' };
}

export function reportStatusCopy(locale: NotificationLocale, statusLabel: string): CopyResult {
  if (locale === 'en') return { title: 'Report status updated', body: `Your report has been ${statusLabel}.` };
  const mkStatus = translateReportStatus(statusLabel);
  return { title: 'Статусот е ажуриран', body: `Вашата пријава е ${mkStatus}.` };
}

export function reportMergePrimaryCopy(locale: NotificationLocale, reportNumber: string): CopyResult {
  if (locale === 'en') {
    return { title: 'Duplicate reports merged', body: `Similar submissions were merged into your report ${reportNumber}.` };
  }
  return { title: 'Спојување на дупликат пријави', body: `Слични пријави се спојуваат во вашата пријава ${reportNumber}.` };
}

export function reportMergeChildCopy(locale: NotificationLocale, reportNumber: string): CopyResult {
  if (locale === 'en') {
    return { title: 'Your report was merged', body: `Your submission was merged into ${reportNumber}.` };
  }
  return { title: 'Вашата пријава е споена', body: `Вашата пријава е споена со ${reportNumber}.` };
}

export function reportCoReporterCreditCopy(locale: NotificationLocale, reportNumber: string): CopyResult {
  if (locale === 'en') {
    return { title: 'Co-reporter credit', body: `You are credited as a co-reporter on ${reportNumber}.` };
  }
  return { title: 'Ко-пријавувач', body: `Вие сте кредитирани како ко-пријавувач на ${reportNumber}.` };
}

function translateReportStatus(status: string): string {
  switch (status) {
    case 'approved': return 'одобрена';
    case 'rejected': return 'одбиена';
    case 'pending': return 'во тек';
    case 'under review': return 'во ревизија';
    default: return status;
  }
}
