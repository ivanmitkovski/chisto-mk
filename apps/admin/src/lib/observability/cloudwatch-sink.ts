import type { TelemetrySink } from './telemetry-sink';
import type { LogLevel, TelemetryEvent } from './types';

function stdoutMethod(level: LogLevel): (message: string) => void {
  if (level === 'error') return console.error.bind(console);
  if (level === 'warn') return console.warn.bind(console);
  return console.info.bind(console);
}

/** Default sink: structured JSON to stdout for CloudWatch / container log aggregation. */
export class CloudWatchTelemetrySink implements TelemetrySink {
  emit(event: TelemetryEvent): void {
    const line = JSON.stringify({
      service: 'chisto-admin',
      level: event.level,
      msg: event.message,
      timestamp: event.timestamp,
      requestId: event.requestId,
      source: event.source ?? 'admin-server',
      ...event.context,
    });
    stdoutMethod(event.level)(line);
  }
}
