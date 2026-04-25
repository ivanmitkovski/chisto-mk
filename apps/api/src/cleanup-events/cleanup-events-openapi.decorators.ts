import { applyDecorators } from '@nestjs/common';
import { ApiResponse } from '@nestjs/swagger';

const errExample = (code: string, message: string) => ({
  schema: {
    example: {
      code,
      message,
      timestamp: '2026-04-16T12:00:00.000Z',
      requestId: '01JF…',
    },
  },
});

/** Shared 4xx/429 for admin cleanup-events HTTP (see `ADMIN_CLEANUP_EVENT_ERROR_CODES` + globals). */
export function ApiAdminCleanupEventsStandardErrors(): ReturnType<typeof applyDecorators> {
  return applyDecorators(
    ApiResponse({
      status: 400,
      description: 'Validation or business rule failure',
      ...errExample('BULK_MODERATION_EMPTY', 'eventIds must not be empty'),
    }),
    ApiResponse({
      status: 401,
      description: 'Missing or invalid bearer token',
      ...errExample('UNAUTHORIZED', 'Unauthorized'),
    }),
    ApiResponse({
      status: 403,
      description: 'Insufficient role for this admin action',
      ...errExample('FORBIDDEN', 'Forbidden'),
    }),
    ApiResponse({
      status: 404,
      description: 'Cleanup event not found',
      ...errExample('CLEANUP_EVENT_NOT_FOUND', 'Cleanup event not found'),
    }),
    ApiResponse({
      status: 409,
      description: 'State conflict (e.g. duplicate bulk job id)',
      ...errExample('DUPLICATE_BULK_MODERATION_JOB', 'This moderation job was already submitted.'),
    }),
    ApiResponse({
      status: 429,
      description: 'Too many requests (throttled)',
      ...errExample('TOO_MANY_REQUESTS', 'Too many requests. Please wait and try again.'),
    }),
  );
}
