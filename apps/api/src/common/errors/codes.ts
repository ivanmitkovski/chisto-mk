/**
 * Stable API error `code` strings for event check-in (HTTP 4xx/5xx bodies) and check-in WebSocket `error` payloads.
 * New endpoints should reuse these; add new codes here when introducing them.
 *
 * **Drift control** — literals `code: '…'` under `src/events` and `src/event-chat` must appear in the merged
 * registry exported from this file; see `test/common/api-error-codes.drift.spec.ts`.
 */
export const CHECK_IN_ERROR_CODES = [
  'CHECK_IN_MISCONFIG',
  'CHECK_IN_SESSION_CLOSED',
  'CHECK_IN_NO_SESSION',
  'CHECK_IN_LIFECYCLE',
  'CHECK_IN_QR_EXPIRED',
  'CHECK_IN_INVALID_QR',
  'CHECK_IN_WRONG_EVENT',
  'CHECK_IN_SESSION_MISMATCH',
  'CHECK_IN_REPLAY',
  'CHECK_IN_REQUIRES_JOIN',
  'CHECK_IN_ALREADY_RECORDED',
  'CHECK_IN_ALREADY_CHECKED_IN',
  'CHECK_IN_NOT_FOUND',
  'CHECK_IN_FORBIDDEN',
  'CHECK_IN_REQUEST_EXPIRED',
  'CHECK_IN_REQUEST_NOT_FOUND',
  'ORGANIZER_CANNOT_CHECK_IN',
  'EVENT_NOT_FOUND',
  'EVENT_NOT_JOINABLE',
  'EVENT_JOIN_NOT_YET_OPEN',
  'EVENT_NOT_APPROVED',
  'NOT_EVENT_ORGANIZER',
] as const;

export type CheckInErrorCode = (typeof CHECK_IN_ERROR_CODES)[number];

/**
 * Stable API error `code` strings for event chat (HTTP 4xx bodies) and chat WebSocket `error` payloads where applicable.
 */
export const EVENT_CHAT_ERROR_CODES = [
  'EVENT_CHAT_FORBIDDEN',
  'EVENT_CHAT_NOT_PARTICIPANT',
  'INVALID_CHAT_CURSOR',
  'EVENT_CHAT_BODY_INVALID',
  'EVENT_CHAT_REPLY_NOT_FOUND',
  'EVENT_CHAT_CLIENT_ID_CONFLICT',
  'EVENT_CHAT_MESSAGE_NOT_FOUND',
  'EVENT_CHAT_EDIT_DELETED',
  'EVENT_CHAT_EDIT_FORBIDDEN',
  'EVENT_CHAT_PIN_FORBIDDEN',
  'EVENT_CHAT_PIN_DELETED',
  'EVENT_CHAT_PIN_TYPE',
  'EVENT_CHAT_PIN_LIMIT',
  'EVENT_CHAT_DELETE_FORBIDDEN',
  'EVENT_CHAT_READ_MESSAGE_NOT_FOUND',
  'CHAT_UPLOAD_TOO_MANY',
  'CHAT_UPLOAD_MIME',
  'CHAT_UPLOAD_SIZE',
  'S3_NOT_CONFIGURED',
  'EVENT_NOT_FOUND',
  'AUTH_FAILED',
] as const;

export type EventChatErrorCode = (typeof EVENT_CHAT_ERROR_CODES)[number];

/**
 * Stable API error `code` strings for public event mutations (PATCH /events/:id, etc.).
 */
export const PUBLIC_EVENT_MUTATION_ERROR_CODES = [
  'EVENT_NOT_EDITABLE',
  'DUPLICATE_EVENT',
  'EVENT_NOT_FOUND',
  'NOT_EVENT_ORGANIZER',
  'INVALID_EVENT_CATEGORY',
  'INVALID_SCHEDULED_AT',
  'INVALID_END_AT',
  'EVENTS_END_DIFFERENT_SKOPJE_CALENDAR_DAY',
  'EVENTS_END_AFTER_SKOPJE_LOCAL_DAY',
  'EVENT_END_AT_TOO_FAR',
  'INVALID_SCALE',
  'INVALID_DIFFICULTY',
] as const;

export type PublicEventMutationErrorCode = (typeof PUBLIC_EVENT_MUTATION_ERROR_CODES)[number];

