/**
 * Prisma `@default(cuid())` primary keys in this codebase (25 chars).
 * Keep in sync with `schema.prisma` string `@id` defaults.
 */
export const PRISMA_CUID_REGEX = /^c[0-9a-z]{24}$/;

export function isPrismaCuid(value: unknown): value is string {
  return typeof value === 'string' && PRISMA_CUID_REGEX.test(value);
}
