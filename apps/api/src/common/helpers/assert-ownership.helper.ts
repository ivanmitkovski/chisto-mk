import { ForbiddenException } from '@nestjs/common';
import { Role } from '../../prisma-client';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';

export type ReportOwnershipContext = {
  id: string;
  reporterId: string | null;
};

/**
 * SECURITY: Central IDOR check for report reads — moderators bypass; otherwise reporter or co-reporter only.
 */
export function assertReportVisibleToUser(
  report: ReportOwnershipContext,
  coReporterUserIds: string[],
  user: AuthenticatedUser,
  moderationRoles: readonly Role[],
): void {
  if (moderationRoles.includes(user.role)) {
    return;
  }
  if (report.reporterId === user.userId) {
    return;
  }
  if (coReporterUserIds.includes(user.userId)) {
    return;
  }
  throw new ForbiddenException({
    code: 'FORBIDDEN',
    message: 'You do not have access to this report',
  });
}
