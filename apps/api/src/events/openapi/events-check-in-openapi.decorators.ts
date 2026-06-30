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

/** Shared 4xx/429 for `/events/:eventId/check-in` REST (see `CHECK_IN_ERROR_CODES` + globals). */
export function ApiEventsCheckInStandardErrors(): ReturnType<typeof applyDecorators> {
  return applyDecorators(
    ApiResponse({
      status: 400,
      description: 'Validation or check-in rule failure',
      ...errExample('CHECK_IN_INVALID_QR', 'Invalid QR payload'),
    }),
    ApiResponse({
      status: 401,
      description: 'Missing or invalid bearer token',
      ...errExample('UNAUTHORIZED', 'Unauthorized'),
    }),
    ApiResponse({
      status: 403,
      description: 'Caller may not perform this check-in action',
      ...errExample('CHECK_IN_FORBIDDEN', 'Check-in action denied'),
    }),
    ApiResponse({
      status: 404,
      description: 'Event or check-in resource not found',
      ...errExample('EVENT_NOT_FOUND', 'Event not found'),
    }),
    ApiResponse({
      status: 429,
      description: 'Too many requests (throttled)',
      ...errExample('TOO_MANY_REQUESTS', 'Too many requests. Please wait and try again.'),
    }),
  );
}
