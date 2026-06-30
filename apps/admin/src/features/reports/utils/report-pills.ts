import type { ReportPriority, ReportStatus } from '../types';

/**
 * CSS module shape for status + priority pills (shared by detail page and review card).
 * Call sites pass their scoped `styles` object cast to this type.
 */
export type ReportPillClassNames = {
  statusPill: string;
  statusNew: string;
  statusInReview: string;
  statusApproved: string;
  statusDeleted: string;
  priorityPill: string;
  priorityLow: string;
  priorityMedium: string;
  priorityHigh: string;
  priorityCritical: string;
};

export function reportStatusPillClass(status: ReportStatus, s: ReportPillClassNames): string {
  const byStatus: Record<ReportStatus, string> = {
    NEW: s.statusNew,
    IN_REVIEW: s.statusInReview,
    APPROVED: s.statusApproved,
    DELETED: s.statusDeleted,
  };
  return `${s.statusPill} ${byStatus[status]}`;
}

export function reportPriorityPillClass(priority: ReportPriority, s: ReportPillClassNames): string {
  const byPriority: Record<ReportPriority, string> = {
    LOW: s.priorityLow,
    MEDIUM: s.priorityMedium,
    HIGH: s.priorityHigh,
    CRITICAL: s.priorityCritical,
  };
  return `${s.priorityPill} ${byPriority[priority]}`;
}
