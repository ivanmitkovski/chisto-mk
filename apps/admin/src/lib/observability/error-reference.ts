import { ApiError } from '@/lib/api/api';

export function getErrorReference(error: unknown): string | undefined {
  if (error instanceof ApiError && error.requestId) {
    return error.requestId;
  }
  if (error && typeof error === 'object' && 'requestId' in error) {
    const requestId = (error as { requestId?: unknown }).requestId;
    if (typeof requestId === 'string' && requestId.length > 0) {
      return requestId;
    }
  }
  return undefined;
}
