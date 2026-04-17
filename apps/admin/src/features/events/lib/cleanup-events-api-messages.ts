import { ApiError } from '@/lib/api';

/** User-safe snack copy for cleanup-event mutations (no stack traces). */
export function cleanupEventMutationMessage(error: unknown, fallback: string): string {
  if (error instanceof ApiError && error.status === 403) {
    return 'Insufficient permissions for this action.';
  }
  if (error instanceof ApiError && error.status === 422) {
    return 'Validation failed. Adjust the fields and try again.';
  }
  if (error instanceof ApiError) {
    return error.message || fallback;
  }
  return fallback;
}
