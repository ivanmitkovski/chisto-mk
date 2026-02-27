import { useState } from 'react';
import { SnackState } from '@/components/ui';
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

export function useReportReview(initialReport: ReportDetail) {
  const [report, setReport] = useState<ReportDetail>(initialReport);
  const [isUpdating, setIsUpdating] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);

  async function mutateStatus(nextStatus: ReportStatus, action: ReviewAction, reason?: string) {
    setIsUpdating(true);
    const res = await fetch(`/api/reports/${encodeURIComponent(report.id)}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ status: nextStatus, reason: reason ?? undefined }),
    });

    const body = await res.json().catch(() => ({}));
    const message =
      body && typeof body.message === 'string'
        ? body.message
        : 'Unable to update this report right now.';

    if (!res.ok) {
      setSnack({
        tone: 'error',
        title: 'Action failed',
        message,
      });
      setIsUpdating(false);
      return;
    }

    const timelineEntry = createTimelineEntry(nextStatus, reason);
    setReport((prev) => ({
      ...prev,
      status: nextStatus,
      timeline: [timelineEntry, ...prev.timeline],
    }));

    if (action === 'approve') {
      setSnack({
        tone: 'success',
        title: 'Report approved',
        message: 'This report has been accepted successfully.',
      });
      setIsUpdating(false);
      return;
    }

    if (action === 'in-review') {
      setSnack({
        tone: 'info',
        title: 'Status updated',
        message: 'This report is now marked as in review.',
      });
      setIsUpdating(false);
      return;
    }

    setSnack({
      tone: 'warning',
      title: 'Report rejected',
      message: reason
        ? `This report has been rejected. Reason: ${reason}`
        : 'This report has been rejected and marked removed.',
    });
    setIsUpdating(false);
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
