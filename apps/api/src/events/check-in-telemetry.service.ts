import { Injectable, Logger } from '@nestjs/common';

/**
 * Structured logs for check-in metrics and audit (no Prometheus dependency).
 * Log processors can aggregate on `type` and `metric` / `action`.
 */
@Injectable()
export class CheckInTelemetryService {
  private readonly logger = new Logger(CheckInTelemetryService.name);

  emitMetric(fields: Record<string, string | number | boolean | null | undefined>): void {
    const payload: Record<string, unknown> = {
      type: 'check_in_metric',
      ts: new Date().toISOString(),
      ...fields,
    };
    this.logger.log(JSON.stringify(payload));
  }

  /** Duration span marker (OTel-style naming without SDK). */
  emitSpan(name: string, fields: Record<string, string | number | boolean | null | undefined>): void {
    this.logger.log(
      JSON.stringify({
        type: 'check_in_span',
        name,
        ts: new Date().toISOString(),
        ...fields,
      }),
    );
  }

  emitAudit(action: string, fields: Record<string, string | number | boolean | null | undefined>): void {
    this.logger.log(
      JSON.stringify({
        type: 'check_in_audit',
        action,
        ts: new Date().toISOString(),
        ...fields,
      }),
    );
  }
}
