'use client';

import { useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useOptimisticMutation } from '@/features/admin-shell';
import { patchReportAssign } from '../lib/patch-report-assign';
import type { ReportDetail } from '../types';

type UseReportAssignOptions = {
  report: ReportDetail;
  currentModeratorId?: string | null;
  moderatorDisplayName?: string | undefined;
  onReportUpdated?: (() => void) | undefined;
  onOptimistic?: (next: Pick<ReportDetail, 'status' | 'moderation'>) => void;
  onRollback?: () => void;
};

export function useReportAssign({
  report,
  currentModeratorId,
  moderatorDisplayName = 'You',
  onReportUpdated,
  onOptimistic,
  onRollback,
}: UseReportAssignOptions) {
  const router = useRouter();
  const tToast = useTranslations('reports.toast');

  const { run, isPending } = useOptimisticMutation({
    mutate: async (body: { moderatorId?: string; unassign?: boolean }) => {
      const result = await patchReportAssign(report.id, body);
      if (!result.ok) {
        throw new Error(result.message);
      }
      return result;
    },
    successToast: {
      title: tToast('assignmentUpdatedTitle'),
      message: tToast('assignmentUpdatedMessage'),
    },
    errorToast: {
      title: tToast('assignmentFailedTitle'),
    },
    onSuccess: () => {
      onReportUpdated?.();
      router.refresh();
    },
  });

  const assignToMe = useCallback(async () => {
    const snapshot = {
      status: report.status,
      moderation: report.moderation,
    };
    await run(
      {},
      {
        optimistic: () =>
          onOptimistic?.({
            status: report.status === 'NEW' ? 'IN_REVIEW' : report.status,
            moderation: {
              ...report.moderation,
              assignedModeratorId: currentModeratorId ?? null,
              assignedModeratorName: moderatorDisplayName,
              assignedTeam: moderatorDisplayName,
            },
          }),
        rollback: () => onRollback?.() ?? onOptimistic?.(snapshot),
      },
    );
  }, [currentModeratorId, moderatorDisplayName, onOptimistic, onRollback, report, run]);

  const assignToModerator = useCallback(
    async (moderatorId: string, displayName: string) => {
      const snapshot = {
        status: report.status,
        moderation: report.moderation,
      };
      await run(
        { moderatorId },
        {
          optimistic: () =>
            onOptimistic?.({
              status: report.status === 'NEW' ? 'IN_REVIEW' : report.status,
              moderation: {
                ...report.moderation,
                assignedModeratorId: moderatorId,
                assignedModeratorName: displayName,
                assignedTeam: displayName,
              },
            }),
          rollback: () => onRollback?.() ?? onOptimistic?.(snapshot),
        },
      );
    },
    [onOptimistic, onRollback, report, run],
  );

  const releaseAssignment = useCallback(async () => {
    const snapshot = {
      status: report.status,
      moderation: report.moderation,
    };
    await run(
      { unassign: true },
      {
        optimistic: () =>
          onOptimistic?.({
            status: report.status,
            moderation: {
              ...report.moderation,
              assignedModeratorId: null,
              assignedModeratorName: null,
              assignedTeam: report.moderation.queueLabel,
            },
          }),
        rollback: () => onRollback?.() ?? onOptimistic?.(snapshot),
      },
    );
  }, [onOptimistic, onRollback, report, run]);

  const isAssignedToMe =
    !!currentModeratorId &&
    report.moderation.assignedModeratorId != null &&
    report.moderation.assignedModeratorId === currentModeratorId;

  return {
    assignToMe,
    assignToModerator,
    releaseAssignment,
    isAssigning: isPending,
    isAssignedToMe,
    hasAssignee: report.moderation.assignedModeratorId != null,
  };
}

export type ReportAssignControls = ReturnType<typeof useReportAssign>;
