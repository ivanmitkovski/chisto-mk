import { ApiError } from '@/lib/api';

type ErrorTranslate = (
  key:
    | 'insufficientPermissions'
    | 'validationFailed'
    | 'eventEndSameDay'
    | 'eventEndBeforeMidnight',
) => string;

/** User-safe snack copy for cleanup-event mutations (no stack traces). */
export function cleanupEventMutationMessage(
  error: unknown,
  fallback: string,
  t?: ErrorTranslate,
): string {
  if (error instanceof ApiError && error.status === 403) {
    return t?.('insufficientPermissions') ?? 'Insufficient permissions for this action.';
  }
  if (error instanceof ApiError && error.status === 422) {
    return t?.('validationFailed') ?? 'Validation failed. Adjust the fields and try again.';
  }
  if (error instanceof ApiError && error.code === 'EVENTS_END_DIFFERENT_SKOPJE_CALENDAR_DAY') {
    return error.message || (t?.('eventEndSameDay') ?? 'Event end must be on the same calendar day as the start.');
  }
  if (error instanceof ApiError && error.code === 'EVENTS_END_AFTER_SKOPJE_LOCAL_DAY') {
    return error.message || (t?.('eventEndBeforeMidnight') ?? 'Event end must not be after 23:59 on the start day.');
  }
  if (error instanceof ApiError) {
    return error.message || fallback;
  }
  return fallback;
}
