import type { AdminReportDetailDto } from './dto/admin-report.dto';
import type { ReportStatus } from '../prisma-client';

export function deriveAdminReportDetailPriority(
  status: ReportStatus,
): AdminReportDetailDto['priority'] {
  if (status === 'NEW') {
    return 'HIGH';
  }

  if (status === 'IN_REVIEW') {
    return 'MEDIUM';
  }

  if (status === 'APPROVED') {
    return 'LOW';
  }

  return 'LOW';
}
