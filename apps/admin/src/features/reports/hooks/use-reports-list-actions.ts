import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import type { SnackState } from '@/components/ui';
import { patchReportStatus } from '../lib/patch-report-status';
import type { ReportStatus } from '../types';

type ActionKind = 'approve' | 'reject';

export function useReportsListActions() {
  const router = useRouter();
  const [snack, setSnack] = useState<SnackState | null>(null);

  useEffect(() => {
    if (!snack) return;
    const t = window.setTimeout(() => setSnack(null), 2400);
    return () => window.clearTimeout(t);
  }, [snack]);

  const updateStatus = useCallback(
    async (id: string, status: ReportStatus, action: ActionKind, reason?: string) => {
      const result = await patchReportStatus(id, status, action, reason);

      if (!result.ok) {
        setSnack({ tone: 'error', title: 'Action failed', message: result.message });
        return false;
      }

      router.refresh();

      if (action === 'approve') {
        setSnack({
          tone: 'success',
          title: 'Report approved',
          message: 'The report has been accepted and moved to approved state.',
        });
      } else {
        setSnack({
          tone: 'warning',
          title: 'Report rejected',
          message: reason ? `The report has been rejected. Reason: ${reason}` : 'The report has been rejected.',
        });
      }

      return true;
    },
    [router],
  );

  return {
    approveReport: useCallback((id: string) => updateStatus(id, 'APPROVED', 'approve'), [updateStatus]),
    rejectReport: useCallback((id: string, reason?: string) => updateStatus(id, 'DELETED', 'reject', reason), [updateStatus]),
    snack,
    clearSnack: useCallback(() => setSnack(null), []),
  };
}
