import type { TelemetryEvent } from './types';

export interface TelemetrySink {
  emit(event: TelemetryEvent): void;
}
