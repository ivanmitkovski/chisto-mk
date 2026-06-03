import { Injectable, Logger } from '@nestjs/common';

/**
 * Structured logs for check-in metrics and audit (no Prometheus dependency).
 * Hot paths use `debug` with summarized fields in production to reduce noise and cost.
 */
@Injectable()
export class CheckInTelemetryService {
  private readonly logger = new Logger(CheckInTelemetryService.name);
  private readonly isProd = (process.env.NODE_ENV ?? '').toLowerCase() === 'production';

  emitMetric(fields: Record<string, string | number | boolean | null | undefined>): void {
    if (this.isProd) {
      this.logger.debug({
        type: 'check_in_metric',
        metric: fields.metric,
        eventId: fields.eventId,
        userId: fields.userId,
        ts: new Date().toISOString(),
      });
      return;
    }
    this.logger.debug(
      JSON.stringify({
        type: 'check_in_metric',
        ts: new Date().toISOString(),
        ...fields,
      }),
    );
  }

  /** Duration span marker (OTel-style naming without SDK). */
  emitSpan(name: string, fields: Record<string, string | number | boolean | null | undefined>): void {
    if (this.isProd) {
      this.logger.debug({ type: 'check_in_span', name, ts: new Date().toISOString() });
      return;
    }
    this.logger.debug(
      JSON.stringify({
        type: 'check_in_span',
        name,
        ts: new Date().toISOString(),
        ...fields,
      }),
    );
  }

  emitAudit(action: string, fields: Record<string, string | number | boolean | null | undefined>): void {
    if (this.isProd) {
      this.logger.debug({
        type: 'check_in_audit',
        action,
        eventId: fields.eventId,
        userId: fields.userId,
        ts: new Date().toISOString(),
      });
      return;
    }
    this.logger.debug(
      JSON.stringify({
        type: 'check_in_audit',
        action,
        ts: new Date().toISOString(),
        ...fields,
      }),
    );
  }
}
