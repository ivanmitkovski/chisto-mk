import { useEffect, useState } from 'react';
import { SnackState } from '@/components/ui';
import { patchReportStatus } from '../lib/patch-report-status';
import { ReportDetail, ReportStatus, ReportTimelineEntry } from '../types';

type ReviewAction = 'approve' | 'reject' | 'in-review';

function nowIsoString() {
  return new Date().toISOString();
}

function createEntryId() {
  return `tl-${Date.now()}-${Math.round(Math.random() * 10000)}`;
}

function createTimelineEntry(status: ReportStatus, reason?: string): ReportTimelineEntry {
  if (status === 'APPROVED') {
    return {
      id: createEntryId(),
      title: 'Report approved',
      detail: 'Moderator accepted the report and moved it to approved lifecycle state.',
      actor: 'Current moderator',
      occurredAt: nowIsoString(),
      tone: 'success',
    };
  }

  if (status === 'DELETED') {
    return {
      id: createEntryId(),
      title: 'Report rejected',
      detail: reason
        ? `Report was rejected and marked as removed. Reason: ${reason}`
        : 'Report was rejected and marked as removed after moderation review.',
      actor: 'Current moderator',
      occurredAt: nowIsoString(),
      tone: 'warning',
    };
  }

  return {
    id: createEntryId(),
    title: 'Moved to in-review',
    detail: 'Report status moved to in-review for deeper moderation checks.',
    actor: 'Current moderator',
    occurredAt: nowIsoString(),
    tone: 'neutral',
  };
}

type UseReportReviewOptions = {
  onReportUpdated?: () => void;
};

function reportReviewServerSyncKey(r: ReportDetail): string {
  const t0 = r.timeline[0];
  return [
    r.id,
    r.status,
    r.submittedAt,
    String(r.evidence.length),
    t0?.id ?? '',
    t0?.occurredAt ?? '',
    r.priority,
  ].join('|');
}

export function useReportReview(initialReport: ReportDetail, options?: UseReportReviewOptions) {
  const onReportUpdated = options?.onReportUpdated;
  const [report, setReport] = useState<ReportDetail>(initialReport);
  const [isUpdating, setIsUpdating] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);

  const serverSyncKey = reportReviewServerSyncKey(initialReport);
  useEffect(() => {
    setReport(initialReport);
  }, [initialReport, serverSyncKey]);

  async function mutateStatus(
    nextStatus: ReportStatus,
    action: ReviewAction,
    reason?: string,
  ): Promise<boolean> {
    setIsUpdating(true);
    const trimmed = (reason ?? '').trim();
    const rejectDefault = 'Rejected by moderator.';

    const result = await patchReportStatus(report.id, nextStatus, action, reason);

    if (!result.ok) {
      setSnack({
        tone: 'error',
        title: 'Action failed',
        message: result.message,
      });
      setIsUpdating(false);
      return false;
    }

    const timelineEntry = createTimelineEntry(
      nextStatus,
      action === 'reject' ? (trimmed.length > 0 ? trimmed : rejectDefault) : reason,
    );
    setReport((prev) => ({
      ...prev,
      status: nextStatus,
      timeline: [timelineEntry, ...prev.timeline],
    }));

    onReportUpdated?.();

    if (action === 'approve') {
      setSnack({
        tone: 'success',
        title: 'Report approved',
        message: 'This report has been accepted successfully.',
      });
      setIsUpdating(false);
      return true;
    }

    if (action === 'in-review') {
      setSnack({
        tone: 'info',
        title: 'Status updated',
        message: 'This report is now marked as in review.',
      });
      setIsUpdating(false);
      return true;
    }

    setSnack({
      tone: 'warning',
      title: 'Report rejected',
      message: reason
        ? `This report has been rejected. Reason: ${reason}`
        : 'This report has been rejected and marked removed.',
    });
    setIsUpdating(false);
    return true;
  }

  return {
    report,
    isUpdating,
    snack,
    setInReview: () => mutateStatus('IN_REVIEW', 'in-review'),
    approveReport: () => mutateStatus('APPROVED', 'approve'),
    rejectReport: (reason?: string) => mutateStatus('DELETED', 'reject', reason),
    clearSnack: () => setSnack(null),
  };
}
