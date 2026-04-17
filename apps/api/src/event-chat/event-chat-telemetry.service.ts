import { Injectable, Logger } from '@nestjs/common';

/**
 * Structured logs for chat metrics, coarse spans, and audit (no Prometheus dependency).
 * Log processors aggregate on `type` and `name` / `action`.
 */
@Injectable()
export class EventChatTelemetryService {
  private readonly logger = new Logger(EventChatTelemetryService.name);

  emitMetric(fields: Record<string, string | number | boolean | null | undefined>): void {
    this.logger.log(
      JSON.stringify({
        type: 'event_chat_metric',
        ts: new Date().toISOString(),
        ...fields,
      }),
    );
  }

  emitSpan(name: string, fields: Record<string, string | number | boolean | null | undefined>): void {
    this.logger.log(
      JSON.stringify({
        type: 'event_chat_span',
        name,
        ts: new Date().toISOString(),
        ...fields,
      }),
    );
  }

  emitAudit(action: string, fields: Record<string, string | number | boolean | null | undefined>): void {
    this.logger.log(
      JSON.stringify({
        type: 'event_chat_audit',
        action,
        ts: new Date().toISOString(),
        ...fields,
      }),
    );
  }
}