/**
 * Cross-cutting HTTP / validation responses (global filter, `ValidationPipe`, throttler).
 */
export const GLOBAL_HTTP_ERROR_CODES = [
  'TOO_MANY_REQUESTS',
  'INTERNAL_ERROR',
  'BAD_REQUEST',
  'UNAUTHORIZED',
  'FORBIDDEN',
  'NOT_FOUND',
  'CONFLICT',
  'HTTP_ERROR',
  'DATABASE_TIMEOUT',
  'DATABASE_UNAVAILABLE',
  'DATABASE_DISCONNECTED',
  'VALIDATION_ERROR',
] as const;

export type GlobalHttpErrorCode = (typeof GLOBAL_HTTP_ERROR_CODES)[number];

/**
 * Stable codes returned from `EventsService` / `events-cursors.util` (public events HTTP) not covered elsewhere.
 */
export const EVENTS_PUBLIC_API_ERROR_CODES = [
  'INVALID_EVENT_STATUS_FILTER',
  'SITE_NOT_FOUND',
  'INVALID_RECURRENCE_RULE',
  'INVALID_LIFECYCLE_STATUS',
  'INVALID_LIFECYCLE_TRANSITION',
  'EVENT_START_TOO_EARLY',
  'EVENT_JOIN_WINDOW_CLOSED',
  'ORGANIZER_CANNOT_JOIN',
  'EVENT_FULL',
  'ALREADY_JOINED',
  'NOT_A_PARTICIPANT',
  'REMINDER_REQUIRES_JOIN',
  'INVALID_REMINDER_AT',
  'INVALID_EVENTS_CURSOR',
  'EVENTS_VIEWER_GEO_INCOMPLETE',
  'INVALID_PARTICIPANTS_CURSOR',
  'EVENTS_ORGANIZER_NOT_CERTIFIED',
  'ORGANIZER_QUIZ_FAILED',
  'ORGANIZER_QUIZ_INVALID',
  'ORGANIZER_QUIZ_SESSION_INVALID',
  'ORGANIZER_QUIZ_SESSION_EXPIRED',
  'ORGANIZER_QUIZ_ANSWERS_MISMATCH',
  'ORGANIZER_CERTIFICATION_ALREADY_CERTIFIED',
  'INVALID_EVIDENCE_KIND',
  'EVIDENCE_LIMIT_REACHED',
  'EVIDENCE_IMAGE_REQUIRED',
  'FIELD_BATCH_EMPTY',
  'ROUTE_SEGMENT_NOT_CLAIMABLE',
  'ROUTE_SEGMENT_CLAIMED',
  'ROUTE_SEGMENT_NOT_COMPLETABLE',
  'ROUTE_SEGMENT_FORBIDDEN',
  'EVENTS_IMPACT_RECEIPT_NOT_AVAILABLE',
] as const;

export type EventsPublicApiErrorCode = (typeof EVENTS_PUBLIC_API_ERROR_CODES)[number];

/**
 * Admin cleanup event bulk moderation and related mutations.
 */
export const ADMIN_CLEANUP_EVENT_ERROR_CODES = [
  'DUPLICATE_BULK_MODERATION_JOB',
  'BULK_MODERATION_EMPTY',
  'BULK_MODERATION_TOO_MANY_IDS',
  'CLEANUP_PATCH_NO_CHANGES',
] as const;

export type AdminCleanupEventErrorCode = (typeof ADMIN_CLEANUP_EVENT_ERROR_CODES)[number];

const MERGED_ERROR_CODE_SET = new Set<string>([
  ...CHECK_IN_ERROR_CODES,
  ...EVENT_CHAT_ERROR_CODES,
  ...PUBLIC_EVENT_MUTATION_ERROR_CODES,
  ...GLOBAL_HTTP_ERROR_CODES,
  ...EVENTS_PUBLIC_API_ERROR_CODES,
  ...ADMIN_CLEANUP_EVENT_ERROR_CODES,
]);

/**
 * Union of registered stable `code` strings used by drift tests and API contracts.
 */
export const ALL_STABLE_API_ERROR_CODES: readonly string[] = Array.from(MERGED_ERROR_CODE_SET).sort();

export function isRegisteredApiErrorCode(code: string): boolean {
  return MERGED_ERROR_CODE_SET.has(code);
}
