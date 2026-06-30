/** Postgres NOTIFY channel when rows are inserted into `NotificationOutbox`. */
export const NOTIFICATION_OUTBOX_ENQUEUED_CHANNEL = 'notification_outbox_enqueued';

/** Postgres NOTIFY channel when rows are inserted into `MapEventOutbox`. */
export const MAP_EVENT_OUTBOX_ENQUEUED_CHANNEL = 'map_event_outbox_enqueued';

/** Static SQL for `pg_notify` (channel names are fixed identifiers). */
export const NOTIFY_SQL = {
  notificationOutboxEnqueued: `SELECT pg_notify('${NOTIFICATION_OUTBOX_ENQUEUED_CHANNEL}', '')`,
  mapEventOutboxEnqueued: `SELECT pg_notify('${MAP_EVENT_OUTBOX_ENQUEUED_CHANNEL}', '')`,
} as const;

export function isPgOutboxListenEnabled(): boolean {
  const v = process.env.PG_OUTBOX_LISTEN?.trim().toLowerCase();
  if (v === 'true' || v === '1' || v === 'on') return true;
  if (v === '0' || v === 'false' || v === 'off') return false;
  if (process.env.NODE_ENV === 'test') return false;
  return true;
}

export function isPgOutboxNotifyEnabled(): boolean {
  const v = process.env.PG_OUTBOX_NOTIFY?.trim().toLowerCase();
  if (v === 'true' || v === '1' || v === 'on') return true;
  if (v === '0' || v === 'false' || v === 'off') return false;
  if (process.env.NODE_ENV === 'test') return false;
  return true;
}
