import { applyDecorators } from '@nestjs/common';
import { ApiResponse } from '@nestjs/swagger';

/** Class-level OpenAPI documentation for common HTTP error shapes. */
export function ApiStandardHttpErrorResponses() {
  return applyDecorators(
    ApiResponse({ status: 400, description: 'Validation or bad request' }),
    ApiResponse({ status: 401, description: 'Missing or invalid bearer token' }),
    ApiResponse({ status: 403, description: 'Insufficient permissions' }),
    ApiResponse({ status: 404, description: 'Resource not found' }),
    ApiResponse({ status: 429, description: 'Rate limited' }),
  );
}
