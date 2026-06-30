import { SetMetadata } from '@nestjs/common';

export const IDEMPOTENCY_SCOPE_KEY = 'idempotency_scope';

/** Marks a mutating route as idempotent when `X-Idempotency-Key` (or `idempotency-key`) is sent. */
export function Idempotent(scope: string): MethodDecorator {
  return SetMetadata(IDEMPOTENCY_SCOPE_KEY, scope);
}
