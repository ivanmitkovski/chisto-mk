import { trace } from '@opentelemetry/api';
import { getInboundTraceparent } from './http-request-trace';

/** Fields merged into every Pino log line for request/trace correlation. */
export function pinoLogMixin(): Record<string, string | undefined> {
  const traceparent = getInboundTraceparent();
  const traceIdFromHeader = traceparent?.split('-')[1];
  const activeSpan = trace.getActiveSpan();
  const spanContext = activeSpan?.spanContext();
  const traceId = traceIdFromHeader ?? spanContext?.traceId;
  const spanId = spanContext?.spanId;

  const out: Record<string, string | undefined> = {};
  if (traceId) {
    out.trace_id = traceId;
  }
  if (spanId) {
    out.span_id = spanId;
  }
  if (traceparent) {
    out.traceparent = traceparent;
  }
  return out;
}

export function resolveLogLevel(): string {
  const raw = process.env.LOG_LEVEL?.trim().toLowerCase();
  if (raw && ['trace', 'debug', 'info', 'warn', 'error', 'fatal'].includes(raw)) {
    return raw;
  }
  return process.env.NODE_ENV === 'production' ? 'info' : 'debug';
}
