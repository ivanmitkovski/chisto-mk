import type { IncomingMessage } from 'http';
import pino from 'pino';

const baseReqSerializer = pino.stdSerializers.req;

/**
 * Pino request serializer that strips credentials from structured logs.
 * nestjs-pino attaches `req` to request-scoped log lines; without this, JWTs leak to log sinks.
 */
export function safePinoReqSerializer(req: IncomingMessage): Record<string, unknown> {
  const serialized = baseReqSerializer(req) as unknown as Record<string, unknown>;
  const headers = serialized['headers'];
  if (!headers || typeof headers !== 'object' || Array.isArray(headers)) {
    return serialized;
  }
  const h = { ...(headers as Record<string, unknown>) };
  delete h.authorization;
  delete h.Authorization;
  delete h.cookie;
  delete h.Cookie;
  return { ...serialized, headers: h };
}
