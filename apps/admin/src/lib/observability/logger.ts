import { CloudWatchTelemetrySink } from './cloudwatch-sink';
import type { TelemetrySink } from './telemetry-sink';
import type { LogLevel, TelemetryEvent } from './types';

let sink: TelemetrySink = new CloudWatchTelemetrySink();

export function setTelemetrySink(next: TelemetrySink): void {
  sink = next;
}

function log(
  level: LogLevel,
  message: string,
  context?: Record<string, unknown> & { requestId?: string; source?: TelemetryEvent['source'] },
): void {
  const { requestId, source, ...rest } = context ?? {};
  sink.emit({
    level,
    message,
    timestamp: new Date().toISOString(),
    source: source ?? 'admin-server',
    ...(requestId !== undefined ? { requestId } : {}),
    ...(Object.keys(rest).length > 0 ? { context: rest } : {}),
  });
}

export const logger = {
  debug: (message: string, context?: Record<string, unknown> & { requestId?: string }) =>
    log('debug', message, context),
  info: (message: string, context?: Record<string, unknown> & { requestId?: string }) =>
    log('info', message, context),
  warn: (message: string, context?: Record<string, unknown> & { requestId?: string }) =>
    log('warn', message, context),
  error: (message: string, context?: Record<string, unknown> & { requestId?: string }) =>
    log('error', message, context),
};
