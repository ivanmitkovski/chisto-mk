import { Logger } from '@nestjs/common';
import { auditWriteFailedTotal } from '../../observability/util/prom-registry';

const auditFailureLogger = new Logger('AuditLog');

export function recordAuditWriteFailure(action: string, err: unknown): void {
  auditWriteFailedTotal.inc({ action });
  auditFailureLogger.warn(
    `audit write failed action=${action} err=${err instanceof Error ? err.message : String(err)}`,
  );
}
