'use client';

import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { useOptimisticMutation } from '@/features/admin-shell';
import { patchReportStatus } from '../lib/patch-report-status';
import { ReportDetail, ReportStatus, ReportTimelineEntry } from '../types';

type ReviewAction = 'approve' | 'reject' | 'in-review';

function nowIsoString() {
  return new Date().toISOString();
}

function createEntryId() {
  return `tl-${Date.now()}-${Math.round(Math.random() * 10000)}`;
}

type TimelineTranslator = (key: string, values?: Record<string, string>) => string;

function createTimelineEntry(
  status: ReportStatus,
  actor: string,
  tTimeline: TimelineTranslator,
  reason?: string,
): ReportTimelineEntry {
  if (status === 'APPROVED') {
    return {
      id: createEntryId(),
      title: tTimeline('approvedTitle'),
      detail: tTimeline('approvedDetail'),
      actor,
      occurredAt: nowIsoString(),
      tone: 'success',
    };
  }

  if (status === 'DELETED') {
    return {
      id: createEntryId(),
      title: tTimeline('rejectedTitle'),
      detail: reason
        ? tTimeline('rejectedDetailWithReason', { reason })
        : tTimeline('rejectedDetail'),
      actor,
      occurredAt: nowIsoString(),
      tone: 'warning',
    };
  }

  return {
    id: createEntryId(),
    title: tTimeline('inReviewTitle'),
    detail: tTimeline('inReviewDetail'),
    actor,
    occurredAt: nowIsoString(),
    tone: 'neutral',
  };
}

type UseReportReviewOptions = {
  moderatorDisplayName?: string;
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
    r.moderation.assignedModeratorId ?? '',
  ].join('|');
}

export function useReportReview(initialReport: ReportDetail, options?: UseReportReviewOptions) {
  const tToast = useTranslations('reports.toast');
  const tTimeline = useTranslations('reports.timeline');
  const onReportUpdated = options?.onReportUpdated;
  const moderatorDisplayName = options?.moderatorDisplayName ?? 'Current moderator';
  const [report, setReport] = useState<ReportDetail>(initialReport);
  const { showToast } = useToast();

  const serverSyncKey = reportReviewServerSyncKey(initialReport);
  useEffect(() => {
    setReport(initialReport);
  }, [initialReport, serverSyncKey]);

  const { run, isPending: isUpdating } = useOptimisticMutation({
    mutate: async ({
      nextStatus,
      action,
      reason,
    }: {
      nextStatus: ReportStatus;
      action: ReviewAction;
      reason?: string | undefined;
    }) => {
      const result = await patchReportStatus(report.id, nextStatus, action, reason);
      if (!result.ok) {
        throw new Error(result.message);
      }
      return { nextStatus, action, reason };
    },
    onSuccess: () => {
      onReportUpdated?.();
    },
    errorToast: {
      title: tToast('actionFailedTitle'),
    },
  });

  async function mutateStatus(
    nextStatus: ReportStatus,
    action: ReviewAction,
    reason?: string,
  ): Promise<boolean> {
    const trimmed = (reason ?? '').trim();
    const rejectDefault = 'Rejected by moderator.';
    const snapshot = report;

    const result = await run(
      { nextStatus, action, reason },
      {
        optimistic: () => {
          const timelineEntry = createTimelineEntry(
            nextStatus,
            moderatorDisplayName,
            tTimeline,
            action === 'reject' ? (trimmed.length > 0 ? trimmed : rejectDefault) : reason,
          );
          setReport((prev) => ({
            ...prev,
            status: nextStatus,
            timeline: [timelineEntry, ...prev.timeline],
          }));
        },
        rollback: () => setReport(snapshot),
      },
    );

    if (result == null) {
      return false;
    }

    if (action === 'approve') {
      showToast({
        tone: 'success',
        title: tToast('approvedTitle'),
        message: tToast('approvedMessage'),
      });
      return true;
    }

    if (action === 'in-review') {
      showToast({
        tone: 'info',
        title: tToast('inReviewTitle'),
        message: tToast('inReviewMessage'),
      });
      return true;
    }

    showToast({
      tone: 'warning',
      title: tToast('rejectedTitle'),
      message: reason
        ? tToast('rejectedWithReasonMessage', { reason })
        : tToast('rejectedMessage'),
    });
    return true;
  }

  return {
    report,
    setReport,
    isUpdating,
    setInReview: () => mutateStatus('IN_REVIEW', 'in-review'),
    approveReport: () => mutateStatus('APPROVED', 'approve'),
    rejectReport: (reason?: string) => mutateStatus('DELETED', 'reject', reason),
  };
}
