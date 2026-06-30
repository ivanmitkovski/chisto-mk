/**
 * Centralized user-visible copy for cleanup event push notifications.
 */
import type { AppLocale } from './app-locale';
import { normalizeAppLocale } from './app-locale';

/** @deprecated Use {@link AppLocale}. */
export type EventNotificationLocale = AppLocale;

export function resolveEventNotificationLocaleFromDeviceLocale(
  deviceLocale: string | null | undefined,
): AppLocale {
  return normalizeAppLocale(deviceLocale);
}

export function cleanupEndingSoonPush(
  locale: AppLocale,
  eventTitle: string,
): { title: string; body: string } {
  const safeTitle = eventTitle.length > 120 ? `${eventTitle.slice(0, 117)}…` : eventTitle;
  switch (locale) {
    case 'en':
      return {
        title: 'Cleanup ending soon',
        body: `“${safeTitle}” ends in about 10 minutes. If you need more time, extend the end time in the app.`,
      };
    case 'sq':
      return {
        title: 'Pastrimi përfundon së shpejti',
        body: `„${safeTitle}“ përfundon për rreth 10 minuta. Nëse ju duhet më shumë kohë, zgjatni kohën e përfundimit në aplikacion.`,
      };
    default:
      return {
        title: 'Наскоро крај на чистењето',
        body: `„${safeTitle}“ завршува за околу 10 минути. Ако ви треба повеќе време, продолжете го крајот во апликацијата.`,
      };
  }
}

export function eventCompletedNoShowPush(
  locale: AppLocale,
  eventTitle: string,
): { title: string; body: string } {
  const safeTitle = eventTitle.length > 120 ? `${eventTitle.slice(0, 117)}…` : eventTitle;
  switch (locale) {
    case 'en':
      return {
        title: 'Event completed',
        body: `Your join bonus for “${safeTitle}” was removed because no check-in was recorded.`,
      };
    case 'sq':
      return {
        title: 'Ngjarja përfundoi',
        body: `Bonusi juaj i pjesëmarrjes për „${safeTitle}“ u hoq sepse nuk u regjistrua asnjë check-in.`,
      };
    default:
      return {
        title: 'Настанот заврши',
        body: `Вашиот бонус за пријавување за „${safeTitle}“ е отстранет бидејќи нема зачленување.`,
      };
  }
}

export function eventCompletedAwardPush(
  locale: AppLocale,
  eventTitle: string,
  points: number,
): { title: string; body: string } {
  const safeTitle = eventTitle.length > 120 ? `${eventTitle.slice(0, 117)}…` : eventTitle;
  switch (locale) {
    case 'en':
      return {
        title: 'Event completed',
        body: `You earned ${points} points for taking part in “${safeTitle}”.`,
      };
    case 'sq':
      return {
        title: 'Ngjarja përfundoi',
        body: `Fitove ${points} pikë për pjesëmarrjen në „${safeTitle}“.`,
      };
    default:
      return {
        title: 'Настанот заврши',
        body: `Освоивте ${points} поени за учество во „${safeTitle}“.`,
      };
  }
}

export function cleanupStaffPendingReviewPush(
  locale: AppLocale,
  title: string,
): { title: string; body: string } {
  const t = title.length > 80 ? `${title.slice(0, 77)}…` : title;
  switch (locale) {
    case 'en':
      return { title: 'New cleanup event', body: `Moderation required: “${t}”.` };
    case 'sq':
      return { title: 'Ngjarje e re pastrimi', body: `Kërkohet moderim: „${t}“.` };
    default:
      return { title: 'Нова акција за чистење', body: `Потребна е модерација: «${t}».` };
  }
}

export function cleanupOrganizerReturnedToPendingPush(
  locale: AppLocale,
): { title: string; body: string } {
  switch (locale) {
    case 'en':
      return {
        title: 'Event updated',
        body: 'The event is back in moderation while the team reviews your changes.',
      };
    case 'sq':
      return {
        title: 'Ngjarja u përditësua',
        body: 'Ngjarja është përsëri në moderim ndërsa ekipi shqyrton ndryshimet tuaja.',
      };
    default:
      return {
        title: 'Промени на настанот',
        body: 'Настанот повторно е на модерација додека тимот ги провери измените.',
      };
  }
}

export function cleanupAudienceEventPublishedPush(
  locale: AppLocale,
  title: string,
): { title: string; body: string } {
  const t = title.length > 100 ? `${title.slice(0, 97)}…` : title;
  switch (locale) {
    case 'en':
      return { title: 'New event', body: `${t}: a new cleanup is open at a site you follow.` };
    case 'sq':
      return { title: 'Ngjarje e re', body: `${t}: një pastrim i ri është hapur në një vend që ndiqni.` };
    default:
      return { title: 'Нов настан', body: `${t}: отворен е нов чистење настан кај зачувана локација.` };
  }
}

export function cleanupOrganizerApprovedPush(
  locale: AppLocale,
  title: string,
): { title: string; body: string } {
  const t = title.length > 80 ? `${title.slice(0, 77)}…` : title;
  switch (locale) {
    case 'en':
      return { title: 'Event approved', body: `“${t}” is approved and visible to volunteers.` };
    case 'sq':
      return { title: 'Ngjarja u miratua', body: `„${t}“ është miratuar dhe e dukshme për vullnetarët.` };
    default:
      return { title: 'Настанот е одобрен', body: `«${t}» е одобрен и видлив за доброволците.` };
  }
}

export function cleanupOrganizerDeclinedPush(
  locale: AppLocale,
  title: string,
  declineReason?: string,
): { title: string; body: string } {
  const t = title.length > 80 ? `${title.slice(0, 77)}…` : title;
  const reason =
    declineReason != null && declineReason.trim().length > 0
      ? declineReason.trim().length > 160
        ? `${declineReason.trim().slice(0, 157)}…`
        : declineReason.trim()
      : null;
  switch (locale) {
    case 'en':
      return {
        title: 'Event not approved',
        body: reason
          ? `“${t}” was not approved. Reason: ${reason}`
          : `“${t}” did not meet the criteria. Edit and submit again.`,
      };
    case 'sq':
      return {
        title: 'Ngjarja nuk u miratua',
        body: reason
          ? `„${t}“ nuk u miratua. Arsyeja: ${reason}`
          : `„${t}“ nuk i plotësoi kriteret. Redaktoni dhe dorëzoni përsëri.`,
      };
    default:
      return {
        title: 'Настанот не е одобрен',
        body: reason
          ? `«${t}» не е одобрен. Причина: ${reason}`
          : `«${t}» не ги исполни критериумите. Уредете и поднесете повторно.`,
      };
  }
}
