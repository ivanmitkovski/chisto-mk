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

/** Shared 4xx/429 shapes for event chat REST (stable `code` strings; see `EVENT_CHAT_ERROR_CODES` in codes.ts). */
export function ApiEventChatStandardErrors(options?: {
  include404?: boolean;
  include403?: boolean;
}): ReturnType<typeof applyDecorators> {
  const include404 = options?.include404 !== false;
  const include403 = options?.include403 !== false;
  return applyDecorators(
    ApiResponse({
      status: 400,
      description: 'Validation or business rule failure',
      ...errExample('EVENT_CHAT_BODY_INVALID', 'Message must be between 1 and 2000 characters'),
    }),
    ...(include403
      ? [
          ApiResponse({
            status: 403,
            description: 'Authenticated user may not perform this action',
            ...errExample('EVENT_CHAT_FORBIDDEN', 'Chat access denied'),
          }),
        ]
      : []),
    ...(include404
      ? [
          ApiResponse({
            status: 404,
            description: 'Resource not found or not visible',
            ...errExample('EVENT_NOT_FOUND', 'Event not found'),
          }),
        ]
      : []),
    ApiResponse({
      status: 429,
      description: 'Too many requests (throttled)',
      ...errExample(
        'TOO_MANY_REQUESTS',
        'Too many requests. Please wait and try again.',
      ),
    }),
  );
}
