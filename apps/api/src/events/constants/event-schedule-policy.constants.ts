/** Max wall-clock span from scheduled start to planned end (public PATCH /events/:id). */
export const PUBLIC_EVENT_MAX_END_AFTER_START_MS = 16 * 60 * 60 * 1000;

/** Organizer "cleanup ending soon" FCM: send when endAt is in [now+start, now+end] (cron tolerance). */
export const END_SOON_WINDOW_START_MS = 8 * 60 * 1000;
export const END_SOON_WINDOW_END_MS = 12 * 60 * 1000;
