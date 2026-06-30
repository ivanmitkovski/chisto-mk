import { Injectable, Logger } from '@nestjs/common';

/**
 * Coarse duration spans for mobile-facing events queries (list, detail, participants).
 * Log processors aggregate on `type` === `events_span` and `name`. Do not log PII.
 */
@Injectable()
export class EventsTelemetryService {
  private readonly logger = new Logger(EventsTelemetryService.name);

  emitSpan(name: string, fields: Record<string, string | number | boolean | null | undefined>): void {
    this.logger.log(
      JSON.stringify({
        type: 'events_span',
        name,
        ts: new Date().toISOString(),
        ...fields,
      }),
    );
  }
}
