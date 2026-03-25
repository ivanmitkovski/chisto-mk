import { ReportStatus } from '../prisma-client';

/**
 * Owner-facing realtime events for citizen clients (mobile).
 *
 * Design goals:
 * - Minimal disclosure: only emit what the authenticated owner is allowed to learn.
 * - Reconciliation-safe: carry identifiers/timestamps so clients can dedupe and recover.
 * - Fetch-based UI: payload is intentionally small; clients refetch affected resources.
 *
 * Emission matrix (owner-relevant):
 * - Report created by user: `report_created`
 * - Moderator changes status/reason/points: `report_updated` (includes status)
 * - Duplicate merge affects a user's report (primary approved, children deleted): `report_updated` for each affected report
 * - Media appended to report: `report_updated`
 */

export type OwnerReportEventType = 'report_created' | 'report_updated';

export type OwnerReportEventMutation =
  | {
      kind: 'created';
    }
  | {
      kind: 'status_changed' | 'merged' | 'media_appended' | 'updated';
      status?: ReportStatus;
    };

export type OwnerReportEvent = {
  /**
   * Unique ID for deduplication across reconnects (best-effort within process).
   */
  eventId: string;
  type: OwnerReportEventType;
  ownerId: string;
  reportId: string;
  occurredAtMs: number;
  mutation: OwnerReportEventMutation;
};

