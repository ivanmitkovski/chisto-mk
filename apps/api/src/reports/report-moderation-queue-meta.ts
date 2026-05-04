import type { ReportStatus } from '../prisma-client';

export type ModerationQueueMeta = {
  readonly moderationQueueLabel: string;
  readonly moderationAssignedTeam: string;
  readonly moderationSlaLabel: string;
};

/**
 * Placeholder moderation UX metadata for the admin panel until assignment/SLA is dynamic.
 */
export function moderationQueueMetaForStatus(status: ReportStatus): ModerationQueueMeta {
  const moderationQueueLabel = 'General Queue';
  const moderationAssignedTeam = 'City Moderation';
  const moderationSlaLabel =
    status === 'NEW' ? '4h remaining' : status === 'IN_REVIEW' ? '2h remaining' : 'Completed';
  return { moderationQueueLabel, moderationAssignedTeam, moderationSlaLabel };
}
