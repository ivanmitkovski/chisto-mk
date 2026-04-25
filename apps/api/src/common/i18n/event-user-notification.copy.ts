/**
 * Centralized user-visible copy for cleanup event push notifications.
 * Keys mirror product intent; callers choose locale (default `mk`).
 */
export type EventNotificationLocale = 'mk' | 'en';

function normalizeLocale(raw: string | null | undefined): EventNotificationLocale {
  const s = raw?.trim().toLowerCase();
  return s === 'en' ? 'en' : 'mk';
}

export function resolveEventNotificationLocaleFromDeviceLocale(
  deviceLocale: string | null | undefined,
): EventNotificationLocale {
  return normalizeLocale(deviceLocale);
}

export function cleanupEndingSoonPush(
  locale: EventNotificationLocale,
  eventTitle: string,
): { title: string; body: string } {
  const safeTitle = eventTitle.length > 120 ? `${eventTitle.slice(0, 117)}…` : eventTitle;
  if (locale === 'en') {
    return {
      title: 'Cleanup ending soon',
      body: `“${safeTitle}” ends in about 10 minutes. If you need more time, extend the end time in the app.`,
    };
  }
  return {
    title: 'Наскоро крај на чистењето',
    body: `„${safeTitle}“ завршува за околу 10 минути. Ако ви треба повеќе време, продолжете го крајот во апликацијата.`,
  };
}

export function eventCompletedNoShowPush(
  locale: EventNotificationLocale,
  eventTitle: string,
): { title: string; body: string } {
  const safeTitle = eventTitle.length > 120 ? `${eventTitle.slice(0, 117)}…` : eventTitle;
  if (locale === 'en') {
    return {
      title: 'Event completed',
      body: `Your join bonus for “${safeTitle}” was removed because no check-in was recorded.`,
    };
  }
  return {
    title: 'Настанот заврши',
    body: `Вашиот бонус за пријавување за „${safeTitle}“ е отстранет бидејќи нема зачленување.`,
  };
}

export function eventCompletedAwardPush(
  locale: EventNotificationLocale,
  eventTitle: string,
  points: number,
): { title: string; body: string } {
  const safeTitle = eventTitle.length > 120 ? `${eventTitle.slice(0, 117)}…` : eventTitle;
  if (locale === 'en') {
    return {
      title: 'Event completed',
      body: `You earned ${points} points for taking part in “${safeTitle}”.`,
    };
  }
  return {
    title: 'Настанот заврши',
    body: `Освоивте ${points} поени за учество во „${safeTitle}“.`,
  };
}

export function cleanupStaffPendingReviewPush(
  locale: EventNotificationLocale,
  title: string,
): { title: string; body: string } {
  const t = title.length > 80 ? `${title.slice(0, 77)}…` : title;
  if (locale === 'en') {
    return {
      title: 'New cleanup event',
      body: `Moderation required: “${t}”.`,
    };
  }
  return {
    title: 'Нова акција за чистење',
    body: `Потребна е модерација: «${t}».`,
  };
}

export function cleanupOrganizerReturnedToPendingPush(
  locale: EventNotificationLocale,
): { title: string; body: string } {
  if (locale === 'en') {
    return {
      title: 'Event updated',
      body: 'The event is back in moderation while the team reviews your changes.',
    };
  }
  return {
    title: 'Промени на настанот',
    body: 'Настанот повторно е на модерација додека тимот ги провери измените.',
  };
}

export function cleanupAudienceEventPublishedPush(
  locale: EventNotificationLocale,
  title: string,
): { title: string; body: string } {
  const t = title.length > 100 ? `${title.slice(0, 97)}…` : title;
  if (locale === 'en') {
    return {
      title: 'New event',
      body: `${t} — a new cleanup is open at a site you follow.`,
    };
  }
  return {
    title: 'Нов настан',
    body: `${t} — отворен е нов чистење настан кај зачувана локација.`,
  };
}

export function cleanupOrganizerApprovedPush(
  locale: EventNotificationLocale,
  title: string,
): { title: string; body: string } {
  const t = title.length > 80 ? `${title.slice(0, 77)}…` : title;
  if (locale === 'en') {
    return {
      title: 'Event approved',
      body: `“${t}” is approved and visible to volunteers.`,
    };
  }
  return {
    title: 'Настанот е одобрен',
    body: `«${t}» е одобрен и видлив за доброволците.`,
  };
}

export function cleanupOrganizerDeclinedPush(
  locale: EventNotificationLocale,
  title: string,
): { title: string; body: string } {
  const t = title.length > 80 ? `${title.slice(0, 77)}…` : title;
  if (locale === 'en') {
    return {
      title: 'Event not approved',
      body: `“${t}” did not meet the criteria. Edit and submit again.`,
    };
  }
  return {
    title: 'Настанот не е одобрен',
    body: `«${t}» не ги исполни критериумите. Уредете и поднесете повторно.`,
  };
}
