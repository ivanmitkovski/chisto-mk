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

/**
 * Shared 4xx/429 shapes for authenticated `/events` REST.
 * Stable `code` values live in `EVENTS_PUBLIC_API_ERROR_CODES`, `PUBLIC_EVENT_MUTATION_ERROR_CODES`, and `GLOBAL_HTTP_ERROR_CODES`.
 */
export function ApiEventsJwtStandardErrors(options?: { include409?: boolean }): ReturnType<typeof applyDecorators> {
  const include409 = options?.include409 === true;
  return applyDecorators(
    ApiResponse({
      status: 400,
      description: 'Validation or business rule failure',
      ...errExample('VALIDATION_ERROR', 'Validation failed'),
    }),
    ApiResponse({
      status: 401,
      description: 'Missing or invalid bearer token',
      ...errExample('UNAUTHORIZED', 'Unauthorized'),
    }),
    ApiResponse({
      status: 403,
      description: 'Authenticated user may not access or mutate this resource',
      ...errExample('NOT_EVENT_ORGANIZER', 'Only the organizer may perform this action'),
    }),
    ApiResponse({
      status: 404,
      description: 'Event not found or not visible',
      ...errExample('EVENT_NOT_FOUND', 'Event not found'),
    }),
    ...(include409
      ? [
          ApiResponse({
            status: 409,
            description: 'State conflict (e.g. duplicate join or capacity)',
            ...errExample('ALREADY_JOINED', 'You are already registered for this event'),
          }),
        ]
      : []),
    ApiResponse({
      status: 429,
      description: 'Too many requests (throttled)',
      ...errExample('TOO_MANY_REQUESTS', 'Too many requests. Please wait and try again.'),
    }),
  );
}
