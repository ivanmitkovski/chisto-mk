import { ReportStatus } from '../../prisma-client';

/** Exposes rejection narrative to reporters only when the report was declined (DELETED). */
export function citizenModerationReasonForResponse(
  status: ReportStatus,
  moderationReason: string | null | undefined,
): string | null {
  if (status !== ReportStatus.DELETED) {
    return null;
  }
  const trimmed = moderationReason?.trim();
  return trimmed && trimmed.length > 0 ? trimmed : null;
}
