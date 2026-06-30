import { InternalServerErrorException } from '@nestjs/common';

/** Safe defaults when env allowlist is unset (never use `*`). */
export const WS_LOCAL_DEV_ORIGINS = ['http://localhost:3000', 'http://localhost:3001'] as const;

/**
 * Parses a comma-separated Socket.IO CORS allowlist.
 * In production/staging: missing or empty list throws (no `*` fallback).
 * In development/test: falls back to localhost dev origins.
 */
export function parseWsCorsAllowlist(
  raw: string | undefined,
  envVarName: string,
): string[] {
  const trimmed = raw?.trim();
  const node = (process.env.NODE_ENV ?? 'development').trim().toLowerCase();
  const strict = node === 'production' || node === 'staging';

  if (!trimmed) {
    if (strict) {
      throw new InternalServerErrorException({
        code: `${envVarName}_MISSING`,
        message: `${envVarName} must be set in ${node} (comma-separated allowlist)`,
      });
    }
    return [...WS_LOCAL_DEV_ORIGINS];
  }

  const list = trimmed.split(',').map((s) => s.trim()).filter(Boolean);
  if (list.length === 0) {
    if (strict) {
      throw new InternalServerErrorException({
        code: `${envVarName}_EMPTY`,
        message: `${envVarName} was set but parsed to an empty allowlist`,
      });
    }
    return [...WS_LOCAL_DEV_ORIGINS];
  }
  return list;
}
