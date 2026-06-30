'use client';

import { useCallback } from 'react';
import { useTranslations } from 'next-intl';
import { useRouter } from 'next/navigation';
import { useToast } from '@/components/ui';
import { useOptimisticMutation } from '@/features/admin-shell';
import { patchReportStatus } from '../lib/patch-report-status';
import type { ReportStatus } from '../types';

type ActionKind = 'approve' | 'reject';

type StatusMutationVariables = {
  id: string;
  status: ReportStatus;
  action: ActionKind;
  reason?: string | undefined;
};

type UseReportsListActionsOptions = {
  onOptimisticStatus?: (id: string, status: ReportStatus) => void;
  onRollbackStatus?: (id: string, status: ReportStatus) => void;
};

export function useReportsListActions(options: UseReportsListActionsOptions = {}) {
  const t = useTranslations('reports.toast');
  const router = useRouter();
  const { showToast } = useToast();
  const { onOptimisticStatus, onRollbackStatus } = options;

  const { run, isPending } = useOptimisticMutation({
    mutate: async ({ id, status, action, reason }: StatusMutationVariables) => {
      const result = await patchReportStatus(id, status, action, reason);
      if (!result.ok) {
        throw new Error(result.message);
      }
      return { ...result, action };
    },
    onSuccess: (result) => {
      if (result.action === 'approve') {
        showToast({
          tone: 'success',
          title: t('approvedTitle'),
          message: t('approvedMessage'),
        });
      } else if (result.action === 'reject') {
        showToast({
          tone: 'success',
          title: t('rejectedTitle'),
          message: t('rejectedMessage'),
        });
      }
      router.refresh();
    },
    errorToast: {
      title: t('actionFailedTitle'),
    },
  });

  const updateStatus = useCallback(
    async (id: string, status: ReportStatus, action: ActionKind, reason?: string, previousStatus?: ReportStatus) => {
      const prior = previousStatus ?? status;
      const result = await run(
        { id, status, action, reason },
        {
          optimistic: () => onOptimisticStatus?.(id, status),
          rollback: () => onRollbackStatus?.(id, prior),
        },
      );

      if (result == null) {
        return false;
      }

      return true;
    },
    [onOptimisticStatus, onRollbackStatus, run],
  );

  return {
    isPending,
    approveReport: useCallback(
      (id: string, previousStatus?: ReportStatus) => updateStatus(id, 'APPROVED', 'approve', undefined, previousStatus),
      [updateStatus],
    ),
    rejectReport: useCallback(
      (id: string, reason?: string, previousStatus?: ReportStatus) =>
        updateStatus(id, 'DELETED', 'reject', reason, previousStatus),
      [updateStatus],
    ),
  };
}
